import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'screens/home_screen.dart';

void main() {
  GoogleFonts.config.allowRuntimeFetching = false;
  runApp(const PrismApp());
}

class MyCustomScrollBehavior extends MaterialScrollBehavior {
  // Override behavior methods and getters like dragDevices
  @override
  Set<PointerDeviceKind> get dragDevices => {
        PointerDeviceKind.touch,
        PointerDeviceKind.mouse,
      };
}

class PrismApp extends StatelessWidget {
  const PrismApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'PRISM DB',
      debugShowCheckedModeBanner: false,
      scrollBehavior: MyCustomScrollBehavior(),
      theme: ThemeData(
        useMaterial3: true,
        brightness: Brightness.dark,
        // Set default font to Poppins for a modern, bold look with dark text theme base
        textTheme: GoogleFonts.poppinsTextTheme(ThemeData.dark().textTheme),
        colorScheme: ColorScheme.fromSeed(
          seedColor: const Color(0xFF1E3A8A), // Deep Slate/Midnight Blue seed
          brightness: Brightness.dark,
          primary: const Color(0xFF3B82F6), // Vibrant royal blue
          onPrimary: Colors.white,
          secondary: const Color(0xFF60A5FA), // Accent light blue
          surface: const Color(0xFF1E293B), // Slate 800
          background: const Color(0xFF0F172A), // Slate 900
          onSurface: const Color(0xFFF8FAFC), // Slate 50
        ),
        scaffoldBackgroundColor: const Color(0xFF0A0F1D), // Dark midnight background
        dividerTheme: DividerThemeData(
          color: Colors.blue.withOpacity(0.15),
        ),
        appBarTheme: AppBarTheme(
          backgroundColor: const Color(0xFF0F172A),
          foregroundColor: const Color(0xFFF8FAFC), // Off-white
          elevation: 0,
          titleTextStyle: GoogleFonts.poppins(
            color: const Color(0xFFF8FAFC),
            fontSize: 22,
            fontWeight: FontWeight.bold,
          ),
          iconTheme: const IconThemeData(color: Color(0xFFF8FAFC)),
        ),
        cardTheme: CardThemeData(
          color: const Color(0xFF151F32), // Darker blue-slate card color
          elevation: 2,
          shadowColor: Colors.black.withOpacity(0.3),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
            side: BorderSide(color: Colors.blue.withOpacity(0.1)),
          ),
        ),
        filledButtonTheme: FilledButtonThemeData(
          style: FilledButton.styleFrom(
            backgroundColor: const Color(0xFF3B82F6),
            foregroundColor: Colors.white,
            textStyle: GoogleFonts.poppins(fontWeight: FontWeight.w600),
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          ),
        ),
        scrollbarTheme: ScrollbarThemeData(
          thumbColor: WidgetStateProperty.all(const Color(0xFF3B82F6).withOpacity(0.5)),
          trackColor: WidgetStateProperty.all(const Color(0xFF1E293B)),
          trackVisibility: WidgetStateProperty.all(false),
          thumbVisibility: WidgetStateProperty.all(false),
          radius: const Radius.circular(8),
          thickness: WidgetStateProperty.all(6),
          interactive: true,
        ),
      ),
      home: const HomeScreen(),
    );
  }
}
