import 'dart:async';

import 'package:jailbreak_root_detection/jailbreak_root_detection.dart';

abstract class SecurityService {
  /// true = kompromitované / nedůvěryhodné prostředí
  Stream<bool> get integrityStream;

  Future<void> refresh();
  void dispose();
}

class BaselineSecurityService implements SecurityService {
  BaselineSecurityService() {
    // baseline: záměrně vždy "OK"
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
      final detection = JailbreakRootDetection.instance;

      final isNotTrust = await detection.isNotTrust; // ne-důvěryhodné prostředí
      final isJailBroken = await detection.isJailBroken; // root/jailbreak
      final isRealDevice = await detection.isRealDevice; // emulator / virtual device
      final issues = await detection.checkForIssues; // detailní seznam problémů

      // Android-only: developer mode / external storage (safe fallback na ostatních platformách)
      bool isDevMode = false;
      bool isOnExternalStorage = false;
      try {
        isDevMode = await detection.isDevMode;
        isOnExternalStorage = await detection.isOnExternalStorage;
      } catch (_) {
        // ignoruj, pokud platforma/impl nenabízí
      }

      final compromised =
          !isRealDevice || // emulátor / ne-reálné zařízení
          isJailBroken || // root / jailbreak
          isNotTrust || // ne-důvěryhodné prostředí
          isDevMode || // developer mode (Android)
          isOnExternalStorage || // instalace na external storage
          issues.isNotEmpty; // libovolný zaznamenaný problém

      _controller.add(compromised);
    } catch (_) {
      // Fail-closed: pokud se detekce pokazí, považuj prostředí za kompromitované
      _controller.add(true);
    }
  }

  @override
  void dispose() {
    _controller.close();
  }
}
