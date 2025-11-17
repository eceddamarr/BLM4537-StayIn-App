import 'package:flutter/material.dart';
import 'HostHomeScreen.dart';

class ProfileScreen extends StatelessWidget {
  final String fullName;
  final String email;
  final VoidCallback? onLogout;
  final VoidCallback? goToProfile;
  final bool isLoggedIn;
  final Widget? bottomNavBar;
  final VoidCallback? onBack;
  const ProfileScreen({
    super.key,
  required this.fullName,
    required this.email,
    this.onLogout,
    this.goToProfile,
    this.isLoggedIn = true,
    this.bottomNavBar,
    this.onBack,
  });

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        title: const Text('Profil', style: TextStyle(color: Colors.black)),
        iconTheme: const IconThemeData(color: Colors.black),
        leading: onBack != null
            ? IconButton(
                icon: const Icon(Icons.arrow_back, color: Colors.black),
                onPressed: onBack,
              )
            : null,
      ),
      body: Padding(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            // Kullanıcı adı soyadı
            Text(
              fullName,
              style: const TextStyle(fontSize: 26, fontWeight: FontWeight.bold),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 16),
            // Ev Sahipliği Yapın butonu
            SizedBox(
              width: double.infinity,
              child: ElevatedButton.icon(
                onPressed: () {
                    // Navigate to HostHomeScreen
                    Navigator.of(context).push(
                      MaterialPageRoute(
                        builder: (context) => HostHomeScreen(
                          userFullName: fullName,
                          userEmail: email,
                        ),
                      ),
                    );
                },
                icon: const Icon(Icons.home_work_outlined, color: Colors.white),
                label: const Text('Ev Sahipliği Yapın', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.redAccent,
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  padding: const EdgeInsets.symmetric(vertical: 16),
                ),
              ),
            ),
            const SizedBox(height: 32),
            // Çıkış Yap butonu
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: () {
                  onLogout?.call();
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.redAccent,
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  padding: const EdgeInsets.symmetric(vertical: 16),
                ),
                child: const Text('Çıkış Yap', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
              ),
            ),
          ],
        ),
      ),
      bottomNavigationBar: bottomNavBar,
    );
  }
}
