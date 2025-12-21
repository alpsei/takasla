import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:kitaptakas/features/requests/bloc/request_event.dart';
import 'package:kitaptakas/features/requests/bloc/request_state.dart';
import '../../../../data/repositories/book_repository.dart';

class RequestsBloc extends Bloc<RequestsEvent, RequestsState> {
  final BookRepository _bookRepository;

  RequestsBloc({required BookRepository bookRepository})
    : _bookRepository = bookRepository,
      super(RequestsInitial()) {
    // Talepleri Getir
    on<RequestsLoad>((event, emit) async {
      emit(RequestsLoading());
      try {
        final requests = await _bookRepository.getIncomingRequests(
          event.userId,
        );
        emit(RequestsSuccess(requests));
      } catch (e) {
        emit(RequestsFailure(e.toString()));
      }
    });

    // Durum Güncelle
    on<RequestsUpdateStatus>((event, emit) async {
      try {
        await _bookRepository.updateRequestStatus(
          event.requestId,
          event.newStatus,
        );
        // İşlem bitince listeyi yenile
        add(RequestsLoad(event.userId));
      } catch (e) {
        emit(RequestsFailure("İşlem başarısız: $e"));
      }
    });
    on<RequestsLoadSent>((event, emit) async {
      emit(RequestsLoading());
      try {
        // Repodaki YENİ fonksiyonu çağır
        final requests = await _bookRepository.getSentRequests(event.userId);
        emit(RequestsSuccess(requests));
      } catch (e) {
        emit(RequestsFailure(e.toString()));
      }
    });
    on<RequestsSubmitReview>((event, emit) async {
      try {
        await _bookRepository.addReview(
          reviewerId: event.reviewerId,
          reviewerName: event.reviewerName,
          targetUserId: event.targetUserId,
          bookId: event.bookId,
          rating: event.rating,
          comment: event.comment,
          requestId: event.requestId,
        );
      } catch (e) {
        emit(RequestsFailure("Yorum yapılamadı: $e"));
      }
    });
    on<RequestsConfirmDelivery>((event, emit) async {
      try {
        await _bookRepository.confirmDelivery(
          requestId: event.requestId,
          isSeller: event.isSeller,
          status: event.status,
        );
      } catch (e) {
        emit(RequestsFailure("Hata: $e"));
      }
    });
  }
}
