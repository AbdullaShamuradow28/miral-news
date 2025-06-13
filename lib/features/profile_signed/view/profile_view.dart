import 'dart:convert';
import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:miral_news/theme_changer.dart';
import 'package:provider/provider.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:http/http.dart' as http;
import 'package:miral_news/features/article_detail/view/article_detail.dart';
import 'package:miral_news/features/home_page/view/homepage.dart';
import 'package:miral_news/features/profile_edit/view/profile_edit.dart';
import 'package:miral_news/features/profile_notsigned/view/profile_message.dart';
import 'package:miral_news/features/settings/view/settings.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:miral_news/features/post_article/view/post_category.dart'; // Import for CategoryGridScreen
import 'package:miral_news/features/account_login/view/account_login.dart'; // Import for AccountLogin

// Enum to define the different display modes for articles
enum ArticleDisplayMode { list, grid }

class ProfileView extends StatefulWidget {
  const ProfileView({super.key});

  @override
  State<ProfileView> createState() => _ProfileViewState();
}

class _ProfileViewState extends State<ProfileView> {
  String? username;
  String? about;
  Uint8List?
  _imageBytesFromPrefs; // Stores image bytes if loaded from SharedPreferences (for newly picked local images)
  String?
  _profileImageUrl; // Stores URL of existing profile picture from backend
  String? mid;
  String? email;
  String profileApiBaseUrl = "http://192.168.1.109:3001/api/profiles";
  String articlesApiUrl = "http://192.168.1.109:3000/"; // URL for articles API
  List<dynamic> _userArticles = [];
  bool _isLoading = true;
  String _errorMessage = '';

  ArticleDisplayMode _displayMode = ArticleDisplayMode.list;

  @override
  void initState() {
    super.initState();
    _loadProfileAndArticles();
  }

  // Combined function to load profile data and articles
  Future<void> _loadProfileAndArticles() async {
    setState(() {
      _isLoading = true;
      _errorMessage = '';
    });
    await _loadProfileData(); // Load profile data first
    await getArticlesCreatedByAuthor(); // Then load articles
    setState(() {
      _isLoading = false; // Set loading to false after all data is fetched
    });
  }

  // Fetches articles created by the logged-in author
  Future<void> getArticlesCreatedByAuthor() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    final authorMid = prefs.getString('mid');

    if (authorMid == null || authorMid.isEmpty) {
      setState(() {
        _errorMessage =
            'Пользователь не авторизован или MID отсутствует. Невозможно загрузить статьи.';
      });
      return;
    }

