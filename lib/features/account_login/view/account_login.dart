// ========================= AccountLogin.dart =========================

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:miral_news/features/account_create/view/account_signup.dart';
import 'package:miral_news/features/verify_code/view/verify_code.dart'; // Assuming this is your main app page
import 'package:http/http.dart' as http;
import 'package:miral_news/theme_changer.dart';
import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:miral_news/features/profile_edit/view/profile_edit.dart'; // Import ProfileEdit
import 'package:miral_news/features/home_page/view/homepage.dart'; // Import HomePage

class AccountLogin extends StatefulWidget {
  const AccountLogin({super.key});

  @override
  State<AccountLogin> createState() => _AccountLoginState();
}

class _AccountLoginState extends State<AccountLogin> {
  String apiUrl = "http://192.168.1.109:3001/api/users/";
  String profileApiUrl =
      "http://192.168.1.109:3001/api/profiles/get_by_mid/"; // New: Profile API URL
  var emailController = TextEditingController();
  var passwordController = TextEditingController();
  String errorMessage = '';

  void logIn() async {
    setState(() {
      errorMessage = '';
    });
    try {
      final response = await http.get(
        // IMPORTANT: For a real login, you should use POST with email/password in body
        // This current GET request to /api/users/ fetches ALL users, which is not secure for login.
        // Assuming this is for demonstration or development purposes.
        // A proper login would look like: http.post(Uri.parse('$apiUrl/login'), body: jsonEncode({'email': emailController.text, 'password': passwordController.text}))
        Uri.parse(apiUrl), // Currently fetches all users
        headers: <String, String>{
          'Content-Type': 'application/json; charset=UTF-8',
        },
      );

      print('Response body: ${response.body}'); // Проверяем, что вернул сервер

      if (response.statusCode == 200) {
        final List<dynamic> dataList = jsonDecode(response.body);

        if (dataList.isEmpty) {
          throw Exception('Сервер вернул пустой список пользователей');
        }

        // Find the user with matching email and password (simulated login)
        // In a real app, the backend would handle authentication and return the specific user.
        final Map<String, dynamic>? foundUser = dataList.firstWhere(
          (user) =>
              user['email'] == emailController.text &&
              user['password'] == passwordController.text,
          orElse: () => null, // Return null if no user is found
        );

        if (foundUser == null) {
          setState(() {
            errorMessage = 'Неверный email или пароль.';
          });
          return;
        }

        final String mid =
            foundUser['mid'].toString(); // Принудительно в строку
        final String email = foundUser['email'] ?? '';

        SharedPreferences prefs = await SharedPreferences.getInstance();
        await prefs.setString('mid', mid);
        await prefs.setString('email', email);

        ScaffoldMessenger.of(
          context,
        ).showSnackBar(const SnackBar(content: Text('Вход выполнен успешно!')));

        // --- NEW LOGIC: Check for existing profile and navigate ---
        await _checkAndNavigateToProfileOrHome(mid);
        // --- END NEW LOGIC ---
      } else {
        setState(() {
          errorMessage =
              'Ошибка при входе. Сервер вернул ${response.statusCode}';
        });
        print('Login failed: ${response.statusCode}, ${response.body}');
      }
    } catch (e) {
      setState(() {
        errorMessage = 'Ошибка сети. Попробуйте позже.';
      });
      print('Error during login: $e');
    }
  }

