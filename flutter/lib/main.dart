import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'views/HomeScreen.dart';
import 'views/LoginScreen.dart';
import 'views/RegisterScreen.dart';
import 'views/ProfileScreen.dart';
import 'views/FavoritesScreen.dart';
import 'views/MyListingsScreen.dart';
import 'widgets/BottomNavBar.dart';
import 'services/favorites_service.dart';

void main() {
  runApp(const MyApp());
}

class MyApp extends StatefulWidget {
  const MyApp({super.key});

  @override
  State<MyApp> createState() => _MyAppState();
}

class _MyAppState extends State<MyApp> {
  bool isLoggedIn = false;
  String fullName = '';
  String email = '';
  String currentScreen = 'home'; // 'home', 'favorites', 'trips', 'messages', 'profile', 'login', 'register'
  int selectedTab = 0;
  final _favoritesService = FavoritesService();
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadUserData();
  }

  // Kullanıcı bilgilerini SharedPreferences'tan yükle
  Future<void> _loadUserData() async {
    final prefs = await SharedPreferences.getInstance();
    final savedEmail = prefs.getString('user_email');
    final savedFullName = prefs.getString('user_fullname');
    final savedIsLoggedIn = prefs.getBool('is_logged_in') ?? false;
    
    if (mounted && savedIsLoggedIn && savedEmail != null) {
      setState(() {
        isLoggedIn = true;
        email = savedEmail;
        fullName = savedFullName ?? '';
        _favoritesService.setUser(savedEmail);
        _isLoading = false;
      });
    } else {
      setState(() {
        _isLoading = false;
      });
    }
  }

  // Kullanıcı bilgilerini SharedPreferences'a kaydet
  Future<void> _saveUserData() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('is_logged_in', isLoggedIn);
    await prefs.setString('user_email', email);
    await prefs.setString('user_fullname', fullName);
  }

  // Kullanıcı bilgilerini temizle
  Future<void> _clearUserData() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove('is_logged_in');
    await prefs.remove('user_email');
    await prefs.remove('user_fullname');
  }

  void handleLogin({String? user, String? mail}) async {
    setState(() {
      isLoggedIn = true;
      currentScreen = 'home';
      selectedTab = 0;
      if (user != null) fullName = user;
      if (mail != null) {
        email = mail;
        _favoritesService.setUser(mail);
      }
    });
    await _saveUserData();
  }

  void handleLogout() async {
    setState(() {
      isLoggedIn = false;
      fullName = '';
      email = '';
      currentScreen = 'login';
      selectedTab = 0;
      _favoritesService.setUser(null);
    });
    await _clearUserData();
  }

  void goToProfile() {
    setState(() {
      currentScreen = 'profile';
      selectedTab = 4;
    });
  }

  void goToLogin() {
    setState(() {
      currentScreen = 'login';
      selectedTab = 0;
    });
  }

  void handleTabSelected(int index) {
    setState(() {
      selectedTab = index;
      switch (index) {
        case 0:
          currentScreen = 'home';
          break;
        case 1:
          currentScreen = 'favorites';
          break;
        case 2:
          currentScreen = 'mylistings';
          break;
        case 3:
          currentScreen = 'trips';
          break;
        case 4:
          currentScreen = 'profile';
          break;
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    // Kullanıcı bilgileri yüklenirken loading göster
    if (_isLoading) {
      return MaterialApp(
        debugShowCheckedModeBanner: false,
        home: Scaffold(
          backgroundColor: Colors.white,
          body: Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Container(
                  padding: const EdgeInsets.all(20),
                  decoration: BoxDecoration(
                    color: Colors.redAccent,
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: const Icon(Icons.home_rounded, color: Colors.white, size: 60),
                ),
                const SizedBox(height: 24),
                const CircularProgressIndicator(color: Colors.redAccent),
                const SizedBox(height: 16),
                const Text(
                  'Stayin App',
                  style: TextStyle(
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                    color: Colors.redAccent,
                  ),
                ),
              ],
            ),
          ),
        ),
      );
    }

    final bottomNavBar = BottomNavBar(
      currentIndex: selectedTab,
      isLoggedIn: isLoggedIn,
      onTabSelected: handleTabSelected,
      onLoginRequested: () {
        setState(() {
          currentScreen = 'login';
          selectedTab = 0;
        });
      },
    );
    return MaterialApp(
      title: 'Stayin App',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.redAccent),
        useMaterial3: true,
      ),
      home: Builder(
        builder: (context) {
          if (currentScreen == 'login') {
            return LoginScreen(
              onLogin: (username, email) => handleLogin(user: username, mail: email),
              onBack: () {
                setState(() {
                  currentScreen = 'home';
                  selectedTab = 0;
                });
              },
            );
          }
          if (currentScreen == 'profile') {
            return ProfileScreen(
              fullName: fullName.isNotEmpty ? fullName : 'Demo Kullanıcı',
              email: email.isNotEmpty ? email : 'demo@email.com',
              onLogout: handleLogout,
              goToProfile: goToProfile,
              isLoggedIn: true,
              bottomNavBar: bottomNavBar,
              onBack: () {
                setState(() {
                  currentScreen = 'home';
                  selectedTab = 0;
                });
              },
            );
          }
          if (currentScreen == 'favorites') {
            return FavoritesScreen(
              bottomNavBar: bottomNavBar,
            );
          }
          if (currentScreen == 'mylistings') {
            return MyListingsScreen(
              bottomNavBar: bottomNavBar,
              userEmail: email,
              userFullName: fullName,
            );
          }
          if (currentScreen == 'trips') {
            return Scaffold(
              appBar: AppBar(title: const Text('Seyahatler')),
              body: const Center(child: Text('Seyahatler Ekranı')), 
              bottomNavigationBar: bottomNavBar,
            );
          }
          // Default: HomeScreen with navbar
          return HomeScreen(
            isLoggedIn: isLoggedIn,
            goToProfile: goToProfile,
            goToLogin: goToLogin,
            bottomNavBar: bottomNavBar,
          );
        },
      ),
      routes: {
        '/home': (_) => HomeScreen(isLoggedIn: true),
  '/login': (_) => LoginScreen(onLogin: (username, email) => handleLogin(user: username, mail: email)),
        '/register': (_) => RegisterScreen(onRegister: (username, email) => handleLogin(user: username, mail: email)),
      },
    );
  }
}
