import 'package:equatable/equatable.dart';

class RequestEvent extends Equatable {
  const RequestEvent();
  @override
  List<Object> get props => [];
}

class RequestSent extends RequestEvent {
  final String bookId;
  final String bookTitle;
  final String receiverId; // Kitap sahibi
  final DateTime? startDate;
  final DateTime? endDate;

  const RequestSent({
    required this.bookId,
    required this.bookTitle,
    required this.receiverId,
    this.startDate,
    this.endDate,
  });

  @override
  List<Object> get props => [
    bookId,
    bookTitle,
    receiverId,
    ?startDate,
    ?endDate,
  ];
}

class RequestCheckStatus extends RequestEvent {
  final String bookId;
  final String userId;

  const RequestCheckStatus({required this.bookId, required this.userId});

  @override
  List<Object> get props => [bookId, userId];
}
