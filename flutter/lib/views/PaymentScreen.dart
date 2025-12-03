import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../services/api_service.dart';

class PaymentScreen extends StatefulWidget {
  final int reservationId;
  final String listingTitle;
  final double totalPrice;
  final DateTime checkInDate;
  final DateTime checkOutDate;
  final int guests;
  final VoidCallback onPaymentSuccess;

  const PaymentScreen({
    Key? key,
    required this.reservationId,
    required this.listingTitle,
    required this.totalPrice,
    required this.checkInDate,
    required this.checkOutDate,
    required this.guests,
    required this.onPaymentSuccess,
  }) : super(key: key);

  @override
  State<PaymentScreen> createState() => _PaymentScreenState();
}

class _PaymentScreenState extends State<PaymentScreen> {
  final _formKey = GlobalKey<FormState>();
  final _cardNumberController = TextEditingController();
  final _cardHolderController = TextEditingController();
  final _expiryMonthController = TextEditingController();
  final _expiryYearController = TextEditingController();
  final _cvvController = TextEditingController();
  bool _isLoading = false;

  @override
  void dispose() {
    _cardNumberController.dispose();
    _cardHolderController.dispose();
    _expiryMonthController.dispose();
    _expiryYearController.dispose();
    _cvvController.dispose();
    super.dispose();
  }

