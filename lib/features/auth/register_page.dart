import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';

import '../../services/firebase_service.dart';
import '../../services/service_locator.dart';

class RegisterPage extends StatefulWidget {
  const RegisterPage({super.key, required this.isHardened});

  final bool isHardened;

  @override
  State<RegisterPage> createState() => _RegisterPageState();
}

class _RegisterPageState extends State<RegisterPage> {
  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();

  late final FirebaseService _firebaseService;

  bool _isLoading = false;
  String? _errorMessage;

  @override
  void initState() {
    super.initState();
    _firebaseService = get<FirebaseService>();
  }

  Future<void> _register() async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });
    try {
      await _firebaseService.register(_emailController.text.trim(), _passwordController.text);
      if (!mounted) return;
      Navigator.pop(context);
    } on FirebaseAuthException catch (error) {
      setState(() {
        _errorMessage = error.message ?? 'Registration failed';
      });
    } catch (error) {
      setState(() {
        _errorMessage = error.toString();
      });
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
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
      appBar: AppBar(title: Text('Register (${widget.isHardened ? 'hardened' : 'baseline'})')),
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
            if (_errorMessage != null) ...[
              const SizedBox(height: 12),
              Text(_errorMessage!, style: const TextStyle(color: Colors.red)),
            ],
            const SizedBox(height: 20),
            _isLoading
                ? const CircularProgressIndicator()
                : ElevatedButton(onPressed: _register, child: const Text('Register')),
          ],
        ),
      ),
    );
  }
}
