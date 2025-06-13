import 'dart:convert';
import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:http/http.dart' as http;
import 'package:miral_news/theme_changer.dart';
import 'package:path/path.dart' as p; // <--- ADDED 'as p'
import 'package:shared_preferences/shared_preferences.dart';
import 'package:image_picker/image_picker.dart';
import 'package:provider/provider.dart';

class PostArticleFormScreen extends StatefulWidget {
  final int? initialCategoryId;
  final String? initialCategoryName;

  const PostArticleFormScreen({
    super.key,
    this.initialCategoryId,
    this.initialCategoryName,
  });

  @override
  State<PostArticleFormScreen> createState() => _PostArticleFormScreenState();
}

class _PostArticleFormScreenState extends State<PostArticleFormScreen> {
  String? username;
  String? mid;
  Uint8List? imageBytes;
  var titleController = TextEditingController();
  var contentController = TextEditingController();
  String apiUrl = "http://192.168.1.109:3000";
  Uint8List? imageBytess;
  final picker = ImagePicker();
  int? selectedCategoryId;
  String? selectedCategoryName;

  @override
  void initState() {
    super.initState();
    _loadProfileData();
    selectedCategoryId = widget.initialCategoryId;
    selectedCategoryName = widget.initialCategoryName;
    if (selectedCategoryName != null) {
      print(
        'Выбрана категория при переходе: $selectedCategoryName (ID: $selectedCategoryId)',
      );
    }
  }

