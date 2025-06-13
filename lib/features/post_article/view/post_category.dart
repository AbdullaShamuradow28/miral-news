import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:http/http.dart' as http;
import 'package:miral_news/features/post_article/view/port_article.dart';
// Импортируйте экран формы

class CategoryGridScreen extends StatefulWidget {
  const CategoryGridScreen({super.key});

  @override
  State<CategoryGridScreen> createState() => _CategoryGridScreenState();
}

class _CategoryGridScreenState extends State<CategoryGridScreen> {
  List<Map<String, dynamic>> categories = [];
  bool isLoading = false;
  String? error;

  @override
  void initState() {
    super.initState();
    _fetchCategories();
  }

  Future<void> _fetchCategories() async {
    setState(() {
      isLoading = true;
      error = null;
    });
    try {
      final response = await http.get(
        Uri.parse('http://192.168.1.109:3000/categories/'),
      );
      if (response.statusCode == 200) {
        final List<dynamic> decodedResponse = json.decode(response.body);
        setState(() {
          categories = decodedResponse.cast<Map<String, dynamic>>();
          isLoading = false;
        });
      } else {
        setState(() {
          error = 'Не удалось загрузить категории: ${response.statusCode}';
          isLoading = false;
        });
      }
    } catch (e) {
      setState(() {
        error = 'Ошибка при загрузке категорий: $e';
        isLoading = false;
      });
    }
  }

  void _selectCategory(int categoryId, String categoryName) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder:
            (context) => PostArticleFormScreen(
              initialCategoryId: categoryId,
              initialCategoryName: categoryName,
            ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(
          'Выберите категорию',
          style: GoogleFonts.geologica(
            fontWeight: FontWeight.bold,
            fontSize: 16,
          ),
        ),
        surfaceTintColor: Colors.white,
        toolbarHeight: 80,
        leading: GestureDetector(
          onTap: () {
            Navigator.pop(context);
          },
          child: const Icon(Icons.arrow_back),
        ),
        centerTitle: true,
      ),
      body: Center(
        child:
            isLoading
                ? const CircularProgressIndicator()
                : error != null
                ? Text(error!, style: const TextStyle(color: Colors.red))
                : categories.isEmpty
                ? const Text('Нет доступных категорий.')
                : GridView.builder(
                  padding: const EdgeInsets.all(16),
                  gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                    crossAxisCount: 2,
                    childAspectRatio: 1.0,
                    crossAxisSpacing: 16,
                    mainAxisSpacing: 16,
                  ),
                  itemCount: categories.length,
                  itemBuilder: (context, index) {
                    final category = categories[index];
                    final int categoryId = category['id'];
                    final String categoryName =
                        category['name'] ?? 'Без названия';
                    final String? imageUrl =
                        category['image']; // Предполагаем, что есть поле 'image'

                    return GestureDetector(
                      onTap: () => _selectCategory(categoryId, categoryName),
                      child: Card(
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            if (imageUrl != null && imageUrl.isNotEmpty)
                              Padding(
                                padding: const EdgeInsets.all(8.0),
                                child: SizedBox(
                                  height: 80,
                                  width: 80,
                                  child: Image.network(
                                    '$imageUrl', // Добавьте базовый URL
                                    fit: BoxFit.cover,
                                    errorBuilder: (context, error, stackTrace) {
                                      return const Icon(
                                        Icons.image_not_supported,
                                        size: 48,
                                      );
                                    },
                                  ),
                                ),
                              )
                            else
                              const Icon(Icons.category, size: 48),
                            Padding(
                              padding: const EdgeInsets.all(8.0),
                              child: Text(
                                categoryName,
                                textAlign: TextAlign.center,
                                style: GoogleFonts.geologica(
                                  fontWeight: FontWeight.bold,
                                ),
                                maxLines: 2,
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                          ],
                        ),
                      ),
                    );
                  },
                ),
      ),
    );
  }
}
