import 'package:flutter/material.dart';
import 'package:provider/provider.dart'; // Добавьте в pubspec.yaml: provider: ^6.0.0 (или актуальную версию)
import 'package:flutter_bloc/flutter_bloc.dart'; // Для BlocProvider
import 'package:google_fonts/google_fonts.dart'; // Для Google Fonts

// Убедитесь, что эти импорты верны в вашем проекте
import 'package:miral_news/app_theme.dart'; // Импортируем новый файл с темами
import 'package:miral_news/theme_changer.dart'; // Импортируем ThemeChanger
import 'package:miral_news/features/home_page/bloc/news_bloc.dart'; // Ваш Bloc
import 'package:miral_news/features/home_page/view/homepage.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  runApp(
    // Оборачиваем все приложение в ChangeNotifierProvider,
    // чтобы ThemeChanger был доступен всем виджетам.
    ChangeNotifierProvider(create: (context) => ThemeChanger(), child: MyApp()),
  );
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    // Слушаем ThemeChanger, чтобы перестроить MaterialApp при изменении темы.
    final themeChanger = context.watch<ThemeChanger>();

    // Определяем ThemeData для светлой темы, используя CustomAppTheme.
    final lightThemeData = ThemeData(
      brightness: Brightness.light,
      primaryColor: CustomAppTheme.lightThemeColors.primaryBlue,
      scaffoldBackgroundColor: CustomAppTheme.lightThemeColors.backgroundGrey,
      appBarTheme: AppBarTheme(
        backgroundColor: CustomAppTheme.lightThemeColors.appBarBackground,
        foregroundColor:
            CustomAppTheme
                .lightThemeColors
                .textBlack, // Цвет текста заголовка AppBar
        titleTextStyle: GoogleFonts.geologica(
          color: CustomAppTheme.lightThemeColors.textBlack,
          fontSize: 20,
          fontWeight: FontWeight.bold,
        ),
      ),
      textTheme: TextTheme(
        bodyLarge: GoogleFonts.geologica(
          color: CustomAppTheme.lightThemeColors.textBlack,
        ),
        bodyMedium: GoogleFonts.geologica(
          color: CustomAppTheme.lightThemeColors.textBlack,
        ),
        // Добавьте другие стили текста по мере необходимости
      ),
      dividerColor: CustomAppTheme.lightThemeColors.dividerColor,
      dialogBackgroundColor: CustomAppTheme.lightThemeColors.dialogBackground,
      // Добавьте другие свойства темы по мере необходимости
      // Например, для ElevatedButton
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor:
              CustomAppTheme.lightThemeColors.primaryBlue, // Цвет кнопки
          foregroundColor:
              CustomAppTheme.lightThemeColors.whiteCol, // Цвет текста на кнопке
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(20000), // Закругленные углы
          ),
        ),
      ),
      floatingActionButtonTheme: FloatingActionButtonThemeData(
        backgroundColor: CustomAppTheme.lightThemeColors.primaryBlue,
        foregroundColor: CustomAppTheme.lightThemeColors.whiteCol,
      ),
      bottomNavigationBarTheme: BottomNavigationBarThemeData(
        backgroundColor: CustomAppTheme.lightThemeColors.whiteCol,
        selectedItemColor: CustomAppTheme.lightThemeColors.primaryBlue,
        unselectedItemColor: CustomAppTheme.lightThemeColors.textGrey,
      ),
    );

    // Определяем ThemeData для темной темы, используя CustomAppTheme.
    final darkThemeData = ThemeData(
      brightness: Brightness.dark,
      primaryColor: CustomAppTheme.darkThemeColors.primaryBlue,
      scaffoldBackgroundColor: CustomAppTheme.darkThemeColors.backgroundGrey,
      appBarTheme: AppBarTheme(
        backgroundColor: CustomAppTheme.darkThemeColors.appBarBackground,
        foregroundColor:
            CustomAppTheme
                .darkThemeColors
                .textBlack, // Цвет текста заголовка AppBar
        titleTextStyle: GoogleFonts.geologica(
          color: CustomAppTheme.darkThemeColors.textBlack,
          fontSize: 20,
          fontWeight: FontWeight.bold,
        ),
      ),
      textTheme: TextTheme(
        bodyLarge: GoogleFonts.geologica(
          color: CustomAppTheme.darkThemeColors.textBlack,
        ),
        bodyMedium: GoogleFonts.geologica(
          color: CustomAppTheme.darkThemeColors.textBlack,
        ),
        // Добавьте другие стили текста по мере необходимости
      ),
      dividerColor: CustomAppTheme.darkThemeColors.dividerColor,
      dialogBackgroundColor: CustomAppTheme.darkThemeColors.dialogBackground,
      // Добавьте другие свойства темы по мере необходимости
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: CustomAppTheme.darkThemeColors.primaryBlue,
          foregroundColor: CustomAppTheme.darkThemeColors.whiteCol,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(20000),
          ),
        ),
      ),
      floatingActionButtonTheme: FloatingActionButtonThemeData(
        backgroundColor: CustomAppTheme.darkThemeColors.primaryBlue,
        foregroundColor: CustomAppTheme.darkThemeColors.whiteCol,
      ),
      bottomNavigationBarTheme: BottomNavigationBarThemeData(
        backgroundColor:
            CustomAppTheme
                .darkThemeColors
                .appBarBackground, // Используем AppBarBackground для нижней навигации
        selectedItemColor: CustomAppTheme.darkThemeColors.primaryBlue,
        unselectedItemColor: CustomAppTheme.darkThemeColors.textGrey,
      ),
    );

    return BlocProvider(
      create: (context) => ArticleBloc()..add(LoadArticles()),
      child: MaterialApp(
        title: 'Miral News', // Обновлен заголовок
        debugShowCheckedModeBanner: false,
        theme: lightThemeData, // Тема по умолчанию (светлая)
        darkTheme: darkThemeData, // Темная тема
        // Управляем режимом темы на основе состояния ThemeChanger
        themeMode: themeChanger.isDarkMode ? ThemeMode.dark : ThemeMode.light,
        home: HomePage(), // Ваш начальный домашний экран
      ),
    );
  }
}
