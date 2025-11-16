import 'dart:async';

import 'package:flutter_jailbreak_detection/flutter_jailbreak_detection.dart';

abstract class SecurityService {
  Stream<bool> get integrityStream;
  Future<void> refresh();
}

class BaselineSecurityService implements SecurityService {
  BaselineSecurityService() {
    _controller.add(false);
  }

  final StreamController<bool> _controller =
      StreamController<bool>.broadcast();

  @override
  Stream<bool> get integrityStream => _controller.stream;

  @override
  Future<void> refresh() async {
    _controller.add(false);
  }
}

class HardenedSecurityService implements SecurityService {
  HardenedSecurityService() {
    refresh();
  }

  final StreamController<bool> _controller =
      StreamController<bool>.broadcast();

  @override
  Stream<bool> get integrityStream => _controller.stream;

  @override
  Future<void> refresh() async {
    final jailbroken = await FlutterJailbreakDetection.jailbroken;
    final developerMode = await FlutterJailbreakDetection.developerMode;
    final suBinary = await FlutterJailbreakDetection.checkForBinary('su');
    final busyboxBinary =
        await FlutterJailbreakDetection.checkForBinary('busybox');
    var systemWritable = false;
    try {
      systemWritable =
          await FlutterJailbreakDetection.canCreateTestFileInSystemDirectories;
    } catch (_) {
      systemWritable = false;
    }
    final compromised =
        jailbroken || developerMode || suBinary || busyboxBinary || systemWritable;
    _controller.add(compromised);
  }
}
