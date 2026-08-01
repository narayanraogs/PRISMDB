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

class PrismApp extends StatefulWidget {
  const PrismApp({super.key});

  static _PrismAppState of(BuildContext context) => 
      context.findAncestorStateOfType<_PrismAppState>()!;

  @override
  State<PrismApp> createState() => _PrismAppState();
}

class _PrismAppState extends State<PrismApp> {
  ThemeMode _themeMode = ThemeMode.light;

  void toggleTheme() {
    setState(() {
      _themeMode = _themeMode == ThemeMode.light ? ThemeMode.dark : ThemeMode.light;
    });
  }

  bool get isLightMode => _themeMode == ThemeMode.light;

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'PRISM DB',
      debugShowCheckedModeBanner: false,
      scrollBehavior: MyCustomScrollBehavior(),
      themeMode: _themeMode,
      theme: ThemeData(
        useMaterial3: true,
        brightness: Brightness.light,
        textTheme: GoogleFonts.poppinsTextTheme(ThemeData.light().textTheme),
        colorScheme: ColorScheme.fromSeed(
          seedColor: const Color(0xFF7B92B3),
          brightness: Brightness.light,
          primary: const Color(0xFF7B92B3), // Subtle Pastel Blue-Grey
          onPrimary: Colors.white,
          secondary: const Color(0xFFA1B5D8), // Lighter Pastel Blue
          surface: Colors.white,
          onSurface: const Color(0xFF334155),
        ),
        scaffoldBackgroundColor: const Color(0xFFF8FAFC),
        dividerTheme: DividerThemeData(
          color: const Color(0xFF7B92B3).withOpacity(0.2),
        ),
        appBarTheme: AppBarTheme(
          backgroundColor: const Color(0xFFF8FAFC),
          foregroundColor: const Color(0xFF334155),
          elevation: 0,
          titleTextStyle: GoogleFonts.poppins(
            color: const Color(0xFF334155),
            fontSize: 22,
            fontWeight: FontWeight.bold,
          ),
          iconTheme: const IconThemeData(color: Color(0xFF334155)),
        ),
        cardTheme: CardThemeData(
          color: Colors.white,
          elevation: 0,
          shadowColor: const Color(0xFF7B92B3).withOpacity(0.1),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
            side: const BorderSide(color: Color(0xFFE2E8F0)),
          ),
        ),
        filledButtonTheme: FilledButtonThemeData(
          style: FilledButton.styleFrom(
            backgroundColor: const Color(0xFF7B92B3),
            foregroundColor: Colors.white,
            textStyle: GoogleFonts.poppins(fontWeight: FontWeight.w600),
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            elevation: 0,
          ),
        ),
        scrollbarTheme: ScrollbarThemeData(
          thumbColor: WidgetStateProperty.all(const Color(0xFF7B92B3).withOpacity(0.5)),
          trackColor: WidgetStateProperty.all(Colors.grey.shade100),
          trackVisibility: WidgetStateProperty.all(false),
          thumbVisibility: WidgetStateProperty.all(false),
          radius: const Radius.circular(8),
          thickness: WidgetStateProperty.all(6),
          interactive: true,
        ),
      ),
      darkTheme: ThemeData(
        useMaterial3: true,
        brightness: Brightness.dark,
        textTheme: GoogleFonts.poppinsTextTheme(ThemeData.dark().textTheme),
        colorScheme: ColorScheme.fromSeed(
          seedColor: const Color(0xFF64748B),
          brightness: Brightness.dark,
          primary: const Color(0xFF94A3B8), // Muted Slate Blue
          onPrimary: const Color(0xFF0F172A),
          secondary: const Color(0xFFCBD5E1), // Light Slate
          surface: const Color(0xFF1E293B), // Slate 800
          background: const Color(0xFF0F172A), // Slate 900
          onSurface: const Color(0xFFF8FAFC), // Slate 50
        ),
        scaffoldBackgroundColor: const Color(0xFF0F172A),
        dividerTheme: DividerThemeData(
          color: const Color(0xFF94A3B8).withOpacity(0.15),
        ),
        appBarTheme: AppBarTheme(
          backgroundColor: const Color(0xFF0F172A),
          foregroundColor: const Color(0xFFF8FAFC), 
          elevation: 0,
          titleTextStyle: GoogleFonts.poppins(
            color: const Color(0xFFF8FAFC),
            fontSize: 22,
            fontWeight: FontWeight.bold,
          ),
          iconTheme: const IconThemeData(color: Color(0xFFF8FAFC)),
        ),
        cardTheme: CardThemeData(
          color: const Color(0xFF1E293B),
          elevation: 0,
          shadowColor: Colors.black.withOpacity(0.2),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
            side: const BorderSide(color: Color(0xFF334155)),
          ),
        ),
        filledButtonTheme: FilledButtonThemeData(
          style: FilledButton.styleFrom(
            backgroundColor: const Color(0xFF94A3B8),
            foregroundColor: const Color(0xFF0F172A),
            textStyle: GoogleFonts.poppins(fontWeight: FontWeight.w600),
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            elevation: 0,
          ),
        ),
        scrollbarTheme: ScrollbarThemeData(
          thumbColor: WidgetStateProperty.all(const Color(0xFF94A3B8).withOpacity(0.5)),
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
