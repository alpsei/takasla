// lib/features/home/bloc/home_event.dart

import 'package:equatable/equatable.dart';

abstract class HomeEvent extends Equatable {
  const HomeEvent();
  @override
  List<Object> get props => [];
}

class HomeBooksRequested extends HomeEvent {}

class HomeFilterChanged extends HomeEvent {
  final String? takasTuru; // "Bağış", "Takas" vs.
  final String? kitapTuru; // "Sınav", "Roman" vs.
  final String? konum; // "Ankara", "İstanbul" vs.

  const HomeFilterChanged({this.takasTuru, this.kitapTuru, this.konum});

  @override
  List<Object?> get props_ => [takasTuru, kitapTuru, konum];
}

class HomeSearchQueryChanged extends HomeEvent {
  final String query;
  const HomeSearchQueryChanged(this.query);

  @override
  List<Object> get props => [query];
}

class HomeSearchModeChanged extends HomeEvent {
  final bool isUserSearch;
  const HomeSearchModeChanged(this.isUserSearch);

  @override
  List<Object> get props => [isUserSearch];
}
