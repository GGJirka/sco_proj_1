import 'dart:async';

import 'package:flutter_jailbreak_detection/flutter_jailbreak_detection.dart';

abstract class SecurityService {
  Stream<bool> get integrityStream;
  Future<void> refresh();
  void dispose();
}

class BaselineSecurityService implements SecurityService {
  BaselineSecurityService() {
    _controller.add(false);
  }

  final StreamController<bool> _controller = StreamController<bool>.broadcast();

  @override
  Stream<bool> get integrityStream => _controller.stream;

  @override
  Future<void> refresh() async {
    _controller.add(false);
  }

  @override
  void dispose() {
    _controller.close();
  }
}

class HardenedSecurityService implements SecurityService {
  HardenedSecurityService() {
    unawaited(refresh());
  }

  final StreamController<bool> _controller = StreamController<bool>.broadcast();

  @override
  Stream<bool> get integrityStream => _controller.stream;

  @override
  Future<void> refresh() async {
    try {
      final jailbroken = await FlutterJailbreakDetection.jailbroken;
      final developerMode = await FlutterJailbreakDetection.developerMode;

      final compromised = jailbroken || developerMode;

      _controller.add(compromised);
    } catch (_) {
      _controller.add(true);
    }
  }

  @override
  void dispose() {
    _controller.close();
  }
}
