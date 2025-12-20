import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:equatable/equatable.dart';

class ReviewModel extends Equatable {
  final String id;
  final String reviewerId;
  final String reviewerName;
  final String targetUserId;
  final String bookId;
  final double rating;
  final String comment;
  final DateTime timestamp;
  final String requestId;

  const ReviewModel({
    required this.id,
    required this.reviewerId,
    required this.reviewerName,
    required this.targetUserId,
    required this.bookId,
    required this.rating,
    required this.comment,
    required this.timestamp,
    required this.requestId,
  });

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'reviewerId': reviewerId,
      'reviewerName': reviewerName,
      'targetUserId': targetUserId,
      'bookId': bookId,
      'rating': rating,
      'comment': comment,
      'timestamp': Timestamp.fromDate(timestamp),
      'requestId': requestId,
    };
  }

  factory ReviewModel.fromJson(Map<String, dynamic> json) {
    return ReviewModel(
      id: json['id'] as String? ?? '',
      reviewerId: json['reviewerId'] as String? ?? '',
      reviewerName: json['reviewerName'] as String? ?? 'Anonim',
      targetUserId: json['targetUserId'] as String? ?? '',
      bookId: json['bookId'] as String? ?? '',
      rating: (json['rating'] as num?)?.toDouble() ?? 0.0,
      comment: json['comment'] as String? ?? '',
      timestamp: (json['timestamp'] as Timestamp?)?.toDate() ?? DateTime.now(),
      requestId: json['requestId'] as String? ?? '',
    );
  }

  @override
  List<Object> get props => [
    id,
    reviewerId,
    targetUserId,
    bookId,
    rating,
    requestId,
  ];
}
