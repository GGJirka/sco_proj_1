import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';

import '../../services/api_service.dart';
import '../../services/firebase_service.dart';
import '../../services/service_locator.dart';
import '../../services/storage_service.dart';

class LoginPage extends StatefulWidget {
  const LoginPage({super.key, required this.isHardened});

  final bool isHardened;

  @override
  State<LoginPage> createState() => _LoginPageState();
}

class _LoginPageState extends State<LoginPage> {
  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();

  late final FirebaseService _firebaseService;
  late final StorageService _storageService;
  late final ApiService _apiService;

  bool _isLoading = false;
  String? _errorMessage;

  @override
  void initState() {
    super.initState();
    _firebaseService = get<FirebaseService>();
    _storageService = get<StorageService>();
    _apiService = get<ApiService>();
    _loadLastEmail();
  }

  Future<void> _loadLastEmail() async {
    final lastEmail = await _storageService.readLastLoginEmail();
    if (lastEmail != null) {
      _emailController.text = lastEmail;
    }
  }

  Future<void> _signIn() async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });
    try {
      final credential = await _firebaseService.signIn(_emailController.text.trim(), _passwordController.text);
      await _persistSessionData(credential);
      if (!mounted) return;
      Navigator.pushReplacementNamed(context, '/home');
    } on FirebaseAuthException catch (error) {
      setState(() => _errorMessage = error.message ?? 'Authentication failed');
    } catch (error) {
      setState(() => _errorMessage = error.toString());
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  Future<void> _persistSessionData(UserCredential credential) async {
    final user = credential.user;
    if (user == null) {
      return;
    }
    final token = await user.getIdToken();

    if (token == null) {
      return;
    }

    await _storageService.saveIdToken(token);
    await _storageService.saveLastLoginEmail(user.email ?? 'unknown@example.com');
    await _storageService.saveLocalSecret('localSecret-demo-${user.uid}');
  }

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text('Login (${widget.isHardened ? 'hardened' : 'baseline'})')),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            TextField(
              controller: _emailController,
              keyboardType: TextInputType.emailAddress,
              decoration: const InputDecoration(labelText: 'Email'),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: _passwordController,
              decoration: const InputDecoration(labelText: 'Password'),
              obscureText: true,
            ),
            const SizedBox(height: 12),
            Text('Feature flag: ${_apiService.featureFlag}', style: const TextStyle(fontStyle: FontStyle.italic)),
            if (_errorMessage != null) ...[
              const SizedBox(height: 12),
              Text(_errorMessage!, style: const TextStyle(color: Colors.red)),
            ],
            const SizedBox(height: 20),
            _isLoading
                ? const CircularProgressIndicator()
                : ElevatedButton(onPressed: _signIn, child: const Text('Sign in')),
            TextButton(
              onPressed: () {
                Navigator.pushNamed(context, '/register');
              },
              child: const Text('Create an account'),
            ),
          ],
        ),
      ),
    );
  }
}
