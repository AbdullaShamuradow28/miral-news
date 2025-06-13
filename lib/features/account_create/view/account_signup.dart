import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:miral_news/features/account_login/view/account_login.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:provider/provider.dart';

import 'package:miral_news/theme_changer.dart'; // Import dart:convert for JSON decoding

class AccountSignup extends StatefulWidget {
  const AccountSignup({super.key});

  @override
  State<AccountSignup> createState() => _AccountSignupState();
}

class _AccountSignupState extends State<AccountSignup> {
  String apiUrl = "http://192.168.1.109:3001/api/users/"; // Corrected API URL
  var emailController = TextEditingController();
  var passwordController = TextEditingController();
  String errorMessage = ''; // To store and display error messages

  void saveUser() async {
    setState(() {
      errorMessage = ''; // Clear previous error messages
    });
    final response = await http.post(
      Uri.parse(apiUrl),
      headers: <String, String>{
        'Content-Type': 'application/json; charset=UTF-8',
      },
      body: jsonEncode(<String, String>{
        'email': emailController.text,
        'password': passwordController.text,
      }),
    );

    if (response.statusCode == 201) {
      // 201 Created
      print(response.body + " CREATED!");
      Navigator.of(
        context,
      ).push(MaterialPageRoute(builder: (context) => AccountLogin()));
    } else if (response.statusCode == 409) {
      // 409 Conflict (email already exists)
      setState(() {
        errorMessage = 'Аккаунт с такой почтой уже существует.';
      });
      print('Email already exists.');
    } else {
      setState(() {
        errorMessage = 'Ошибка при создании аккаунта. Попробуйте позже.';
      });
      print('Error: ${response.statusCode}, ${response.body}');
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
          child: Container(
            padding: const EdgeInsets.only(bottom: 16),
            margin: const EdgeInsets.only(left: 20),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.start,
              children: [
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
                "Создайте аккаунт",
                style: GoogleFonts.geologica(
                  fontSize: 32,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 10),
              Text(
                "Начните пользоваться всеми преимуществами уже сегодня!",
                style: GoogleFonts.geologica(fontSize: 20),
              ),
              const SizedBox(height: 36),
              Text(
                "Регистрация",
                style: GoogleFonts.geologica(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 12),
              Container(
                padding: const EdgeInsets.only(
                  left: 15,
                  right: 15,
                  top: 5,
                  bottom: 5,
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
                padding: const EdgeInsets.only(
                  left: 15,
                  right: 15,
                  top: 5,
                  bottom: 5,
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
                onTap: saveUser, // Call saveUser on tap
                child: Container(
                  padding: const EdgeInsets.only(
                    left: 15,
                    right: 15,
                    top: 5,
                    bottom: 5,
                  ),
                  width: MediaQuery.of(context).size.width,
                  height: 50,
                  decoration: const BoxDecoration(
                    borderRadius: BorderRadius.all(Radius.circular(20000)),
                    color: Color(0xFF334EFF),
                  ),
                  child: Center(
                    child: Text(
                      "Создать аккаунт",
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
                      builder: (context) => const AccountLogin(),
                    ),
                  );
                },
                child: Container(
                  padding: const EdgeInsets.only(
                    left: 15,
                    right: 15,
                    top: 5,
                    bottom: 5,
                  ),
                  width: MediaQuery.of(context).size.width,
                  height: 50,
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.all(Radius.circular(20000)),
                    color: currentColors.settingsBg,
                  ),
                  child: Center(
                    child: Text(
                      "Уже есть аккаунт? Войти",
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
