import 'package:camera/camera.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';
import 'package:get_it/get_it.dart';
import 'package:padizdoctor/features/auth/services/auth_service.dart';

import 'firebase_options.dart';
import 'app.dart';
import 'features/settings/services/settings_controller.dart';
import 'features/settings/services/settings_service.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  final settingsController = SettingsController(SettingsService());

  await settingsController.loadSettings();

  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );

  await AuthService.instance.initializeGoogleSignIn();

  final cameras = await availableCameras();
  GetIt.instance.registerSingleton<List<CameraDescription>>(cameras);

  runApp(
    MyApp(settingsController: settingsController),
  );
}
