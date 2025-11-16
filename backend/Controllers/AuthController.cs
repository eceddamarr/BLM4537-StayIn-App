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
            return BadRequest(new { success = false, message = "Email ve şifre gerekli." });

        // Veritabanında kullanıcıyı bul
        var user = await _db.Users.FirstOrDefaultAsync(u => u.Email == request.Email);
        if (user == null)
            return Unauthorized(new { success = false, message = "Kullanıcı bulunamadı veya şifre hatalı." });

        // BCrypt ile şifreyi karşılaştır
        var ok = BCrypt.Net.BCrypt.Verify(request.Password, user.PasswordHash);
        if (!ok)
            return Unauthorized(new { success = false, message = "Kullanıcı bulunamadı veya şifre hatalı." });

        //  JWT üret ve döndür
        var token = GenerateJwt(user.Id, user.Email, user.Role);

        return Ok(new
        {
            success = true,
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
            return BadRequest(new { success = false, message = "Lütfen tüm alanları doldurun." });

        // Şifreler eşleşmiyorsa
        if (request.Password != request.PasswordConfirm)
            return BadRequest(new { success = false, message = "Şifreler eşleşmiyor." });

        // Aynı email ile kullanıcı var mı kontrol et
        var existingUser = await _db.Users.AnyAsync(u => u.Email == request.Email);
        if (existingUser)
            return BadRequest(new { success = false, message = "Bu email ile zaten bir kullanıcı mevcut." });

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
            success = true,
            token,
            user = new { user.Id, user.FullName, user.Email, user.Role }
        });
    }


    // POST /api/Auth/forgot-password - 1. Adım: Email'e kod gönder
    [HttpPost("forgot-password")]
    public async Task<IActionResult> ForgotPassword([FromBody] ForgotPasswordRequest request)
    {
        if (string.IsNullOrWhiteSpace(request.Email))
            return BadRequest(new { success = false, message = "Email gerekli." });

        // Kullanıcıyı bul
        var user = await _db.Users.FirstOrDefaultAsync(u => u.Email == request.Email);
        if (user == null)
            return BadRequest("Bu email sistemde kayıtlı değil!");

        // 6 haneli rastgele kod üret
        var random = new Random();
        var code = random.Next(100000, 999999).ToString();

        // Kodu ve son kullanma tarihini kullanıcıya kaydet (10 dakika geçerli)
        user.VerificationCode = code;
        user.VerificationCodeExpires = DateTime.UtcNow.AddMinutes(10);
        await _db.SaveChangesAsync();

        // Email gönder (mock service konsola yazdırır)
        await _emailService.SendVerificationCodeAsync(user.Email, code);

        return Ok(new { success = true, message = "Doğrulama kodu email adresinize gönderildi." });
    }

    // POST /api/Auth/verify-code - 2. Adım: Kodu doğrula
    [HttpPost("verify-code")]
    public async Task<IActionResult> VerifyCode([FromBody] VerifyCodeRequest request)
    {
        if (string.IsNullOrWhiteSpace(request.Email) || string.IsNullOrWhiteSpace(request.Code))
            return BadRequest(new { success = false, message = "Email ve kod gerekli." });

        // Kullanıcıyı bul
        var user = await _db.Users.FirstOrDefaultAsync(u => u.Email == request.Email);
        if (user == null)
            return BadRequest(new { success = false, message = "Geçersiz email veya kod." });

        // Kod kontrolü
        if (user.VerificationCode != request.Code)
            return BadRequest(new { success = false, message = "Geçersiz kod." });

        // Kodun süresi dolmuş mu?
        if (user.VerificationCodeExpires == null || user.VerificationCodeExpires < DateTime.UtcNow)
            return BadRequest(new { success = false, message = "Kodun süresi dolmuş. Lütfen yeni kod isteyin." });

        return Ok(new { success = true, message = "Kod doğrulandı. Yeni şifrenizi belirleyebilirsiniz." });
    }

    // POST /api/Auth/reset-password - 3. Adım: Yeni şifre belirle
    [HttpPost("reset-password")]
    public async Task<IActionResult> ResetPassword([FromBody] ResetPasswordRequest request)
    {
        // Validasyon
        if (string.IsNullOrWhiteSpace(request.Email) || string.IsNullOrWhiteSpace(request.Code))
            return BadRequest(new { success = false, message = "Email ve kod gerekli." });

        if (string.IsNullOrWhiteSpace(request.NewPassword) || string.IsNullOrWhiteSpace(request.NewPasswordConfirm))
            return BadRequest(new { success = false, message = "Şifre alanları gerekli." });

        if (request.NewPassword != request.NewPasswordConfirm)
            return BadRequest(new { success = false, message = "Şifreler eşleşmiyor." });

        // Kullanıcıyı bul
        var user = await _db.Users.FirstOrDefaultAsync(u => u.Email == request.Email);
        if (user == null)
            return BadRequest(new { success = false, message = "Geçersiz email veya kod." });

        // Şifreyi güncelle
        user.PasswordHash = BCrypt.Net.BCrypt.HashPassword(request.NewPassword);
        
        // Kullanılmış kodu temizle
        user.VerificationCode = null;
        user.VerificationCodeExpires = null;
        
        await _db.SaveChangesAsync();

        return Ok(new { success = true, message = "Şifreniz başarıyla değiştirildi. Artık giriş yapabilirsiniz." });
    }

    // Token üretme fonksiyonu
    private string GenerateJwt(int userId, string email, string role)
    {
        var jwt = _config.GetSection("Jwt");
        var key = new SymmetricSecurityKey(Encoding.UTF8.GetBytes(jwt["Key"]!));
        var creds = new SigningCredentials(key, SecurityAlgorithms.HmacSha256);

         // Kullanıcı bilgilerini token'a ekle
        var claims = new List<Claim>
        {
            new Claim(JwtRegisteredClaimNames.Sub, userId.ToString()),
            new Claim(JwtRegisteredClaimNames.Email, email),
            new Claim(ClaimTypes.Role, role),
            new Claim(JwtRegisteredClaimNames.Jti, Guid.NewGuid().ToString())
        };

        // Token'ı imzala (şifrele)
        var token = new JwtSecurityToken(
            issuer: jwt["Issuer"],
            audience: jwt["Audience"],
            claims: claims,
            notBefore: DateTime.UtcNow,
            expires: DateTime.UtcNow.AddHours(6), // 6 saat geçerli
            signingCredentials: creds
        );

        // String'e çevir ve döndür
        return new JwtSecurityTokenHandler().WriteToken(token);
    }
}