  Future<void> _checkAndNavigateToProfileOrHome(String mid) async {
    try {
      final profileResponse = await http.get(
        Uri.parse('$profileApiUrl?mid=$mid'),
      );

      if (profileResponse.statusCode == 200) {
        final List<dynamic> profileData = jsonDecode(profileResponse.body);
        if (profileData.isNotEmpty) {
          // Profile exists, navigate to HomePage
          Navigator.of(context).pushReplacement(
            MaterialPageRoute(builder: (context) => HomePage()),
          );
        } else {
          // Profile does not exist, navigate to ProfileEdit
          Navigator.of(context).pushReplacement(
            MaterialPageRoute(builder: (context) => const ProfileEdit()),
          );
        }
      } else {
        // Handle server error during profile check, maybe default to ProfileEdit
        print(
          'Error checking profile existence: ${profileResponse.statusCode}, ${profileResponse.body}',
        );
        Navigator.of(context).pushReplacement(
          MaterialPageRoute(builder: (context) => const ProfileEdit()),
        );
      }
    } catch (e) {
      print('Network error during profile check: $e');
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Ошибка сети при проверке профиля.')),
      );
      Navigator.of(context).pushReplacement(
        MaterialPageRoute(builder: (context) => const ProfileEdit()),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final themeChanger = Provider.of<ThemeChanger>(context);
    final currentColors = themeChanger.currentColors;
    return Scaffold(
      appBar: AppBar(
        toolbarHeight: 150,
        automaticallyImplyLeading: false,
        bottom: PreferredSize(
          preferredSize: Size.fromHeight(0),
          child: Padding(
            padding: EdgeInsets.only(bottom: 16, left: 20),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.start,
              children: [
                // Gesture detector for back button, uncomment if needed
                GestureDetector(
                  onTap: () {
                    Navigator.pop(context);
                  },
                  child: const Icon(Icons.close, size: 35),
                ),
              ],
            ),
          ),
        ),
      ),
      body: SingleChildScrollView(
        child: Padding(
          padding: const EdgeInsets.all(20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                "Войдите в аккаунт",
                style: GoogleFonts.geologica(
                  fontSize: 32,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 10),
              Text(
                "Всегда оставайтесь на связи со своей учетной записью!",
                style: GoogleFonts.geologica(fontSize: 20),
              ),
              const SizedBox(height: 36),
              Text(
                "Вход",
                style: GoogleFonts.geologica(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 12),
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 15,
                  vertical: 5,
                ),
                width: MediaQuery.of(context).size.width,
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.all(Radius.circular(20000)),
                  color: currentColors.inputCol,
                ),
                child: TextField(
                  controller: emailController,
                  decoration: const InputDecoration(
                    hintText: "Введите почту",
                    border: InputBorder.none,
                    focusedBorder: InputBorder.none,
                    enabledBorder: InputBorder.none,
                    errorBorder: InputBorder.none,
                    disabledBorder: InputBorder.none,
                  ),
                  style: GoogleFonts.geologica(fontSize: 16),
                ),
              ),
              const SizedBox(height: 8),
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 15,
                  vertical: 5,
                ),
                width: MediaQuery.of(context).size.width,
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.all(Radius.circular(20000)),
                  color: currentColors.inputCol,
                ),
                child: TextField(
                  controller: passwordController,
                  decoration: const InputDecoration(
                    hintText: "Введите пароль",
                    border: InputBorder.none,
                    focusedBorder: InputBorder.none,
                    enabledBorder: InputBorder.none,
                    errorBorder: InputBorder.none,
                    disabledBorder: InputBorder.none,
                  ),
                  style: GoogleFonts.geologica(fontSize: 16),
                  obscureText: true,
                ),
              ),
              const SizedBox(height: 8),
              GestureDetector(
                onTap: logIn,
                child: Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 15,
                    vertical: 5,
                  ),
                  width: MediaQuery.of(context).size.width,
                  height: 50,
                  decoration: const BoxDecoration(
                    borderRadius: BorderRadius.all(Radius.circular(20000)),
                    color: Color(0xFF334EFF),
                  ),
                  child: Center(
                    child: Text(
                      "Войти в аккаунт",
                      style: GoogleFonts.geologica(
                        color: Colors.white,
                        fontSize: 16,
                      ),
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 8),
              GestureDetector(
                onTap: () {
                  Navigator.of(context).push(
                    MaterialPageRoute(
                      builder: (context) => const AccountSignup(),
                    ),
                  );
                },
                child: Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 15,
                    vertical: 5,
                  ),
                  width: MediaQuery.of(context).size.width,
                  height: 50,
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.all(Radius.circular(20000)),
                    color: currentColors.settingsBg,
                  ),
                  child: Center(
                    child: Text(
                      "Еще нет аккаунта? Создать",
                      style: GoogleFonts.geologica(fontSize: 16),
                    ),
                  ),
                ),
              ),
              if (errorMessage.isNotEmpty)
                Padding(
                  padding: const EdgeInsets.only(top: 8.0),
                  child: Text(
                    errorMessage,
                    style: const TextStyle(color: Colors.red),
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }
}
