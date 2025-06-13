// In lib/edit_article.dart

import 'dart:convert';
import 'dart:typed_data';
import 'package:http/http.dart' as http;
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:image_picker/image_picker.dart';
import 'package:miral_news/features/home_page/bloc/news_bloc.dart';
import 'package:miral_news/features/home_page/view/homepage.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:flutter_bloc/flutter_bloc.dart'; // Import flutter_bloch if needed

class EditArticle extends StatefulWidget {
  const EditArticle({
    super.key,
    required this.initialTitle,
    required this.id,
    required this.initialContent,
    required this.author,
    this.initialImage,
    required this.authorImage,
    this.articleBloc, // Add ArticleBloc instance here
  });

  final String initialTitle;
  final int id;
  final String initialContent;
  final String? initialImage;
  final String author;
  final String authorImage;
  final ArticleBloc?
  articleBloc; // Make it nullable if not always provided directly

  @override
  State<EditArticle> createState() => _EditArticleState();
}

class _EditArticleState extends State<EditArticle> {
  String? username;
  String? mid;
  Uint8List? imageBytes;
  var titleController = TextEditingController();
  var contentController = TextEditingController();
  String apiUrl = "http://192.168.1.109:3000";
  Uint8List? articleImageBytes;
  final picker = ImagePicker();

