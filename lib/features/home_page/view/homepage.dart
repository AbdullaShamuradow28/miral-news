import "package:flutter/material.dart";
import 'package:flutter_svg/svg.dart';
import "package:google_fonts/google_fonts.dart";
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:miral_news/features/article_detail/view/article_detail.dart';
import 'package:miral_news/features/home_page/bloc/news_bloc.dart'; // Import your bloc
import 'package:miral_news/features/post_article/view/port_article.dart';
import 'package:miral_news/features/post_article/view/post_category.dart';
import 'package:miral_news/features/profile_notsigned/view/profile_message.dart';
import 'package:miral_news/features/account_login/view/account_login.dart';
import 'package:miral_news/features/profile_signed/view/profile_view.dart';
import 'package:miral_news/features/search/view/search_view.dart';
import 'package:miral_news/theme_changer.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:shimmer/shimmer.dart';
import 'package:provider/provider.dart'; // Импортируем provider
import 'package:http/http.dart' as http;
import 'dart:convert';

class HomePage extends StatefulWidget {
  const HomePage({super.key});

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  String apiCategoriesUrl = "http://192.168.1.109:3000/categories/";

  List<dynamic> categories = [];
  // Add a set to keep track of selected category names
  Set<String> _selectedCategories = {};

  @override
  void initState() {
    super.initState();
    _fetchCategories();
    // Initialize the ArticleBloc to load articles without any specific category filter initially
    // This assumes the ArticleBloc is already provided higher up in the widget tree
    // If not, you'd move the BlocProvider from the build method to main.dart or your App widget
    // BlocProvider.of<ArticleBloc>(context).add(LoadArticles()); // This would cause an error if BlocProvider is in build method
  }

  Future<void> _fetchCategories() async {
    try {
      final response = await http.get(Uri.parse(apiCategoriesUrl));
      if (response.statusCode == 200) {
        final List<dynamic> data = json.decode(response.body);
        setState(() {
          categories = data;
        });
      } else {
        print(
          'DEBUG: HomePage: Failed to fetch categories: ${response.statusCode}',
        );
        // Handle error appropriately, maybe show a snackbar
      }
    } catch (error) {
      print('DEBUG: HomePage: Error fetching categories: $error');
      // Handle error appropriately
    }
  }

  // New method to handle category tap
  void _onCategoryTapped(String categoryName) {
    setState(() {
      if (_selectedCategories.contains(categoryName)) {
        _selectedCategories.remove(categoryName);
      } else {
        _selectedCategories.add(categoryName);
      }
      // Trigger a new LoadArticles event with the updated filters
      BlocProvider.of<ArticleBloc>(context).add(
        LoadArticles(
          categories:
              _selectedCategories.toList(), // Pass the selected categories
        ),
      );
    });
  }

  // Method to handle "All Categories" tap
  void _onAllCategoriesTapped() {
    setState(() {
      _selectedCategories.clear(); // Clear all selections
    });
    // Trigger a new LoadArticles event with no category filters
    BlocProvider.of<ArticleBloc>(context).add(LoadArticles(categories: []));
  }

  Future<bool> _checkProfileDataExists() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    print('DEBUG: HomePage: Checking profile data...');

    // Retrieve all relevant profile data
    String? mid = prefs.getString('mid');
    String? username = prefs.getString('username');
    String? about = prefs.getString('about');
    String? imageBytes = prefs.getString(
      'imageBytes',
    ); // This can be null if not set
    String? email = prefs.getString('email');

    print('DEBUG: HomePage: SharedPreferences values:');
    print('DEBUG: HomePage: Username: $username');
    print('DEBUG: HomePage: About: $about');
    print(
      'DEBUG: HomePage: ImageBytes (present): ${imageBytes != null && imageBytes.isNotEmpty}',
    );
    print('DEBUG: HomePage: Mid: $mid');
    print('DEBUG: HomePage: Email: $email');

    // A profile is considered "existing" if at least MID, username, and about are present and not empty.
    // imageBytes can be optional, but if it's expected to be present, add it to the check.
    // For this fix, we'll consider a profile exists if mid, username, and about are non-null and non-empty.
    bool exists =
        mid != null &&
        mid.isNotEmpty &&
        username != null &&
        username.isNotEmpty &&
        about != null &&
        about.isNotEmpty;
    // If imageBytes is mandatory for a "complete" profile, uncomment the line below:
    // && imageBytes != null && imageBytes.isNotEmpty;

