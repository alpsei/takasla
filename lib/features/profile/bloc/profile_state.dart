import 'package:equatable/equatable.dart';
import 'package:kitaptakas/data/models/review_model.dart';
import '../../../../data/models/book_model.dart';

abstract class ProfileState extends Equatable {
  const ProfileState();
  @override
  List<Object> get props => [];
}

class ProfileInitial extends ProfileState {}

class ProfileLoading extends ProfileState {}

class ProfileSuccess extends ProfileState {
  final List<BookModel> userBooks;
  final List<ReviewModel> userReviews;

  const ProfileSuccess({required this.userBooks, required this.userReviews});

  @override
  List<Object> get props => [userBooks, userReviews];
}

class ProfileFailure extends ProfileState {
  final String error;
  const ProfileFailure(this.error);
}
