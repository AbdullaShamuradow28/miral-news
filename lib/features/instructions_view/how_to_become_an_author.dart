import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:path/path.dart';

class AuthorInstructions extends StatefulWidget {
  const AuthorInstructions({super.key});

  @override
  State<AuthorInstructions> createState() => _AuthorInstructionsState();
}

class _AuthorInstructionsState extends State<AuthorInstructions> {
  @override
  Widget build(BuildContext context) {
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
                  child: const Icon(Icons.arrow_back_ios_new, size: 35),
                ),
              ],
            ),
          ),
        ),
      ),
      body: SingleChildScrollView(
        child: Padding(
          padding: const EdgeInsets.all(20.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                "Как написать хорошую статью",
                style: GoogleFonts.geologica(
                  fontSize: 32,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 10),
              Text(
                "5 советов от разработчика Miral News",
                style: GoogleFonts.geologica(fontSize: 20),
              ),
              const SizedBox(height: 36),
              Text(
                "1. Передавайте суть статьи ясно и точно",
                style: GoogleFonts.geologica(fontSize: 17),
              ),
              Divider(),
              Text(
                "2. В случае с портированием статьи из другого ресурса указывайте источник в конце статьи",
                style: GoogleFonts.geologica(fontSize: 17),
              ),
              Divider(),
              Text(
                "3. Если контент был полностью сгенерирован ИИ, включите соответствующую отметку",
                style: GoogleFonts.geologica(fontSize: 17),
              ),
              Divider(),
              Text(
                "4. Статья должна иметь вступление и заключение",
                style: GoogleFonts.geologica(fontSize: 17),
              ),
              Divider(),
              Text(
                "5. Не рекламировать сторонние сервисы, сконцентрироваться на основной части статьи",
                style: GoogleFonts.geologica(fontSize: 17),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
