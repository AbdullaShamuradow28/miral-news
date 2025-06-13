import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:miral_news/features/account_login/view/account_login.dart';
import 'package:miral_news/features/home_page/bloc/news_bloc.dart'; // Assuming Article class is here
import 'package:http/http.dart' as http;
import 'package:miral_news/features/home_page/view/homepage.dart';
import 'package:miral_news/features/post_article/view/post_category.dart';
import 'package:miral_news/features/profile_notsigned/view/profile_message.dart';
import 'package:miral_news/features/profile_signed/view/profile_view.dart';
import 'package:miral_news/theme_changer.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:shimmer/shimmer.dart'; // Import shimmer
import 'package:provider/provider.dart';

// Assuming your Article model is defined similarly to this in news_bloc.dart or a separate model file
// If it's not, you'll need to define it or adjust the code to match your Article model.
/*
class Article {
  final String id;
  final String title;
  final String content;
  final String image;
  final String author;
  final String formattedCreatedAt;
  final String? category; // Make category nullable if it can be missing

  Article({
    required this.id,
    required this.title,
    required this.content,
    required this.image,
    required this.author,
    required this.formattedCreatedAt,
    this.category,
  });

  factory Article.fromJson(Map<String, dynamic> json) {
    return Article(
      id: json['_id'] as String,
      title: json['title'] as String,
      content: json['content'] as String,
      image: json['image'] as String,
      author: json['author'] as String,
      formattedCreatedAt: json['formattedCreatedAt'] as String,
      category: json['category'] as String?,
    );
  }
}
*/

enum SortOrder { newestToOldest, oldestToNewest }

class SearchResults extends StatefulWidget {
  final String searchQuery; // New: Accept a search query

  const SearchResults({Key? key, required this.searchQuery}) : super(key: key);

  @override
  State<SearchResults> createState() => _SearchResultsState();
}

class _SearchResultsState extends State<SearchResults> {
  List<Article> _searchResults = [];
  bool _isLoading = false;
  String? _error;
  String _apiUrl =
      "http://192.168.1.109:3000"; // Ensure this matches your API URL
  SortOrder _currentSortOrder = SortOrder.newestToOldest; // Default sort order

  // Add a TextEditingController to control the search text field
  late TextEditingController _searchController;

