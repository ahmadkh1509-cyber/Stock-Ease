import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../core/constantscolors.dart';
import '../../services/auth_provider.dart';
import '../dashboard/dash_board_screen.dart';
import 'login_screen.dart';
import '../main_shell.dart'; // replaces the dashboard_screen import

class AuthWrapper extends StatelessWidget {
  const AuthWrapper({super.key});

  @override
  Widget build(BuildContext context) {
    final auth = context.watch<AuthProvider>();

    if (auth.isInitializing) {
      return const Scaffold(
        body: Center(
          child: CircularProgressIndicator(color: AppColors.primary),
        ),
      );
    }

    return auth.isLoggedIn ? const MainShell() : const LoginScreen();
  }
}
