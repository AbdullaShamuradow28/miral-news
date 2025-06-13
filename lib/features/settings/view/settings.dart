import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_swipe_detector/flutter_swipe_detector.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:path/path.dart';
import 'package:provider/provider.dart'; // Импортируем provider
import 'package:shared_preferences/shared_preferences.dart';

// Убедитесь, что эти импорты верны в вашем проекте
import 'package:miral_news/app_theme.dart'; // Используем новый файл с темами
import 'package:miral_news/theme_changer.dart'; // Используем ThemeChanger
import 'package:miral_news/features/home_page/view/homepage.dart';
import 'package:miral_news/features/instructions_view/how_to_become_an_author.dart';
import 'package:miral_news/features/profile_notsigned/view/profile_message.dart';
import 'package:miral_news/features/account_login/view/account_login.dart';
import 'package:url_launcher/url_launcher.dart';

class SettingsScreen extends StatefulWidget {
  const SettingsScreen({super.key});

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  // Переменная 'switched' больше не нужна, так как состояние управляется ThemeChanger.
  String? username;
  String? about;
  String? imageBytes;
  String? mid;
  String? email;

  @override
  void initState() {
    super.initState();
    _loadProfileData(); // Загружаем данные профиля при инициализации экрана
  }

  /// Загружает данные профиля пользователя из SharedPreferences.
  Future<void> _loadProfileData() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    setState(() {
      username = prefs.getString('username');
      about = prefs.getString('about');
      imageBytes = prefs.getString('imageBytes');
      mid = prefs.getString('mid');
      email = prefs.getString('email');
    });
    print('Checking profile data...');
    print('Username: ${prefs.getString('username')}');
    print('About: ${prefs.getString('about')}');
    print('ImageBytes: ${prefs.getString('imageBytes')}');
    print('Mid: ${prefs.getString('mid')}');
    print('Email: ${prefs.getString('email')}');
    bool exists =
        prefs.containsKey('username') &&
        prefs.containsKey('about') &&
        prefs.containsKey('imageBytes') &&
        prefs.containsKey('mid') &&
        prefs.containsKey('email');
    print('Profile data exists: $exists');
  }

  @override
  Widget build(BuildContext context) {
    // Получаем экземпляр ThemeChanger и текущие цвета темы.
    // Provider.of<ThemeChanger>(context) без listen: false будет перестраивать виджет при изменении темы.
    final themeChanger = Provider.of<ThemeChanger>(context);
    final currentColors = themeChanger.currentColors;

    return Scaffold(
      appBar: AppBar(
        toolbarHeight: 150,
        backgroundColor:
            currentColors.appBarBackground, // Используем цвет из текущей темы
        automaticallyImplyLeading: false,
        bottom: PreferredSize(
          preferredSize: Size.fromHeight(0),
          child: Container(
            padding: EdgeInsets.only(bottom: 16),
            margin: EdgeInsets.only(left: 20),
            child: Row(
              mainAxisAlignment:
                  MainAxisAlignment.start, // Выравнивание по левому краю
              children: [
                Text(
                  "Настройки",
                  style: GoogleFonts.geologica(
                    color:
                        currentColors
                            .textBlack, // Используем цвет текста из текущей темы
                    fontSize: 36,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
      backgroundColor:
          currentColors.settingsBg, // Используем цвет фона из текущей темы
      body: SwipeDetector(
        onSwipeRight: (offset) => Navigator.pop(context),
        child: ListView(
          children: [
            SizedBox(height: 20),
            Container(
              width: MediaQuery.of(context).size.width,
              padding: EdgeInsets.all(20),
              color: currentColors.whiteCol, // Используем цвет из текущей темы
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    "Оформление",
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 16,
                      color: currentColors.textBlack,
                    ), // Используем цвет текста из текущей темы
                  ),
                  SizedBox(height: 12),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        "Темная тема",
                        style: TextStyle(
                          fontSize: 16,
                          color: currentColors.textBlack,
                        ),
                      ), // Используем цвет текста из текущей темы
                      CupertinoSwitch(
                        activeTrackColor:
                            currentColors
                                .primaryBlue, // Используем цвет из текущей темы
                        onChanged: (value) {
                          themeChanger
                              .toggleTheme(); // Переключаем тему через ThemeChanger
                          print("Switched to dark: ${themeChanger.isDarkMode}");
                        },
                        value:
                            themeChanger
                                .isDarkMode, // Используем состояние из ThemeChanger
                      ),
                    ],
                  ),
                ],
              ),
            ),
            SizedBox(height: 20),
            Container(
              width: MediaQuery.of(context).size.width,
              padding: EdgeInsets.all(20),
              color: currentColors.whiteCol, // Используем цвет из текущей темы
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    "Для авторов",
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 16,
                      color: currentColors.textBlack,
                    ), // Используем цвет текста из текущей темы
                  ),
                  SizedBox(height: 20),
                  GestureDetector(
                    onTap: () {
                      // Мы будем перекидывать в бота предложку (ТГ БОТ Miral News | Предложить идею)
                      showModalBottomSheet(
                        context: context,
                        builder:
                            (context) => Container(
                              padding: EdgeInsets.all(20),
                              height: 210,
                              decoration: BoxDecoration(
                                color: currentColors.dialogBackground,
                                borderRadius: BorderRadius.only(
                                  topLeft: Radius.circular(20),
                                  topRight: Radius.circular(20),
                                ),
                              ), // Используем цвет фона диалога из текущей темы
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    "Переход в Telegram",
                                    style: GoogleFonts.geologica(
                                      fontSize: 20,
                                      color: currentColors.textBlack,
                                    ), // Используем цвет текста из текущей темы
                                  ),
                                  SizedBox(height: 10),
                                  Text(
                                    "Данная ссылка переведет вас в бота, где вы можете предложить идею или сообщить об ошибке",
                                    style: GoogleFonts.geologica(
                                      fontSize: 14,
                                      color:
                                          currentColors
                                              .dialogTextMuted, // Используем приглушенный цвет текста из текущей темы
                                    ),
                                  ),
                                  SizedBox(height: 10),
                                  Container(
                                    child: GestureDetector(
                                      onTap: () {
                                        launchUrl(
                                          Uri.parse(
                                            "https://t.me/MiralNewsBot",
                                          ),
                                        );
                                      },
                                      child: Container(
                                        padding: EdgeInsets.only(
                                          left: 15,
                                          right: 15,
                                          top: 5,
                                          bottom: 5,
                                        ),
                                        width:
                                            MediaQuery.of(context).size.width,
                                        height: 50,
                                        decoration: BoxDecoration(
                                          borderRadius: BorderRadius.all(
                                            Radius.circular(20000),
                                          ),
                                          color:
                                              currentColors
                                                  .primaryBlue, // Используем основной синий цвет из текущей темы
                                        ),
                                        child: Center(
                                          child: Text(
                                            "Перейти в Telegram",
                                            style: GoogleFonts.geologica(
                                              color:
                                                  (currentColors.settingsBg ==
                                                          Color.fromARGB(
                                                            255,
                                                            20,
                                                            20,
                                                            20,
                                                          ))
                                                      ? currentColors.textBlack
                                                      : currentColors
                                                          .whiteCol, // Используем цвет текста из текущей темы (белый в светлой, черный в темной)
                                              fontSize: 16,
                                            ),
                                          ),
                                        ),
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                      );
                    },
                    child: Row(
                      children: [
                        Icon(
                          Icons.lightbulb_outline,
                          color: currentColors.textBlack,
                        ), // Используем цвет иконки из текущей темы
                        SizedBox(width: 10),
                        Text(
                          "Предложить идею",
                          style: TextStyle(
                            fontSize: 16,
                            color: currentColors.textBlack,
                          ),
                        ), // Используем цвет текста из текущей темы
                      ],
                    ),
                  ),
                  SizedBox(height: 10),
                  // Divider(
                  //   color: currentColors.dividerColor,
                  //   height: 5,
                  // ), // Используем
                  // GestureDetector(
                  //   onTap: () {
                  //     Navigator.of(context).push(
                  //       MaterialPageRoute(
                  //         builder: (context) => AuthorInstructions(),
                  //       ),
                  //     );
                  //   },
                  //   child: Row(
                  //     children: [
                  //       Icon(
                  //         Icons.question_mark_outlined,
                  //         color: currentColors.textBlack,
                  //       ), // Используем цвет иконки из текущей темы
                  //       SizedBox(width: 10),
                  //       Text(
                  //         "Как стать автором?",
                  //         style: TextStyle(
                  //           fontSize: 16,
                  //           color: currentColors.textBlack,
                  //         ), // Используем цвет текста из текущей темы
                  //       ),
                  //     ],
                  //   ),
                  // ),
                ],
              ),
            ),
            SizedBox(height: 20),
            Container(
              width: MediaQuery.of(context).size.width,
              padding: EdgeInsets.all(20),
              color: currentColors.whiteCol, // Используем цвет из текущей темы
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    "Поиск",
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 16,
                      color: currentColors.textBlack,
                    ), // Используем цвет текста из текущей темы
                  ),
                  SizedBox(height: 20),
                  GestureDetector(
                    onTap: () async {
                      final sp = await SharedPreferences.getInstance();
                      sp.remove("searchHistory");
                      showDialog(
                        context: context,
                        builder:
                            (context) => AlertDialog(
                              shape: const RoundedRectangleBorder(
                                borderRadius: BorderRadius.all(
                                  Radius.circular(24),
                                ),
                              ),
                              backgroundColor:
                                  currentColors
                                      .dialogBackground, // Используем цвет фона диалога из текущей темы
                              title: Text(
                                "Готово!",
                                style: GoogleFonts.geologica(
                                  fontSize: 20,
                                  fontWeight: FontWeight.bold,
                                  color:
                                      currentColors
                                          .textBlack, // Используем цвет текста из текущей темы
                                ),
                              ),
                              content: Text(
                                "История поиска удалена",
                                style: GoogleFonts.geologica(
                                  fontSize: 16,
                                  color:
                                      currentColors
                                          .dialogTextMuted, // Используем приглушенный цвет текста из текущей темы
                                ),
                              ),
                              actions: [
                                GestureDetector(
                                  onTap: () async {
                                    Navigator.pop(context);
                                  },
                                  child: Text(
                                    "Ок",
                                    style: GoogleFonts.geologica(
                                      fontSize: 16,
                                      color:
                                          currentColors
                                              .primaryBlue, // Используем основной синий цвет из текущей темы
                                    ),
                                  ),
                                ),
                              ],
                            ),
                      );
                    },
                    child: Row(
                      children: [
                        Icon(
                          Icons.delete_forever,
                          color: currentColors.errorRed,
                        ), // Используем цвет ошибки из текущей темы
                        SizedBox(width: 10),
                        Text(
                          "Очистить историю поиска",
                          style: TextStyle(
                            fontSize: 16,
                            color: currentColors.errorRed,
                          ), // Используем цвет ошибки из текущей темы
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            SizedBox(height: 20),
            Container(
              width: MediaQuery.of(context).size.width,
              padding: EdgeInsets.all(20),
              color: currentColors.whiteCol, // Используем цвет из текущей темы
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    "Аккаунт",
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 16,
                      color: currentColors.textBlack,
                    ), // Используем цвет текста из текущей темы
                  ),
                  SizedBox(height: 20),
                  // Проверяем mid на пустую строку или null
                  mid == "" || mid == null
                      ? GestureDetector(
                        onTap: () {
                          Navigator.of(context).push(
                            MaterialPageRoute(
                              builder: (context) => AccountLogin(),
                            ),
                          );
                        },
                        child: Row(
                          children: [
                            Icon(
                              Icons.door_sliding_outlined,
                              color: currentColors.textBlack,
                            ), // Используем цвет иконки из текущей темы
                            SizedBox(width: 10),
                            Text(
                              "Войти",
                              style: TextStyle(
                                fontSize: 16,
                                color: currentColors.textBlack,
                              ),
                            ), // Используем цвет текста из текущей темы
                          ],
                        ),
                      )
                      : GestureDetector(
                        onTap: () async {
                          final sp = await SharedPreferences.getInstance();
                          sp.remove("mid");
                          sp.remove("username");
                          sp.remove("about");
                          sp.remove("imageBytes");
                          sp.remove("email"); // Также удаляем email
                          setState(() {
                            mid = null; // Обновляем локальное состояние
                          });
                          showDialog(
                            context: context,
                            builder:
                                (context) => AlertDialog(
                                  shape: const RoundedRectangleBorder(
                                    borderRadius: BorderRadius.all(
                                      Radius.circular(24),
                                    ),
                                  ),
                                  backgroundColor:
                                      currentColors
                                          .dialogBackground, // Используем цвет фона диалога из текущей темы
                                  title: Text(
                                    "Готово!",
                                    style: GoogleFonts.geologica(
                                      fontSize: 20,
                                      fontWeight: FontWeight.bold,
                                      color:
                                          currentColors
                                              .textBlack, // Используем цвет текста из текущей темы
                                    ),
                                  ),
                                  content: Text(
                                    "Теперь вам придется заново войти или остаться в гостевом режиме",
                                    style: GoogleFonts.geologica(
                                      fontSize: 16,
                                      color:
                                          currentColors
                                              .dialogTextMuted, // Используем приглушенный цвет текста из текущей темы
                                    ),
                                  ),
                                  actions: [
                                    GestureDetector(
                                      onTap: () async {
                                        Navigator.pop(context);
                                        Navigator.push(
                                          context,
                                          MaterialPageRoute(
                                            builder: (context) => HomePage(),
                                          ),
                                        );
                                      },
                                      child: Text(
                                        "Ок",
                                        style: GoogleFonts.geologica(
                                          fontSize: 16,
                                          color:
                                              currentColors
                                                  .primaryBlue, // Используем основной синий цвет из текущей темы
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                          );
                        },
                        child: Row(
                          children: [
                            Icon(
                              Icons.door_sliding_outlined,
                              color: currentColors.errorRed,
                            ), // Используем цвет ошибки из текущей темы
                            SizedBox(width: 10),
                            Text(
                              "Выйти",
                              style: TextStyle(
                                fontSize: 16,
                                color: currentColors.errorRed,
                              ), // Используем цвет ошибки из текущей темы
                            ),
                          ],
                        ),
                      ),
                ],
              ),
            ),
          ],
        ),
      ),
      bottomNavigationBar: Container(
        width: MediaQuery.of(context).size.width,
        height: 80,
        color:
            (currentColors.backgroundGrey == Color(0xFFF4F4F4))
                ? Color(0xFFFFFFFF)
                : currentColors
                    .settingsBg, // Используем цвет для нижней навигации из текущей темы
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceEvenly,
          children: [
            GestureDetector(
              onTap: () {
                Navigator.of(
                  context,
                ).push(MaterialPageRoute(builder: (context) => HomePage()));
              },
              child: Icon(
                Icons.home,
                size: 35,
                color: currentColors.textGrey,
              ), // Используем цвет иконки из текущей темы
            ),
            Container(
              margin: EdgeInsets.only(bottom: 10),
              child: FloatingActionButton(
                onPressed: () async {
                  showModalBottomSheet(
                    context: context,
                    builder:
                        (context) => Container(
                          decoration: BoxDecoration(
                            color: currentColors.dialogBackground,
                            borderRadius: BorderRadius.only(
                              topLeft: Radius.circular(20),
                              topRight: Radius.circular(20),
                            ),
                          ),
                          padding: EdgeInsets.all(20),
                          height:
                              210, // Используем цвет фона диалога из текущей темы
                          child: Column(
                            children: [
                              Text(
                                "Упс, похоже кто-то хочет создать статью без входа в систему!",
                                style: GoogleFonts.geologica(
                                  fontSize: 20,
                                  color: currentColors.textBlack,
                                ), // Используем цвет текста из текущей темы
                              ),
                              SizedBox(height: 10),
                              Text(
                                "Но так нельзя! Для того, чтобы написать статью, необходимо войти в Miral Account!",
                                style: GoogleFonts.geologica(
                                  fontSize: 14,
                                  color:
                                      currentColors
                                          .dialogTextMuted, // Используем приглушенный цвет текста из текущей темы
                                ),
                              ),
                              SizedBox(height: 10),
                              Container(
                                child: GestureDetector(
                                  onTap: () {
                                    Navigator.of(context).push(
                                      MaterialPageRoute(
                                        builder: (context) => AccountLogin(),
                                      ),
                                    );
                                  },
                                  child: Container(
                                    padding: EdgeInsets.only(
                                      left: 15,
                                      right: 15,
                                      top: 5,
                                      bottom: 5,
                                    ),
                                    width: MediaQuery.of(context).size.width,
                                    height: 50,
                                    decoration: BoxDecoration(
                                      borderRadius: BorderRadius.all(
                                        Radius.circular(20000),
                                      ),
                                      color: currentColors.primaryBlue,
                                    ),
                                    child: Center(
                                      child: Text(
                                        "Войти в Miral Account",
                                        style: GoogleFonts.geologica(
                                          color:
                                              currentColors
                                                  .whiteCol, // Используем цвет текста из текущей темы
                                          fontSize: 16,
                                        ),
                                      ),
                                    ),
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                  );
                },
                splashColor: Colors.transparent,
                backgroundColor:
                    currentColors
                        .primaryBlue, // Используем основной синий цвет из текущей темы
                child: Icon(
                  Icons.add,
                  size: 30,
                  color: Colors.white,
                ), // Используем цвет иконки из текущей темы
              ),
              width: 50,
              height: 50,
            ),
            GestureDetector(
              onTap: () {
                Navigator.of(context).push(
                  MaterialPageRoute(builder: (context) => ProfileMessage()),
                );
              },
              child: Icon(
                Icons.person,
                size: 35,
                color: currentColors.primaryBlue,
              ), // Используем основной синий цвет из текущей темы
            ),
          ],
        ),
      ),
    );
  }
}
