import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'screens/main_shell.dart';

void main() {
  WidgetsFlutterBinding.ensureInitialized();
  SystemChrome.setSystemUIOverlayStyle(
    const SystemUiOverlayStyle(
      statusBarColor: Colors.transparent,
      statusBarIconBrightness: Brightness.dark,
    ),
  );
  runApp(const HealthyUnairApp());
}

class HealthyUnairApp extends StatelessWidget {
  const HealthyUnairApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Healthy UNAIR',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        useMaterial3: true,
        fontFamily: 'Inter',
        colorScheme: const ColorScheme(
          brightness: Brightness.light,
          primary: Color(0xFF0D631B),
          onPrimary: Colors.white,
          primaryContainer: Color(0xFF2E7D32),
          onPrimaryContainer: Color(0xFFCBFFC2),
          secondary: Color(0xFF3C6842),
          onSecondary: Colors.white,
          secondaryContainer: Color(0xFFBDEFBE),
          onSecondaryContainer: Color(0xFF426E47),
          tertiary: Color(0xFF4D5950),
          onTertiary: Colors.white,
          tertiaryContainer: Color(0xFF657167),
          onTertiaryContainer: Color(0xFFE8F5E9),
          error: Color(0xFFBA1A1A),
          onError: Colors.white,
          errorContainer: Color(0xFFFFDAD6),
          onErrorContainer: Color(0xFF93000A),
          surface: Color(0xFFFBF9F1),
          onSurface: Color(0xFF1B1C17),
          surfaceContainerHighest: Color(0xFFE4E3DA),
          onSurfaceVariant: Color(0xFF40493D),
          outline: Color(0xFF707A6C),
          outlineVariant: Color(0xFFBFCABA),
          shadow: Colors.black,
          scrim: Colors.black,
          inverseSurface: Color(0xFF30312B),
          onInverseSurface: Color(0xFFF2F1E8),
          inversePrimary: Color(0xFF88D982),
        ),
        scaffoldBackgroundColor: const Color(0xFFFBF9F1),
        appBarTheme: const AppBarTheme(
          backgroundColor: Color(0xFFFBF9F1),
          foregroundColor: Color(0xFF1B1C17),
          elevation: 0,
          scrolledUnderElevation: 1,
        ),
      ),
      home: const MainShell(),
    );
  }
}