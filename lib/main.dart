import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'core/theme.dart';
import 'firebase_options.dart';
import 'services/auth_provider.dart';
import 'screens/auth/auth_wrapper.dart';
import 'services/dash_board_provider.dart';
import 'services/product_provider.dart';
import 'services/transaction_provider.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => AuthProvider()),
        ChangeNotifierProxyProvider<AuthProvider, ProductProvider>(
          create: (_) => ProductProvider(),
          update: (_, auth, product) => product!..updateUser(auth.user?.uid),
        ),
        ChangeNotifierProxyProvider<AuthProvider, TransactionProvider>(
          create: (_) => TransactionProvider(),
          update: (_, auth, tx) => tx!..updateUser(auth.user?.uid),
        ),
      ],
      child: MaterialApp(
        title: 'StockEase',
        debugShowCheckedModeBanner: false,
        theme: AppTheme.light,
        home: const AuthWrapper(),
      ),
    );
  }
}
