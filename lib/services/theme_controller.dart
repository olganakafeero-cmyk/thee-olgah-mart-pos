import 'package:flutter/material.dart';
import '../database/db_helper.dart';

class ThemeController extends ChangeNotifier {
  ThemeController._();
  static final ThemeController instance = ThemeController._();

  static const Map<String, Color> colors = {
    'Green': Colors.green,
    'Blue': Colors.blue,
    'Purple': Colors.purple,
    'Orange': Colors.orange,
    'Red': Colors.red,
    'Teal': Colors.teal,
  };

  ThemeMode themeMode = ThemeMode.light;
  String colorName = 'Green';

  Color get seedColor => colors[colorName] ?? Colors.green;

  Future<void> load() async {
    final mode = await DbHelper.instance.getSetting('theme_mode');
    final color = await DbHelper.instance.getSetting('theme_color');
    themeMode = ThemeMode.values.firstWhere(
          (m) => m.name == mode,
      orElse: () => ThemeMode.light,
    );
    if (color != null && colors.containsKey(color)) {
      colorName = color;
    }
  }

  Future<void> setMode(ThemeMode mode) async {
    themeMode = mode;
    notifyListeners();
    await DbHelper.instance.setSetting('theme_mode', mode.name);
  }

  Future<void> setColor(String name) async {
    colorName = name;
    notifyListeners();
    await DbHelper.instance.setSetting('theme_color', name);
  }
}