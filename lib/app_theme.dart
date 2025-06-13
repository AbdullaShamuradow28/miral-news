import 'package:flutter/material.dart';

/// Класс, определяющий полный набор цветов для одной темы.
/// Это позволяет легко переключаться между светлой и темной темой,
/// используя один и тот же набор свойств.
class CustomAppTheme {
  final Color primaryBlue;
  final Color backgroundGrey;
  final Color textBlack;
  final Color textGrey;
  final Color dividerColor;
  final Color errorRed;
  final Color dialogBackground;
  final Color dialogTextMuted;
  final Color appBarBackground;
  final Color settingsBg;
  final Color inputCol;
  final Color
  whiteCol; // Этот цвет используется для контейнеров, которые обычно белые в светлой теме

  CustomAppTheme({
    required this.primaryBlue,
    required this.backgroundGrey,
    required this.inputCol,
    required this.textBlack,
    required this.textGrey,
    required this.dividerColor,
    required this.errorRed,
    required this.dialogBackground,
    required this.dialogTextMuted,
    required this.appBarBackground,
    required this.whiteCol,
    required this.settingsBg,
  });

  /// Статический экземпляр для светлой темы.
  static final CustomAppTheme lightThemeColors = CustomAppTheme(
    inputCol: Color(0xFFF4F4F4),
    primaryBlue: const Color(0xFF334EFF),
    backgroundGrey: Colors.white,
    textBlack: Colors.black,
    textGrey: const Color(0xFFA7A7A7),
    dividerColor: Colors.black12,
    errorRed: Colors.red,
    dialogBackground: Colors.white,
    dialogTextMuted: Colors.black54,
    appBarBackground: Colors.white,
    settingsBg: Color(0xFFF4F4F4),
    whiteCol: Colors.white, // В светлой теме "белый" цвет - это белый
  );

  /// Статический экземпляр для темной темы.
  /// Цвета адаптированы для лучшей читаемости в темном режиме.
  static final CustomAppTheme darkThemeColors = CustomAppTheme(
    primaryBlue: const Color(
      0xFF334EFF,
    ), // Основной синий может оставаться тем же
    backgroundGrey: const Color.fromARGB(255, 27, 27, 27), // Темный фон
    textBlack: Colors.white, // Текст становится белым
    textGrey: const Color(
      0xFFA7A7A7,
    ), // Серый текст может быть похожим или немного отличаться
    dividerColor: const Color.fromARGB(
      31,
      194,
      194,
      194,
    ), // Разделитель для темного фона
    errorRed: Colors.red, // Красный цвет ошибки обычно остается неизменным
    dialogBackground: const Color.fromARGB(
      255,
      60,
      60,
      60,
    ), // Темный фон диалогов
    dialogTextMuted: Colors.white70, // Приглушенный текст для темного режима
    appBarBackground: const Color.fromARGB(
      255,
      27,
      27,
      27,
    ), // Темный фон AppBar
    whiteCol: const Color.fromARGB(
      255,
      27,
      27,
      27,
    ), // В темной теме "белый" цвет - это черный (для элементов, которые были белыми в светлой теме)
    settingsBg: Color.fromARGB(255, 20, 20, 20),
    inputCol: Color.fromARGB(255, 34, 34, 34),
  );
}
