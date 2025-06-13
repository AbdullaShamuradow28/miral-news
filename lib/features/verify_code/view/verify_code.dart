import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:http/http.dart' as http; // Import for making HTTP requests
import 'dart:async';
import 'dart:convert'; // Import for JSON encoding/decoding
import 'package:pinput/pinput.dart'; // For the OTP input field
import 'package:shared_preferences/shared_preferences.dart'; // For local data storage

// Assuming these paths are correct for your project structure
import 'package:miral_news/features/home_page/view/homepage.dart';
import 'package:miral_news/features/profile_edit/view/profile_edit.dart';

class VerifyCode extends StatefulWidget {
  const VerifyCode({super.key});

  @override
  State<VerifyCode> createState() => _VerifyCodeState();
}

class _VerifyCodeState extends State<VerifyCode> {
  int _start = 60; // Начальное значение для таймера обратного отсчета
  Timer? _timer; // Объект таймера
  bool _timerRunning = true; // Флаг для отслеживания состояния таймера

  // Функция для запуска или перезапуска таймера обратного отсчета
  void startTimer() {
    setState(() {
      _start = 60; // Сброс таймера до 60 секунд
      _timerRunning = true; // Установка состояния таймера на "работает"
    });
    // Создание периодического таймера, который срабатывает каждую секунду
    _timer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (_start == 0) {
        // Если отсчет достигает 0, отменить таймер
        setState(() {
          timer.cancel();
          _timerRunning = false; // Установка состояния таймера на "остановлен"
        });
      } else {
        // Уменьшение значения отсчета
        setState(() {
          _start--;
        });
      }
    });
  }

  @override
  void initState() {
    super.initState();
    startTimer(); // Запуск таймера при инициализации виджета
  }

  // Асинхронная функция для проверки существования данных профиля пользователя через API
  Future<bool> _checkProfileDataExists() async {
    SharedPreferences prefs =
        await SharedPreferences.getInstance(); // Получение экземпляра SharedPreferences
    final String? userMid = prefs.getString(
      'mid',
    ); // Получение mid пользователя из SharedPreferences

    if (userMid == null || userMid.isEmpty) {
      print(
        'User MID not found in SharedPreferences. Cannot check API.',
      ); // Отладочный вывод
      return false; // Невозможно продолжить без MID пользователя
    }

    print(
      'Checking profile data from API for MID: $userMid',
    ); // Отладочный вывод

    try {
      // Выполнение HTTP GET запроса к API
      // Обновлен URL API, чтобы соответствовать предоставленному примеру (добавлен порт 3001)
      final response = await http.get(
        Uri.parse('http://192.168.1.109:3001/api/users'),
      );

      if (response.statusCode == 200) {
        // Если запрос успешен, декодировать JSON-ответ
        final List<dynamic> profiles = json.decode(response.body);
        bool profileFound = false;

        // Итерация по списку профилей для поиска совпадения по mid
        for (var profile in profiles) {
          if (profile is Map<String, dynamic> && profile['mid'] == userMid) {
            // Профиль найден, сохранить его данные в SharedPreferences
            // Сохраняем nickname как username, если он есть, иначе first_name
            await prefs.setString(
              'username',
              profile['nickname'] ?? profile['first_name'] ?? '',
            );
            await prefs.setString(
              'about',
              profile['about_me'] ?? '',
            ); // Сохраняем about_me как about
            await prefs.setString(
              'imageBytes',
              profile['profile_picture_url'] ??
                  '', // Сохраняем profile_picture_url как imageBytes
            );
            // Поле email не было в предоставленном примере API, но сохраняем его, если оно появится
            // 'mid' уже находится в prefs, нет необходимости устанавливать его снова, если только его не нужно обновить из API.

            print(
              'Profile found in API for MID: $userMid. Data saved to SharedPreferences.',
            ); // Отладочный вывод
            profileFound = true;
            break; // Выход из цикла после нахождения профиля
          }
        }
        return profileFound; // Возвращает true, если профиль найден, false в противном случае
      } else {
        print(
          'Failed to load profiles from API. Status code: ${response.statusCode}',
        ); // Отладочный вывод
        return false; // Возвращает false при ошибке загрузки профилей
      }
    } catch (e) {
      print(
        'Error fetching profiles from API: $e',
      ); // Обработка ошибок сети или парсинга JSON
      return false; // Возвращает false при возникновении исключения
    }
  }

  @override
  void dispose() {
    _timer
        ?.cancel(); // Отмена таймера при удалении виджета, чтобы предотвратить утечки памяти
    super.dispose();
  }

  // Асинхронная функция для проверки введенного PIN-кода
  Future<void> _verifyCode(String pin) async {
    // Жестко закодированный PIN-код для демонстрации. В реальном приложении это будет проверяться на бэкэнде.
    if (pin != "3030") {
      // Показать сообщение об ошибке, если PIN-код неверен
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text("Неверный код! Пожалуйста, повторите попытку!"),
        ),
      );
      return; // Прекратить выполнение, если PIN-код неверен
    }

    // Проверить, существует ли профиль после успешного ввода PIN-кода
    bool profileExists = await _checkProfileDataExists();
    if (profileExists) {
      // Если профиль существует, перейти на HomePage и заменить текущий маршрут
      Navigator.of(context).pushReplacement(
        MaterialPageRoute(builder: (context) => const HomePage()),
      );
    } else {
      // Если профиль не существует, перейти на ProfileEdit и заменить текущий маршрут
      Navigator.of(context).pushReplacement(
        MaterialPageRoute(builder: (context) => const ProfileEdit()),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        toolbarHeight: 150, // Высота AppBar
        automaticallyImplyLeading:
            false, // Не добавлять автоматически кнопку "назад"
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(
            0,
          ), // Нет дополнительной высоты для нижнего виджета
          child: Container(
            padding: const EdgeInsets.only(bottom: 16), // Отступ снизу
            margin: const EdgeInsets.only(left: 20), // Отступ слева
            child: Row(
              mainAxisAlignment:
                  MainAxisAlignment
                      .start, // Выравнивание содержимого по левому краю
              children: [
                GestureDetector(
                  child: const Icon(
                    Icons.arrow_back_ios_new, // Иконка стрелки назад
                    size: 35, // Размер иконки
                    color: Colors.black, // Цвет иконки
                  ),
                  onTap: () {
                    Navigator.pop(
                      context,
                    ); // Выход из текущего маршрута при нажатии
                  },
                ),
              ],
            ),
          ),
        ),
      ),
      body: SingleChildScrollView(
        // Позволяет содержимому прокручиваться, если оно переполняется
        child: Padding(
          padding: const EdgeInsets.all(20), // Отступ вокруг содержимого
          child: Column(
            crossAxisAlignment:
                CrossAxisAlignment
                    .start, // Выравнивание дочерних элементов по началу (слева)
            children: [
              Text(
                "Введите 4-значный код", // Текст заголовка
                style: GoogleFonts.geologica(
                  // Пользовательский шрифт
                  fontSize: 32,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 10), // Разделитель
              Text(
                "Ваш код был отправлен на почту!", // Текст подзаголовка
                style: GoogleFonts.geologica(fontSize: 20),
              ),
              const SizedBox(height: 36), // Разделитель
              // Поле ввода OTP с использованием Pinput
              Center(
                child: Pinput(
                  length: 4, // 4-значный OTP
                  defaultPinTheme: PinTheme(
                    width: 90,
                    height: 90,
                    textStyle: GoogleFonts.geologica(
                      fontSize: 50,
                      color: const Color(0xFF333337),
                      fontWeight: FontWeight.w900,
                    ),
                    decoration: BoxDecoration(
                      color: const Color(0xFFF4F4F4),
                      borderRadius: BorderRadius.circular(10),
                    ),
                  ),
                  onChanged: (pin) {
                    print(
                      "PIN changed: $pin",
                    ); // Обратный вызов при изменении PIN-кода
                  },
                  onCompleted: (pin) {
                    print(
                      "Entered PIN: $pin",
                    ); // Обратный вызов при полном вводе PIN-кода
                    _verifyCode(pin); // Вызов функции проверки
                  },
                  errorTextStyle: const TextStyle(
                    color: Colors.red,
                    fontSize: 15,
                  ), // Стиль для текста ошибки
                ),
              ),
              const SizedBox(height: 24), // Разделитель
              Text(
                "Повторно отправить код: $_start сек", // Текст отображения таймера
                style: GoogleFonts.geologica(
                  fontSize: 16,
                  color: const Color(0xFFA7A7A7),
                ),
              ),
              const SizedBox(height: 12), // Разделитель
              // Отображение опции "Запросить еще раз" только если таймер остановлен
              if (!_timerRunning)
                Row(
                  children: [
                    Text(
                      "Не получили код?", // Текст подсказки
                      style: GoogleFonts.geologica(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                        color: const Color(0xFF000000),
                      ),
                    ),
                    const SizedBox(width: 10), // Разделитель
                    GestureDetector(
                      onTap: startTimer, // Нажатие для перезапуска таймера
                      child: Text(
                        "Запросите еще раз", // Текст для повторной отправки
                        style: GoogleFonts.geologica(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                          color: const Color(
                            0xFF334EFF,
                          ), // Синий цвет для ссылки повторной отправки
                        ),
                      ),
                    ),
                  ],
                ),
            ],
          ),
        ),
      ),
    );
  }
}
