import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import 'package:http/http.dart' as http;
import 'package:miral_news/features/article_detail/view/article_detail.dart';
import 'package:miral_news/features/profile_edit/view/profile_edit.dart'; // Import ProfileEdit
import 'package:miral_news/features/settings/view/settings.dart'; // Import SettingsScreen
import 'package:miral_news/theme_changer.dart';
import 'package:shared_preferences/shared_preferences.dart'; // Import shared_preferences
import 'package:miral_news/features/account_login/view/account_login.dart'; // Import AccountLogin

// Enum to define the different display modes for articles
enum ArticleDisplayMode { list, grid }

class AuthorProfileView extends StatefulWidget {
  final String authorMid; // The MID of the author whose profile to display

  const AuthorProfileView({super.key, required this.authorMid});

  @override
  State<AuthorProfileView> createState() => _AuthorProfileViewState();
}

class _AuthorProfileViewState extends State<AuthorProfileView> {
  String? username;
  String? about;
  String?
  _profileImageUrl; // Stores URL of existing profile picture from backend
  String?
  currentLoggedInUserMid; // To store the MID of the currently logged-in user

  String profileApiBaseUrl =
      "http://192.168.1.109:3001/api/profiles/get_by_mid/";
  String articlesApiUrl = "http://192.168.1.109:3000/"; // URL for articles API
  List<dynamic> _userArticles = [];
  bool _isLoading = true;
  String _errorMessage = '';

  // Переменные для счетчиков (предположим, что они приходят из API профиля)
  int _subscriptionsCount = 0; // Количество подписок
  int _subscribersCount = 0; // Количество подписчиков

  ArticleDisplayMode _displayMode = ArticleDisplayMode.list;

  @override
  void initState() {
    super.initState();
    _initProfileData();
  }

