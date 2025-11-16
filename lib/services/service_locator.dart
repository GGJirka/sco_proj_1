import 'package:firebase_core/firebase_core.dart';
import 'package:get_it/get_it.dart';

import '../firebase_options.dart';
import 'api_service.dart';
import 'firebase_service.dart';
import 'security_service.dart';
import 'storage_service.dart';

final GetIt serviceLocator = GetIt.instance;

Future<void> setupLocator({required bool hardened}) async {
  if (serviceLocator.isRegistered<FirebaseService>()) {
    await serviceLocator.reset();
  }

  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );

  final storageService = hardened
      ? SecureStorageService()
      : InsecureStorageService();
  await storageService.init();
  serviceLocator.registerSingleton<StorageService>(storageService);

  final securityService = hardened
      ? HardenedSecurityService()
      : BaselineSecurityService();
  serviceLocator.registerSingleton<SecurityService>(securityService);

  final firebaseService = FirebaseService(isHardened: hardened);
  await firebaseService.initialize();
  serviceLocator.registerSingleton<FirebaseService>(firebaseService);

  final apiService = ApiService(
    isHardened: hardened,
    storageService: storageService,
  );
  await apiService.initialize();
  serviceLocator.registerSingleton<ApiService>(apiService);
}
