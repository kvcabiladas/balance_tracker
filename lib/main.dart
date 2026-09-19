import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import 'firebase_options.dart';
import 'providers/tab_provider.dart';
import 'screens/auth_wrapper.dart';
import 'services/auth_service.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  
  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );

  SystemChrome.setSystemUIOverlayStyle(const SystemUiOverlayStyle(
    statusBarColor: Colors.transparent,
    statusBarIconBrightness: Brightness.dark,
    statusBarBrightness: Brightness.light,
  ));

  runApp(
    MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => AuthService()),
        ChangeNotifierProvider(create: (_) => TabProvider()),
      ],
      child: const BalanceTrackerApp(),
    ),
  );
}

class BalanceTrackerApp extends StatelessWidget {
  const BalanceTrackerApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Balance Tracker',
      debugShowCheckedModeBanner: false,

      // Modern Light Theme
      theme: ThemeData(
        useMaterial3: true,
        brightness: Brightness.light,
        primaryColor: const Color(0xFF9CAF88), // Sage Green #9caf88
        colorScheme: const ColorScheme.light(
          primary: Color(0xFF9CAF88),
          secondary: Color(0xFF7E946A),
          surface: Colors.white,
          error: Color(0xFFB91C1C),
        ),
        scaffoldBackgroundColor: const Color(0xFFF8FAFC), // Slate 50
        appBarTheme: const AppBarTheme(
          systemOverlayStyle: SystemUiOverlayStyle.dark,
        ),
      ),

      // Modern Slate Dark Theme
      darkTheme: ThemeData(
        useMaterial3: true,
        brightness: Brightness.dark,
        primaryColor: const Color(0xFF9CAF88),
        colorScheme: const ColorScheme.dark(
          primary: Color(0xFF9CAF88),
          secondary: Color(0xFFB8C9A7),
          surface: Color(0xFF1E293B), // Slate 800
          error: Color(0xFFB91C1C),
        ),
        scaffoldBackgroundColor: const Color(0xFF0F172A), // Slate 900
        appBarTheme: const AppBarTheme(
          systemOverlayStyle: SystemUiOverlayStyle.light,
        ),
      ),

      themeMode: ThemeMode.system,
      home: const AuthWrapper(),
    );
  }
}
