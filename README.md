
# StayInApp

Flutter ve .NET 9.0 ile geliştirilmiş tam özellikli konaklama yönetim uygulaması. Kullanıcılar ilan oluşturabilir, rezervasyon yapabilir, yorum ekleyebilir ve güvenli ödeme gerçekleştirebilir.

## Teknolojiler

- **Frontend:** Flutter (Android, iOS, Web, Windows, MacOS, Linux)
- **Backend:** .NET 9.0 Web API + Entity Framework Core
- **Kimlik Doğrulama:** JWT Bearer Token
- **Harita:** OpenStreetMap (Nominatim API)
- **Email:** Mock Service

## Proje Yapısı

### Backend
- `Controllers/`: Auth, Listings, Reservation, Reviews, Payments, Favorites, User
- `Models/`: User, Listing, Reservation, Review, Payment
- `Services/`: Email servisi
- `Migrations/`: Veritabanı migration'ları

### Frontend
- `services/api_service.dart`: API entegrasyonları
- `views/`: Tüm ekranlar (Home, Login, Listing, Reservation, Review, Payment, Profile)
- `widgets/`: Ortak bileşenler

## Özellikler

### Kimlik Doğrulama
- Kullanıcı kayıt/giriş, JWT token
- Email ile şifre sıfırlama
- Profil ve şifre yönetimi

### İlan Yönetimi
- Wizard ile ilan oluşturma/düzenleme
- Harita entegrasyonu ve konum seçimi
- Çoklu fotoğraf yükleme
- Favori sistemi

### Rezervasyon
- Tarih bazlı rezervasyon ve çakışma kontrolü
- Otomatik fiyat hesaplama
- Durum yönetimi (Beklemede, Onaylandı, Reddedildi, İptal)
- Ev sahibi onay/red sistemi

### Yorum ve Değerlendirme
- 1-5 yıldız puan sistemi
- Tamamlanmış rezervasyonlar için yorum
- Düzenleme ve silme

### Ödeme
- Güvenli kredi kartı ödemesi
- Transaction ID takibi
- Ödeme geçmişi

## API Endpoint'leri

- **Auth:** register, login, forgot-password, reset-password, change-password, update-profile
- **Reservation:** create, my-reservations, incoming-requests, approve, reject, cancel
- **Reviews:** create, listing reviews, my-reviews, update, delete
- **Payments:** process payment, payment details, my-payments
- **Listings:** list, create, update, delete, my-listings
- **Favorites:** add, remove, list


## Kurulum

**Backend:** .NET 9.0 SDK + SQL Server kurulu olmalı. `appsettings.json` ayarları yapıldıktan sonra:
```sh
dotnet ef database update
dotnet run
```

**Frontend:** Flutter SDK kurulu olmalı. `api_service.dart` dosyasında backend adresi ayarlandıktan sonra:
```sh
flutter pub get
flutter run
```
