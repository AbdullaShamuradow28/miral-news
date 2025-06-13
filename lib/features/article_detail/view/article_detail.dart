import 'dart:convert';
import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'dart:ui';
import 'package:google_fonts/google_fonts.dart';
import 'package:path/path.dart';
import 'package:provider/provider.dart';
import 'package:http/http.dart' as http;
import 'package:miral_news/features/post_article/view/edit_article.dart';
import 'package:miral_news/features/profile_signed/view/author_profile_view.dart';
import 'package:miral_news/theme_changer.dart';
import 'package:shared_preferences/shared_preferences.dart';

class ArticleDetail extends StatefulWidget {
  const ArticleDetail({
    super.key,
    required this.title,
    required this.category,
    required this.author,
    required this.content,
    required this.image,
    required this.formattedDate,
    required this.time,
    required this.articleId,
    required this.authorImage, // This will still be passed, but we'll fetch the actual image here
    required this.midAuthor,
  });

  final String midAuthor;
  final String title;
  final int articleId;
  final String category;
  final String content;
  final String author; // This is the author's MID
  final String image; // Article image URL
  final String formattedDate;
  final String time;
  final String
  authorImage; // This is currently an empty string from ProfileView

  @override
  State<ArticleDetail> createState() => _ArticleDetailState();
}

class _ArticleDetailState extends State<ArticleDetail> {
  final String API_URL = "http://192.168.1.109:3000/"; // URL for articles API
  final String profileApiBaseUrl =
      "http://192.168.1.109:3001/api/profiles"; // Base URL for profiles API
  final String usersApiUrl =
      "http://192.168.1.109:3001/api/users/"; // Base URL for users API

  String? _currentUserName; // Current logged-in user's name
  String? _currentUserId; // Current logged-in user's MID
  Uint8List?
  _currentUserImageBytes; // Current logged-in user's profile image bytes (from prefs)

  String? _articleAuthorName; // Article author's name fetched from profile API
  String?
  _articleAuthorImageUrl; // Article author's image URL fetched from profile API

  bool _isLoading = true; // To manage loading state for profile data

  // --- Like State ---
  bool _isLiked = false; // State variable to track if the item is liked
  int _likeCount = 999; // Initial like count - test with different values
  // --- End Like State ---

  @override
  void initState() {
    super.initState();
    _loadAllData(); // Call a combined function to load both current user and article author data
  }

  Future<void> _loadAllData() async {
    setState(() {
      _isLoading = true;
    });
    await _loadCurrentUserMidAndImage(); // Load current user's data
    await _fetchArticleAuthorProfile(); // Fetch article author's profile
    setState(() {
      _isLoading = false;
    });
  }

