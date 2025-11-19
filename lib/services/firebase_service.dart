import 'dart:convert';
import 'dart:io';

import 'package:cloud_firestore/cloud_firestore.dart';
// import 'package:cloud_functions/cloud_functions.dart'; // <- už není potřeba
import 'package:firebase_app_check/firebase_app_check.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:http/http.dart' as http;
import 'package:http/io_client.dart';

http.Client createHttpClient({required bool isHardened}) {
  if (isHardened) {
    // Hardened: default Client → normální cert verify + případné pinning
    return http.Client();
  }

  final HttpClient ioClient = HttpClient()
    ..badCertificateCallback = (X509Certificate cert, String host, int port) {
      return true; // akceptuj jakýkoliv cert
    };

  return IOClient(ioClient);
}

class FirebaseService {
  FirebaseService({required this.isHardened});

  final bool isHardened;
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  Future<void> initialize() async {
    if (isHardened) {
      await FirebaseAppCheck.instance.activate(androidProvider: AndroidProvider.playIntegrity);
    } else {
      // Baseline intentionally leaves App Check disabled for research demos.
    }
  }

  Stream<User?> get authStateChanges => _auth.authStateChanges();

  User? get currentUser => _auth.currentUser;

  Future<UserCredential> signIn(String email, String password) {
    return _auth.signInWithEmailAndPassword(email: email, password: password);
  }

  Future<UserCredential> register(String email, String password) async {
    final credential = await _auth.createUserWithEmailAndPassword(email: email, password: password);
    final user = credential.user;
    if (user != null) {
      await _firestore.collection('users').doc(user.uid).set({
        'balance': 0,
        'updatedAt': FieldValue.serverTimestamp(),
      }, SetOptions(merge: true));
    }
    return credential;
  }

  Future<void> signOut() => _auth.signOut();

  Stream<DocumentSnapshot<Map<String, dynamic>>> userDocumentStream(String uid) {
    return _firestore.collection('users').doc(uid).snapshots();
  }

  Future<Map<String, dynamic>> fetchPremiumReport() async {
    final projectId = Firebase.app().options.projectId;
    final uri = Uri.parse('https://us-central1-$projectId.cloudfunctions.net/getPremiumReport');

    final headers = <String, String>{'X-Debug': 'enabled'};

    final user = _auth.currentUser;
    final idToken = await user?.getIdToken();
    if (idToken != null) {
      headers['Authorization'] = 'Bearer $idToken';
    }

    if (isHardened) {
      final token = await FirebaseAppCheck.instance.getToken(false);
      if (token != null) {
        headers['X-Firebase-AppCheck'] = token;
      }
    }

    final response = await createHttpClient(isHardened: isHardened).post(uri, headers: headers);
    if (response.statusCode != 200) {
      throw Exception('Premium report error: ${response.statusCode}');
    }

    return jsonDecode(response.body) as Map<String, dynamic>;
  }
}
