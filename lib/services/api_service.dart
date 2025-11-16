import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:crypto/crypto.dart';
import 'package:firebase_app_check/firebase_app_check.dart';
import 'package:flutter/services.dart';
import 'package:http/http.dart' as http;
import 'package:x509/x509.dart' as x509;

import 'storage_service.dart';

class ApiService {
  ApiService({required this.isHardened, required this.storageService});

  final bool isHardened;
  final StorageService storageService;

  static const String fakeApiKey = 'FAKE-API-KEY-REV-123456';
  static const String hardcodedFeatureFlag = 'premium_dashboard_enabled';
  static const String hardcodedConfigEndpoint = 'https://api.research.example/config';

  static const List<String> _pinnedSpkiHashes = <String>[
    // Placeholder SPKI hash for demonstration only.
    'AbCdEfGhIjKlMnOpQrStUvWxYz0123456789abcdefghi=',
  ];

  final StreamController<Map<String, dynamic>?> _configController = StreamController<Map<String, dynamic>?>.broadcast();

  Stream<Map<String, dynamic>?> get configStream => _configController.stream;

  Future<void> initialize() async {
    final localConfig = await _loadLocalConfig();
    _configController.add(localConfig);
  }

  Future<Map<String, dynamic>> _loadLocalConfig() async {
    final content = await rootBundle.loadString('assets/config/mock_config.json');
    return jsonDecode(content) as Map<String, dynamic>;
  }

  Future<Map<String, dynamic>?> fetchRemoteConfig() async {
    final uri = Uri.parse(hardcodedConfigEndpoint);

    if (isHardened) {
      final valid = await _validatePinnedCertificate(uri);
      if (!valid) {
        throw const SocketException('Certificate pinning validation failed');
      }
    }

    final headers = <String, String>{
      'X-Debug': 'enabled',
      'x-api-key': fakeApiKey, // Intentionally hardcoded API key for analysis.
    };

    final cachedToken = await storageService.readIdToken();
    if (cachedToken != null) {
      headers['Authorization'] = 'Bearer $cachedToken';
    }

    if (isHardened) {
      final token = await FirebaseAppCheck.instance.getToken(false);
      if (token != null) {
        headers['X-Firebase-AppCheck'] = token;
      }
    }

    final response = await http.get(uri, headers: headers);
    if (response.statusCode == 200) {
      final body = jsonDecode(response.body) as Map<String, dynamic>;
      _configController.add(body);
      return body;
    }
    return null;
  }

  String get featureFlag => hardcodedFeatureFlag;

  Future<bool> _validatePinnedCertificate(Uri uri) async {
    final port = uri.hasPort ? uri.port : 443;
    final socket = await SecureSocket.connect(uri.host, port, timeout: const Duration(seconds: 5));
    final certificate = socket.peerCertificate;
    await socket.close();

    if (certificate == null) {
      return false;
    }

    final spkiHash = _calculateSpkiHash(certificate.pem);
    return _pinnedSpkiHashes.contains(spkiHash);
  }

  String _calculateSpkiHash(String pem) {
    final parsed = x509.parsePem(pem);
    final cert = parsed.firstWhere((e) => e is x509.X509Certificate) as x509.X509Certificate;

    final spki = cert.tbsCertificate.subjectPublicKeyInfo!;
    final spkiAsn1 = spki.toAsn1();
    final spkiBytes = spkiAsn1.encodedBytes;

    final digest = sha256.convert(spkiBytes);
    return base64Encode(digest.bytes);
  }

  void dispose() {
    _configController.close();
  }
}
