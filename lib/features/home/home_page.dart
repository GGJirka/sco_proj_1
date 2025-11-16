import 'dart:convert';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';

import '../../services/api_service.dart';
import '../../services/firebase_service.dart';
import '../../services/security_service.dart';
import '../../services/service_locator.dart';
import '../../services/storage_service.dart';

class HomePage extends StatefulWidget {
  const HomePage({super.key, required this.isHardened});

  final bool isHardened;

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  late final FirebaseService _firebaseService;
  late final StorageService _storageService;
  late final ApiService _apiService;
  late final SecurityService _securityService;

  Map<String, dynamic>? _premiumReport;
  String? _premiumError;
  bool _loadingPremium = false;

  String? _storedToken;
  String? _storedSecret;

  @override
  void initState() {
    super.initState();
    _firebaseService = get<FirebaseService>();
    _storageService = get<StorageService>();
    _apiService = get<ApiService>();
    _securityService = get<SecurityService>();
    _securityService.refresh();
    _loadStoredValues();
  }

  Future<void> _loadStoredValues() async {
    final token = await _storageService.readIdToken();
    final secret = await _storageService.readLocalSecret();
    if (!mounted) return;
    setState(() {
      _storedToken = token;
      _storedSecret = secret;
    });
  }

  Future<void> _fetchPremiumReport() async {
    setState(() {
      _loadingPremium = true;
      _premiumError = null;
    });
    try {
      final report = await _firebaseService.fetchPremiumReport();
      if (!mounted) return;
      setState(() {
        _premiumReport = report;
      });
    } catch (error) {
      if (!mounted) return;
      setState(() {
        _premiumError = error.toString();
      });
    } finally {
      if (mounted) {
        setState(() {
          _loadingPremium = false;
        });
      }
    }
  }

  Future<void> _refreshConfig() async {
    try {
      await _apiService.fetchRemoteConfig();
    } catch (error) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Config fetch failed: $error')));
    }
  }

  @override
  Widget build(BuildContext context) {
    final user = _firebaseService.currentUser;
    if (user == null) {
      return const Scaffold(body: Center(child: Text('No authenticated user')));
    }

    return Scaffold(
      appBar: AppBar(
        title: Text('Home (${widget.isHardened ? 'hardened' : 'baseline'})'),
        actions: [
          IconButton(
            onPressed: () async {
              await _firebaseService.signOut();
            },
            icon: const Icon(Icons.logout),
            tooltip: 'Sign out',
          ),
        ],
      ),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: StreamBuilder<bool>(
          stream: _securityService.integrityStream,
          builder: (context, integritySnapshot) {
            final compromised = integritySnapshot.data ?? false;
            return SingleChildScrollView(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('User UID: ${user.uid}'),
                  const SizedBox(height: 8),
                  Text('Stored ID token (cached): ${_storedToken ?? 'not stored'}'),
                  const SizedBox(height: 4),
                  Text('Stored localSecret: ${_storedSecret ?? 'not stored'}'),
                  const SizedBox(height: 16),
                  StreamBuilder<DocumentSnapshot<Map<String, dynamic>>>(
                    stream: _firebaseService.userDocumentStream(user.uid),
                    builder: (context, snapshot) {
                      if (snapshot.connectionState == ConnectionState.waiting) {
                        return const CircularProgressIndicator();
                      }
                      if (!snapshot.hasData || !snapshot.data!.exists) {
                        return const Text('No balance document found');
                      }
                      final data = snapshot.data!.data();
                      final balance = data?['balance'] ?? 0;
                      return Text('Balance: $balance');
                    },
                  ),
                  const SizedBox(height: 16),
                  StreamBuilder<Map<String, dynamic>?>(
                    stream: _apiService.configStream,
                    builder: (context, snapshot) {
                      if (!snapshot.hasData) {
                        return const Text('No configuration loaded');
                      }
                      return Text('Config: ${jsonEncode(snapshot.data)}');
                    },
                  ),
                  const SizedBox(height: 8),
                  ElevatedButton(onPressed: _refreshConfig, child: const Text('Refresh remote config')),
                  const SizedBox(height: 16),
                  if (compromised)
                    const Text(
                      'Limited mode: device integrity checks detected a rooted or jailbroken environment. Premium features hidden.',
                      style: TextStyle(color: Colors.orange),
                    )
                  else
                    ElevatedButton(
                      onPressed: _loadingPremium ? null : _fetchPremiumReport,
                      child: _loadingPremium
                          ? const SizedBox(width: 16, height: 16, child: CircularProgressIndicator(strokeWidth: 2))
                          : const Text('Premium report'),
                    ),
                  if (_premiumError != null) ...[
                    const SizedBox(height: 8),
                    Text(_premiumError!, style: const TextStyle(color: Colors.red)),
                  ],
                  if (_premiumReport != null && !compromised) ...[
                    const SizedBox(height: 8),
                    Text('Premium report: ${jsonEncode(_premiumReport)}'),
                  ],
                ],
              ),
            );
          },
        ),
      ),
    );
  }
}
