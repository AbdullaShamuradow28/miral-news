import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart'; // Для ChangeNotifier
import 'package:shared_preferences/shared_preferences.dart';
import 'app_theme.dart'; // Импортируем новый файл с темами

/// Класс-ChangeNotifier для управления темой приложения.
/// Уведомляет слушателей при изменении темы.
class ThemeChanger with ChangeNotifier {
  static const String _themeKey =
      'isDarkMode'; // Ключ для сохранения состояния темы в SharedPreferences
  bool _isDarkMode = false; // Текущее состояние: темная тема включена?

  ThemeChanger() {
    _loadThemePreference(); // Загружаем предпочтения темы при инициализации
  }

  /// Геттер, возвращающий текущий набор цветов темы (светлый или темный).
  CustomAppTheme get currentColors =>
      _isDarkMode
          ? CustomAppTheme.darkThemeColors
          : CustomAppTheme.lightThemeColors;

  /// Геттер, возвращающий текущее состояние темной темы.
  bool get isDarkMode => _isDarkMode;

  /// Загружает предпочтение темы из SharedPreferences.
  /// Если предпочтение не найдено, по умолчанию устанавливается светлая тема.
  Future<void> _loadThemePreference() async {
    final prefs = await SharedPreferences.getInstance();
    _isDarkMode =
        prefs.getBool(_themeKey) ?? false; // По умолчанию светлая тема
    notifyListeners(); // Уведомляем слушателей после загрузки начальных предпочтений
  }

  /// Переключает тему и сохраняет предпочтение в SharedPreferences.
  void toggleTheme() async {
    _isDarkMode = !_isDarkMode; // Инвертируем состояние темы
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_themeKey, _isDarkMode); // Сохраняем новое состояние
    notifyListeners(); // Уведомляем слушателей об изменении
  }
}
