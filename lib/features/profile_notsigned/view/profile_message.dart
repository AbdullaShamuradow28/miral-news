import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:miral_news/app_theme.dart';
import 'package:miral_news/features/account_create/view/account_signup.dart';
import 'package:miral_news/features/account_login/view/account_login.dart';
import 'package:miral_news/features/home_page/view/homepage.dart';
import 'package:miral_news/features/settings/view/settings.dart';
import 'package:miral_news/theme_changer.dart';
import 'package:provider/provider.dart';

class ProfileMessage extends StatefulWidget {
  const ProfileMessage({super.key});

  @override
  State<ProfileMessage> createState() => _ProfileMessageState();
}

class _ProfileMessageState extends State<ProfileMessage> {
  @override
  Widget build(BuildContext context) {
    final themeChanger = Provider.of<ThemeChanger>(context);
    final currentColors = themeChanger.currentColors;
    return Scaffold(
      appBar: AppBar(
        automaticallyImplyLeading: false,
        actions: [
          Container(
            margin: EdgeInsets.all(20),
            child: GestureDetector(
              child: Icon(
                Icons.settings,
                size: 32,
                color:
                    (currentColors.whiteCol == Color.fromARGB(255, 27, 27, 27))
                        ? Colors.white
                        : Colors.black,
              ),
              onTap: () {
                Navigator.of(context).push(
                  MaterialPageRoute(builder: (context) => SettingsScreen()),
                );
              },
            ),
          ),
        ],
      ),
      bottomNavigationBar: Container(
        width: MediaQuery.of(context).size.width,
        height: 80,
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceEvenly,
          children: [
            GestureDetector(
              onTap: () {
                Navigator.of(
                  context,
                ).push(MaterialPageRoute(builder: (context) => HomePage()));
              },
              child: Icon(Icons.home, size: 35, color: Color(0xFFA7A7A7)),
            ),
            Container(
              margin: EdgeInsets.only(bottom: 10),
              child: FloatingActionButton(
                onPressed: () {
                  showModalBottomSheet(
                    context: context,
                    builder:
                        (context) => Container(
                          padding: EdgeInsets.all(20),
                          height: 210,
                          child: Column(
                            children: [
                              Text(
                                "Упс, похоже кто-то хочет создать статью без входа в систему!",
                                style: GoogleFonts.geologica(fontSize: 20),
                              ),
                              SizedBox(height: 10),
                              Text(
                                "Но так нельзя! Для того, чтобы написать статью, необходимо войти в Miral Account!",
                                style: GoogleFonts.geologica(
                                  fontSize: 14,
                                  color: Colors.black.withOpacity(0.7),
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
                                      color: Color(0xFF334EFF),
                                    ),
                                    child: Center(
                                      child: Text(
                                        "Войти в Miral Account",
                                        style: GoogleFonts.geologica(
                                          color: Colors.white,
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
                backgroundColor: Color(0xFF334EFF),
                child: Icon(Icons.add, size: 30, color: Colors.white),
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
              child: Icon(Icons.person, size: 35, color: Color(0xFF334EFF)),
            ),
          ],
        ),
      ),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            Text(
              "Войдите в аккаунт",
              style: GoogleFonts.geologica(
                fontSize: 30,
                fontWeight: FontWeight.bold,
              ),
            ),
            Text(
              "Публикуйте ваши статьи в вашем профиле",
              style: GoogleFonts.geologica(fontSize: 15),
            ),
            SizedBox(height: 20),
            SizedBox(
              child: ElevatedButton(
                onPressed: () {
                  Navigator.of(context).push(
                    MaterialPageRoute(builder: (context) => AccountSignup()),
                  );
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: Color(0xFF334EFF),
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.all(Radius.circular(20000)),
                  ),
                ),
                child: Text(
                  "Войти в аккаунт",
                  style: GoogleFonts.geologica(color: Colors.white),
                ),
              ),
              width: 177,
              height: 48,
            ),
          ],
        ),
      ),
    );
  }
}
