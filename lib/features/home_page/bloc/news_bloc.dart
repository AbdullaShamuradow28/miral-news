// lib/features/home_page/bloc/news_bloc.dart

import 'package:bloc/bloc.dart';
import 'package:flutter/foundation.dart'; // For listEquals
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:collection/collection.dart'; // Still needed for listEquals

part 'news_event.dart';

// Removed 'extends Equatable'
@immutable
abstract class ArticleState {}

class ArticlesInitial extends ArticleState {}

class ArticlesLoading extends ArticleState {}

class ArticlesLoaded extends ArticleState {
  final List<Article> articles;

  ArticlesLoaded(this.articles);

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is ArticlesLoaded &&
          runtimeType == other.runtimeType &&
          listEquals(articles, other.articles); // Use listEquals for deep comparison

  @override
  int get hashCode => articles.hashCode;
}

class ArticlesLoadError extends ArticleState {
  final String error;

  ArticlesLoadError(this.error);
}

class Article {
  final int id;
  final String image;
  final String title;
  final String content;
  final String author; // This is likely the author's display name
  final String formattedCreatedAt;
  final String category;
  final String?
  midAuthor; // Made nullable, or provide a default if it can be null

  Article({
    required this.id,
    required this.image,
    required this.title,
    required this.category,
    required this.content,
    required this.author,
    this.midAuthor, // No longer required if nullable
    required this.formattedCreatedAt,
  });

  factory Article.fromJson(Map<String, dynamic> json) {
    return Article(
      id: json['id'],
      image: json['image'] ?? '', // Provide default empty string for image
      title: json['title'] ?? 'No Title', // Provide default
      content:
          json['content']?.toString() ??
          'No Content', // .toString() and default
      category:
          json['category']?.toString() ??
          'Uncategorized', // .toString() and default
      author: json['author'] ?? 'Unknown Author', // Provide default
      midAuthor:
          json['authorMid']
              ?.toString(), // Corrected typo and made nullable (safe)
      formattedCreatedAt:
          json['formatted_created_at'] ?? 'No Date', // Provide default
    );
  }
}

class ArticleBloc extends Bloc<ArticleEvent, ArticleState> {
  ArticleBloc() : super(ArticlesInitial()) {
    on<LoadArticles>(_onLoadArticles);
  }

  Future<void> _onLoadArticles(
    LoadArticles event,
    Emitter<ArticleState> emit,
  ) async {
    emit(ArticlesLoading());
    try {
      String baseUrl = 'http://192.168.1.109:3000/';
      Uri uri = Uri.parse(baseUrl);

      if (event.categories.isNotEmpty) {
        uri = uri.replace(
          queryParameters: {'category': event.categories.join(',')},
        );
      }

      print('DEBUG: ArticleBloc: Fetching articles from URI: $uri');

      final response = await http.get(uri);

      if (response.statusCode == 200) {
        final String decodedBody = utf8.decode(response.bodyBytes);
        print('DEBUG: ArticleBloc: Received decoded body: $decodedBody');
        final List<dynamic> articlesJson = json.decode(decodedBody);

        final List<Article> articles =
            articlesJson.map((json) => Article.fromJson(json)).toList();
        emit(ArticlesLoaded(articles));
      } else {
        emit(
          ArticlesLoadError('Failed to load articles: ${response.statusCode}'),
        );
        print(
          'DEBUG: ArticleBloc: HTTP Error Status Code: ${response.statusCode}',
        );
        print('DEBUG: ArticleBloc: HTTP Error Body: ${response.body}');
      }
    } catch (e) {
      emit(ArticlesLoadError('An error occurred: $e'));
      print('DEBUG: ArticleBloc: Catch Error: $e');
    }
  }
}
