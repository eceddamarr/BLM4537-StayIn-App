using System.Net;
using System.IdentityModel.Tokens.Jwt;
using System.Security.Claims;
using System.Text;
using BCrypt.Net;
using Microsoft.AspNetCore.Mvc;
using Microsoft.EntityFrameworkCore;
using Microsoft.IdentityModel.Tokens;
using StayIn.Api.Data;
using StayIn.Api.Services;

namespace StayIn.Api.Controllers;

[ApiController]
[Route("api/[controller]")]
public class AuthController : ControllerBase
{
    private readonly AppDbContext _db;
    private readonly IConfiguration _config;
    private readonly IEmailService _emailService;

    public AuthController(AppDbContext db, IConfiguration config, IEmailService emailService)
    {
        _db = db;
        _config = config;
        _emailService = emailService;
    }

    // İstekle gelecek veriyi temsil eden mini sınıf
    public class LoginRequest
    {
        public string Email { get; set; } = default!;
        public string Password { get; set; } = default!;
    }

    public class RegisterRequest
    {
        public string FullName { get; set; } = default!;
        public string Email { get; set; } = default!;
        public string Password { get; set; } = default!;

        public string PasswordConfirm { get; set; } = default!;
    }

    public class ForgotPasswordRequest
    {
        public string Email { get; set; } = default!;
    }

    public class VerifyCodeRequest
    {
        public string Email { get; set; } = default!;
        public string Code { get; set; } = default!;
    }

    public class ResetPasswordRequest
    {
    public string Email { get; set; } = default!;
    public string Code { get; set; } = default!;
    public string NewPassword { get; set; } = default!;
    public string NewPasswordConfirm { get; set; } = default!;
    }

    // POST /api/Auth/login
    [HttpPost("login")]
    public async Task<IActionResult> Login([FromBody] LoginRequest request)
    {
        // Email veya şifre boşsa
        if (string.IsNullOrWhiteSpace(request.Email) || string.IsNullOrWhiteSpace(request.Password))
            return BadRequest(new { message = "Email ve şifre gerekli." });

        // Veritabanında kullanıcıyı bul
        var user = await _db.Users.FirstOrDefaultAsync(u => u.Email == request.Email);
        if (user == null)
            return Unauthorized(new { message = "Kullanıcı bulunamadı veya şifre hatalı." });

        // BCrypt ile şifreyi karşılaştır
        var ok = BCrypt.Net.BCrypt.Verify(request.Password, user.PasswordHash);
        if (!ok)
            return Unauthorized(new { message = "Kullanıcı bulunamadı veya şifre hatalı." });

        //  JWT üret ve döndür
        var token = GenerateJwt(user.Id, user.Email, user.Role);

        return Ok(new
        {
            token,
            user = new { user.Id, user.FullName, user.Email, user.Role }
        });
    }

    // POST /api/Auth/register
    [HttpPost("register")]
    public async Task<IActionResult> Register([FromBody] RegisterRequest request)
    {
        // Tüm alanların dolu olduğunu kontrol et
        if (string.IsNullOrWhiteSpace(request.Email) || string.IsNullOrWhiteSpace(request.Password) 
        || string.IsNullOrWhiteSpace(request.FullName) || string.IsNullOrWhiteSpace(request.PasswordConfirm))
            return BadRequest(new { message = "Lütfen tüm alanları doldurun." });

        // Şifreler eşleşmiyorsa
        if (request.Password != request.PasswordConfirm)
            return BadRequest(new { message = "Şifreler eşleşmiyor." });

        // Aynı email ile kullanıcı var mı kontrol et
        var existingUser = await _db.Users.AnyAsync(u => u.Email == request.Email);
        if (existingUser)
            return BadRequest(new { message = "Bu email ile zaten bir kullanıcı mevcut." });

        // Yeni kullanıcı oluştur
        var user = new Models.User
        {
            FullName = request.FullName,
            Email = request.Email,
            PasswordHash = BCrypt.Net.BCrypt.HashPassword(request.Password),
            Role = "User" // varsayılan rol
        };

        _db.Users.Add(user);
        await _db.SaveChangesAsync();

        //  JWT üret ve döndür
        var token = GenerateJwt(user.Id, user.Email, user.Role);

        return Ok(new
        {
            token,
            user = new { user.Id, user.FullName, user.Email, user.Role }
        });
    }

