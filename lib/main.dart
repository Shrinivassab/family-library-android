import 'package:flutter/material.dart';
import 'screens/home_screen.dart';

void main() {
  runApp(const FamilyLibraryApp());
}

class FamilyLibraryApp extends StatelessWidget {
  const FamilyLibraryApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Family Library AI Companion',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        primarySwatch: Colors.blue,
        primaryColor: const Color(0xFF1f77b4),
        scaffoldBackgroundColor: Colors.white,
        textTheme: ThemeData.light().textTheme,
        appBarTheme: const AppBarTheme(
          backgroundColor: Color(0xFF1f77b4),
          foregroundColor: Colors.white,
          elevation: 2,
        ),
        elevatedButtonTheme: ElevatedButtonThemeData(
          style: ElevatedButton.styleFrom(
            backgroundColor: const Color(0xFF1f77b4),
            foregroundColor: Colors.white,
            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 14),
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
          ),
        ),
      ),
      home: const HomeScreen(),
    );
  }
}
