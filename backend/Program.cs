using System.Text;
using Microsoft.AspNetCore.Authentication.JwtBearer;
using Microsoft.EntityFrameworkCore;
using Microsoft.IdentityModel.Tokens;
using StayIn.Api.Data;
using StayIn.Api.Services;

var builder = WebApplication.CreateBuilder(args);

//  Controllers + Swagger
builder.Services.AddControllers();
builder.Services.AddEndpointsApiExplorer();
builder.Services.AddSwaggerGen();

//  DbContext - SQLite
builder.Services.AddDbContext<AppDbContext>(opts =>
    opts.UseSqlite(builder.Configuration.GetConnectionString("DefaultConnection")));

// Email Service - Geliştirme için Mock kullan
builder.Services.AddScoped<IEmailService, MockEmailService>();

// CORS (Vue 5173, 5174 için izin)
// CORS - Tüm localhost portlarına izin ver
builder.Services.AddCors(options =>
{
    options.AddPolicy("DevCors", policy =>
    {
        policy.SetIsOriginAllowed(origin =>
        {
            if (string.IsNullOrWhiteSpace(origin)) return false;
            
            // localhost veya 127.0.0.1 ile başlayan tüm portlara izin ver
            if (origin.StartsWith("http://localhost:") || 
                origin.StartsWith("http://127.0.0.1:") ||
                origin.StartsWith("https://localhost:") || 
                origin.StartsWith("https://127.0.0.1:"))
            {
                return true;
            }
            
            return false;
        })
        .AllowAnyHeader()
        .AllowAnyMethod()
        .AllowCredentials();
    });
});


// JWT ayarları
var jwtSection = builder.Configuration.GetSection("Jwt");
var key = Encoding.UTF8.GetBytes(jwtSection["Key"]!);

builder.Services
    .AddAuthentication(JwtBearerDefaults.AuthenticationScheme)
    .AddJwtBearer(options =>
    {
        options.TokenValidationParameters = new TokenValidationParameters
        {
            ValidateIssuer = true,
            ValidateAudience = true,
            ValidateIssuerSigningKey = true,
            ValidIssuer = jwtSection["Issuer"],
            ValidAudience = jwtSection["Audience"],
            IssuerSigningKey = new SymmetricSecurityKey(key),
            ClockSkew = TimeSpan.Zero
        };
    });

builder.Services.AddAuthorization();

var app = builder.Build();

// Middleware sırası
if (app.Environment.IsDevelopment())
{
    app.UseSwagger();
    app.UseSwaggerUI();
}

app.UseCors("DevCors");
app.UseHttpsRedirection();

app.UseAuthentication();
app.UseAuthorization();

app.MapControllers();

// Seed data
using (var scope = app.Services.CreateScope())
{
    var db = scope.ServiceProvider.GetRequiredService<AppDbContext>();
    db.Database.Migrate(); // Migration'ları uygula

    // Eğer hiç kullanıcı yoksa bir admin ekle
    if (!db.Users.Any())
    {
        var admin = new StayIn.Api.Models.User
        {
            FullName = "Admin User",
            Email = "admin@stayin.dev",
            PhoneNumber = "+90 555 123 4567",
            PasswordHash = BCrypt.Net.BCrypt.HashPassword("123456"),
            Role = "Admin"
        };
        db.Users.Add(admin);
        db.SaveChanges();
    }
    
    // Review seed data ekle
    await SeedReviews.SeedData(db);
}

app.Run();
