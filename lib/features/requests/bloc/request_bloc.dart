import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:kitaptakas/features/requests/bloc/request_event.dart';
import 'package:kitaptakas/features/requests/bloc/request_state.dart';
import '../../../../data/repositories/book_repository.dart';

class RequestsBloc extends Bloc<RequestsEvent, RequestsState> {
  final BookRepository _bookRepository;

  RequestsBloc({required BookRepository bookRepository})
    : _bookRepository = bookRepository,
      super(RequestsInitial()) {
    // 1. Talepleri Getir
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

    // 2. Durum Güncelle
    on<RequestsUpdateStatus>((event, emit) async {
      // Mevcut listeyi kaybetmemek için loading yapmıyoruz, direkt işlemi yapıyoruz
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
      // Loading vermiyoruz ki liste kaybolmasın, arkada yapsın
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
        // Listeyi yenile (Alıcı veya Satıcı ID'sine göre - Şimdilik basitçe reload yapalım)
        // Burada basit bir trick: Hangi sayfadaysak oranın Load eventini tetiklemek gerekir.
        // Şimdilik state'i Success olarak tekrar emit edelim veya failure vermeyelim yeter.
      } catch (e) {
        emit(RequestsFailure("Hata: $e"));
      }
    });
  }
}
