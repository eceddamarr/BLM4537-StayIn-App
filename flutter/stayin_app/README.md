
# StayInApp

StayInApp, Flutter ile geliştirilmiş bir konaklama ve ilan yönetim uygulamasıdır. Kullanıcılar ev, oda veya farklı konaklama türlerinde ilan oluşturabilir, düzenleyebilir, favorilere ekleyebilir ve rezervasyon yapabilir. Uygulama, .NET tabanlı bir backend API ile tam entegre çalışır.

## Genel Yapı

- **Frontend:** Flutter (Dart)
- **Backend:** .NET API (RESTful)
- **Mobil Platformlar:** Android, iOS, Web, Windows, MacOS, Linux
- **Harita Servisi:** OpenStreetMap (Nominatim API)
- **Fotoğraf Yönetimi:** Base64 ve URL desteği

## Klasör Yapısı

- `lib/`
  - `main.dart`: Uygulamanın giriş noktası
  - `services/`: API servisleri (auth, ilan, favori, kullanıcı işlemleri)
  - `views/`: Ekranlar (Ana sayfa, ilan detay, favoriler, ilan oluşturma/düzenleme)
  - `widgets/`: Ortak widgetlar (alt menü, özel bileşenler)
- `assets/`: Uygulama varlıkları (fotoğraflar, ikonlar, fontlar)
- `android/`, `ios/`, `web/`, `windows/`, `macos/`, `linux/`: Platforma özel dosyalar

## Temel Özellikler

### 1. İlan Oluşturma ve Düzenleme
- Adım adım wizard ile ilan oluşturma
- Konum seçimi ve harita entegrasyonu
- Otomatik adres doldurma (Nominatim API)
- Fotoğraf ekleme (galeriden çoklu seçim, base64 ve URL desteği)
- Fiyat, başlık, açıklama, oda/banyo/kişi sayısı, olanaklar

### 2. İlan Listeleme ve Detay
- Tüm ilanları listeleme
- Detay ekranında fotoğraf galerisi, açıklama, konum, olanaklar
- İlan sahibinin bilgileri
- Favori ekleme/çıkarma
- Rezervasyon akışı (giriş/çıkış tarihi, misafir sayısı, toplam ücret)

### 3. Favoriler
- İlanları favorilere ekleme/çıkarma
- Favori ilanları listeleme
- Favori işlemleri backend API ile tam entegre

### 4. Kullanıcı İşlemleri
- Giriş/çıkış akışı
- Kullanıcıya özel ilanlar (İlanlarım ekranı)
- İlan düzenleme/silme

### 5. Harita ve Konum
- OpenStreetMap tabanlı harita
- Konum arama ve seçme
- Koordinattan adres bilgisi alma
- Seçilen konumu haritada pin ile gösterme

### 6. Fotoğraf Yönetimi
- Fotoğraflar hem base64 hem de URL olarak gösterilebilir
- Fotoğraf ekleme, silme, önizleme

## API Entegrasyonu
- Tüm işlemler (ilan, favori, kullanıcı, rezervasyon) .NET API üzerinden yapılır
- HTTP istekleri için `http` paketi kullanılır
- JSON parse işlemleri `dart:convert` ile yapılır
- Token tabanlı kimlik doğrulama

## Kullanılan Paketler
- `http`: API istekleri
- `flutter_map`: Harita entegrasyonu
- `latlong2`: Koordinat yönetimi
- `image_picker`: Fotoğraf seçimi
- `typeahead`: Adres arama autocomplete

## Geliştirici Notları
- Kodda fonksiyon başı açıklama yorumları ile okunabilirlik artırılmıştır
- Mock/sahte veri kaldırılmış, tüm akışlar backend ile entegre
- Adres ve fotoğraf alanları otomatik doldurulabilir ve düzenlenebilir
- Tüm akışlar test edilmiş, hata bulunmamıştır

## Kurulum
1. Flutter SDK kurulu olmalı
2. Gerekli paketler yüklenmeli:
	```sh
	flutter pub get
	```
3. Backend API adresi ve portu doğru şekilde ayarlanmalı
4. Uygulama aşağıdaki komutla başlatılabilir:
	```sh
	flutter run
	```