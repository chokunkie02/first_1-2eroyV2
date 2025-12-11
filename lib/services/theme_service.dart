import 'package:flutter/material.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'database_service.dart';

class ThemeService extends ChangeNotifier {
  static final ThemeService _instance = ThemeService._internal();
  factory ThemeService() => _instance;
  ThemeService._internal();

  static const String _themeModeKey = 'theme_mode_index'; // 0: System, 1: Light, 2: Dark
  static const String _themeColorKey = 'theme_color_index';
  static const String _pastelModeKey = 'pastel_mode';

  // Color palettes
  static const List<Color> _vibrantPalette = [
    Colors.blue,
    Colors.purple,
    Colors.pink,
    Colors.red,
    Colors.orange,
    Colors.green,
    Colors.teal,
    Colors.indigo,
  ];

  static const List<Color> _pastelPalette = [
    Color(0xFFB3D9FF), // Pastel blue
    Color(0xFFE6CCFF), // Pastel purple
    Color(0xFFFFCCE5), // Pastel pink
    Color(0xFFFFCCCC), // Pastel red
    Color(0xFFFFE5CC), // Pastel orange
    Color(0xFFCCFFCC), // Pastel green
    Color(0xFFCCFFFF), // Pastel teal
    Color(0xFFCCCCFF), // Pastel indigo
  ];

  // State
  ThemeMode _currentThemeMode = ThemeMode.system;
  int _currentThemeColorIndex = 0;
  bool _isPastelMode = false;

  // Getters
  ThemeMode get currentThemeMode => _currentThemeMode;
  ThemeMode get themeMode => _currentThemeMode; // Alias for compatibility
  int get currentThemeColorIndex => _currentThemeColorIndex;
  bool get isPastelMode => _isPastelMode;
  List<Color> get currentPalette => _isPastelMode ? _pastelPalette : _vibrantPalette;

  Future<void> loadSettings() async {
    final box = DatabaseService().settingsBox;
    final modeIndex = box.get(_themeModeKey, defaultValue: 0);
    _currentThemeMode = _indexToThemeMode(modeIndex);
    _currentThemeColorIndex = box.get(_themeColorKey, defaultValue: 0);
    _isPastelMode = box.get(_pastelModeKey, defaultValue: false);
    notifyListeners();
  }

  Future<void> setThemeMode(ThemeMode mode) async {
    _currentThemeMode = mode;
    notifyListeners();
    await DatabaseService().settingsBox.put(_themeModeKey, _themeModeToIndex(mode));
  }

  Future<void> setThemeColor(int index) async {
    if (index < 0 || index >= currentPalette.length) return;
    _currentThemeColorIndex = index;
    notifyListeners();
    await DatabaseService().settingsBox.put(_themeColorKey, index);
  }

  Future<void> setPastelMode(bool enabled) async {
    _isPastelMode = enabled;
    notifyListeners();
    await DatabaseService().settingsBox.put(_pastelModeKey, enabled);
  }

  ThemeMode _indexToThemeMode(int index) {
    switch (index) {
      case 1: return ThemeMode.light;
      case 2: return ThemeMode.dark;
      default: return ThemeMode.system;
    }
  }

  int _themeModeToIndex(ThemeMode mode) {
    switch (mode) {
      case ThemeMode.light: return 1;
      case ThemeMode.dark: return 2;
      default: return 0;
    }
  }
}
