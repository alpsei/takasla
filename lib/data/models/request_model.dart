import 'package:equatable/equatable.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class RequestModel extends Equatable {
  final String id;
  final String bookId; // Talep edilen kitabın ID'si
  final String bookTitle; // Talep edilen kitabın Adı
  final String senderId; // Talep gönderen kişinin ID'si
  final String receiverId; // Kitap sahibinin ID'si
  final String status; // "Beklemede", "Onaylandı", "Reddedildi"
  final DateTime sentAt;
  final String? buyerStatus;
  final String? sellerStatus;
  final DateTime? loanStartDate;
  final DateTime? loanEndDate;
  final String senderName;

  const RequestModel({
    required this.id,
    required this.bookId,
    required this.bookTitle,
    required this.senderId,
    required this.receiverId,
    this.status = 'Beklemede',
    required this.sentAt,
    this.buyerStatus,
    this.sellerStatus,
    this.loanStartDate,
    this.loanEndDate,
    required this.senderName,
  });

  // Firestore'dan gelen veriyi Modele çevir
  factory RequestModel.fromJson(Map<String, dynamic> json) {
    return RequestModel(
      id: json['id'] as String? ?? '',
      bookId: json['bookId'] as String? ?? '',
      bookTitle: json['bookTitle'] as String? ?? '',
      senderId: json['senderId'] as String? ?? '',
      receiverId: json['receiverId'] as String? ?? '',
      status: json['status'] as String? ?? 'Beklemede',
      sentAt: (json['sentAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
      buyerStatus: (json['buyerStatus'] as String?),
      sellerStatus: (json['sellerStatus' as String?]),
      loanStartDate: (json['loanStartDate'] as Timestamp?)?.toDate(),
      loanEndDate: (json['loanEndDate'] as Timestamp?)?.toDate(),
      senderName: json['senderName'] as String? ?? 'İsimsiz Kullanıcı',
    );
  }

  // Modeli Firestore'a göndermek için JSON'a çevir
  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'bookId': bookId,
      'bookTitle': bookTitle,
      'senderId': senderId,
      'receiverId': receiverId,
      'status': status,
      'sentAt': Timestamp.fromDate(sentAt),
      'buyerStatus': buyerStatus,
      'sellerStatus': sellerStatus,
      'loanStartDate': loanStartDate != null
          ? Timestamp.fromDate(loanStartDate!)
          : null,
      'loanEndDate': loanEndDate != null
          ? Timestamp.fromDate(loanEndDate!)
          : null,
      'senderName': senderName,
    };
  }

  @override
  List<Object> get props => [
    id,
    bookId,
    senderId,
    receiverId,
    status,
    ?buyerStatus,
    ?sellerStatus,
    ?loanStartDate,
    ?loanEndDate,
    senderName,
  ];
}
