import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:kitaptakas/data/models/book_model.dart';
import 'package:kitaptakas/data/models/review_model.dart';
import '../../../../data/repositories/book_repository.dart';
import 'profile_event.dart';
import 'profile_state.dart';

class ProfileBloc extends Bloc<ProfileEvent, ProfileState> {
  final BookRepository _bookRepository;

  ProfileBloc({required BookRepository bookRepository})
    : _bookRepository = bookRepository,
      super(ProfileInitial()) {
    on<ProfileLoadUserBooks>((event, emit) async {
      emit(ProfileLoading());
      try {
        final results = await Future.wait([
          _bookRepository.getUserBooks(event.userId),
          _bookRepository.getUserReviews(event.userId),
        ]);
        final books = results[0] as List<BookModel>;
        final reviews = results[1] as List<ReviewModel>;
        emit(ProfileSuccess(userBooks: books, userReviews: reviews));
      } catch (e) {
        emit(ProfileFailure(e.toString()));
      }
    });
  }
}