  @override
  void initState() {
    super.initState();
    _loadProfileData();
    titleController.text = widget.initialTitle;
    contentController.text = widget.initialContent;
    if (widget.initialImage != null && widget.initialImage!.isNotEmpty) {
      try {
        // Handle image loading if needed, as discussed in the previous response.
      } catch (e) {
        print("Error decoding initial image: $e");
      }
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

  Future<void> _updateArticle() async {
    if (titleController.text.isEmpty ||
        contentController.text.isEmpty ||
        username == null) {
      ScaffoldMessenger.of(context).showSnackBar(
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
      Uri url = Uri.parse('$apiUrl/${widget.id}/');
      var request = http.MultipartRequest("PUT", url);
      request.headers.addAll({'Content-Type': 'multipart/form-data'});

      if (articleImageBytes != null) {
        request.files.add(
          http.MultipartFile.fromBytes(
            'image',
            articleImageBytes!,
            filename: 'article_image.png',
          ),
        );
      } else if (widget.initialImage != null &&
          widget.initialImage!.isNotEmpty) {
        // If no new image is selected, and there was an initial image,
        // you might need to handle this based on your backend.
        // If your backend keeps the old image if 'image' field is absent, no action is needed here.
        // If it requires the old image to be explicitly sent again, you'd need to fetch it.
      }

      request.fields['title'] = titleController.text;
      request.fields['content'] = contentController.text;
      request.fields['author'] = mid!;

      final response = await request.send();
      final statusCode = response.statusCode;
      final responseBody = await response.stream.bytesToString();
      print("Server Response: $responseBody");
      print("Status Code: $statusCode");

      if (statusCode == 200) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text("Статья успешно обновлена!")),
        );

        // --- THE KEY CHANGE HERE ---
        // Access the BLoC and add the LoadArticles event
        if (widget.articleBloc != null) {
          widget.articleBloc!.add(LoadArticles());
        } else {
          // Fallback if bloc is not passed directly, try to find it in the context
          // This is less ideal for explicit dependencies but can work if setup allows.
          try {
            BlocProvider.of<ArticleBloc>(context).add(LoadArticles());
          } catch (e) {
            print(
              "Warning: Could not find ArticleBloc in context to refresh: $e",
            );
          }
        }
        // --- END KEY CHANGE ---

        Navigator.of(
          context,
        ).push(MaterialPageRoute(builder: (context) => HomePage()));
      } else {
        String errorMessage = "Не удалось обновить статью.";
        if (statusCode == 400) {
          errorMessage =
              "Ошибка запроса: Сервер не понял запрос. Пожалуйста, проверьте введенные данные.";
        } else if (statusCode == 401) {
          errorMessage =
              "Ошибка авторизации: У вас нет прав на обновление статьи.";
        } else if (statusCode == 413) {
          errorMessage = "Ошибка: Размер изображения слишком велик.";
        } else if (statusCode >= 500) {
          errorMessage = "Ошибка сервера: Попробуйте позже.";
        }
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text("$errorMessage (Код ошибки: $statusCode)"),
            backgroundColor: Colors.redAccent,
          ),
        );
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text("Произошла ошибка при обновлении статьи: $e"),
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
        articleImageBytes = bytes;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        surfaceTintColor: Colors.white,
        toolbarHeight: 80,
        leading: GestureDetector(
          onTap: () {
            Navigator.pop(context);
          },
          child: const Icon(Icons.arrow_back, color: Colors.black),
        ),
        title: Text(
          "Изменить статью",
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
                context: context,
                builder:
                    (context) => AlertDialog(
                      shape: const RoundedRectangleBorder(
                        borderRadius: BorderRadius.all(Radius.circular(24)),
                      ),
                      backgroundColor: Colors.white,
                      title: Text(
                        "Обновить статью",
                        style: GoogleFonts.geologica(
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                          color: Colors.black,
                        ),
                      ),
                      content: Text(
                        "Вы уверены, что хотите обновить эту статью?",
                        style: GoogleFonts.geologica(
                          fontSize: 16,
                          color: Colors.black54,
                        ),
                      ),
                      actions: [
                        GestureDetector(
                          onTap: () {
                            Navigator.pop(context);
                          },
                          child: Text(
                            "Отмена",
                            style: GoogleFonts.geologica(
                              fontSize: 16,
                              color: Colors.black,
                            ),
                          ),
                        ),
                        const SizedBox(width: 12),
                        GestureDetector(
                          onTap: () async {
                            Navigator.pop(context); // Close the dialog
                            _updateArticle(); // Call the update method
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
              child: const Icon(Icons.done_all, color: Colors.black),
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
                GestureDetector(
                  onTap: _selectImage,
                  child: Container(
                    width: MediaQuery.of(context).size.width,
                    height: 200,
                    decoration: const BoxDecoration(
                      border: Border.symmetric(
                        horizontal: BorderSide(width: 1, color: Colors.black54),
                      ),
                    ),
                    child: Center(
                      child:
                          articleImageBytes != null
                              ? Image.memory(
                                articleImageBytes!,
                                fit: BoxFit.cover,
                              )
                              : widget.initialImage != null &&
                                  widget.initialImage!.isNotEmpty
                              ? Image.network(
                                widget.initialImage!,
                                fit: BoxFit.cover,
                                errorBuilder: (context, error, stackTrace) {
                                  return Column(
                                    mainAxisAlignment: MainAxisAlignment.center,
                                    crossAxisAlignment:
                                        CrossAxisAlignment.center,
                                    children: [
                                      const Icon(
                                        Icons.photo_outlined,
                                        size: 60,
                                        color: Colors.black54,
                                      ),
                                      const SizedBox(height: 10),
                                      Text(
                                        "Ошибка загрузки изображения. Нажмите, чтобы выбрать новое.",
                                        textAlign: TextAlign.center,
                                        style: GoogleFonts.geologica(
                                          color: Colors.black54,
                                        ),
                                      ),
                                    ],
                                  );
                                },
                              )
                              : Column(
                                mainAxisAlignment: MainAxisAlignment.center,
                                crossAxisAlignment: CrossAxisAlignment.center,
                                children: [
                                  const Icon(
                                    Icons.photo_outlined,
                                    size: 60,
                                    color: Colors.black54,
                                  ),
                                  const SizedBox(height: 10),
                                  Text(
                                    "Выберите изображение",
                                    style: GoogleFonts.geologica(
                                      color: Colors.black54,
                                    ),
                                  ),
                                ],
                              ),
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
                          imageBytes == null
                              ? const Icon(Icons.person, size: 60)
                              : null,
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
                      color: Colors.black54,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  style: GoogleFonts.geologica(
                    fontSize: 28,
                    color: Colors.black,
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
                      color: Colors.black54,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  style: GoogleFonts.geologica(
                    fontSize: 16,
                    color: Colors.black,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 16),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
