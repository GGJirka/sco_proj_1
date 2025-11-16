import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';

import 'features/auth/login_page.dart';
import 'features/auth/register_page.dart';
import 'features/home/home_page.dart';
import 'services/firebase_service.dart';
import 'services/service_locator.dart';

class MyApp extends StatefulWidget {
  const MyApp({super.key, required this.buildFlavor, required this.isHardened});

  final String buildFlavor;
  final bool isHardened;

  @override
  State<MyApp> createState() => _MyAppState();
}

class _MyAppState extends State<MyApp> {
  late final FirebaseService _firebaseService;

  @override
  void initState() {
    super.initState();
    _firebaseService = serviceLocator<FirebaseService>();
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Rev Research (${widget.buildFlavor})',
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.deepPurple),
        useMaterial3: true,
      ),
      routes: {
        '/login': (_) => LoginPage(isHardened: widget.isHardened),
        '/register': (_) => RegisterPage(isHardened: widget.isHardened),
        '/home': (_) => HomePage(isHardened: widget.isHardened),
      },
      home: StreamBuilder<User?>(
        stream: _firebaseService.authStateChanges,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Scaffold(
              body: Center(child: CircularProgressIndicator()),
            );
          }
          if (snapshot.hasData && snapshot.data != null) {
            return HomePage(isHardened: widget.isHardened);
          }
          return LoginPage(isHardened: widget.isHardened);
        },
      ),
    );
  }
}
