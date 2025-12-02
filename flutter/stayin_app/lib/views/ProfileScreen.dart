import 'package:flutter/material.dart';
import 'HostHomeScreen.dart';
import 'IncomingRequestsScreen.dart';
import 'EditProfileScreen.dart';
import 'ChangePasswordScreen.dart';

class ProfileScreen extends StatefulWidget {
  final String fullName;
  final String email;
  final String phoneNumber;
  final VoidCallback? onLogout;
  final VoidCallback? goToProfile;
  final bool isLoggedIn;
  final Widget? bottomNavBar;
  final VoidCallback? onBack;
  
  const ProfileScreen({
    super.key,
    required this.fullName,
    required this.email,
    required this.phoneNumber,
    this.onLogout,
    this.goToProfile,
    this.isLoggedIn = true,
    this.bottomNavBar,
    this.onBack,
  });

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  late String displayName;
  late String displayEmail;
  late String displayPhone;

  @override
  void initState() {
    super.initState();
    displayName = widget.fullName;
    displayEmail = widget.email;
    displayPhone = widget.phoneNumber;
  }

  void _updateDisplayInfo(String name, String email, String phone) {
    setState(() {
      displayName = name;
      displayEmail = email;
      displayPhone = phone;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey[50],
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        title: const Text('Profil', style: TextStyle(color: Colors.black, fontWeight: FontWeight.bold)),
        iconTheme: const IconThemeData(color: Colors.black),
        leading: widget.onBack != null
            ? IconButton(
                icon: const Icon(Icons.arrow_back, color: Colors.black),
                onPressed: widget.onBack,
              )
            : null,
      ),
      body: SingleChildScrollView(
        child: Column(
          children: [
            // Header Card with User Info
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(24),
              decoration: const BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.vertical(bottom: Radius.circular(24)),
              ),
              child: Column(
                children: [
                  // Avatar
                  Container(
                    width: 100,
                    height: 100,
                    decoration: BoxDecoration(
                      gradient: const LinearGradient(
                        colors: [Colors.redAccent, Colors.orangeAccent],
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                      ),
                      shape: BoxShape.circle,
                      boxShadow: [
                        BoxShadow(
                          color: Colors.redAccent.withOpacity(0.3),
                          blurRadius: 20,
                          offset: const Offset(0, 10),
                        ),
                      ],
                    ),
                    child: Center(
                      child: Text(
                        displayName.isNotEmpty ? displayName[0].toUpperCase() : 'U',
                        style: const TextStyle(
                          fontSize: 40,
                          fontWeight: FontWeight.bold,
                          color: Colors.white,
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(height: 16),
                  // Name
                  Text(
                    displayName,
                    style: const TextStyle(
                      fontSize: 24,
                      fontWeight: FontWeight.bold,
                      color: Colors.black87,
                    ),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 4),
                  // Email
                  Text(
                    displayEmail,
                    style: TextStyle(
                      fontSize: 14,
                      color: Colors.grey[600],
                    ),
                    textAlign: TextAlign.center,
                  ),
                ],
              ),
            ),
            
            const SizedBox(height: 16),
            
            // Menu Items
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: Column(
                children: [
                  // Ev Sahipliği Section
                  _buildSectionHeader('Ev Sahipliği'),
                  const SizedBox(height: 8),
                  _buildMenuCard(
                    context,
                    icon: Icons.home_work,
                    iconColor: Colors.redAccent,
                    iconBgColor: Colors.redAccent.withOpacity(0.1),
                    title: 'Ev Sahipliği Yapın',
                    subtitle: 'Mekanınızı paylaşın ve kazanın',
                    onTap: () {
                      Navigator.of(context).push(
                        MaterialPageRoute(
                          builder: (context) => HostHomeScreen(
                            userFullName: displayName,
                            userEmail: displayEmail,
                          ),
                        ),
                      );
                    },
                  ),
                  const SizedBox(height: 8),
                  _buildMenuCard(
                    context,
                    icon: Icons.inbox_rounded,
                    iconColor: Colors.redAccent,
                    iconBgColor: Colors.redAccent.withOpacity(0.1),
                    title: 'Gelen Rezervasyon Talepleri',
                    subtitle: 'Rezervasyon isteklerini yönetin',
                    onTap: () {
                      Navigator.of(context).push(
                        MaterialPageRoute(
                          builder: (context) => const IncomingRequestsScreen(),
                        ),
                      );
                    },
                  ),
                  
                  const SizedBox(height: 24),
                  
                  // Hesap Section
                  _buildSectionHeader('Hesap'),
                  const SizedBox(height: 8),
                  _buildMenuCard(
                    context,
                    icon: Icons.person_outline,
                    iconColor: Colors.blueAccent,
                    iconBgColor: Colors.blueAccent.withOpacity(0.1),
                    title: 'Profili Düzenle',
                    subtitle: 'Ad, email ve telefon bilgilerinizi güncelleyin',
                    onTap: () {
                      Navigator.of(context).push(
                        MaterialPageRoute(
                          builder: (context) => EditProfileScreen(
                            fullName: displayName,
                            email: displayEmail,
                            phoneNumber: displayPhone,
                            onProfileUpdated: _updateDisplayInfo,
                          ),
                        ),
                      );
                    },
                  ),
                  const SizedBox(height: 8),
                  _buildMenuCard(
                    context,
                    icon: Icons.lock_outline,
                    iconColor: Colors.orangeAccent,
                    iconBgColor: Colors.orangeAccent.withOpacity(0.1),
                    title: 'Şifre Değiştir',
                    subtitle: 'Hesap şifrenizi güncelleyin',
                    onTap: () {
                      Navigator.of(context).push(
                        MaterialPageRoute(
                          builder: (context) => const ChangePasswordScreen(),
                        ),
                      );
                    },
                  ),
                  const SizedBox(height: 8),
                  _buildMenuCard(
                    context,
                    icon: Icons.logout_rounded,
                    iconColor: Colors.grey[700]!,
                    iconBgColor: Colors.grey.withOpacity(0.1),
                    title: 'Çıkış Yap',
                    subtitle: 'Hesabınızdan çıkış yapın',
                    onTap: () {
                      _showLogoutDialog(context);
                    },
                  ),
                  
                  const SizedBox(height: 24),
                ],
              ),
            ),
          ],
        ),
      ),
      bottomNavigationBar: widget.bottomNavBar,
    );
  }

  Widget _buildSectionHeader(String title) {
    return Align(
      alignment: Alignment.centerLeft,
      child: Padding(
        padding: const EdgeInsets.only(left: 4),
        child: Text(
          title,
          style: TextStyle(
            fontSize: 13,
            fontWeight: FontWeight.w600,
            color: Colors.grey[600],
            letterSpacing: 0.5,
          ),
        ),
      ),
    );
  }

  Widget _buildMenuCard(
    BuildContext context, {
    required IconData icon,
    required Color iconColor,
    required Color iconBgColor,
    required String title,
    required String subtitle,
    required VoidCallback onTap,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(16),
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.04),
              blurRadius: 10,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Row(
          children: [
            // Icon
            Container(
              width: 48,
              height: 48,
              decoration: BoxDecoration(
                color: iconBgColor,
                borderRadius: BorderRadius.circular(12),
              ),
              child: Icon(
                icon,
                color: iconColor,
                size: 24,
              ),
            ),
            const SizedBox(width: 16),
            // Text
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                      color: Colors.black87,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    subtitle,
                    style: TextStyle(
                      fontSize: 13,
                      color: Colors.grey[600],
                    ),
                  ),
                ],
              ),
            ),
            // Arrow
            Icon(
              Icons.arrow_forward_ios_rounded,
              size: 16,
              color: Colors.grey[400],
            ),
          ],
        ),
      ),
    );
  }

  void _showLogoutDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: const Text('Çıkış Yap'),
        content: const Text('Çıkış yapmak istediğinizden emin misiniz?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('İptal'),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(context);
              widget.onLogout?.call();
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.redAccent,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(8),
              ),
            ),
            child: const Text('Çıkış Yap', style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );
  }
}
