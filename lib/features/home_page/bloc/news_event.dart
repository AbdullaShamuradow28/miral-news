// lib/features/home_page/bloc/news_event.dart

part of 'news_bloc.dart';

@immutable
abstract class ArticleEvent {}

// Modify LoadArticles to accept an optional list of categories
class LoadArticles extends ArticleEvent {
  final List<String> categories;

  // Initialize with an empty list by default, meaning no filter initially
  LoadArticles({this.categories = const []});
}
