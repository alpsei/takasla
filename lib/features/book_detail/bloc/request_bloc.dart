import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:kitaptakas/features/book_detail/bloc/request_state.dart';
import '../../../../data/repositories/book_repository.dart';
import 'request_event.dart';

class RequestBloc extends Bloc<RequestEvent, RequestState> {
  final BookRepository _bookRepository;

  RequestBloc({required BookRepository bookRepository})
    : _bookRepository = bookRepository,
      super(RequestInitial()) {
    on<RequestSent>(_onRequestSent);
    on<RequestCheckStatus>((event, emit) async {
      try {
        final exists = await _bookRepository.checkIfRequestExists(
          event.bookId,
          event.userId,
        );
        emit(RequestStatusLoaded(exists));
      } catch (e) {
        emit(const RequestStatusLoaded(false));
      }
    });
  }

  Future<void> _onRequestSent(
    RequestSent event,
    Emitter<RequestState> emit,
  ) async {
    emit(RequestLoading());
    try {
      final senderId = FirebaseAuth.instance.currentUser?.uid;

      if (senderId == null) {
        emit(const RequestFailure("Giriş yapmalısınız."));
        return;
      }

      await _bookRepository.sendBookRequest(
        bookId: event.bookId,
        bookTitle: event.bookTitle,
        senderId: senderId,
        receiverId: event.receiverId,
        startDate: event.startDate,
        endDate: event.endDate,
      );

      emit(RequestActionSuccess());
    } catch (e) {
      emit(RequestFailure(e.toString().replaceAll("Exception: ", "")));
    }
  }
}
