import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter_swipe_detector/flutter_swipe_detector.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:miral_news/features/search/view/search_results.dart';
import 'package:miral_news/theme_changer.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:http/http.dart' as http;
import 'package:provider/provider.dart';

class SearchView extends StatefulWidget {
  const SearchView({super.key});

  @override
  State<SearchView> createState() => _SearchViewState();
}

class _SearchViewState extends State<SearchView> {
  bool _showOverlay = false;
  late SharedPreferences _prefs;
  static const String _overlayShownKey = 'swipeOverlayShown';
  static const String _searchHistoryKey = 'searchHistory';
  final TextEditingController _searchController = TextEditingController();
  List<String> _searchSuggestions = []; // Будет заполняться данными с сервера
  List<String> _filteredSuggestions = [];
  bool _showSuggestions = false;
  List<String> _recentSearches = [];
  bool _isLoadingSuggestions = false;
  String? _suggestionsError;
  String _apiUrl = "http://192.168.1.109:3000";

  @override
  void initState() {
    super.initState();
    _loadPrefs();
    _loadArticleTitles(); // Загрузка названий статей для подсказок
    _searchController.addListener(_onSearchChanged);
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _loadPrefs() async {
    _prefs = await SharedPreferences.getInstance();
    _checkIfOverlayShown();
    _loadSearchHistory();
  }

  Future<void> _loadSearchHistory() async {
    setState(() {
      _recentSearches = _prefs.getStringList(_searchHistoryKey) ?? [];
    });
  }

  Future<void> _saveSearchHistory(String query) async {
    if (query.isNotEmpty && !_recentSearches.contains(query)) {
      _recentSearches.insert(0, query);
      if (_recentSearches.length > 10) {
        _recentSearches.removeLast();
      }
      await _prefs.setStringList(_searchHistoryKey, _recentSearches);
      setState(() {});
    }
  }

  Future<void> _clearSearchHistory() async {
    await _prefs.remove(_searchHistoryKey);
    setState(() {
      _recentSearches.clear();
    });
  }

  void _checkIfOverlayShown() {
    final bool overlayShown = _prefs.getBool(_overlayShownKey) ?? false;
    if (!overlayShown) {
      setState(() {
        _showOverlay = true;
      });
    }
  }

  Future<void> _markOverlayAsShown() async {
    await _prefs.setBool(_overlayShownKey, true);
  }

  Future<void> _loadArticleTitles() async {
    setState(() {
      _isLoadingSuggestions = true;
      _suggestionsError = null;
    });
    try {
      final response = await http.get(Uri.parse('$_apiUrl'));
      if (response.statusCode == 200) {
        final List<dynamic> decodedResponse = json.decode(response.body);
        setState(() {
          _searchSuggestions =
              decodedResponse
                  .where((article) => article.containsKey('title'))
                  .map<String>((article) => article['title'] as String)
                  .toList();
          _isLoadingSuggestions = false;
        });
      } else {
        setState(() {
          _suggestionsError =
              'Не удалось загрузить названия статей: ${response.statusCode}';
          _isLoadingSuggestions = false;
        });
      }
    } catch (e) {
      setState(() {
        _suggestionsError = 'Ошибка при загрузке названий статей: $e';
        _isLoadingSuggestions = false;
      });
    }
  }

  void _onSearchChanged() {
    if (_searchController.text.isNotEmpty) {
      setState(() {
        _filteredSuggestions =
            _searchSuggestions
                .where(
                  (suggestion) => suggestion.toLowerCase().contains(
                    _searchController.text.toLowerCase(),
                  ),
                )
                .toList();
        _showSuggestions = _filteredSuggestions.isNotEmpty;
      });
    } else {
      setState(() {
        _filteredSuggestions.clear();
        _showSuggestions = false;
      });
    }
  }

  void _onSuggestionTap(String suggestion) {
    setState(() {
      _searchController.text = suggestion;
      _showSuggestions = false;
    });
    _saveSearchHistory(suggestion);
    // Perform search action here if needed
    Navigator.of(context).push(
      MaterialPageRoute(
        builder:
            (context) => SearchResults(searchQuery: _searchController.text),
      ),
    );
  }

  void _onRecentSearchTap(String recentSearch) {
    setState(() {
      _searchController.text = recentSearch;
      _showSuggestions = false;
    });
    // Perform search action here if needed
    Navigator.of(context).push(
      MaterialPageRoute(
        builder:
            (context) => SearchResults(searchQuery: _searchController.text),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final themeChanger = Provider.of<ThemeChanger>(context);
    final currentColors = themeChanger.currentColors;
    return Scaffold(
      body: Stack(
        children: [
          SwipeDetector(
            onSwipeRight: (offset) => Navigator.pop(context),
            child: Column(
              children: [
                Padding(
                  padding: const EdgeInsets.only(
                    top: 25,
                    left: 16,
                    right: 16,
                    bottom: 16,
                  ),
                  child: Container(
                    decoration: BoxDecoration(
                      color:
                          (currentColors.backgroundGrey == Colors.white)
                              ? Color(0xFFF4F4F4)
                              : const Color.fromARGB(255, 20, 20, 20),
                      borderRadius: BorderRadius.all(Radius.circular(2033)),
                    ),
                    child: TextField(
                      controller: _searchController,
                      enabled: true,
                      autofocus: true,
                      onTap: () {
                        setState(() {
                          _showSuggestions =
                              _filteredSuggestions.isNotEmpty &&
                              _searchController.text.isNotEmpty;
                        });
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
                Expanded(
                  child: ListView(
                    shrinkWrap: true,
                    physics: const ClampingScrollPhysics(),
                    children: [
                      if (_searchController.text.isEmpty &&
                          _recentSearches.isNotEmpty)
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Padding(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 16,
                                vertical: 8,
                              ),
                              child: Text(
                                'Недавние запросы',
                                style: GoogleFonts.geologica(
                                  color: currentColors.textBlack,
                                  fontSize: 14,
                                ),
                              ),
                            ),
                            ListView.builder(
                              shrinkWrap: true,
                              physics: const NeverScrollableScrollPhysics(),
                              itemCount: _recentSearches.length,
                              itemBuilder: (context, index) {
                                final recentSearch = _recentSearches[index];
                                return ListTile(
                                  onTap: () => _onRecentSearchTap(recentSearch),
                                  title: Text(
                                    recentSearch,
                                    style: TextStyle(
                                      color: const Color(0xFF334EFF),
                                      fontSize: 16,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                  trailing: IconButton(
                                    icon: const Icon(
                                      Icons.close,
                                      color: Color(0xFF334EFF),
                                    ),
                                    onPressed: () {
                                      setState(() {
                                        _recentSearches.removeAt(index);
                                        _prefs.setStringList(
                                          _searchHistoryKey,
                                          _recentSearches,
                                        );
                                      });
                                    },
                                  ),
                                );
                              },
                            ),
                          ],
                        ),
                      if (_showSuggestions)
                        ListView.builder(
                          shrinkWrap: true,
                          physics: const NeverScrollableScrollPhysics(),
                          itemCount: _filteredSuggestions.length,
                          itemBuilder: (context, index) {
                            final suggestion = _filteredSuggestions[index];
                            return ListTile(
                              onTap: () => _onSuggestionTap(suggestion),
                              title: Text(
                                suggestion,
                                style: TextStyle(
                                  color: const Color(0xFF334EFF),
                                  fontSize: 16,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            );
                          },
                        ),
                      if ((_searchController.text.isEmpty ||
                              !_showSuggestions) &&
                          _recentSearches.isNotEmpty)
                        ListTile(
                          title: const Text(
                            "Очистить историю поиска",
                            style: TextStyle(color: Colors.red),
                          ),
                          leading: const Icon(Icons.delete, color: Colors.red),
                          onTap: _clearSearchHistory,
                        ),
                      if (_isLoadingSuggestions)
                        const Padding(
                          padding: EdgeInsets.all(16.0),
                          child: Center(child: CircularProgressIndicator()),
                        ),
                      if (_suggestionsError != null)
                        Padding(
                          padding: const EdgeInsets.all(16.0),
                          child: Center(
                            child: Text(
                              _suggestionsError!,
                              style: const TextStyle(color: Colors.red),
                              textAlign: TextAlign.center,
                            ),
                          ),
                        ),
                      if (!_isLoadingSuggestions &&
                          _suggestionsError == null &&
                          _searchController.text.isEmpty &&
                          _recentSearches.isEmpty &&
                          _searchSuggestions.isEmpty)
                        const Padding(
                          padding: EdgeInsets.all(16.0),
                          child: Center(
                            child: Text(
                              'Нет доступных подсказок.',
                              style: TextStyle(color: Colors.grey),
                              textAlign: TextAlign.center,
                            ),
                          ),
                        ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          if (_showOverlay)
            GestureDetector(
              onTap: () {
                setState(() {
                  _showOverlay = false;
                });
                _markOverlayAsShown(); // Mark as shown when closed
              },
              child: Container(
                color: Colors.black.withOpacity(0.7),
                child: Center(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Icon(
                        Icons.swipe_right,
                        color: Colors.white,
                        size: 60,
                      ),
                      const SizedBox(height: 10),
                      Text(
                        'Смахните вправо, чтобы вернуться',
                        style: GoogleFonts.geologica(
                          color: Colors.white,
                          fontSize: 18,
                        ),
                        textAlign: TextAlign.center,
                      ),
                      const SizedBox(height: 20),
                      Text(
                        'Нажмите в любом месте, чтобы закрыть',
                        style: GoogleFonts.geologica(
                          color: Colors.grey[400],
                          fontSize: 14,
                        ),
                        textAlign: TextAlign.center,
                      ),
                    ],
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }
}