  @override
  void initState() {
    super.initState();
    _searchController = TextEditingController(text: widget.searchQuery);
    _fetchSearchResults();
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
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  // Method to fetch search results
  Future<void> _fetchSearchResults() async {
    setState(() {
      _isLoading = true;
      _error = null;
      _searchResults.clear();
    });

    try {
      final response = await http.get(
        Uri.parse(
          '$_apiUrl/search?query=${Uri.encodeComponent(widget.searchQuery)}',
        ),
      );

      if (response.statusCode == 200) {
        final List<dynamic> decodedResponse = json.decode(response.body);
        setState(() {
          _searchResults =
              decodedResponse.map((json) => Article.fromJson(json)).toList();
          _sortArticles(_currentSortOrder); // Apply initial sort
          _isLoading = false;
        });
      } else {
        setState(() {
          _error = 'Не удалось найти статьи: ${response.statusCode}';
          _isLoading = false;
        });
      }
    } catch (e) {
      setState(() {
        _error = 'Ошибка при поиске статей: $e';
        _isLoading = false;
      });
    }
  }

  // Method to sort articles based on the selected order
  void _sortArticles(SortOrder order) {
    setState(() {
      _currentSortOrder = order;
      if (order == SortOrder.newestToOldest) {
        _searchResults.sort(
          (a, b) => b.formattedCreatedAt.compareTo(a.formattedCreatedAt),
        ); // Assuming formattedCreatedAt is sortable
      } else {
        _searchResults.sort(
          (a, b) => a.formattedCreatedAt.compareTo(b.formattedCreatedAt),
        ); // Assuming formattedCreatedAt is sortable
      }
    });
  }

  // Shimmer effect for loading articles
  Widget _buildShimmerSearchResults() {
    return ListView.builder(
      itemCount: 3, // Show a few shimmer items
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
                const SizedBox(height: 8),
                Container(
                  width: 150,
                  height: 16,
                  color: Colors.white, // Placeholder for title
                ),
                const SizedBox(height: 4),
                Container(
                  width: double.infinity,
                  height: 12,
                  color: Colors.white, // Placeholder for content line 1
                ),
                const SizedBox(height: 2),
                Container(
                  width: MediaQuery.of(context).size.width * 0.8,
                  height: 12,
                  color: Colors.white, // Placeholder for content line 2
                ),
                const SizedBox(height: 8),
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
    );
  }

  @override
  Widget build(BuildContext context) {
    final themeChanger = Provider.of<ThemeChanger>(context);
    final currentColors = themeChanger.currentColors;
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

        automaticallyImplyLeading: false, // Keep back button
        title: Container(
          margin: const EdgeInsets.only(top: 10), // Adjust margin as needed
          decoration: BoxDecoration(
            color:
                (currentColors.backgroundGrey == Colors.white)
                    ? Color(0xFFF4F4F4)
                    : const Color.fromARGB(255, 20, 20, 20),
            borderRadius: BorderRadius.all(Radius.circular(2033)),
          ),
          child: TextField(
            controller: _searchController, // Use the controller
            onSubmitted: (newQuery) {
              // Handle new search query submission from AppBar
              if (newQuery.isNotEmpty && newQuery != widget.searchQuery) {
                Navigator.of(context).pushReplacement(
                  MaterialPageRoute(
                    builder: (context) => SearchResults(searchQuery: newQuery),
                  ),
                );
              }
            },
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
      body:
          _isLoading
              ? _buildShimmerSearchResults() // Show shimmer while loading
              : _error != null
              ? Center(
                child: Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Text(
                    _error!,
                    style: const TextStyle(color: Colors.red),
                    textAlign: TextAlign.center,
                  ),
                ),
              )
              : Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Padding(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 16.0,
                      vertical: 8.0,
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          'Показано ${_searchResults.length} результатов',
                          style: GoogleFonts.geologica(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        GestureDetector(
                          onTap: () {
                            showModalBottomSheet(
                              context: context,
                              builder: (BuildContext context) {
                                return Container(
                                  padding: EdgeInsets.all(20),
                                  child: Column(
                                    mainAxisSize: MainAxisSize.min,
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        'Сортировать по',
                                        style: GoogleFonts.geologica(
                                          fontSize: 20,
                                          fontWeight: FontWeight.bold,
                                        ),
                                      ),
                                      const SizedBox(height: 15),
                                      ListTile(
                                        title: Text(
                                          'Новые сначала',
                                          style: GoogleFonts.geologica(),
                                        ),
                                        trailing:
                                            _currentSortOrder ==
                                                    SortOrder.newestToOldest
                                                ? Icon(
                                                  Icons.check,
                                                  color: Color(0xFF334EFF),
                                                )
                                                : null,
                                        onTap: () {
                                          _sortArticles(
                                            SortOrder.newestToOldest,
                                          );
                                          Navigator.pop(context);
                                        },
                                      ),
                                      ListTile(
                                        title: Text(
                                          'Старые сначала',
                                          style: GoogleFonts.geologica(),
                                        ),
                                        trailing:
                                            _currentSortOrder ==
                                                    SortOrder.oldestToNewest
                                                ? Icon(
                                                  Icons.check,
                                                  color: Color(0xFF334EFF),
                                                )
                                                : null,
                                        onTap: () {
                                          _sortArticles(
                                            SortOrder.oldestToNewest,
                                          );
                                          Navigator.pop(context);
                                        },
                                      ),
                                    ],
                                  ),
                                );
                              },
                            );
                          },
                          child: Row(
                            children: [
                              Text(
                                'Сортировать',
                                style: GoogleFonts.geologica(
                                  fontSize: 16,
                                  color: Color(0xFF334EFF),
                                ),
                              ),
                              Icon(Icons.sort, color: Color(0xFF334EFF)),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                  _searchResults.isEmpty
                      ? Expanded(
                        child: Center(
                          child: Text(
                            'Нет статей, соответствующих вашему запросу "${widget.searchQuery}".',
                            style: GoogleFonts.geologica(
                              color: Colors.grey,
                              fontSize: 16,
                            ),
                            textAlign: TextAlign.center,
                          ),
                        ),
                      )
                      : Expanded(
                        child: ListView.builder(
                          itemCount: _searchResults.length,
                          itemBuilder: (context, index) {
                            final article = _searchResults[index];
                            return GestureDetector(
                              onTap: () {
                                // TODO: Implement navigation to the full article view
                                // Example of navigation to ArticleDetail (assuming you have it)
                                // Make sure to pass all necessary data to ArticleDetail
                                /*
                                      Navigator.of(context).push(
                                        MaterialPageRoute(
                                          builder: (context) => ArticleDetail(
                                            title: article.title,
                                            articleId: article.id,
                                            category: article.category!,
                                            author: article.author,
                                            content: article.content,
                                            image: article.image,
                                            formattedDate: article.formattedCreatedAt,
                                            time: '', // Adjust as per your ArticleDetail needs
                                            authorImage: '', // Adjust as per your ArticleDetail needs
                                          ),
                                        ),
                                      );
                                      */
                                ScaffoldMessenger.of(context).showSnackBar(
                                  SnackBar(
                                    content: Text(
                                      'Просмотр статьи: ${article.title}',
                                    ),
                                  ),
                                );
                              },
                              child: Container(
                                margin: const EdgeInsets.all(10),
                                padding: const EdgeInsets.all(10),
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
                                        errorBuilder: (
                                          context,
                                          error,
                                          stackTrace,
                                        ) {
                                          return Container(
                                            width: double.infinity,
                                            height: 200,
                                            color: Colors.grey[200],
                                            child: const Icon(
                                              Icons.broken_image,
                                              color: Colors.grey,
                                            ),
                                          );
                                        },
                                      ),
                                    ),
                                    const SizedBox(height: 8),
                                    Text(
                                      article.title,
                                      style: GoogleFonts.geologica(
                                        fontSize: 18,
                                      ),
                                    ),
                                    const SizedBox(height: 4),
                                    Text(
                                      article.content,
                                      maxLines: 2,
                                      overflow: TextOverflow.ellipsis,
                                      style: GoogleFonts.geologica(),
                                    ),
                                    const SizedBox(height: 8),
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
                      ),
                ],
              ),
    );
  }
}
