import 'package:flutter/material.dart';

/// Uygulama genelinde kullanılan tema renkleri ve stilleri
class AppTheme {
  // Ana renkler
  static const Color primaryColor = Color(0xFF00D9C0); // Cyan/Teal
  static const Color primaryDark = Color(0xFF00B8A0);
  static const Color accentColor = Color(0xFF00F5D4);

  // Arka plan renkleri
  static const Color backgroundColor = Color(0xFF0A0E14); // Çok koyu mavi-siyah
  static const Color surfaceColor = Color(0xFF12171F); // Kart arka planı
  static const Color cardColor = Color(0xFF1A1F2A); // Form arka planı

  // Metin renkleri
  static const Color textPrimary = Color(0xFFFFFFFF);
  static const Color textSecondary = Color(0xFF8A8F98);
  static const Color textHint = Color(0xFF5A5F68);

  // Border renkleri
  static const Color borderColor = Color(0xFF2A3040);
  static const Color borderFocused = Color(0xFF00D9C0);

  // Gradient
  static const LinearGradient primaryGradient = LinearGradient(
    colors: [Color(0xFF00D9C0), Color(0xFF00F5D4)],
    begin: Alignment.centerLeft,
    end: Alignment.centerRight,
  );

  static const LinearGradient buttonGradient = LinearGradient(
    colors: [Color(0xFF00C9B0), Color(0xFF00E5C4)],
    begin: Alignment.centerLeft,
    end: Alignment.centerRight,
  );

  // Input Decoration
  static InputDecoration inputDecoration({
    required String label,
    String? hint,
    required IconData prefixIcon,
    Widget? suffixIcon,
  }) {
    return InputDecoration(
      labelText: label,
      hintText: hint,
      labelStyle: const TextStyle(
        color: textSecondary,
        fontSize: 14,
        fontWeight: FontWeight.w500,
      ),
      hintStyle: TextStyle(
        color: textHint.withValues(alpha: 0.7),
        fontSize: 14,
      ),
      prefixIcon: Container(
        padding: const EdgeInsets.all(12),
        child: Icon(prefixIcon, color: textSecondary, size: 22),
      ),
      suffixIcon: suffixIcon,
      filled: true,
      fillColor: surfaceColor,
      contentPadding: const EdgeInsets.symmetric(vertical: 16, horizontal: 16),
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: const BorderSide(color: borderColor, width: 1),
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: const BorderSide(color: borderColor, width: 1),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: const BorderSide(color: borderFocused, width: 1.5),
      ),
      errorBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: const BorderSide(color: Colors.redAccent, width: 1),
      ),
    );
  }

  // Primary Button Style
  static ButtonStyle primaryButtonStyle = ButtonStyle(
    padding: WidgetStateProperty.all(
      const EdgeInsets.symmetric(vertical: 16, horizontal: 24),
    ),
    shape: WidgetStateProperty.all(
      RoundedRectangleBorder(borderRadius: BorderRadius.circular(30)),
    ),
    elevation: WidgetStateProperty.all(0),
    backgroundColor: WidgetStateProperty.all(Colors.transparent),
  );

  // Card Decoration
  static BoxDecoration cardDecoration = BoxDecoration(
    color: cardColor,
    borderRadius: BorderRadius.circular(20),
    border: Border.all(color: borderColor, width: 1),
  );

  // Dialog Theme
  static void showAppDialog({
    required BuildContext context,
    required String title,
    required String message,
    bool isError = false,
  }) {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (BuildContext ctx) {
        return AlertDialog(
          backgroundColor: cardColor,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
            side: const BorderSide(color: borderColor),
          ),
          title: Text(
            title,
            style: TextStyle(
              color: isError ? Colors.redAccent : primaryColor,
              fontWeight: FontWeight.bold,
            ),
          ),
          content: Text(message, style: const TextStyle(color: textSecondary)),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(ctx).pop(),
              child: const Text(
                "TAMAM",
                style: TextStyle(
                  color: primaryColor,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ],
        );
      },
    );
  }
}
