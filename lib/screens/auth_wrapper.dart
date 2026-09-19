import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/tab_provider.dart';
import '../services/auth_service.dart';
import 'home_screen.dart';
import 'login_screen.dart';

class AuthWrapper extends StatelessWidget {
  const AuthWrapper({super.key});

  @override
  Widget build(BuildContext context) {
    final authService = Provider.of<AuthService>(context, listen: false);

    return StreamBuilder<User?>(
      stream: authService.authStateChanges,
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Scaffold(
            body: Center(
              child: CircularProgressIndicator(
                color: Color(0xFF9CAF88),
              ),
            ),
          );
        }

        final user = snapshot.data;
        if (user == null) {
          // Reset user scope in provider
          WidgetsBinding.instance.addPostFrameCallback((_) {
            Provider.of<TabProvider>(context, listen: false).updateUser(null);
          });
          return const LoginScreen();
        }

        // Update provider with current user ID
        WidgetsBinding.instance.addPostFrameCallback((_) {
          Provider.of<TabProvider>(context, listen: false).updateUser(user.uid);
        });

        return const HomeScreen();
      },
    );
  }
}
