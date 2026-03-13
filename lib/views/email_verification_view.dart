import 'dart:async';
import 'package:flutter/material.dart';
import 'package:todo_app/services/auth_service.dart';
import 'package:todo_app/theme/app_theme.dart';
import 'package:todo_app/views/home_view.dart';

class EmailVerificationView extends StatefulWidget {
  const EmailVerificationView({super.key});

  @override
  State<EmailVerificationView> createState() => _EmailVerificationViewState();
}

class _EmailVerificationViewState extends State<EmailVerificationView> {
  final AuthService _authService = AuthService();
  bool _canResendEmail = true;
  Timer? _timer;
  int _resendCooldown = 0;

  @override
  void initState() {
    super.initState();
    // Sayfa acildiginda otomatik e-posta gonder
    _sendInitialVerificationEmail();
    // Ilk olarak dogrulama durumunu kontrol et
    _checkEmailVerified();
    // Her 3 saniyede bir dogrulama durumunu kontrol et
    _timer = Timer.periodic(
      const Duration(seconds: 3),
      (_) => _checkEmailVerified(),
    );
  }

  Future<void> _sendInitialVerificationEmail() async {
    await _authService.sendEmailVerification();
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  Future<void> _checkEmailVerified() async {
    final isVerified = await _authService.isEmailVerified();

    if (isVerified) {
      _timer?.cancel();
      if (mounted) {
        // Ana ekrana yonlendir
        Navigator.of(context).pushReplacement(
          MaterialPageRoute(builder: (_) => const HomeScreen()),
        );
      }
    }
  }

  Future<void> _sendVerificationEmail() async {
    if (!_canResendEmail) return;

    setState(() {
      _canResendEmail = false;
      _resendCooldown = 60;
    });

    final result = await _authService.sendEmailVerification();

    if (mounted) {
      if (result.errorMessage == null) {
        _showDialog(
          "Başarılı!",
          "Doğrulama e-postası gönderildi. Lütfen gelen kutunuzu kontrol edin.",
          false,
        );
      } else {
        _showDialog("Hata", result.errorMessage!, true);
        setState(() => _canResendEmail = true);
        return;
      }
    }

    // Geri sayim baslat
    Timer.periodic(const Duration(seconds: 1), (timer) {
      if (mounted) {
        setState(() {
          if (_resendCooldown > 0) {
            _resendCooldown--;
          } else {
            _canResendEmail = true;
            timer.cancel();
          }
        });
      } else {
        timer.cancel();
      }
    });
  }

  void _showDialog(String title, String message, bool isError) {
    AppTheme.showAppDialog(
      context: context,
      title: title,
      message: message,
      isError: isError,
    );
  }

  @override
  Widget build(BuildContext context) {
    final user = _authService.currentUser;
    final email = user?.email ?? '';

    return Scaffold(
      backgroundColor: AppTheme.backgroundColor,
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(24.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              // Mail ikonu
              Container(
                width: 100,
                height: 100,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: AppTheme.primaryColor.withValues(alpha: 0.1),
                  border: Border.all(color: AppTheme.primaryColor, width: 2),
                ),
                child: const Icon(
                  Icons.mark_email_unread_outlined,
                  size: 50,
                  color: AppTheme.primaryColor,
                ),
              ),
              const SizedBox(height: 32),

              // Baslik
              const Text(
                "E-posta Doğrulaması",
                style: TextStyle(
                  fontSize: 28,
                  fontWeight: FontWeight.bold,
                  color: AppTheme.textPrimary,
                ),
              ),
              const SizedBox(height: 16),

              // Aciklama
              Text(
                "Doğrulama e-postası şu adrese gönderildi:",
                textAlign: TextAlign.center,
                style: TextStyle(fontSize: 14, color: AppTheme.textSecondary),
              ),
              const SizedBox(height: 8),
              Text(
                email,
                style: const TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  color: AppTheme.primaryColor,
                ),
              ),
              const SizedBox(height: 24),

              // Bilgi kutusu
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: AppTheme.cardColor,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: AppTheme.borderColor),
                ),
                child: Column(
                  children: [
                    Row(
                      children: [
                        Icon(
                          Icons.info_outline,
                          color: AppTheme.primaryColor,
                          size: 20,
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Text(
                            "Gelen kutunuzu kontrol edin ve e-postadaki bağlantıya tıklayın.",
                            style: TextStyle(
                              color: AppTheme.textSecondary,
                              fontSize: 13,
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),
                    Row(
                      children: [
                        Icon(
                          Icons.folder_outlined,
                          color: AppTheme.textSecondary,
                          size: 20,
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Text(
                            "E-postayı bulamıyorsanız spam/gereksiz klasörünü kontrol edin.",
                            style: TextStyle(
                              color: AppTheme.textSecondary,
                              fontSize: 13,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 32),

              // Tekrar Gonder Butonu
              SizedBox(
                width: double.infinity,
                height: 54,
                child: Container(
                  decoration: BoxDecoration(
                    gradient: _canResendEmail ? AppTheme.buttonGradient : null,
                    color: _canResendEmail ? null : AppTheme.cardColor,
                    borderRadius: BorderRadius.circular(30),
                    boxShadow: _canResendEmail
                        ? [
                            BoxShadow(
                              color: AppTheme.primaryColor.withValues(
                                alpha: 0.3,
                              ),
                              blurRadius: 12,
                              offset: const Offset(0, 4),
                            ),
                          ]
                        : null,
                  ),
                  child: ElevatedButton(
                    onPressed: _canResendEmail ? _sendVerificationEmail : null,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.transparent,
                      shadowColor: Colors.transparent,
                      disabledBackgroundColor: Colors.transparent,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(30),
                      ),
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(
                          Icons.refresh,
                          color: _canResendEmail
                              ? const Color(0xFF0A0E14)
                              : AppTheme.textSecondary,
                          size: 20,
                        ),
                        const SizedBox(width: 8),
                        Text(
                          _canResendEmail
                              ? "TEKRAR GÖNDER"
                              : "TEKRAR GÖNDER ($_resendCooldown)",
                          style: TextStyle(
                            color: _canResendEmail
                                ? const Color(0xFF0A0E14)
                                : AppTheme.textSecondary,
                            fontSize: 14,
                            fontWeight: FontWeight.bold,
                            letterSpacing: 1,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 16),

              // Cikis Yap
              TextButton.icon(
                onPressed: () async {
                  await _authService.signOut();
                  if (!context.mounted) return;
                  Navigator.of(context).pop();
                },
                icon: const Icon(
                  Icons.logout,
                  color: AppTheme.textSecondary,
                  size: 18,
                ),
                label: const Text(
                  "Farklı hesapla giriş yap",
                  style: TextStyle(color: AppTheme.textSecondary, fontSize: 14),
                ),
              ),

              const SizedBox(height: 24),

              // Yukleniyor gostergesi
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  SizedBox(
                    width: 16,
                    height: 16,
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                      color: AppTheme.primaryColor.withValues(alpha: 0.5),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Text(
                    "Doğrulama bekleniyor...",
                    style: TextStyle(
                      color: AppTheme.textSecondary.withValues(alpha: 0.7),
                      fontSize: 12,
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}