    print('DEBUG: HomePage: Profile data exists (calculated): $exists');
    return exists;
  }

  @override
  Widget build(BuildContext context) {
    final themeChanger = Provider.of<ThemeChanger>(context);
    final currentColors = themeChanger.currentColors;
    // Moved BlocProvider to main.dart or a higher-level widget for proper context
    // It's still here for demonstration, but ideally it should be higher.
    return Scaffold(
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
              child: Icon(Icons.home, size: 35, color: Color(0xFF334EFF)),
            ),
            Container(
              margin: EdgeInsets.only(bottom: 10),
              child: FloatingActionButton(
                onPressed: () async {
                  bool b = await _checkProfileDataExists();
                  print(
                    'DEBUG: HomePage: FloatingActionButton pressed. Profile data exists: $b',
                  );
                  if (b == true) {
                    Navigator.of(context).push(
                      MaterialPageRoute(
                        builder: (context) => CategoryGridScreen(),
                      ),
                    );
                  } else {
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
                                    color:
                                        (currentColors.whiteCol ==
                                                Color.fromARGB(255, 27, 27, 27))
                                            ? Colors.white54
                                            : Colors.black38,
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
                  }
                },
                splashColor: Colors.transparent,
                backgroundColor: Color(0xFF334EFF),
                child: Icon(Icons.add, size: 30, color: Colors.white),
              ),
              width: 50,
              height: 50,
            ),
            GestureDetector(
              onTap: () async {
                bool profileExists = await _checkProfileDataExists();
                print(
                  'DEBUG: HomePage: Profile icon tapped. Profile data exists: $profileExists',
                );
                if (profileExists) {
                  Navigator.of(context).push(
                    MaterialPageRoute(
                      builder: (context) => const ProfileView(),
                    ),
                  );
                } else {
                  Navigator.of(context).push(
                    MaterialPageRoute(
                      builder: (context) => const ProfileMessage(),
                    ),
                  );
                }
              },
              child: Icon(Icons.person, size: 35, color: Color(0xFFA7A7A7)),
            ),
          ],
        ),
      ),
      appBar: AppBar(
        toolbarHeight: 80,
        surfaceTintColor:
            (currentColors.backgroundGrey == Colors.white)
                ? Colors.white
                : const Color.fromARGB(255, 27, 27, 27),
        backgroundColor:
            (currentColors.backgroundGrey == Colors.white)
                ? Colors.white
                : const Color.fromARGB(255, 27, 27, 27),
        automaticallyImplyLeading: false,
        title: Container(
          margin: EdgeInsets.only(top: 25),
          decoration: BoxDecoration(
            color:
                (currentColors.backgroundGrey == Colors.white)
                    ? Color(0xFFF4F4F4)
                    : const Color.fromARGB(255, 20, 20, 20),
            borderRadius: BorderRadius.all(Radius.circular(2033)),
          ),
          child: GestureDetector(
            onTap: () {
              Navigator.of(
                context,
              ).push(MaterialPageRoute(builder: (context) => SearchView()));
            },
            child: TextField(
              enabled: false,
              decoration: InputDecoration(
                hintText: 'Искать статьи',
                border: InputBorder.none,
                prefixIcon: Icon(
                  Icons.search,
                  color:
                      (currentColors.backgroundGrey == Colors.white)
                          ? Colors.black54
                          : Colors.white24,
                ),
              ),
            ),
          ),
        ),
      ),
      body: RefreshIndicator(
        onRefresh: () async {
          // When refreshing, reload articles based on current selections
          BlocProvider.of<ArticleBloc>(
            context,
          ).add(LoadArticles(categories: _selectedCategories.toList()));
          // Wait for the bloc to update before finishing the refresh.
          // A more robust way to wait for BLoC completion would be to listen to the BLoC state changes.
          await Future.delayed(
            Duration(milliseconds: 100),
          ); // Add a small delay.
        },
        child: BlocBuilder<ArticleBloc, ArticleState>(
          builder: (context, state) {
            if (state is ArticlesLoading) {
              return buildShimmerList(context);
            } else if (state is ArticlesLoaded) {
              return ListView(
                children: [
                  SizedBox(
                    width: MediaQuery.of(context).size.width,
                    height: 125,
                    child: ListView.builder(
                      scrollDirection: Axis.horizontal,
                      itemCount:
                          categories.length + 1, // +1 for "All Categories" card
                      itemBuilder: (BuildContext context, int index) {
                        if (index == categories.length) {
                          // This is the last item, build the "All Categories" card
                          final bool isSelected = _selectedCategories.isEmpty;
                          return GestureDetector(
                            onTap: _onAllCategoriesTapped,
                            child: Container(
                              width: 140,
                              height: 135,
                              margin: EdgeInsets.all(10),
                              padding: EdgeInsets.only(left: 20, right: 20),
                              decoration: BoxDecoration(
                                color:
                                    isSelected
                                        ? Color(0xFF334EFF)
                                        : (currentColors.backgroundGrey ==
                                            Colors.white)
                                        ? Color(0xFFF4F4F4)
                                        : const Color.fromARGB(255, 20, 20, 20),
                                borderRadius: BorderRadius.all(
                                  Radius.circular(10),
                                ),
                              ),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Padding(
                                    padding: const EdgeInsets.only(top: 8.0),
                                    child: Icon(
                                      Icons.list_alt,
                                      size: 72,
                                      color:
                                          isSelected
                                              ? Colors.white
                                              : (currentColors.backgroundGrey ==
                                                  Colors.white)
                                              ? Colors.black
                                              : Colors.white,
                                    ),
                                  ),
                                  Text(
                                    "Все категории",
                                    overflow: TextOverflow.ellipsis,
                                    style: GoogleFonts.geologica(
                                      color:
                                          isSelected
                                              ? Colors.white
                                              : (currentColors.backgroundGrey ==
                                                  Colors.white)
                                              ? Colors.black
                                              : Colors.white,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          );
                        }

                        // Regular category card
                        final category = categories[index];
                        final categoryName = category['name']?.toString() ?? '';
                        final isSelected = _selectedCategories.contains(
                          categoryName,
                        );
                        return GestureDetector(
                          onTap: () => _onCategoryTapped(categoryName),
                          child: Container(
                            width: 140,
                            height: 135,
                            margin: EdgeInsets.all(10),
                            padding: EdgeInsets.only(left: 20, right: 20),
                            decoration: BoxDecoration(
                              // Change color based on selection
                              color:
                                  isSelected
                                      ? Color(0xFF334EFF)
                                      : (currentColors.backgroundGrey ==
                                          Colors.white)
                                      ? Color(0xFFF4F4F4)
                                      : const Color.fromARGB(255, 20, 20, 20),
                              borderRadius: BorderRadius.all(
                                Radius.circular(10),
                              ),
                            ),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Image.network(
                                  category['image']?.toString() ?? '',
                                  width: 80,
                                  height: 80,
                                  errorBuilder: (context, error, stackTrace) {
                                    return SvgPicture.asset(
                                      'assets/placeholder.svg',
                                      width: 80,
                                      height: 80,
                                    );
                                  },
                                ),
                                Text(
                                  categoryName,
                                  overflow: TextOverflow.ellipsis,
                                  style: GoogleFonts.geologica(
                                    // Change text color based on selection
                                    color:
                                        isSelected
                                            ? Colors.white
                                            : (currentColors.backgroundGrey ==
                                                Color.fromARGB(255, 27, 27, 27))
                                            ? Colors
                                                .white // Dark theme text
                                            : Colors.black, // Light theme text
                                  ),
                                ),
                              ],
                            ),
                          ),
                        );
                      },
                    ),
                  ),
                  Container(
                    margin: EdgeInsets.all(10),
                    child: Text(
                      "Лента",
                      style: GoogleFonts.geologica(fontSize: 32),
                    ),
                  ),
                  ListView.builder(
                    shrinkWrap: true,
                    physics: NeverScrollableScrollPhysics(),
                    itemCount: state.articles.length,
                    itemBuilder: (context, index) {
                      final article = state.articles[index];
                      return GestureDetector(
                        onTap: () {
                          Navigator.of(context).push(
                            MaterialPageRoute(
                              builder:
                                  (context) => ArticleDetail(
                                    midAuthor: article.midAuthor!,
                                    title: article.title,
                                    articleId: article.id,
                                    category: article.category!,
                                    author: article.author,
                                    content: article.content,
                                    image: article.image,
                                    formattedDate:
                                        article
                                            .formattedCreatedAt, // Pass correct data
                                    time:
                                        '', // Assuming time is part of formattedCreatedAt or not needed
                                    authorImage:
                                        '', // Pass actual author image if available
                                  ),
                            ),
                          );
                        },
                        child: Container(
                          margin: EdgeInsets.all(10),
                          padding: EdgeInsets.all(10),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              ClipRRect(
                                borderRadius: BorderRadius.circular(8),
                                child: Image.network(
                                  article.image,
                                  width: double.infinity,
                                  height: 200,
                                  fit: BoxFit.cover,
                                  errorBuilder: (context, error, stackTrace) {
                                    return SvgPicture.asset(
                                      'assets/placeholder.svg', // Placeholder for article image
                                      width: double.infinity,
                                      height: 200,
                                      fit: BoxFit.cover,
                                    );
                                  },
                                ),
                              ),
                              SizedBox(height: 8),
                              Text(
                                article.title.toString(),
                                style: GoogleFonts.geologica(fontSize: 18),
                              ),
                              SizedBox(height: 4),
                              Text(
                                article.content,
                                maxLines: 2,
                                overflow: TextOverflow.ellipsis,
                                style: GoogleFonts.geologica(),
                              ),
                              SizedBox(height: 8),
                              Text(
                                article.formattedCreatedAt,
                                style: GoogleFonts.geologica(
                                  fontSize: 18,
                                  color: Colors.grey,
                                ),
                              ),
                            ],
                          ),
                        ),
                      );
                    },
                  ),
                ],
              );
            } else if (state is ArticlesLoadError) {
              return Padding(
                padding: const EdgeInsets.all(10.0),
                child: Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    crossAxisAlignment: CrossAxisAlignment.center,
                    children: [
                      SvgPicture.asset(
                        'assets/nowifi.svg',
                        width: 200,
                        height: 200,
                      ), // Ensure this path is correct
                      SizedBox(height: 10),
                      Text(
                        "Ошибка подключения к базе данных",
                        style: GoogleFonts.geologica(
                          fontSize: 24,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      SizedBox(height: 8),
                      Text(
                        "Пожалуйста, проверьте свое интернет соединение, и попробуйте снова",
                        style: GoogleFonts.geologica(
                          color: currentColors.textBlack,
                        ),
                      ),
                      SizedBox(height: 8),
                      GestureDetector(
                        onTap: () {
                          // Reload articles with current filters on retry
                          BlocProvider.of<ArticleBloc>(context).add(
                            LoadArticles(
                              categories: _selectedCategories.toList(),
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
                              "Попробовать снова",
                              style: GoogleFonts.geologica(
                                color: Colors.white,
                                fontSize: 16,
                              ),
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              );
            } else {
              return Center(child: CircularProgressIndicator());
            }
          },
        ),
      ),
    );
  }
}

Widget buildShimmerList(BuildContext context) {
  return ListView(
    children: [
      SizedBox(
        width: MediaQuery.of(context).size.width,
        height: 125,
        child: ListView.builder(
          scrollDirection: Axis.horizontal,
          itemCount: 2,
          itemBuilder: (BuildContext context, int index) {
            return Container(
              width: 140,
              height: 135,
              margin: EdgeInsets.all(10),
              padding: EdgeInsets.only(left: 20, right: 20),
              child: Shimmer.fromColors(
                baseColor: Colors.grey[300]!,
                highlightColor: Colors.grey[100]!,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Container(
                      width: 100,
                      height: 60,
                      color: Colors.white, // Placeholder for image
                      margin: EdgeInsets.only(top: 10, bottom: 8),
                    ),
                    Container(
                      width: 80,
                      height: 12,
                      color: Colors.white, // Placeholder for text
                    ),
                  ],
                ),
              ),
            );
          },
        ),
      ),
      Padding(
        padding: const EdgeInsets.all(10.0),
        child: Shimmer.fromColors(
          baseColor: Colors.grey[300]!,
          highlightColor: Colors.grey[100]!,
          child: Container(
            width: 30,
            height: 10,
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.all(Radius.circular(20000)),
            ),
          ),
        ),
      ),
      ListView.builder(
        shrinkWrap: true,
        physics: NeverScrollableScrollPhysics(),
        itemCount: 1, // Примерное количество элементов в ленте
        itemBuilder: (context, index) {
          return Padding(
            padding: const EdgeInsets.all(10.0),
            child: Shimmer.fromColors(
              baseColor: Colors.grey[300]!,
              highlightColor: Colors.grey[100]!,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Container(
                    width: double.infinity,
                    height: 200,
                    color: Colors.white, // Placeholder for image
                  ),
                  SizedBox(height: 8),
                  Container(
                    width: 150,
                    height: 16,
                    color: Colors.white, // Placeholder for title
                  ),
                  SizedBox(height: 4),
                  Container(
                    width: double.infinity,
                    height: 12,
                    color: Colors.white, // Placeholder for content line 1
                  ),
                  SizedBox(height: 2),
                  Container(
                    width: double.infinity * 0.8,
                    height: 12,
                    color: Colors.white, // Placeholder for content line 2
                  ),
                  SizedBox(height: 8),
                  Container(
                    width: 80,
                    height: 10,
                    color: Colors.white, // Placeholder for date
                  ),
                ],
              ),
            ),
          );
        },
      ),
    ],
  );
}
