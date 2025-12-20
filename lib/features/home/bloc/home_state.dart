import 'package:equatable/equatable.dart';
import 'package:kitaptakas/data/models/user_model.dart';
import '../../../../data/models/book_model.dart';

abstract class HomeState extends Equatable {
  const HomeState();

  @override
  List<Object?> get props => [];
}

class HomeInitial extends HomeState {}

class HomeLoading extends HomeState {}

class HomeSuccess extends HomeState {
  final List<BookModel> books;
  final List<BookModel> allBooks;
  final String? activeTakasTuru;
  final String? activeKitapTuru;
  final String? activeKonum;
  final String? activeSearchQuery;

  final bool isUserSearchMode;
  final List<UserModel> userResults;

  const HomeSuccess({
    required this.books,
    required this.allBooks,
    this.activeKitapTuru,
    this.activeKonum,
    this.activeSearchQuery,
    this.activeTakasTuru,
    this.isUserSearchMode = false,
    this.userResults = const [],
  });
  HomeSuccess copyWith({
    List<BookModel>? books,
    List<BookModel>? allBooks,
    String? activeTakasTuru,
    String? activeKitapTuru,
    String? activeKonum,
    String? activeSearchQuery,
    bool? isUserSearchMode,
    List<UserModel>? userResults,
  }) {
    return HomeSuccess(
      books: books ?? this.books,
      allBooks: allBooks ?? this.allBooks,
      activeTakasTuru: activeTakasTuru ?? this.activeTakasTuru,
      activeKitapTuru: activeKitapTuru ?? this.activeKitapTuru,
      activeKonum: activeKonum ?? this.activeKonum,
      activeSearchQuery: activeSearchQuery ?? this.activeSearchQuery,
      isUserSearchMode: isUserSearchMode ?? this.isUserSearchMode,
      userResults: userResults ?? this.userResults,
    );
  }

  @override
  List<Object?> get props => [
    books,
    allBooks,
    activeTakasTuru,
    activeKitapTuru,
    activeKonum,
    activeSearchQuery,
    isUserSearchMode,
    userResults,
  ];
}

class HomeFailure extends HomeState {
  final String error;

  const HomeFailure(this.error);

  @override
  List<Object> get props => [error];
}