  // Initializes user MID and then loads profile and articles
  Future<void> _initProfileData() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    setState(() {
      currentLoggedInUserMid = prefs.getString('mid');
    });
    await _loadAuthorProfileAndArticles();
  }

  // Combined function to load author profile data and their articles
  Future<void> _loadAuthorProfileAndArticles() async {
    setState(() {
      _isLoading = true;
      _errorMessage = '';
    });
    await _loadAuthorProfileData(); // Load profile data first
    await _fetchArticles(); // Then load articles
    setState(() {
      _isLoading = false; // Set loading to false after all data is fetched
    });
  }

  // Fetches all articles and filters by author
  Future<void> _fetchArticles() async {
    if (widget.authorMid.isEmpty) {
      setState(() {
        _errorMessage = 'MID автора отсутствует. Невозможно загрузить статьи.';
      });
      return;
    }

    try {
      final Uri uri = Uri.parse(articlesApiUrl);
      final response = await http.get(uri);

      if (response.statusCode == 200) {
        final List<dynamic> allFetchedArticles = json.decode(
          utf8.decode(response.bodyBytes),
        ); // Decode UTF-8

        setState(() {
          // Filter articles by author's MID
          _userArticles =
              allFetchedArticles
                  .where((article) => article['authorMid'] == widget.authorMid)
                  .toList();
        });
      } else {
        setState(() {
          _errorMessage = 'Не удалось загрузить статьи: ${response.statusCode}';
        });
        print(
          'DEBUG: AuthorProfileView:_fetchArticles: Failed to fetch articles: ${response.statusCode}',
        );
      }
    } catch (e) {
      setState(() {
        _errorMessage = 'Ошибка загрузки статей: $e';
      });
      print(
        'DEBUG: AuthorProfileView:_fetchArticles: Error fetching articles: $e',
      );
    }
  }

  // Loads profile data for the specific author from API
  Future<void> _loadAuthorProfileData() async {
    final url = Uri.parse(
      '$profileApiBaseUrl${widget.authorMid}',
    ); // No trailing slash needed here for get_by_mid

    try {
      print(
        'DEBUG: AuthorProfileView:_loadAuthorProfileData: Attempting to load profile for MID: ${widget.authorMid} at URL: $url',
      );
      final response = await http.get(url);

      if (response.statusCode == 200) {
        final Map<String, dynamic> profileData = json.decode(
          utf8.decode(response.bodyBytes),
        ); // Decode UTF-8
        setState(() {
          username =
              '${profileData['first_name'] ?? ''} ${profileData['last_name'] ?? ''}'
                  .trim();
          about = profileData['about_me']?.toString();
          _profileImageUrl = profileData['profile_picture_url']?.toString();
          // Предположим, что эти данные приходят из API профиля
          _subscriptionsCount = profileData['subscriptions_count'] ?? 0;
          _subscribersCount = profileData['subscribers_count'] ?? 0;
          print(
            "DEBUG: AuthorProfileView:_loadAuthorProfileData: Profile loaded for author: $username",
          );
        });
      } else if (response.statusCode == 404) {
        setState(() {
          _errorMessage = 'Профиль автора не найден.';
          username = 'Автор не найден'; // Set placeholder names
          about = 'Информация об авторе недоступна.';
          _profileImageUrl = null;
        });
        print(
          'DEBUG: AuthorProfileView:_loadAuthorProfileData: Profile not found for MID: ${widget.authorMid}.',
        );
      } else {
        setState(() {
          _errorMessage =
              'Ошибка сервера при загрузке профиля автора: ${response.statusCode}';
        });
        print(
          'DEBUG: AuthorProfileView:_loadAuthorProfileData: Server error ${response.statusCode} when loading profile: ${response.body}',
        );
      }
    } catch (e) {
      setState(() {
        _errorMessage = 'Ошибка запроса профиля автора: $e';
      });
      print(
        'DEBUG: AuthorProfileView:_loadAuthorProfileData: Network error loading profile: $e',
      );
    }
  }

  // Widget to build an article item in list view
  Widget _buildArticleListItem(Map<String, dynamic> article) {
    return GestureDetector(
      onTap: () {
        Navigator.of(context).push(
          MaterialPageRoute(
            builder:
                (context) => ArticleDetail(
                  midAuthor: article['authorMid'], // Pass midAuthor here
                  articleId: article['id'],
                  title: article['title']?.toString() ?? '',
                  category: article['category'],
                  author:
                      article['author']?.toString() ??
                      '', // Author's display name
                  content: article['content']?.toString() ?? '',
                  image: article['image']?.toString() ?? '',
                  formattedDate:
                      article['formatted_created_at']?.split(' ').first ?? '',
                  time: article['formatted_created_at']?.split(' ').last ?? '',
                  authorImage:
                      _profileImageUrl ??
                      '', // Use the fetched author's profile image
                ),
          ),
        );
      },
      child: Container(
        margin: const EdgeInsets.symmetric(vertical: 8.0),
        // padding: const EdgeInsets.all(10),
        decoration: BoxDecoration(
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
              style: GoogleFonts.geologica(
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              article['content']?.toString() ?? 'No Content',
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
              style: GoogleFonts.geologica(
                fontSize: 14,
                color: Colors.grey[700],
              ),
            ),
            const SizedBox(height: 8),
            Text(
              article['formatted_created_at']?.toString() ?? 'No Date',
              style: GoogleFonts.geologica(fontSize: 12, color: Colors.grey),
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
                  midAuthor: article['authorMid'], // Pass midAuthor here
                  title: article['title']?.toString() ?? '',
                  articleId: article['id'],
                  category: article['category'],
                  author:
                      article['author']?.toString() ??
                      '', // Author's display name
                  content: article['content']?.toString() ?? '',
                  image: article['image']?.toString() ?? '',
                  formattedDate:
                      article['formatted_created_at']?.split(' ').first ?? '',
                  time: article['formatted_created_at']?.split(' ').last ?? '',
                  authorImage:
                      _profileImageUrl ??
                      '', // Use the fetched author's profile image
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
              style: GoogleFonts.geologica(
                fontSize: 14,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              article['content']?.toString() ?? 'No Content',
              maxLines: 1, // Shorter content for grid
              overflow: TextOverflow.ellipsis,
              style: GoogleFonts.geologica(
                fontSize: 10,
                color: Colors.grey[700],
              ),
            ),
            const SizedBox(height: 8),
            Text(
              article['formatted_created_at']?.toString() ?? 'No Date',
              style: GoogleFonts.geologica(fontSize: 10, color: Colors.grey),
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
    bool isMyProfile =
        (currentLoggedInUserMid != null &&
            currentLoggedInUserMid == widget.authorMid);

    return Scaffold(
      appBar: AppBar(
        toolbarHeight: 370,
        surfaceTintColor:
            (currentColors.backgroundGrey == Colors.white)
                ? Colors.white
                : const Color.fromARGB(255, 27, 27, 27),
        backgroundColor:
            (currentColors.backgroundGrey == Colors.white)
                ? Colors.white
                : const Color.fromARGB(255, 27, 27, 27),
        // If it's my profile, we might want to disable the default back button
        // if this view is pushed from the bottom nav bar, but for other profiles,
        // it makes sense to have it. Let's keep it true to allow going back.
        automaticallyImplyLeading:
            false, // Allow default back button for navigating back to article detail

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
                      backgroundImage:
                          _profileImageUrl != null &&
                                  _profileImageUrl!.isNotEmpty
                              ? NetworkImage(_profileImageUrl!)
                              : null,
                      child:
                          (_profileImageUrl == null ||
                                  _profileImageUrl!.isEmpty)
                              ? const Icon(
                                Icons.person,
                                size: 60,
                                color: Colors.grey,
                              )
                              : null,
                    ),
                    // Settings icon is now in actions, not here.
                    if (isMyProfile) // Show settings icon only if it's my profile
                      IconButton(
                        icon: const Icon(Icons.settings_outlined, size: 32),
                        onPressed: () {
                          Navigator.of(context).push(
                            MaterialPageRoute(
                              builder: (context) => const SettingsScreen(),
                            ),
                          );
                        },
                      ),
                  ],
                ),
                const SizedBox(height: 8),
                Text(
                  username != null && username!.isNotEmpty
                      ? username!
                      : 'Загрузка...', // Placeholder while loading
                  style: GoogleFonts.geologica(
                    color: currentColors.textBlack,
                    fontSize: 30,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                Text(
                  about != null && about!.isNotEmpty
                      ? about!
                      : 'Нет описания', // Placeholder while loading
                  style: GoogleFonts.geologica(
                    color: currentColors.textBlack,
                    fontSize: 15,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 20),
                Padding(
                  padding: const EdgeInsets.only(left: 10, right: 10),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Text(
                            "0",
                            // style: TextStyle(color: currentColors.textBlack),
                          ), // Подписки (0)
                          Text(
                            "Подписок",
                            // style: TextStyle(color: currentColors.textBlack),
                          ),
                        ],
                      ),
                      Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Text(
                            "0",
                            // style: TextStyle(color: currentColors.textBlack),
                          ), // Подписчики (0)
                          Text(
                            "Подписчиков",
                            // style: TextStyle(color: currentColors.textBlack),
                          ),
                        ],
                      ),
                      Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Text(
                            _userArticles.length
                                .toString(), // Реальное количество статей
                            // style: TextStyle(color: currentColors.textBlack),
                          ),
                          Text(
                            "Статей",
                            // style: TextStyle(color: currentColors.textBlack),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 20),
                // Conditional button rendering
                if (isMyProfile)
                  GestureDetector(
                    onTap: () async {
                      await Navigator.of(context).push(
                        MaterialPageRoute(
                          builder: (context) => const ProfileEdit(),
                        ),
                      );
                      // Reload profile data after returning from ProfileEdit
                      _loadAuthorProfileAndArticles(); // Reload both profile and articles
                    },
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 15,
                        vertical: 5,
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
                  )
                else // If it's not my profile
                  GestureDetector(
                    onTap: () async {
                      final prefs = await SharedPreferences.getInstance();
                      if (prefs.getString("mid") == null) {
                        // User is NOT logged in -> Show login modal
                        showDialog(
                          context: context,
                          builder:
                              (context) => AlertDialog(
                                shape: const RoundedRectangleBorder(
                                  borderRadius: BorderRadius.all(
                                    Radius.circular(24),
                                  ),
                                ),
                                backgroundColor:
                                    currentColors
                                        .dialogBackground, // Используем цвет фона диалога из текущей темы
                                title: Text(
                                  "Ошибка!",
                                  style: GoogleFonts.geologica(
                                    fontSize: 20,
                                    fontWeight: FontWeight.bold,
                                    color:
                                        currentColors
                                            .textBlack, // Используем цвет текста из текущей темы
                                  ),
                                ),
                                content: Text(
                                  "Чтобы подписаться, необходимо войти в аккаунт",
                                  style: GoogleFonts.geologica(
                                    fontSize: 16,
                                    color:
                                        currentColors
                                            .dialogTextMuted, // Используем приглушенный цвет текста из текущей темы
                                  ),
                                ),
                                actions: [
                                  GestureDetector(
                                    onTap: () async {
                                      Navigator.pop(context);
                                    },
                                    child: Text(
                                      "Отмена",
                                      style: GoogleFonts.geologica(
                                        fontSize: 16,
                                        color: currentColors.textBlack,
                                      ),
                                    ),
                                  ),
                                  GestureDetector(
                                    onTap: () async {
                                      Navigator.pop(context);
                                      Navigator.push(
                                        context,
                                        MaterialPageRoute(
                                          builder: (context) => AccountLogin(),
                                        ),
                                      );
                                    },
                                    child: Text(
                                      "Войти",
                                      style: GoogleFonts.geologica(
                                        fontSize: 16,
                                        color:
                                            currentColors
                                                .primaryBlue, // Используем основной синий цвет из текущей темы
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                        );
                      } else {
                        // User IS logged in AND it's not their profile -> Show SnackBar for subscribe
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(
                            content: Text(
                              'Функционал подписки еще не реализован!',
                            ),
                          ),
                        );
                      }
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
                        color:
                            (currentLoggedInUserMid != null &&
                                    currentLoggedInUserMid!.isNotEmpty)
                                ? const Color(
                                  0xFF334EFF,
                                ) // Blue for subscribe if logged in
                                : const Color.fromARGB(
                                  255,
                                  231,
                                  234,
                                  255,
                                ), // Lighter blue for "Войти" if not logged in
                      ),
                      child: Center(
                        child: Text(
                          (currentLoggedInUserMid != null &&
                                  currentLoggedInUserMid!.isNotEmpty)
                              ? "Подписаться"
                              : "Подписаться",
                          style: GoogleFonts.geologica(
                            color:
                                (currentLoggedInUserMid != null &&
                                        currentLoggedInUserMid!.isNotEmpty)
                                    ? Colors
                                        .white // White text for subscribe
                                    : const Color(
                                      0xFF334EFF,
                                    ), // Blue text for "Войти"
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
                  'Публикации', // Теперь всегда "Публикации"
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
                        // Этот блок теперь выводится, когда у автора НЕТ статей
                        crossAxisAlignment: CrossAxisAlignment.center,
                        mainAxisAlignment:
                            MainAxisAlignment.center, // Центрируем по вертикали
                        children: [
                          const SizedBox(height: 8),
                          Text(
                            "У этого автора пока нет публикаций.",
                            style: GoogleFonts.geologica(
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                              color:
                                  currentColors
                                      .textBlack, // Цвет текста из темы
                            ),
                            textAlign: TextAlign.center,
                          ),
                          const SizedBox(height: 4),
                          Text(
                            "Загляните позже, возможно, скоро появятся новые статьи.",
                            style: GoogleFonts.geologica(
                              color:
                                  currentColors.textGrey, // Цвет текста из темы
                              fontSize: 14,
                            ),
                            textAlign: TextAlign.center,
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