    try {
      final Uri uri = Uri.parse(articlesApiUrl);
      final response = await http.get(uri);

      if (response.statusCode == 200) {
        final List<dynamic> allArticles = json.decode(response.body);
        setState(() {
          _userArticles =
              allArticles
                  .where((article) => article['author'] == authorMid)
                  .toList();
        });
      } else {
        setState(() {
          _errorMessage = 'Не удалось загрузить статьи: ${response.statusCode}';
        });
        print(
          'DEBUG: ProfileView:getArticlesCreatedByAuthor: Failed to fetch articles: ${response.statusCode}',
        );
      }
    } catch (e) {
      setState(() {
        _errorMessage = 'Ошибка загрузки статей: $e';
      });
      print(
        'DEBUG: ProfileView:getArticlesCreatedByAuthor: Error fetching articles: $e',
      );
    }
  }

  // Loads profile data from API or SharedPreferences
  Future<void> _loadProfileData() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    final storedMid = prefs.getString('mid');

    // If _profileImageUrl is null and storedMid exists, attempt to fetch from API
    // This block was already attempting to get the image URL from the API first.
    if (_profileImageUrl == null && storedMid != null) {
      final url = Uri.parse(
        'http://192.168.1.109:3001/api/profiles/get_by_mid/$storedMid',
      );

      try {
        final response = await http.post(url);

        if (response.statusCode == 200) {
          final data = json.decode(response.body);

          if (data != null && data['profile_picture_url'] != null) {
            setState(() {
              _profileImageUrl = data['profile_picture_url'];
              _imageBytesFromPrefs =
                  null; // Clear local bytes if URL is from server
              print(
                "DEBUG: ProfileView:_loadProfileData: Image URL loaded from API.",
              );
            });
          }
        } else {
          print('Ошибка при получении данных профиля: ${response.statusCode}');
        }
      } catch (e) {
        print('Ошибка запроса: $e');
      }
    }

    if (storedMid == null || storedMid.isEmpty) {
      setState(() {
        username = 'Нет данных';
        about = 'Нет описания';
        _imageBytesFromPrefs = null;
        _profileImageUrl = null;
        mid = null;
        email = null;
        _errorMessage = 'Пользователь не авторизован. Войдите в систему.';
      });
      print(
        'DEBUG: ProfileView:_loadProfileData: MID not found in SharedPreferences. Profile cannot be loaded.',
      );
      return;
    }

    // Try to load image from SharedPreferences first (for newly picked local images)
    String? imageBytesString = prefs.getString('imageBytes');
    if (imageBytesString != null && imageBytesString.isNotEmpty) {
      try {
        _imageBytesFromPrefs = base64Decode(imageBytesString);
        _profileImageUrl = null; // Clear URL if loading from base64 in prefs
        print(
          "DEBUG: ProfileView:_loadProfileData: Image bytes loaded from SharedPreferences (priority). Size: ${_imageBytesFromPrefs?.lengthInBytes} bytes",
        );
      } catch (e) {
        print(
          "DEBUG: ProfileView:_loadProfileData: Error decoding image from SharedPreferences: $e",
        );
        _imageBytesFromPrefs = null;
      }
    } else {
      _imageBytesFromPrefs = null;
    }

    // Attempt to fetch from server (even if image bytes were found, as server has priority for URL)
    try {
      final String profileGetUrl = '$profileApiBaseUrl/$storedMid/';
      print(
        'DEBUG: ProfileView:_loadProfileData: Attempting to load profile from server for MID: $storedMid at URL: $profileGetUrl',
      );
      final response = await http.get(Uri.parse(profileGetUrl));

      if (response.statusCode == 200) {
        final Map<String, dynamic> profileData = json.decode(response.body);
        setState(() {
          username =
              '${profileData['first_name'] ?? ''} ${profileData['last_name'] ?? ''}'
                  .trim();
          about = profileData['about_me']?.toString();
          email = prefs.getString('email');
          mid = storedMid;

          String? imageUrl = profileData['profile_picture_url']?.toString();
          if (imageUrl != null && imageUrl.isNotEmpty) {
            _profileImageUrl = imageUrl;
            // If we get an image URL from the server, it overrides any locally stored image bytes
            _imageBytesFromPrefs = null;
            print(
              "DEBUG: ProfileView:_loadProfileData: Image URL loaded from server: $_profileImageUrl",
            );
          }
        });
        await prefs.setString('username', username ?? '');
        await prefs.setString('about', about ?? '');
        // If a profile image URL is received from the server, store it as well
        if (_profileImageUrl != null) {
          await prefs.setString('profileImageUrl', _profileImageUrl!);
        } else {
          // If no URL from server, ensure old URL is cleared
          await prefs.remove('profileImageUrl');
        }
        print(
          'DEBUG: ProfileView:_loadProfileData: Profile loaded from server.',
        );
        return;
      } else if (response.statusCode == 404) {
        print(
          'DEBUG: ProfileView:_loadProfileData: Profile not found on server for MID: $storedMid. Checking SharedPreferences for remaining data.',
        );
      } else {
        print(
          'DEBUG: ProfileView:_loadProfileData: Server error ${response.statusCode} when loading profile: ${response.body}. Checking SharedPreferences for remaining data.',
        );
      }
    } catch (e) {
      print(
        'DEBUG: ProfileView:_loadProfileData: Network error loading profile from server: $e. Checking SharedPreferences for remaining data.',
      );
    }

    // Fallback: Load from SharedPreferences if server fetch fails or no profile found
    // (This part will only execute if the server request failed or returned 404,
    // or if the server response didn't contain a profile picture URL)
    setState(() {
      username = prefs.getString('username');
      about = prefs.getString('about');
      email = prefs.getString('email');
      mid = storedMid;

      // If no image bytes were loaded initially, and no image URL from server,
      // then check for a stored image URL in SharedPreferences.
      if (_imageBytesFromPrefs == null && _profileImageUrl == null) {
        String? storedImageUrl = prefs.getString('profileImageUrl');
        if (storedImageUrl != null && storedImageUrl.isNotEmpty) {
          _profileImageUrl = storedImageUrl;
          print(
            "DEBUG: ProfileView:_loadProfileData: Image URL loaded from SharedPreferences (fallback).",
          );
        } else {
          _profileImageUrl = null;
        }
      }
    });
    print(
      'DEBUG: ProfileView:_loadProfileData: Profile data loaded from SharedPreferences (fallback/supplemental).',
    );
  }

  // Checks if all required profile data exists in SharedPreferences
  Future<bool> _checkProfileDataExists() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    bool exists =
        prefs.containsKey('username') &&
        prefs.containsKey('about') &&
        prefs.containsKey('mid') &&
        prefs.containsKey('email');
    return exists;
  }

  // Widget to build an article item in list view
  Widget _buildArticleListItem(Map<String, dynamic> article) {
    return GestureDetector(
      onTap: () {
        Navigator.of(context).push(
          MaterialPageRoute(
            builder:
                (context) => ArticleDetail(
                  midAuthor: article['midAuthor'] ?? '',
                  articleId: article['id'],
                  title: article['title']?.toString() ?? '',
                  category: article['category'],
                  author: article['author']?.toString() ?? '',
                  content: article['content']?.toString() ?? '',
                  image: article['image']?.toString() ?? '',
                  formattedDate:
                      article['formatted_created_at']?.split(' ').first ?? '',
                  time: article['formatted_created_at']?.split(' ').last ?? '',
                  authorImage: '', // Assuming no author image in this response
                ),
          ),
        );
      },
      child: Container(
        margin: const EdgeInsets.symmetric(vertical: 8.0, horizontal: 16.0),
        padding: const EdgeInsets.all(10),
        decoration: BoxDecoration(
          // color: Colors.white,
          borderRadius: BorderRadius.circular(8),
          // boxShadow: [
          //   BoxShadow(
          //     color: Colors.grey.withOpacity(0.1),
          //     spreadRadius: 1,
          //     blurRadius: 5,
          //     offset: const Offset(0, 3), // changes position of shadow
          //   ),
          // ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            ClipRRect(
              borderRadius: BorderRadius.circular(8),
              child: Image.network(
                article['image']?.toString() ?? '',
                width: double.infinity,
                height: 200,
                fit: BoxFit.cover,
                errorBuilder: (context, error, stackTrace) {
                  return SizedBox(
                    width: double.infinity,
                    height: 200,
                    child: const Center(
                      child: Icon(
                        Icons.image_not_supported,
                        size: 60,
                        color: Colors.grey,
                      ),
                    ),
                  );
                },
              ),
            ),
            const SizedBox(height: 8),
            Text(
              article['title']?.toString() ?? 'No Title',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 4),
            Text(
              article['content']?.toString() ?? 'No Content',
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(fontSize: 14, color: Colors.grey[700]),
            ),
            const SizedBox(height: 8),
            Text(
              article['formatted_created_at']?.toString() ?? 'No Date',
              style: TextStyle(fontSize: 12, color: Colors.grey),
            ),
          ],
        ),
      ),
    );
  }

  // Widget to build an article item in grid view
  Widget _buildArticleGridItem(Map<String, dynamic> article) {
    return GestureDetector(
      onTap: () {
        Navigator.of(context).push(
          MaterialPageRoute(
            builder:
                (context) => ArticleDetail(
                  midAuthor: article['midAuthor'],
                  title: article['title']?.toString() ?? '',
                  articleId: article['id'],
                  category: article['category'],
                  author: article['author']?.toString() ?? '',
                  content: article['content']?.toString() ?? '',
                  image: article['image']?.toString() ?? '',
                  formattedDate:
                      article['formatted_created_at']?.split(' ').first ?? '',
                  time: article['formatted_created_at']?.split(' ').last ?? '',
                  authorImage: '', // Assuming no author image in this response
                ),
          ),
        );
      },
      child: Container(
        padding: const EdgeInsets.all(8.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            ClipRRect(
              borderRadius: BorderRadius.circular(8),
              child: Image.network(
                article['image']?.toString() ?? '',
                width: double.infinity,
                height: 120, // Smaller height for grid item
                fit: BoxFit.cover,
                errorBuilder: (context, error, stackTrace) {
                  return SizedBox(
                    width: double.infinity,
                    height: 120,
                    child: const Center(
                      child: Icon(
                        Icons.image_not_supported,
                        size: 40,
                        color: Colors.grey,
                      ),
                    ),
                  );
                },
              ),
            ),
            const SizedBox(height: 8),
            Text(
              article['title']?.toString() ?? 'No Title',
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 4),
            Text(
              article['content']?.toString() ?? 'No Content',
              maxLines: 1, // Shorter content for grid
              overflow: TextOverflow.ellipsis,
              style: TextStyle(fontSize: 10, color: Colors.grey[700]),
            ),
            const SizedBox(height: 8),
            Text(
              article['formatted_created_at']?.toString() ?? 'No Date',
              style: TextStyle(fontSize: 10, color: Colors.grey),
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final themeChanger = Provider.of<ThemeChanger>(context);
    final currentColors = themeChanger.currentColors;
    print(
      'DEBUG: ProfileView:build: _profileImageUrl: $_profileImageUrl, _imageBytesFromPrefs: ${_imageBytesFromPrefs != null ? 'present' : 'null'}',
    );
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
              child: Icon(Icons.home, size: 35, color: const Color(0xFFA7A7A7)),
            ),
            Container(
              margin: const EdgeInsets.only(bottom: 10),
              child: FloatingActionButton(
                onPressed: () async {
                  bool b = await _checkProfileDataExists();
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
                            padding: const EdgeInsets.all(20),
                            height: 210,
                            child: Column(
                              children: [
                                Text(
                                  "Упс, похоже кто-то хочет создать статью без входа в систему!",
                                  style: GoogleFonts.geologica(fontSize: 20),
                                ),
                                const SizedBox(height: 10),
                                Text(
                                  "Но так нельзя! Для того, чтобы написать статью, необходимо войти в Miral Account!",
                                  style: GoogleFonts.geologica(
                                    fontSize: 14,
                                    color: Colors.black.withOpacity(0.7),
                                  ),
                                ),
                                const SizedBox(height: 10),
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
                                      padding: const EdgeInsets.only(
                                        left: 15,
                                        right: 15,
                                        top: 5,
                                        bottom: 5,
                                      ),
                                      width: MediaQuery.of(context).size.width,
                                      height: 50,
                                      decoration: const BoxDecoration(
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
                backgroundColor: const Color(0xFF334EFF),
                child: const Icon(Icons.add, size: 30, color: Colors.white),
              ),
              width: 50,
              height: 50,
            ),
            GestureDetector(
              onTap: () async {
                Navigator.of(context).push(
                  MaterialPageRoute(builder: (context) => const ProfileView()),
                );
              },
              child: Icon(
                Icons.person,
                size: 35,
                color: const Color(0xFF334EFF),
              ),
            ),
          ],
        ),
      ),
      appBar: AppBar(
        toolbarHeight: 300,
        surfaceTintColor: currentColors.appBarBackground,
        backgroundColor: currentColors.appBarBackground,
        automaticallyImplyLeading: false,
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(0),
          child: Container(
            padding: const EdgeInsets.only(bottom: 16, left: 16, right: 16),
            alignment: Alignment.centerLeft,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisAlignment: MainAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    CircleAvatar(
                      radius: 60,
                      backgroundColor: Colors.grey[200],
                      // Safely handle image display based on what's available
                      backgroundImage:
                          _imageBytesFromPrefs != null
                              ? MemoryImage(_imageBytesFromPrefs!)
                              : (_profileImageUrl != null &&
                                  _profileImageUrl!.isNotEmpty)
                              ? NetworkImage(_profileImageUrl!)
                              : null, // No image if both are null/empty
                      child:
                          (_imageBytesFromPrefs == null &&
                                  (_profileImageUrl == null ||
                                      _profileImageUrl!.isEmpty))
                              ? const Icon(
                                Icons.person,
                                size: 60,
                                color: Colors.grey,
                              )
                              : null,
                    ),
                    GestureDetector(
                      onTap: () {
                        Navigator.of(context).push(
                          MaterialPageRoute(
                            builder: (context) => const SettingsScreen(),
                          ),
                        );
                      },
                      child: const Icon(Icons.settings_outlined, size: 32),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                Text(
                  username != null && username!.isNotEmpty
                      ? username!
                      : 'Добавить username',
                  style: GoogleFonts.geologica(
                    //color: Colors.black,
                    fontSize: 30,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                Text(
                  about != null && about!.isNotEmpty ? about! : 'Нет описания',
                  style: GoogleFonts.geologica(
                    // color: Colors.black,
                    fontSize: 15,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 10),
                GestureDetector(
                  onTap: () async {
                    await Navigator.of(context).push(
                      MaterialPageRoute(
                        builder: (context) => const ProfileEdit(),
                      ),
                    );
                    // IMPORTANT: Reload profile data after returning from ProfileEdit
                    _loadProfileAndArticles();
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
                    decoration: const BoxDecoration(
                      borderRadius: BorderRadius.all(Radius.circular(20000)),
                      color: Color(0xFFE7EAFF),
                    ),
                    child: Center(
                      child: Text(
                        "Изменить профиль",
                        style: GoogleFonts.geologica(
                          color: const Color(0xFF334EFF),
                          fontSize: 16,
                        ),
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const SizedBox(height: 8),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'Публикации',
                  style: GoogleFonts.geologica(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                Row(
                  children: [
                    GestureDetector(
                      onTap: () {
                        setState(() {
                          _displayMode = ArticleDisplayMode.list;
                        });
                      },
                      child: Icon(
                        Icons.list,
                        size: 32,
                        color:
                            _displayMode == ArticleDisplayMode.list
                                ? const Color(0xFF334EFF)
                                : Colors.grey,
                      ),
                    ),
                    const SizedBox(width: 16),
                    GestureDetector(
                      onTap: () {
                        setState(() {
                          _displayMode = ArticleDisplayMode.grid;
                        });
                      },
                      child: Icon(
                        Icons.grid_on,
                        size: 32,
                        color:
                            _displayMode == ArticleDisplayMode.grid
                                ? const Color(0xFF334EFF)
                                : Colors.grey,
                      ),
                    ),
                    const SizedBox(width: 16),
                  ],
                ),
              ],
            ),
            const SizedBox(height: 15),
            Expanded(
              child:
                  _isLoading
                      ? const Center(child: CircularProgressIndicator())
                      : _errorMessage.isNotEmpty
                      ? Center(child: Text(_errorMessage))
                      : _userArticles.isEmpty
                      ? Column(
                        crossAxisAlignment: CrossAxisAlignment.center,
                        children: [
                          const SizedBox(height: 8),
                          Text(
                            "Создайте свою первую статью",
                            style: GoogleFonts.geologica(
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            "Ваша публикация будет отображаться в профиле и будет доступна всем!",
                            style: GoogleFonts.geologica(
                              color: const Color(0xFFA7A7A7),
                              fontSize: 16,
                            ),
                            textAlign: TextAlign.center,
                          ),
                          const SizedBox(height: 8),
                          Text(
                            "Создать",
                            style: GoogleFonts.geologica(
                              color: const Color(0xFF334EFF),
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ],
                      )
                      : _displayMode == ArticleDisplayMode.list
                      ? ListView.builder(
                        itemCount: _userArticles.length,
                        itemBuilder: (context, index) {
                          final article = _userArticles[index];
                          return _buildArticleListItem(article);
                        },
                      )
                      : GridView.builder(
                        gridDelegate:
                            const SliverGridDelegateWithFixedCrossAxisCount(
                              crossAxisCount: 2,
                              crossAxisSpacing: 10,
                              mainAxisSpacing: 10,
                              childAspectRatio: 0.7,
                            ),
                        itemCount: _userArticles.length,
                        itemBuilder: (context, index) {
                          final article = _userArticles[index];
                          return _buildArticleGridItem(article);
                        },
                      ),
            ),
          ],
        ),
      ),
    );
  }
}
