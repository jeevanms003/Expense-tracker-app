import 'package:flutter/material.dart';

// Custom ThemeExtension for gradients since ThemeData doesn't support them directly
class CustomGradients extends ThemeExtension<CustomGradients> {
  final LinearGradient cardGradient;
  final LinearGradient scaffoldGradient;
  final LinearGradient micButtonGradient;
  final LinearGradient addButtonGradient;

  CustomGradients({
    required this.cardGradient,
    required this.scaffoldGradient,
    required this.micButtonGradient,
    required this.addButtonGradient,
  });

  @override
  CustomGradients copyWith({
    LinearGradient? cardGradient,
    LinearGradient? scaffoldGradient,
    LinearGradient? micButtonGradient,
    LinearGradient? addButtonGradient,
  }) {
    return CustomGradients(
      cardGradient: cardGradient ?? this.cardGradient,
      scaffoldGradient: scaffoldGradient ?? this.scaffoldGradient,
      micButtonGradient: micButtonGradient ?? this.micButtonGradient,
      addButtonGradient: addButtonGradient ?? this.addButtonGradient,
    );
  }

  @override
  CustomGradients lerp(ThemeExtension<CustomGradients>? other, double t) {
    if (other is! CustomGradients) {
      return this;
    }
    // LinearGradient doesn't support lerp, so we return the current instance
    return this;
  }
}

class AppTheme {
  static final lightTheme = ThemeData(
    useMaterial3: true,
    colorScheme: ColorScheme.fromSeed(
      seedColor: Colors.teal,
      brightness: Brightness.light,
      primary: Colors.teal[600]!,
      onPrimary: Colors.white,
      secondary: Colors.deepPurple[800]!,
      onSecondary: Colors.white,
      surface: Colors.grey[100]!,
      onSurface: Colors.grey[900]!,
    ),
    fontFamily: 'Poppins',
    scaffoldBackgroundColor: Colors.transparent, // Gradient handled by CustomGradients
    appBarTheme: AppBarTheme(
      elevation: 0,
      backgroundColor: Colors.teal[600],
      foregroundColor: Colors.white,
      titleTextStyle: const TextStyle(
        fontFamily: 'Poppins',
        fontSize: 20,
        fontWeight: FontWeight.w600,
        color: Colors.white,
      ),
    ),
    cardTheme: CardTheme(
      elevation: 4,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      color: Colors.transparent, // Gradient handled by CustomGradients
      shadowColor: Colors.grey.withOpacity(0.2),
    ),
    elevatedButtonTheme: ElevatedButtonThemeData(
      style: ElevatedButton.styleFrom(
        backgroundColor: Colors.teal[600],
        foregroundColor: Colors.white,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
        textStyle: const TextStyle(
          fontFamily: 'Poppins',
          fontSize: 14,
          fontWeight: FontWeight.w500,
        ),
      ),
    ),
    textButtonTheme: TextButtonThemeData(
      style: TextButton.styleFrom(
        foregroundColor: Colors.deepPurple[700],
        textStyle: const TextStyle(
          fontFamily: 'Poppins',
          fontSize: 14,
          fontWeight: FontWeight.w500,
        ),
      ),
    ),
    textTheme: const TextTheme(
      titleLarge: TextStyle(fontSize: 18, fontWeight: FontWeight.w600, color: Colors.grey),
      titleMedium: TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
      bodyMedium: TextStyle(fontSize: 14, fontWeight: FontWeight.w400),
      labelMedium: TextStyle(fontSize: 14, fontWeight: FontWeight.w500),
      bodySmall: TextStyle(fontSize: 12, fontWeight: FontWeight.w400),
    ).apply(
      displayColor: Colors.grey[900],
      bodyColor: Colors.grey[900],
    ),
    progressIndicatorTheme: ProgressIndicatorThemeData(
      color: Colors.teal[600],
    ),
    dialogTheme: DialogTheme(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      elevation: 6,
      backgroundColor: Colors.white,
    ),
    extensions: [
      CustomGradients(
        cardGradient: const LinearGradient(
          colors: [Color(0xFFFCE4EC), Color(0xFFF8BBD0)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        scaffoldGradient: const LinearGradient(
          colors: [Color(0xFFE8F5E9), Color(0xFFF3E5F5)],
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
        ),
        micButtonGradient: const LinearGradient(
          colors: [Color(0xFF2E7D32), Color(0xFF81C784)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        addButtonGradient: const LinearGradient(
          colors: [Color(0xFF6A1B9A), Color(0xFFAB47BC)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
      ),
    ],
  );

  static final darkTheme = ThemeData(
    useMaterial3: true,
    colorScheme: ColorScheme.fromSeed(
      seedColor: Colors.teal,
      brightness: Brightness.dark,
      primary: Colors.teal[400]!,
      onPrimary: Colors.white,
      secondary: Colors.amber[400]!,
      onSecondary: Colors.black,
      surface: Colors.grey[900]!,
      onSurface: Colors.white,
    ),
    fontFamily: 'Poppins',
    scaffoldBackgroundColor: Colors.transparent, // Gradient handled by CustomGradients
    appBarTheme: AppBarTheme(
      elevation: 0,
      backgroundColor: Colors.teal[700],
      foregroundColor: Colors.white,
      titleTextStyle: const TextStyle(
        fontFamily: 'Poppins',
        fontSize: 20,
        fontWeight: FontWeight.w600,
        color: Colors.white,
      ),
    ),
    cardTheme: CardTheme(
      elevation: 4,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      color: Colors.transparent, // Gradient handled by CustomGradients
      shadowColor: Colors.black.withOpacity(0.2),
    ),
    elevatedButtonTheme: ElevatedButtonThemeData(
      style: ElevatedButton.styleFrom(
        backgroundColor: Colors.teal[700],
        foregroundColor: Colors.white,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
        textStyle: const TextStyle(
          fontFamily: 'Poppins',
          fontSize: 14,
          fontWeight: FontWeight.w500,
        ),
      ),
    ),
    textButtonTheme: TextButtonThemeData(
      style: TextButton.styleFrom(
        foregroundColor: Colors.amber[400],
        textStyle: const TextStyle(
          fontFamily: 'Poppins',
          fontSize: 14,
          fontWeight: FontWeight.w500,
        ),
      ),
    ),
    textTheme: const TextTheme(
      titleLarge: TextStyle(fontSize: 18, fontWeight: FontWeight.w600),
      titleMedium: TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
      bodyMedium: TextStyle(fontSize: 14, fontWeight: FontWeight.w400),
      labelMedium: TextStyle(fontSize: 14, fontWeight: FontWeight.w500),
      bodySmall: TextStyle(fontSize: 12, fontWeight: FontWeight.w400),
    ).apply(
      displayColor: Colors.white,
      bodyColor: Colors.white,
    ),
    progressIndicatorTheme: ProgressIndicatorThemeData(
      color: Colors.teal[400],
    ),
    dialogTheme: DialogTheme(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      elevation: 6,
      backgroundColor: Colors.grey[900],
    ),
    extensions: [
      CustomGradients(
        cardGradient: const LinearGradient(
          colors: [Color(0xFF2E2E2E), Color(0xFF424242)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        scaffoldGradient: const LinearGradient(
          colors: [Color(0xFF121212), Color(0xFF1E1E1E)],
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
        ),
        micButtonGradient: const LinearGradient(
          colors: [Color(0xFF26A69A), Color(0xFF80CBC4)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        addButtonGradient: const LinearGradient(
          colors: [Color(0xFFAB47BC), Color(0xFFCE93D8)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
      ),
    ],
  );
}