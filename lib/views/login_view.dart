
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:todo_app/views/register_view.dart';
import 'package:todo_app/services/auth_service.dart';
import 'package:todo_app/theme/app_theme.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});
  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final AuthService _authService = AuthService();
  bool _isLoading = false;
  bool _obscurePassword = true;
  bool _rememberMe = false;

  void _showErrorDialog(String title, String message) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: AppTheme.cardColor,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
          side: BorderSide(color: AppTheme.borderColor),
        ),
        title: Row(
          children: [
            const Icon(Icons.error_outline, color: Colors.red),
            const SizedBox(width: 8),
            Text(title, style: const TextStyle(color: AppTheme.textPrimary)),
          ],
        ),  
        content: Text(message, style: const TextStyle(color: AppTheme.textSecondary)),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text("Tamam", style: TextStyle(color: AppTheme.primaryColor)),
          ),
        ],
      ),
    );
  }

  void _showSuccessDialog(String title, String message) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: AppTheme.cardColor,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
          side: BorderSide(color: AppTheme.borderColor),
        ),
        title: Row(
          children: [
            const Icon(Icons.check_circle, color: AppTheme.primaryColor),
            const SizedBox(width: 8),
            Text(title, style: const TextStyle(color: AppTheme.textPrimary)),
          ],
        ),
        content: Text(message, style: const TextStyle(color: AppTheme.textSecondary)),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text("Tamam", style: TextStyle(color: AppTheme.primaryColor)),
          ),
        ],
      ),
    );
  }

  void _showForgotPasswordDialog() {
    final resetEmailController = TextEditingController();
    bool isResetting = false;
    showDialog(
      context: context,
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setDialogState) {
            return AlertDialog(
              backgroundColor: AppTheme.cardColor,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(16),
                side: BorderSide(color: AppTheme.borderColor),
              ),
              title: Row(
                children: [
                  Icon(Icons.lock_reset, color: AppTheme.primaryColor),
                  const SizedBox(width: 8),
                  const Text("Şifremi Unuttum", style: TextStyle(color: AppTheme.textPrimary)),
                ],
              ),
              content: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Text("E-posta adresinizi girin.", style: TextStyle(color: AppTheme.textSecondary)),
                  const SizedBox(height: 16),
                  TextField(
                    controller: resetEmailController,
                    keyboardType: TextInputType.emailAddress,
                    style: const TextStyle(color: AppTheme.textPrimary),
                    decoration: InputDecoration(
                      labelText: 'E-posta',
                      labelStyle: const TextStyle(color: AppTheme.textSecondary),
                      prefixIcon: const Icon(Icons.email, color: AppTheme.textSecondary),
                      filled: true,
                      fillColor: AppTheme.backgroundColor,
                      border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none),
                    ),
                  ),
                ],
              ),
              actions: [
                TextButton(onPressed: () => Navigator.pop(context), child: const Text("Iptal", style: TextStyle(color: AppTheme.textSecondary))),
                isResetting
                    ? const Padding(padding: EdgeInsets.all(8.0), child: SizedBox(width: 24, height: 24, child: CircularProgressIndicator(color: AppTheme.primaryColor, strokeWidth: 2)))
                    : ElevatedButton(
                        onPressed: () async {
                          if (resetEmailController.text.trim().isEmpty) return;
                          setDialogState(() => isResetting = true);
                          final result = await _authService.sendPasswordResetEmail(resetEmailController.text.trim());
                          setDialogState(() => isResetting = false);
                          if (!context.mounted) return;
                          Navigator.pop(context);
                          if (result.errorMessage == null) {
                            _showSuccessDialog("Başarılı", "Şifre sıfırlama bağlantısı gönderildi.");
                          } else {
                            _showErrorDialog("Hata", result.errorMessage!);
                          }
                        },
                        style: ElevatedButton.styleFrom(backgroundColor: AppTheme.primaryColor, shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8))),
                        child: const Text("Gönder", style: TextStyle(color: Color(0xFF0A0E14))),
                      ),
              ],
            );
          },
        );
      },
    );
  }

  Future<void> _login() async {
    if (_emailController.text.isEmpty || _passwordController.text.isEmpty) {
      _showErrorDialog("Uyarı", "E-posta ve şifre boş olamaz.");
      return;
    }
    setState(() => _isLoading = true);
    final result = await _authService.signInWithEmailAndPassword(_emailController.text.trim(), _passwordController.text);
    if (!mounted) return;
    setState(() => _isLoading = false);
    if (result.user != null) {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setBool('rememberMe', _rememberMe);
    } else {
      _showErrorDialog("Hata", result.errorMessage ?? "E-posta veya şifre hatalı.");
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.backgroundColor,
      body: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(24),
            child: Column(
              children: [
                Container(
                  width: 70, height: 70,
                  decoration: BoxDecoration(shape: BoxShape.circle, border: Border.all(color: AppTheme.primaryColor, width: 2)),
                  child: const Icon(Icons.check, color: AppTheme.primaryColor, size: 36),
                ),
                const SizedBox(height: 24),
                const Text('örevListem', style: TextStyle(fontSize: 32, fontWeight: FontWeight.bold, color: AppTheme.primaryColor)),
                const SizedBox(height: 48),
                Container(
                  padding: const EdgeInsets.all(24),
                  decoration: BoxDecoration(color: AppTheme.cardColor, borderRadius: BorderRadius.circular(16), border: Border.all(color: AppTheme.borderColor)),
                  child: Column(
                    children: [
                      const Text('Giriş Yap', style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: AppTheme.textPrimary)),
                      const SizedBox(height: 24),
                      TextField(
                        controller: _emailController,
                        keyboardType: TextInputType.emailAddress,
                        style: const TextStyle(color: AppTheme.textPrimary),
                        decoration: InputDecoration(
                          labelText: 'E-posta',
                          labelStyle: const TextStyle(color: AppTheme.textSecondary),
                          prefixIcon: const Icon(Icons.email, color: AppTheme.textSecondary),
                          filled: true, fillColor: AppTheme.backgroundColor,
                          border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none),
                        ),
                      ),
                      const SizedBox(height: 16),
                      TextField(
                        controller: _passwordController,
                        obscureText: _obscurePassword,
                        style: const TextStyle(color: AppTheme.textPrimary),
                        decoration: InputDecoration(
                          labelText: 'Şifre',
                          labelStyle: const TextStyle(color: AppTheme.textSecondary),
                          prefixIcon: const Icon(Icons.lock, color: AppTheme.textSecondary),
                          suffixIcon: IconButton(icon: Icon(_obscurePassword ? Icons.visibility_off : Icons.visibility, color: AppTheme.textSecondary), onPressed: () => setState(() => _obscurePassword = !_obscurePassword)),
                          filled: true, fillColor: AppTheme.backgroundColor,
                          border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none),
                        ),
                      ),
                      const SizedBox(height: 16),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Row(children: [
                            Checkbox(value: _rememberMe, onChanged: (v) => setState(() => _rememberMe = v ?? false), activeColor: AppTheme.primaryColor),
                            const Text('Beni Hatırla', style: TextStyle(color: AppTheme.textSecondary)),
                          ]),
                          GestureDetector(
                            onTap: _showForgotPasswordDialog,
                            child: const Text('Şifremi Unuttum?', style: TextStyle(color: AppTheme.primaryColor, fontWeight: FontWeight.w500)),
                          ),
                        ],
                      ),
                      const SizedBox(height: 24),
                      SizedBox(
                        width: double.infinity, height: 50,
                        child: ElevatedButton(
                          onPressed: _isLoading ? null : _login,
                          style: ElevatedButton.styleFrom(backgroundColor: AppTheme.primaryColor, shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12))),
                          child: _isLoading ? const CircularProgressIndicator(color: Colors.white) : const Text('GIRIS YAP', style: TextStyle(color: Color(0xFF0A0E14), fontWeight: FontWeight.bold)),
                        ),
                      ),
                      const SizedBox(height: 16),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          const Text('Hesabınız yok mu? ', style: TextStyle(color: AppTheme.textSecondary)),
                          GestureDetector(onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const RegisterScreen())), child: const Text('Kayıt Ol', style: TextStyle(color: AppTheme.primaryColor, fontWeight: FontWeight.bold))),
                        ],
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
