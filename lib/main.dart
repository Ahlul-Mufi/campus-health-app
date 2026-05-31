import 'package:flutter/material.dart';
import 'screens/home/home_screen.dart';

void main() {
  runApp(const CampusHealthApp());
}

class CampusHealthApp extends StatelessWidget {
  const CampusHealthApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Campus Health',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(
          seedColor: const Color(0xFF96B6C5),
          primary: const Color(0xFF96B6C5),
          secondary: const Color(0xFFADC4CE),
          surface: const Color(0xFFF1F0E8),
        ),
        scaffoldBackgroundColor: const Color(0xFFF1F0E8),
        appBarTheme: const AppBarTheme(
          backgroundColor: Color(0xFF96B6C5),
          foregroundColor: Colors.white,
          elevation: 0,
        ),
        useMaterial3: true,
      ),
      home: const HomeScreen(),
    );
  }
}
