import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:todo_app/views/home_view.dart';
import 'package:todo_app/views/login_view.dart';
import 'package:todo_app/views/email_verification_view.dart';
import 'package:todo_app/theme/app_theme.dart';

class AuthGate extends StatefulWidget {
  const AuthGate({super.key});

  @override
  State<AuthGate> createState() => _AuthGateState();
}

class _AuthGateState extends State<AuthGate> {
  bool _isChecking = true;

  @override
  void initState() {
    super.initState();
    _checkRememberMe();
  }

  Future<void> _checkRememberMe() async {
    final user = FirebaseAuth.instance.currentUser;

    if (user != null) {
      // Kullanıcı giriş yapmış, "Beni Hatırla" tercihini kontrol et
      final prefs = await SharedPreferences.getInstance();
      final rememberMe = prefs.getBool('rememberMe') ?? false;

      if (!rememberMe) {
        // "Beni Hatırla" seçilmemişse, çıkış yap
        await FirebaseAuth.instance.signOut();
      }
    }

    if (mounted) {
      setState(() {
        _isChecking = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_isChecking) {
      return Scaffold(
        backgroundColor: AppTheme.backgroundColor,
        body: const Center(
          child: CircularProgressIndicator(color: AppTheme.primaryColor),
        ),
      );
    }

    return StreamBuilder<User?>(
      stream: FirebaseAuth.instance.authStateChanges(),
      builder: (context, snapshot) {
        if (!snapshot.hasData) {
          return LoginScreen();
        }

        // E-posta dogrulanmamissa dogrulama ekranina yonlendir
        final user = snapshot.data!;
        if (!user.emailVerified) {
          return const EmailVerificationView();
        }

        return const HomeScreen();
      },
    );
  }
}
