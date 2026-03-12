import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'screens/home_screen.dart';

void main() {
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
        // Set default font to Poppins for a modern, bold look
        textTheme: GoogleFonts.poppinsTextTheme(),
        colorScheme: ColorScheme.fromSeed(
          seedColor: Colors.indigo,
          brightness: Brightness.light,
          primary: Colors.indigo,
          onPrimary: Colors.white,
          secondary: Colors.blueAccent,
          surface: Colors.white,
          background: const Color(0xFFEFF6FF), // Blue 50
          onSurface: const Color(0xFF1F2937), // Grey 900
        ),
        scaffoldBackgroundColor: const Color(0xFFF3F4F6), // Cool Grey 100
        dividerTheme: DividerThemeData(
          color: Colors.indigo.withOpacity(0.1),
        ),
        appBarTheme: AppBarTheme(
          backgroundColor: Colors.white,
          foregroundColor: const Color(0xFF1F2937), // Grey 900
          elevation: 0,
          titleTextStyle: GoogleFonts.poppins(
            color: const Color(0xFF1F2937), // Grey 900
            fontSize: 22,
            fontWeight: FontWeight.bold,
          ),
          iconTheme: const IconThemeData(color: Color(0xFF1F2937)),
        ),
        cardTheme: CardThemeData(
          color: Colors.white,
          elevation: 2,
          shadowColor: Colors.indigo.withOpacity(0.1),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
            side: BorderSide(color: Colors.indigo.withOpacity(0.1)),
          ),
        ),
        filledButtonTheme: FilledButtonThemeData(
          style: FilledButton.styleFrom(
            backgroundColor: Colors.indigo,
            foregroundColor: Colors.white,
            textStyle: GoogleFonts.poppins(fontWeight: FontWeight.w600),
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          ),
        ),
        scrollbarTheme: ScrollbarThemeData(
          thumbColor: MaterialStateProperty.all(Colors.indigo[700]),
          trackColor: MaterialStateProperty.all(Colors.blue[100]),
          trackVisibility: MaterialStateProperty.all(false),
          thumbVisibility: MaterialStateProperty.all(false),
          radius: const Radius.circular(8),
          thickness: MaterialStateProperty.all(6),
          interactive: true,
        ),
      ),
      home: const HomeScreen(),
    );
  }
}
