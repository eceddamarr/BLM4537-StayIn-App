using MailKit.Net.Smtp;
using MailKit.Security;
using MimeKit;

namespace StayIn.Api.Services;

public interface IEmailService
{
    Task SendVerificationCodeAsync(string toEmail, string code);
}

// Geliştirme için Mock Email Service - Gerçekten e-posta göndermez
public class MockEmailService : IEmailService
{
    private readonly ILogger<MockEmailService> _logger;

    public MockEmailService(ILogger<MockEmailService> logger)
    {
        _logger = logger;
    }

    public Task SendVerificationCodeAsync(string toEmail, string code)
    {
        _logger.LogInformation("========================================");
        _logger.LogInformation("E-POSTA GÖNDERİLDİ (MOCK)");
        _logger.LogInformation("Alıcı: {Email}", toEmail);
        _logger.LogInformation("Doğrulama Kodu: {Code}", code);
        _logger.LogInformation("Geçerlilik: 10 dakika");
        _logger.LogInformation("========================================");
        
        return Task.CompletedTask;
    }
}

// Gerçek Email Service - SMTP ile e-posta gönderir
public class EmailService : IEmailService
{
    private readonly IConfiguration _config;

    public EmailService(IConfiguration config)
    {
        _config = config;
    }

    public async Task SendVerificationCodeAsync(string toEmail, string code)
    {
        var email = new MimeMessage();
        email.From.Add(MailboxAddress.Parse(_config["Email:From"]));
        email.To.Add(MailboxAddress.Parse(toEmail));
        email.Subject = "Doğrulama Kodunuz - StayIn";

        email.Body = new TextPart(MimeKit.Text.TextFormat.Html)
        {
            Text = $@"
                <h2>Doğrulama Kodunuz</h2>
                <p>Merhaba,</p>
                <p>Doğrulama kodunuz: <strong>{code}</strong></p>
                <p>Bu kod 10 dakika geçerlidir.</p>
                <p>Eğer bu işlemi siz yapmadıysanız, lütfen bu e-postayı görmezden gelin.</p>
                <br/>
                <p>Saygılarımızla,<br/>StayIn Ekibi</p>
            "
        };

        using var smtp = new SmtpClient();
        await smtp.ConnectAsync(
            _config["Email:Host"], 
            int.Parse(_config["Email:Port"]!), 
            SecureSocketOptions.StartTls
        );
        
        await smtp.AuthenticateAsync(_config["Email:Username"], _config["Email:Password"]);
        await smtp.SendAsync(email);
        await smtp.DisconnectAsync(true);
    }
}