  // Loads current user's MID and local image from SharedPreferences
  Future<void> _loadCurrentUserMidAndImage() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    setState(() {
      _currentUserName = prefs.getString('username') ?? '';
      _currentUserId = prefs.getString('mid') ?? '';

      String? imageBytesString = prefs.getString('imageBytes');
      if (imageBytesString != null && imageBytesString.isNotEmpty) {
        try {
          _currentUserImageBytes = base64Decode(imageBytesString);
        } catch (e) {
          print(
            "DEBUG: ArticleDetail:_loadCurrentUserMidAndImage: Error decoding image from SharedPreferences: $e",
          );
          _currentUserImageBytes = null;
        }
      } else {
        _currentUserImageBytes = null;
      }
    });
    print(
      'DEBUG: ArticleDetail:_loadCurrentUserMidAndImage: Current user MID: $_currentUserId, Name: $_currentUserName',
    );
  }

  // Fetches the article author's profile picture and name from the API
  Future<void> _fetchArticleAuthorProfile() async {
    final String authorMid = widget.author;
    if (authorMid.isEmpty) {
      print(
        'DEBUG: ArticleDetail:_fetchArticleAuthorProfile: Author MID is empty. Cannot fetch profile.',
      );
      setState(() {
        _articleAuthorName = 'Неизвестный автор';
        _articleAuthorImageUrl = null;
      });
      return;
    }

    try {
      final String profileGetUrl = '$profileApiBaseUrl/get_by_mid/$authorMid/';
      print(
        'DEBUG: ArticleDetail:_fetchArticleAuthorProfile: Attempting to load author profile from server for MID: $authorMid at URL: $profileGetUrl',
      );
      final response = await http.get(Uri.parse(profileGetUrl));

      if (response.statusCode == 200) {
        final Map<String, dynamic> profileData = json.decode(response.body);
        setState(() {
          _articleAuthorName =
              '${profileData['first_name'] ?? ''} ${profileData['last_name'] ?? ''}'
                  .trim();
          _articleAuthorImageUrl =
              profileData['profile_picture_url']?.toString();
          print(
            "DEBUG: ArticleDetail:_fetchArticleAuthorProfile: Author profile loaded: Name: $_articleAuthorName, Image URL: $_articleAuthorImageUrl",
          );
        });
      } else {
        print(
          'DEBUG: ArticleDetail:_fetchArticleAuthorProfile: Server returned ${response.statusCode} when fetching author profile: ${response.body}.',
        );
        setState(() {
          _articleAuthorName = 'Неизвестный автор';
          _articleAuthorImageUrl = null;
        });
      }
    } catch (e) {
      print(
        'DEBUG: ArticleDetail:_fetchArticleAuthorProfile: Network error fetching author profile: $e',
      );
      setState(() {
        _articleAuthorName = 'Неизвестный автор';
        _articleAuthorImageUrl = null;
      });
    }
  }

  void _toggleLike() {
    setState(() {
      _isLiked = !_isLiked; // Toggle the like state
      if (_isLiked) {
        _likeCount++; // Increment count if liked
      } else {
        _likeCount--; // Decrement count if unliked
      }
    });
  }

  // Helper function to format the count
  String _formatCount(int count) {
    if (count < 1000) {
      return count.toString();
    } else if (count < 1000000) {
      double kCount = count / 1000;
      return '${kCount.toStringAsFixed(kCount.truncateToDouble() == kCount ? 0 : 1)}k';
    } else {
      double mCount = count / 1000000;
      return '${mCount.toStringAsFixed(mCount.truncateToDouble() == mCount ? 0 : 1)}M';
    }
  }

  @override
  Widget build(BuildContext context) {
    final themeChanger = Provider.of<ThemeChanger>(context);
    final currentColors = themeChanger.currentColors;

    if (_isLoading) {
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }

    return Scaffold(
      extendBodyBehindAppBar: true,
      backgroundColor: currentColors.backgroundGrey,
      body: Column(
        children: [
          // === IMAGE + ACTION BUTTONS ===
          Stack(
            children: [
              ClipRRect(
                borderRadius: const BorderRadius.vertical(
                  bottom: Radius.circular(0),
                ),
                child: Image.network(
                  widget.image,
                  width: double.infinity,
                  height: 250,
                  fit: BoxFit.cover,
                  errorBuilder: (context, error, stackTrace) {
                    return SizedBox(
                      width: double.infinity,
                      height: 250,
                      child: const Center(
                        child: Icon(
                          Icons.image_not_supported,
                          size: 80,
                          color: Colors.grey,
                        ),
                      ),
                    );
                  },
                ),
              ),
              Positioned(
                top: MediaQuery.of(context).padding.top + 12,
                left: 16,
                child: _circleButton(
                  icon: Icons.arrow_back,
                  onTap: () => Navigator.of(context).pop(),
                ),
              ),

              if (_currentUserId == widget.author)
                Positioned(
                  top: MediaQuery.of(context).padding.top + 12,
                  right: 125,
                  child: _circleButton(
                    icon: Icons.info_outline_rounded,
                    onTap: () {
                      // modal bottom sheet
                      showModalBottomSheet(
                        context: context,
                        builder: (BuildContext context) {
                          return Container(
                            padding: EdgeInsets.all(20),
                            child: Column(
                              mainAxisSize: MainAxisSize.min,
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  'Укажите причину жалобы',
                                  style: GoogleFonts.geologica(
                                    fontSize: 20,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                                const SizedBox(height: 15),
                                ListTile(
                                  title: Text(
                                    'Статья нарушает авторские права',
                                    style: GoogleFonts.geologica(),
                                  ),
                                  onTap: () {
                                    Navigator.pop(context);
                                    ScaffoldMessenger.of(context).showSnackBar(
                                      SnackBar(
                                        content: Text(
                                          "Жалоба успешно отправлена!",
                                        ),
                                      ),
                                    );
                                  },
                                ),
                                ListTile(
                                  title: Text(
                                    'Ложная информация',
                                    style: GoogleFonts.geologica(),
                                  ),
                                  onTap: () {
                                    Navigator.pop(context);
                                    ScaffoldMessenger.of(context).showSnackBar(
                                      SnackBar(
                                        content: Text(
                                          "Жалоба успешно отправлена!",
                                        ),
                                      ),
                                    );
                                  },
                                ),
                              ],
                            ),
                          );
                        },
                      );
                    }, // для редактирования
                  ),
                ),

              // Display edit and delete buttons only if current user is the author
              if (_currentUserId == widget.author)
                Positioned(
                  top: MediaQuery.of(context).padding.top + 12,
                  right: 70,
                  child: _circleButton(
                    icon: Icons.edit_outlined,
                    onTap: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder:
                              (_) => EditArticle(
                                initialTitle: widget.title,
                                id: widget.articleId,
                                initialContent: widget.content,
                                author: widget.author,
                                initialImage: widget.image,
                                authorImage: widget.authorImage,
                              ),
                        ),
                      );
                    }, // для редактирования
                  ),
                ),
              if (_currentUserId == widget.author)
                Positioned(
                  top: MediaQuery.of(context).padding.top + 12,
                  right: 16,
                  child: _circleButton(
                    icon: Icons.delete_outline_outlined,
                    onTap: () {
                      // TODO: Implement delete functionality
                      showDialog(
                        context: context,
                        builder:
                            (context) => AlertDialog(
                              shape: const RoundedRectangleBorder(
                                borderRadius: BorderRadius.all(
                                  Radius.circular(24),
                                ),
                              ),
                              backgroundColor: Colors.white,
                              title: Text(
                                "Удалить статью",
                                style: GoogleFonts.geologica(
                                  fontSize: 20,
                                  fontWeight: FontWeight.bold,
                                  color: Colors.black,
                                ),
                              ),
                              content: Text(
                                "Удалив статью можно вернуть ее из черновиков в течении 1 недели",
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
                                    final response = await http.delete(
                                      Uri.parse(
                                        "http://192.168.1.109:3000/${widget.articleId}/delete/",
                                      ),
                                    );
                                    if (response.statusCode == 200) {
                                      print("DELETED");
                                    }
                                  },
                                  child: Text(
                                    "Подтвердить",
                                    style: GoogleFonts.geologica(
                                      fontSize: 16,
                                      color: const Color.fromARGB(
                                        255,
                                        255,
                                        51,
                                        85,
                                      ),
                                    ),
                                  ),
                                ),
                              ],
                            ),
                      );
                    }, // для удаления
                  ),
                ),
            ],
          ),

          // === CONTENT ===
          Expanded(
            child: Container(
              decoration: BoxDecoration(
                borderRadius: BorderRadius.only(
                  topLeft: Radius.circular(10),
                  topRight: Radius.circular(10),
                ),
              ),
              child: Expanded(
                child: ListView(
                  padding: const EdgeInsets.all(16),
                  children: [
                    Text(
                      widget.title,
                      style: GoogleFonts.geologica(
                        fontSize: 22,
                        fontWeight: FontWeight.w900,
                      ),
                    ),
                    // Автор
                    const SizedBox(height: 12),
                    Align(
                      alignment: Alignment.centerLeft,
                      child: Container(
                        padding: EdgeInsets.symmetric(
                          horizontal: 12,
                          vertical: 8,
                        ),
                        decoration: BoxDecoration(
                          // Translucent white
                          borderRadius: BorderRadius.circular(15),
                          border: Border.all(
                            color: currentColors.textBlack, // Light border
                          ),
                        ),
                        child: Text("${widget.category}"),
                      ),
                    ),
                    const SizedBox(height: 12),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        GestureDetector(
                          onTap: () {
                            Navigator.of(context).push(
                              MaterialPageRoute(
                                builder:
                                    (context) => AuthorProfileView(
                                      authorMid: widget.midAuthor,
                                    ),
                              ),
                            );
                          },
                          child: Row(
                            children: [
                              CircleAvatar(
                                radius: 14,
                                backgroundColor: Colors.grey[200],
                                backgroundImage:
                                    _articleAuthorImageUrl != null &&
                                            _articleAuthorImageUrl!.isNotEmpty
                                        ? NetworkImage(_articleAuthorImageUrl!)
                                            as ImageProvider<Object>?
                                        : null,
                                child:
                                    _articleAuthorImageUrl == null ||
                                            _articleAuthorImageUrl!.isEmpty
                                        ? const Icon(
                                          Icons.person,
                                          size: 14,
                                          color: Colors.grey,
                                        )
                                        : null,
                              ),
                              const SizedBox(width: 8),
                              Text(
                                _articleAuthorName ??
                                    'Loading Author...', // Display loaded author name
                                style: GoogleFonts.geologica(
                                  fontSize: 14,
                                  color:
                                      (currentColors.textBlack == Colors.black)
                                          ? Colors.grey[700]
                                          : Colors.white,
                                  fontWeight: FontWeight.w800,
                                ),
                              ),
                            ],
                          ),
                        ),
                        Row(
                          children: [
                            // Likes Container
                            ClipRRect(
                              borderRadius: BorderRadius.only(
                                topLeft: Radius.circular(15),
                                bottomLeft: Radius.circular(15),
                                topRight: Radius.circular(5),
                                bottomRight: Radius.circular(5),
                              ),
                              child: BackdropFilter(
                                filter: ImageFilter.blur(sigmaX: 5, sigmaY: 5),
                                child: GestureDetector(
                                  // Use GestureDetector for the entire container
                                  onTap:
                                      _toggleLike, // Toggle like on container tap
                                  child: Container(
                                    padding: EdgeInsets.symmetric(
                                      horizontal: 12,
                                      vertical: 8,
                                    ),
                                    decoration: BoxDecoration(
                                      color:
                                          _isLiked
                                              ? const Color(
                                                0xFF334EFF,
                                              ) // Blue when liked
                                              : const Color.fromARGB(
                                                123,
                                                255,
                                                255,
                                                255,
                                              ).withOpacity(
                                                0.2,
                                              ), // Default white when not liked
                                      borderRadius: BorderRadius.only(
                                        topLeft: Radius.circular(15),
                                        bottomLeft: Radius.circular(15),
                                        topRight: Radius.circular(5),
                                        bottomRight: Radius.circular(5),
                                      ),
                                      border: Border.all(
                                        color: const Color.fromARGB(
                                          157,
                                          24,
                                          24,
                                          24,
                                        ),
                                      ),
                                    ),
                                    child: Row(
                                      mainAxisSize: MainAxisSize.min,
                                      children: [
                                        Icon(
                                          _isLiked
                                              ? Icons.favorite
                                              : Icons
                                                  .favorite_border_outlined, // Filled icon when liked
                                          color:
                                              _isLiked
                                                  ? Colors.white
                                                  : currentColors
                                                      .textBlack, // Blue icon when liked
                                        ),
                                        SizedBox(width: 5),
                                        Text(
                                          _formatCount(
                                            _likeCount,
                                          ), // Apply formatting
                                          style: GoogleFonts.geologica(
                                            color:
                                                _isLiked
                                                    ? Colors.white
                                                    : currentColors.textBlack,
                                            fontSize: 14,
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                ),
                              ),
                            ),
                            // Views Container
                            SizedBox(width: 2.5),
                            ClipRRect(
                              borderRadius: BorderRadius.only(
                                topLeft: Radius.circular(5),
                                bottomLeft: Radius.circular(5),
                                topRight: Radius.circular(15),
                                bottomRight: Radius.circular(15),
                              ),
                              child: BackdropFilter(
                                filter: ImageFilter.blur(sigmaX: 5, sigmaY: 5),
                                child: Container(
                                  padding: EdgeInsets.symmetric(
                                    horizontal: 12,
                                    vertical: 8,
                                  ),
                                  decoration: BoxDecoration(
                                    color: const Color.fromARGB(
                                      123,
                                      255,
                                      255,
                                      255,
                                    ).withOpacity(0.2),
                                    borderRadius: BorderRadius.only(
                                      topLeft: Radius.circular(5),
                                      bottomLeft: Radius.circular(5),
                                      topRight: Radius.circular(15),
                                      bottomRight: Radius.circular(15),
                                    ),
                                    border: Border.all(
                                      color: const Color.fromARGB(
                                        157,
                                        24,
                                        24,
                                        24,
                                      ),
                                    ),
                                  ),
                                  child: Row(
                                    mainAxisSize: MainAxisSize.min,
                                    children: [
                                      Icon(
                                        Icons.remove_red_eye_outlined,
                                        color: currentColors.textBlack,
                                      ),
                                      SizedBox(width: 5),
                                      Text(
                                        "155k", // Assuming views are static for now
                                        style: GoogleFonts.geologica(
                                          color: currentColors.textBlack,
                                          fontSize: 14,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),

                    // const SizedBox(height: 12),
                    // // Заголовок
                    const SizedBox(height: 12),

                    // Контент
                    Text(
                      widget.content,
                      style: GoogleFonts.geologica(fontSize: 16, height: 1.5),
                    ),

                    // comments
                    // const SizedBox(height: 20),

                    // SizedBox(
                    //   width: MediaQuery.of(context).size.width,
                    //   height: 50,
                    //   child: Row(
                    //     children: [
                    //       CircleAvatar(),
                    //       SizedBox(width: 10),
                    //       SizedBox(
                    //         height: 50,
                    //         width: MediaQuery.of(context).size.width - 130,
                    //         child: TextField(
                    //           keyboardType: TextInputType.multiline,
                    //           decoration: InputDecoration(
                    //             hintText: "Добавьте комментарий",
                    //           ),
                    //         ),
                    //       ),
                    //       SizedBox(width: 20),
                    //       Icon(Icons.send_rounded),
                    //     ],
                    //   ),
                    // ),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _circleButton({required IconData icon, required VoidCallback onTap}) {
    return ClipRRect(
      // Clip the background to the button's shape
      borderRadius: const BorderRadius.all(Radius.circular(10)),
      child: BackdropFilter(
        // Apply the blur effect
        filter: ImageFilter.blur(
          sigmaX: 10,
          sigmaY: 10,
        ), // Adjust sigmaX and sigmaY for blur intensity
        child: Material(
          color: Colors.black.withOpacity(0.4),
          shape: const RoundedRectangleBorder(
            borderRadius: BorderRadius.all(Radius.circular(10)),
          ),
          child: InkWell(
            customBorder: const Border(),
            borderRadius: const BorderRadius.all(Radius.circular(10)),
            onTap: onTap,
            child: Padding(
              padding: const EdgeInsets.all(12),
              child: Icon(icon, color: Colors.white, size: 20),
            ),
          ),
        ),
      ),
    );
  }
}
