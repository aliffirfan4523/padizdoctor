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
  // Set up the SettingsController, which will glue user settings to multiple
  // Flutter Widgets.
  final settingsController = SettingsController(SettingsService());

  // Load the user's preferred theme while the splash screen is displayed.
  // This prevents a sudden theme change when the app is first displayed.
  await settingsController.loadSettings();

  // Run the app and pass in the SettingsController. The app listens to the
  // SettingsController for changes, then passes it further down to the
  // SettingsView.

  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );

  await AuthService.instance.initializeGoogleSignIn();

  // Initialize the camera
  final cameras = await availableCameras();
  GetIt.instance.registerSingleton<List<CameraDescription>>(cameras);

  runApp(
    MyApp(settingsController: settingsController),
  );
}