    [HttpPost("forgot-password")]
    public async Task<IActionResult> ForgotPassword([FromBody] ForgotPasswordRequest request)
    {
        if (string.IsNullOrWhiteSpace(request.Email))
            return BadRequest(new { message = "Email gerekli." });

        var user = await _db.Users.FirstOrDefaultAsync(u => u.Email == request.Email);
        if (user == null)
            return NotFound(new { message = "Bu email ile kayıtlı kullanıcı bulunamadı." });

        // 6 haneli rastgele kod oluştur
        var code = new Random().Next(100000, 999999).ToString();
        
        // Kodu veritabanına kaydet (10 dakika geçerli)
        user.VerificationCode = code;
        user.VerificationCodeExpires = DateTime.UtcNow.AddMinutes(10);
        await _db.SaveChangesAsync();

        // E-posta gönder
        try
        {
            await _emailService.SendVerificationCodeAsync(user.Email, code);
            
            // Development ortamında kodu response'da da döndür
            #if DEBUG
            return Ok(new { 
                message = "Doğrulama kodu e-posta adresinize gönderildi.",
                code = code // Sadece test için
            });
            #else
            return Ok(new { message = "Doğrulama kodu e-posta adresinize gönderildi." });
            #endif
        }
        catch (Exception ex)
        {
            return StatusCode(500, new { message = "E-posta gönderilirken bir hata oluştu.", error = ex.Message });
        }
    }

    [HttpPost("verify-code")]
    public async Task<IActionResult> VerifyCode([FromBody] VerifyCodeRequest request)
    {
        if (string.IsNullOrWhiteSpace(request.Email) || string.IsNullOrWhiteSpace(request.Code))
            return BadRequest(new { message = "Email ve kod gerekli." });

        var user = await _db.Users.FirstOrDefaultAsync(u => u.Email == request.Email);
        if (user == null)
            return NotFound(new { message = "Kullanıcı bulunamadı." });

        // Kod kontrolü
        if (user.VerificationCode != request.Code)
            return BadRequest(new { message = "Geçersiz kod." });

        // Süre kontrolü
        if (user.VerificationCodeExpires == null || user.VerificationCodeExpires < DateTime.UtcNow)
            return BadRequest(new { message = "Kod süresi dolmuş. Lütfen yeni bir kod isteyin." });

        return Ok(new { message = "Kod doğrulandı. Şifrenizi sıfırlayabilirsiniz." });
    }

    [HttpPost("reset-password")]
    public async Task<IActionResult> ResetPassword([FromBody] ResetPasswordRequest request)
    {
        if (string.IsNullOrWhiteSpace(request.Email) || string.IsNullOrWhiteSpace(request.Code) 
            || string.IsNullOrWhiteSpace(request.NewPassword) || string.IsNullOrWhiteSpace(request.NewPasswordConfirm))
            return BadRequest(new { message = "Tüm alanlar gerekli." });

        if (request.NewPassword != request.NewPasswordConfirm)
            return BadRequest(new { message = "Şifreler aynı olmalı." });

        var user = await _db.Users.FirstOrDefaultAsync(u => u.Email == request.Email);
        if (user == null)
            return NotFound(new { message = "Kullanıcı bulunamadı." });

        // Kod kontrolü
        if (user.VerificationCode != request.Code)
            return BadRequest(new { message = "Geçersiz kod." });

        // Süre kontrolü
        if (user.VerificationCodeExpires == null || user.VerificationCodeExpires < DateTime.UtcNow)
            return BadRequest(new { message = "Kod süresi dolmuş." });

        // Şifreyi güncelle
        user.PasswordHash = BCrypt.Net.BCrypt.HashPassword(request.NewPassword);
        user.VerificationCode = null;
        user.VerificationCodeExpires = null;
        await _db.SaveChangesAsync();

        return Ok(new { message = "Şifreniz başarıyla sıfırlandı." });
    }

    // Token üretme fonksiyonu
    private string GenerateJwt(int userId, string email, string role)
    {
        var jwt = _config.GetSection("Jwt");
        var key = new SymmetricSecurityKey(Encoding.UTF8.GetBytes(jwt["Key"]!));
        var creds = new SigningCredentials(key, SecurityAlgorithms.HmacSha256);

        var claims = new List<Claim>
        {
            new Claim(JwtRegisteredClaimNames.Sub, userId.ToString()),
            new Claim(JwtRegisteredClaimNames.Email, email),
            new Claim(ClaimTypes.Role, role),
            new Claim(JwtRegisteredClaimNames.Jti, Guid.NewGuid().ToString())
        };

        var token = new JwtSecurityToken(
            issuer: jwt["Issuer"],
            audience: jwt["Audience"],
            claims: claims,
            notBefore: DateTime.UtcNow,
            expires: DateTime.UtcNow.AddHours(6), // 6 saat geçerli
            signingCredentials: creds
        );

        return new JwtSecurityTokenHandler().WriteToken(token);
    }
}
