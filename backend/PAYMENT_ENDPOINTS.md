# Ödeme Sistemi API Endpointleri

## 🔐 Tüm endpointler JWT Authentication gerektir

## 1️⃣ Rezervasyon İçin Ödeme Yap
**Endpoint:** `POST /api/Payments/reservation/{reservationId}`

**Authorization:** Bearer Token (Kullanıcı kendi rezervasyonuna ödeme yapabilir)

**Request Body:**
```json
{
  "cardNumber": "1234567812345678",
  "cardHolder": "AHMET YILMAZ",
  "expiryMonth": "12",
  "expiryYear": "2025",
  "cvv": "123",
  "amount": 1500.00
}
```

**Validasyonlar:**
- ✅ Rezervasyon bulunmalı
- ✅ Sadece kendi rezervasyonuna ödeme yapabilir (GuestId kontrolü)
- ✅ Rezervasyon "Approved" statüsünde olmalı
- ✅ Rezervasyon daha önce ödenmemiş olmalı (IsPaid = false)
- ✅ Ödeme tutarı rezervasyon TotalPrice ile eşleşmeli
- ✅ Kart numarası 16 hane olmalı
- ✅ CVV 3-4 hane olmalı
- ✅ Son kullanma tarihi geçerli olmalı

**Success Response (200):**
```json
{
  "success": true,
  "message": "Ödeme başarıyla alındı.",
  "data": {
    "transactionId": "TXN-A3F2B1C4",
    "amount": 1500.00,
    "paymentDate": "2024-12-02T19:50:00Z",
    "cardLastFour": "5678"
  }
}
```

**Error Responses:**
- `401 Unauthorized`: Kullanıcı doğrulanamadı
- `403 Forbidden`: Başka birinin rezervasyonuna ödeme yapmaya çalışıldı
- `404 Not Found`: Rezervasyon bulunamadı
- `400 Bad Request`: Validasyon hataları

---

## 2️⃣ Rezervasyon Ödeme Detayı
**Endpoint:** `GET /api/Payments/reservation/{reservationId}`

**Authorization:** Bearer Token (Misafir veya Ev Sahibi)

**Success Response (200):**
```json
{
  "success": true,
  "data": {
    "id": 1,
    "reservationId": 5,
    "cardNumber": "**** **** **** 5678",
    "cardHolder": "AHMET YILMAZ",
    "amount": 1500.00,
    "paymentDate": "2024-12-02T19:50:00Z",
    "transactionId": "TXN-A3F2B1C4"
  }
}
```

**Not:** Sadece kendi rezervasyonunun ödemesini görüntüleyebilir (Misafir veya Ev Sahibi)

---

## 3️⃣ Kullanıcının Tüm Ödemeleri
**Endpoint:** `GET /api/Payments/my-payments`

**Authorization:** Bearer Token

**Success Response (200):**
```json
{
  "success": true,
  "data": [
    {
      "id": 1,
      "reservationId": 5,
      "listingTitle": "Modern Loft in City Center",
      "cardNumber": "**** **** **** 5678",
      "cardHolder": "AHMET YILMAZ",
      "amount": 1500.00,
      "paymentDate": "2024-12-02T19:50:00Z",
      "transactionId": "TXN-A3F2B1C4"
    }
  ]
}
```

**Not:** Kullanıcının misafir olarak yaptığı tüm ödemeleri listeler

---

## 🔒 Güvenlik Özellikleri

1. **Kart Numarası Maskeleme:** Sadece son 4 hane saklanır ve gösterilir
2. **CVV Saklanmaz:** CVV sadece validasyon için kullanılır, veritabanına kaydedilmez
3. **Authorization:** Tüm endpointler JWT token gerektirir
4. **Ownership Kontrolü:** Kullanıcılar sadece kendi işlemlerini görüntüleyebilir
5. **Transaction ID:** Her ödeme için benzersiz TXN-XXXXXXXX formatında ID üretilir

---

## 📊 Veritabanı Değişikleri

### Payments Tablosu
- **Id** (PK, Auto-increment)
- **ReservationId** (FK, Unique) - Her rezervasyon için 1 ödeme
- **CardNumber** (string) - Son 4 hane
- **CardHolder** (string)
- **ExpiryMonth** (string)
- **ExpiryYear** (string)
- **Amount** (decimal)
- **PaymentDate** (DateTime)
- **TransactionId** (string)

### Reservations Tablosuna Eklenen Alanlar
- **IsPaid** (bool) - Ödeme yapıldı mı?
- **PaymentDate** (DateTime?) - Ödeme tarihi
- **TransactionId** (string?) - İşlem numarası

---

## 🎨 Frontend Entegrasyonu

### PaymentModal.vue Örnek Kod
```javascript
const processPayment = async () => {
  try {
    const response = await axios.post(
      `/api/Payments/reservation/${reservationId}`,
      {
        cardNumber: cardNumber.value,
        cardHolder: cardHolder.value,
        expiryMonth: expiryMonth.value,
        expiryYear: expiryYear.value,
        cvv: cvv.value,
        amount: totalPrice.value
      },
      {
        headers: {
          Authorization: `Bearer ${token}`
        }
      }
    );

    if (response.data.success) {
      alert('Ödeme başarılı! İşlem No: ' + response.data.data.transactionId);
      // Rezervasyon sayfasını yenile
      router.push('/my-reservations');
    }
  } catch (error) {
    alert(error.response?.data?.message || 'Ödeme başarısız!');
  }
};
```

### MyReservations.vue - Ödeme Durumu Gösterimi
```vue
<div v-if="reservation.isPaid" class="badge badge-success">
  Ödendi ✓
  <small>{{ reservation.transactionId }}</small>
</div>
<button v-else @click="openPaymentModal(reservation)" class="btn btn-primary">
  Ödeme Yap
</button>
```

---

## ✅ Test Edilmesi Gerekenler

1. ✅ Normal ödeme akışı
2. ✅ Zaten ödenmiş rezervasyona tekrar ödeme denemesi
3. ✅ Başka kullanıcının rezervasyonuna ödeme denemesi
4. ✅ Onaylanmamış rezervasyona ödeme denemesi
5. ✅ Geçersiz kart numarası (15 hane, 17 hane vb.)
6. ✅ Geçersiz CVV (2 hane, 5 hane vb.)
7. ✅ Süresi dolmuş kart
8. ✅ Tutar uyumsuzluğu
9. ✅ Ödeme detaylarını görüntüleme
10. ✅ Tüm ödemeleri listeleme
