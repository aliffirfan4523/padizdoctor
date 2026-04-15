import 'package:flutter/material.dart';

class ToggleButtonsOption<T> {
  final ThemeMode theme;
  final Widget widget;

  const ToggleButtonsOption({required this.theme, required this.widget});
}

final List<ToggleButtonsOption> options = [
  ToggleButtonsOption<ThemeMode>(
    theme: ThemeMode.system,
    widget: const Icon(Icons.brightness_auto),
  ),
  ToggleButtonsOption<ThemeMode>(
    theme: ThemeMode.light,
    widget: const Icon(Icons.light_mode),
  ),
  ToggleButtonsOption<ThemeMode>(
    theme: ThemeMode.dark,
    widget: const Icon(Icons.dark_mode),
  ),
];