  Future<void> _loadProfileData() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    setState(() {
      username = prefs.getString('username');
      mid = prefs.getString('mid');
      String? imageString = prefs.getString('imageBytes');
      if (imageString != null) {
        imageBytes = base64Decode(imageString);
      }
    });
  }

  Future<void> _sendArticle() async {
    if (titleController.text.isEmpty ||
        contentController.text.isEmpty ||
        username == null ||
        selectedCategoryId == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        // This 'context' is correct (BuildContext)
        const SnackBar(
          content: Text(
            "Пожалуйста, заполните заголовок, содержание и выберите категорию.",
          ),
          backgroundColor: Colors.orangeAccent,
        ),
      );
      return;
    }

    try {
      Uri url = Uri.parse('$apiUrl'); // Убедитесь, что эндпоинт правильный
      var request = http.MultipartRequest("POST", url);
      request.headers.addAll({'Content-Type': 'multipart/form-data'});

      if (imageBytess != null) {
        request.files.add(
          http.MultipartFile.fromBytes(
            'image',
            imageBytess!,
            filename: 'article_image.png',
          ),
        );
      }

      request.fields['title'] = titleController.text;
      request.fields['content'] = contentController.text;
      request.fields['category'] =
          selectedCategoryName.toString(); // Отправляем ID категории
      request.fields['author'] = mid!;
      request.fields['authorMid'] = mid!;

      final response = await request.send();
      final statusCode = response.statusCode;
      final responseBody = await response.stream.bytesToString();
      print("Server Response: $responseBody");
      print("Status Code: $statusCode");

      if (statusCode == 201) {
        ScaffoldMessenger.of(context).showSnackBar(
          // This 'context' is correct (BuildContext)
          const SnackBar(
            content: Text("Статья успешно отправлена на проверку!"),
          ),
        );
        Navigator.pop(context); // This 'context' is correct (BuildContext)
      } else {
        String errorMessage = "Не удалось отправить статью.";
        if (statusCode == 400) {
          errorMessage =
              "Ошибка запроса: Сервер не понял запрос. Пожалуйста, проверьте введенные данные.";
          try {
            final errorJson = jsonDecode(responseBody);
            if (errorJson.containsKey('category')) {
              errorMessage =
                  "Ошибка категории: ${errorJson['category'].join(', ')}";
            } else if (errorJson.containsKey('message')) {
              errorMessage = "Ошибка запроса: ${errorJson['message']}";
            }
          } catch (e) {
            print("Failed to decode error response: $e");
          }
        } else if (statusCode == 401) {
          errorMessage =
              "Ошибка авторизации: У вас нет прав на отправку статьи.";
        } else if (statusCode == 413) {
          errorMessage = "Ошибка: Размер изображения слишком велик.";
        } else if (statusCode >= 500) {
          errorMessage = "Ошибка сервера: Попробуйте позже.";
        }
        ScaffoldMessenger.of(context).showSnackBar(
          // This 'context' is correct (BuildContext)
          SnackBar(
            content: Text("$errorMessage (Код ошибки: $statusCode)"),
            backgroundColor: Colors.redAccent,
          ),
        );
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        // This 'context' is correct (BuildContext)
        SnackBar(
          content: Text("Произошла ошибка при отправке статьи: $e"),
          backgroundColor: Colors.redAccent,
        ),
      );
    }
  }

  Future<void> _selectImage() async {
    final pickedFile = await picker.pickImage(source: ImageSource.gallery);
    if (pickedFile != null) {
      final bytes = await pickedFile.readAsBytes();
      setState(() {
        imageBytess = bytes;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    // This 'context' is BuildContext
    final themeChanger = Provider.of<ThemeChanger>(context);
    final currentColors = themeChanger.currentColors;
    return Scaffold(
      appBar: AppBar(
        surfaceTintColor: Colors.white,
        toolbarHeight: 80,
        leading: GestureDetector(
          onTap: () {
            Navigator.pop(context); // This 'context' is correct (BuildContext)
          },
          child: const Icon(Icons.arrow_back),
        ),
        title: Text(
          "Написать статью",
          style: GoogleFonts.geologica(
            fontWeight: FontWeight.bold,
            fontSize: 16,
          ),
        ),
        centerTitle: true,
        actions: [
          GestureDetector(
            onTap: () {
              showDialog(
                context: context, // This 'context' is correct (BuildContext)
                builder:
                    (context) => AlertDialog(
                      // This 'context' is correct (BuildContext)
                      shape: const RoundedRectangleBorder(
                        borderRadius: BorderRadius.all(Radius.circular(24)),
                      ),
                      backgroundColor: currentColors.dialogBackground,
                      title: Text(
                        "Отправить статью на проверку",
                        style: GoogleFonts.geologica(
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                          color: currentColors.textBlack,
                        ),
                      ),
                      content: Text(
                        "Перед публикацией статья пройдет проверку, это займет не много времени! Вы получите уведомление на почту, привязанную к Miral Account",
                        style: GoogleFonts.geologica(
                          fontSize: 16,
                          color: currentColors.textGrey,
                        ),
                      ),
                      actions: [
                        GestureDetector(
                          onTap: () {
                            Navigator.pop(
                              context,
                            ); // This 'context' is correct (BuildContext)
                          },
                          child: Text(
                            "Отмена",
                            style: GoogleFonts.geologica(fontSize: 16),
                          ),
                        ),
                        const SizedBox(width: 12),
                        GestureDetector(
                          onTap: () async {
                            _sendArticle();
                          },
                          child: Text(
                            "Подтвердить",
                            style: GoogleFonts.geologica(
                              fontSize: 16,
                              color: const Color(0xFF334EFF),
                            ),
                          ),
                        ),
                      ],
                    ),
              );
            },
            child: Container(
              margin: const EdgeInsets.only(right: 10),
              child: const Icon(Icons.done_all),
            ),
          ),
        ],
      ),
      body: ListView(
        children: [
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // if (widget.initialCategoryName != null)
                //   Padding(
                //     padding: const EdgeInsets.only(bottom: 16.0),
                //     child: Text(
                //       'Выбрана категория: ${widget.initialCategoryName}',
                //       style: GoogleFonts.geologica(
                //         fontSize: 16,
                //         fontWeight: FontWeight.bold,
                //         color: Colors.green,
                //       ),
                //     ),
                //   ),
                GestureDetector(
                  onTap: _selectImage,
                  child: Container(
                    width: MediaQuery.of(context).size.width,
                    height: 200,
                    decoration: BoxDecoration(
                      border: Border.symmetric(
                        horizontal: BorderSide(
                          width: 1,
                          color: currentColors.textBlack,
                        ),
                      ),
                    ),
                    child: Center(
                      child:
                          imageBytess == null
                              ? Column(
                                mainAxisAlignment: MainAxisAlignment.center,
                                crossAxisAlignment: CrossAxisAlignment.center,
                                children: [
                                  const Icon(Icons.photo_outlined, size: 60),
                                  const SizedBox(height: 10),
                                  Text(
                                    "Выберите изображение",
                                    style: GoogleFonts.geologica(),
                                  ),
                                ],
                              )
                              : Image.memory(imageBytess!, fit: BoxFit.cover),
                    ),
                  ),
                ),
                const SizedBox(height: 15),
                Row(
                  children: [
                    const SizedBox(width: 20),
                    CircleAvatar(
                      radius: 20,
                      backgroundImage:
                          imageBytes != null ? MemoryImage(imageBytes!) : null,
                      child:
                          imageBytes == null ? const Icon(Icons.person) : null,
                    ),
                    const SizedBox(width: 10),
                    Text(
                      username ?? "Загрузка...",
                      style: GoogleFonts.geologica(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                TextField(
                  controller: titleController,
                  decoration: InputDecoration(
                    border: InputBorder.none,
                    focusedBorder: InputBorder.none,
                    errorBorder: InputBorder.none,
                    enabledBorder: InputBorder.none,
                    disabledBorder: InputBorder.none,
                    focusedErrorBorder: InputBorder.none,
                    hintText: "Заголовок",
                    hintStyle: GoogleFonts.geologica(
                      fontSize: 28,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  style: GoogleFonts.geologica(
                    fontSize: 28,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 16),
                Container(
                  padding: const EdgeInsets.all(20),
                  decoration: const BoxDecoration(
                    borderRadius: BorderRadius.all(Radius.circular(20)),
                    color: Color(0xFFE7EAFF),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisAlignment: MainAxisAlignment.start,
                    children: [
                      Text(
                        "Как делать статьи?",
                        style: GoogleFonts.geologica(
                          color: const Color(0xFF334EFF),
                          fontSize: 20,
                        ),
                      ),
                      const SizedBox(height: 6),
                      Text(
                        "1. Используйте перед предложением символ # для создания заголовка",
                        style: GoogleFonts.geologica(
                          color: const Color(0xFF334EFF),
                          fontSize: 16,
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 16),
                TextField(
                  controller: contentController,
                  maxLines: null,
                  keyboardType: TextInputType.multiline,
                  decoration: InputDecoration(
                    border: InputBorder.none,
                    focusedBorder: InputBorder.none,
                    errorBorder: InputBorder.none,
                    enabledBorder: InputBorder.none,
                    disabledBorder: InputBorder.none,
                    focusedErrorBorder: InputBorder.none,
                    hintText: "Напишите вашу статью",
                    hintStyle: GoogleFonts.geologica(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  style: GoogleFonts.geologica(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
