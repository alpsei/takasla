import 'package:equatable/equatable.dart';
import 'package:kitaptakas/features/book_detail/bloc/request_event.dart';

abstract class RequestsEvent extends Equatable {
  const RequestsEvent();
  @override
  List<Object> get props => [];
}

// Talepleri Yükle
class RequestsLoad extends RequestsEvent {
  final String userId;
  const RequestsLoad(this.userId);
}

// Durumu Güncelle
class RequestsUpdateStatus extends RequestsEvent {
  final String requestId;
  final String newStatus;
  final String userId;

  const RequestsUpdateStatus({
    required this.requestId,
    required this.newStatus,
    required this.userId,
  });
}

class RequestsLoadSent extends RequestsEvent {
  final String userId;
  const RequestsLoadSent(this.userId);
}

class RequestsSubmitReview extends RequestsEvent {
  final String reviewerId;
  final String reviewerName;
  final String targetUserId;
  final String bookId;
  final double rating;
  final String comment;
  final String requestId;

  const RequestsSubmitReview({
    required this.reviewerId,
    required this.reviewerName,
    required this.targetUserId,
    required this.bookId,
    required this.rating,
    required this.comment,
    required this.requestId,
  });

  @override
  List<Object> get props => [reviewerId, targetUserId, bookId, rating, comment];
}

class RequestsConfirmDelivery extends RequestsEvent {
  final String requestId;
  final bool isSeller;
  final String status; // 'success' veya 'failed'

  const RequestsConfirmDelivery({
    required this.requestId,
    required this.isSeller,
    required this.status,
  });
}
