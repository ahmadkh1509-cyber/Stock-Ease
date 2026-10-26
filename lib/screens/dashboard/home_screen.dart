import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../core/constantscolors.dart';
import '../../services/auth_provider.dart';

class HomeScreen extends StatelessWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final user = context.watch<AuthProvider>().user;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Dashboard'),
        backgroundColor: Colors.white,
        actions: [
          IconButton(
            icon: const Icon(Icons.logout_rounded),
            onPressed: () => context.read<AuthProvider>().logout(),
          ),
        ],
      ),
      body: Center(
        child: Text(
          'Welcome, ${user?.displayName ?? user?.email ?? ''}',
          style: const TextStyle(fontSize: 18, color: AppColors.textDark),
        ),
      ),
    );
  }
}