  Future<void> _processPayment() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isLoading = true);

    // Yılı 20XX formatına çevir (örn: 25 -> 2025)
    final year = _expiryYearController.text.trim();
    final fullYear = '20$year';
    
    final result = await ApiService.processPayment(
      reservationId: widget.reservationId,
      cardNumber: _cardNumberController.text.replaceAll(' ', ''),
      cardHolder: _cardHolderController.text.trim(),
      expiryMonth: _expiryMonthController.text.trim(),
      expiryYear: fullYear,
      cvv: _cvvController.text.trim(),
      amount: widget.totalPrice,
    );

    setState(() => _isLoading = false);

    if (mounted) {
      if (result['success']) {
        widget.onPaymentSuccess();
        Navigator.pop(context);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(result['message'] ?? 'Ödeme başarılı!'),
            backgroundColor: Colors.green,
          ),
        );
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(result['message'] ?? 'Ödeme yapılamadı'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  String _formatCardNumber(String text) {
    text = text.replaceAll(' ', '');
    var buffer = StringBuffer();
    for (int i = 0; i < text.length; i++) {
      buffer.write(text[i]);
      var nonZeroIndex = i + 1;
      if (nonZeroIndex % 4 == 0 && nonZeroIndex != text.length) {
        buffer.write(' ');
      }
    }
    return buffer.toString();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        title: const Text('Ödeme', style: TextStyle(color: Colors.black, fontWeight: FontWeight.bold)),
        leading: IconButton(
          icon: const Icon(Icons.close, color: Colors.black),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: SingleChildScrollView(
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Form(
            key: _formKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Rezervasyon Özeti Başlığı
                Row(
                  children: [
                    Icon(Icons.receipt_long, color: Colors.redAccent, size: 24),
                    const SizedBox(width: 8),
                    const Text(
                      'Rezervasyon Özeti',
                      style: TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 16),

                // Rezervasyon Bilgisi
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: Colors.red[50],
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: Colors.red[100]!, width: 1),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // İlan Adı
                      Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text(
                            'İlan:',
                            style: TextStyle(
                              fontSize: 14,
                              color: Colors.black87,
                            ),
                          ),
                          const SizedBox(width: 8),
                          Expanded(
                            child: Text(
                              widget.listingTitle,
                              style: const TextStyle(
                                fontSize: 14,
                                fontWeight: FontWeight.bold,
                              ),
                              textAlign: TextAlign.right,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 12),
                      
                      // Tarih
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          const Text(
                            'Giriş - Çıkış:',
                            style: TextStyle(
                              fontSize: 14,
                              color: Colors.black87,
                            ),
                          ),
                          Text(
                            '${widget.checkInDate.day}.${widget.checkInDate.month}.${widget.checkInDate.year} - ${widget.checkOutDate.day}.${widget.checkOutDate.month}.${widget.checkOutDate.year}',
                            style: const TextStyle(
                              fontSize: 14,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 12),
                      
                      // Misafir Sayısı
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          const Text(
                            'Misafir:',
                            style: TextStyle(
                              fontSize: 14,
                              color: Colors.black87,
                            ),
                          ),
                          Text(
                            '${widget.guests} kişi',
                            style: const TextStyle(
                              fontSize: 14,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 12),
                      const Divider(),
                      const SizedBox(height: 12),
                      
                      // Toplam Tutar
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          const Text(
                            'Toplam Tutar:',
                            style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                          ),
                          Text(
                            '₺${widget.totalPrice.toStringAsFixed(0)}',
                            style: const TextStyle(
                              fontSize: 22,
                              fontWeight: FontWeight.bold,
                              color: Colors.redAccent,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),

                const SizedBox(height: 24),

                // Kart Bilgileri Başlık
                const Text(
                  'Kart Bilgileri',
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 16),

                // Kart Numarası
                Container(
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: Colors.grey[300]!, width: 1),
                  ),
                  child: TextFormField(
                    controller: _cardNumberController,
                    keyboardType: TextInputType.number,
                    inputFormatters: [
                      FilteringTextInputFormatter.digitsOnly,
                      LengthLimitingTextInputFormatter(16),
                    ],
                    decoration: InputDecoration(
                      labelText: 'Kart Numarası',
                      hintText: '1234 5678 9012 3456',
                      prefixIcon: const Icon(Icons.credit_card),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide: BorderSide.none,
                      ),
                      filled: true,
                      fillColor: Colors.white,
                    ),
                    onChanged: (value) {
                      final formatted = _formatCardNumber(value);
                      _cardNumberController.value = TextEditingValue(
                        text: formatted,
                        selection: TextSelection.collapsed(offset: formatted.length),
                      );
                    },
                    validator: (value) {
                      if (value == null || value.isEmpty) {
                        return 'Kart numarası gerekli';
                      }
                      final digitsOnly = value.replaceAll(' ', '');
                      if (digitsOnly.length != 16) {
                        return 'Kart numarası 16 hane olmalıdır';
                      }
                      return null;
                    },
                  ),
                ),

                const SizedBox(height: 16),

                // Kart Sahibi
                Container(
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: Colors.grey[300]!, width: 1),
                  ),
                  child: TextFormField(
                    controller: _cardHolderController,
                    textCapitalization: TextCapitalization.characters,
                    decoration: InputDecoration(
                      labelText: 'Kart Üzerindeki İsim',
                      hintText: 'AD SOYAD',
                      prefixIcon: const Icon(Icons.person),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide: BorderSide.none,
                      ),
                      filled: true,
                      fillColor: Colors.white,
                    ),
                    validator: (value) {
                      if (value == null || value.isEmpty) {
                        return 'Kart sahibi adı gerekli';
                      }
                      if (value.length < 3) {
                        return 'Geçerli bir isim girin';
                      }
                      return null;
                    },
                  ),
                ),

                const SizedBox(height: 16),

                // Son Kullanma Tarihi ve CVV
                Row(
                  children: [
                    // Ay
                    Expanded(
                      child: Container(
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(color: Colors.grey[300]!, width: 1),
                        ),
                        child: TextFormField(
                          controller: _expiryMonthController,
                          keyboardType: TextInputType.number,
                          inputFormatters: [
                            FilteringTextInputFormatter.digitsOnly,
                            LengthLimitingTextInputFormatter(2),
                          ],
                          decoration: InputDecoration(
                            labelText: 'Ay',
                            hintText: 'MM',
                            prefixIcon: const Icon(Icons.calendar_today),
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(12),
                              borderSide: BorderSide.none,
                            ),
                            filled: true,
                            fillColor: Colors.white,
                          ),
                          validator: (value) {
                            if (value == null || value.isEmpty) {
                              return 'Ay gerekli';
                            }
                            final month = int.tryParse(value);
                            if (month == null || month < 1 || month > 12) {
                              return 'Geçersiz';
                            }
                            return null;
                          },
                        ),
                      ),
                    ),
                    const SizedBox(width: 12),
                    // Yıl
                    Expanded(
                      child: Container(
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(color: Colors.grey[300]!, width: 1),
                        ),
                        child: TextFormField(
                          controller: _expiryYearController,
                          keyboardType: TextInputType.number,
                          inputFormatters: [
                            FilteringTextInputFormatter.digitsOnly,
                            LengthLimitingTextInputFormatter(2),
                          ],
                          decoration: InputDecoration(
                            labelText: 'Yıl',
                            hintText: 'YY',
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(12),
                              borderSide: BorderSide.none,
                            ),
                            filled: true,
                            fillColor: Colors.white,
                          ),
                          validator: (value) {
                            if (value == null || value.isEmpty) {
                              return 'Yıl gerekli';
                            }
                            if (value.length != 2) {
                              return 'Geçersiz';
                            }
                            final year = int.tryParse(value);
                            if (year == null) {
                              return 'Geçersiz';
                            }
                            final fullYear = 2000 + year;
                            if (fullYear < DateTime.now().year) {
                              return 'Geçersiz';
                            }
                            return null;
                          },
                        ),
                      ),
                    ),
                    const SizedBox(width: 12),
                    // CVV
                    Expanded(
                      child: Container(
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(color: Colors.grey[300]!, width: 1),
                        ),
                        child: TextFormField(
                          controller: _cvvController,
                          keyboardType: TextInputType.number,
                          obscureText: true,
                          inputFormatters: [
                            FilteringTextInputFormatter.digitsOnly,
                            LengthLimitingTextInputFormatter(3),
                          ],
                          decoration: InputDecoration(
                            labelText: 'CVV',
                            hintText: '123',
                            prefixIcon: const Icon(Icons.lock),
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(12),
                              borderSide: BorderSide.none,
                            ),
                            filled: true,
                            fillColor: Colors.white,
                          ),
                          validator: (value) {
                            if (value == null || value.isEmpty) {
                              return 'CVV gerekli';
                            }
                            if (value.length != 3) {
                              return 'Geçersiz';
                            }
                            return null;
                          },
                        ),
                      ),
                    ),
                  ],
                ),

                const SizedBox(height: 32),

                // Ödeme Butonu
                SizedBox(
                  width: double.infinity,
                  height: 56,
                  child: ElevatedButton(
                    onPressed: _isLoading ? null : _processPayment,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.redAccent,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                      elevation: 0,
                    ),
                    child: _isLoading
                        ? const SizedBox(
                            width: 24,
                            height: 24,
                            child: CircularProgressIndicator(
                              strokeWidth: 2,
                              color: Colors.white,
                            ),
                          )
                        : Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              const Icon(Icons.payment, color: Colors.white),
                              const SizedBox(width: 8),
                              Text(
                                '₺${widget.totalPrice.toStringAsFixed(0)} Öde',
                                style: const TextStyle(
                                  color: Colors.white,
                                  fontSize: 18,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ],
                          ),
                  ),
                ),

                const SizedBox(height: 16),

                // Güvenlik Mesajı
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: Colors.red[50],
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: Colors.red[100]!, width: 1),
                  ),
                  child: Row(
                    children: [
                      Icon(Icons.security, color: Colors.redAccent, size: 20),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          'Ödemeniz güvenli bir şekilde işlenir',
                          style: TextStyle(
                            color: Colors.red[900],
                            fontSize: 13,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
