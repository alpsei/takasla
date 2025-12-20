import 'package:equatable/equatable.dart';
import 'package:cloud_firestore/cloud_firestore.dart'; // Timestamp için

class BookModel extends Equatable {
  final String id;
  final String title;
  final String author;
  final String description;
  final String publisher;
  final String category; // "Sınav Kitabı" veya "Okuma Kitabı"
  final String condition; // "Yeni", "İyi", "Yıpranmış"
  final List<String> imageUrls;
  final String ownerId; // Kitabı yükleyen kullanıcının ID'si
  final String location; // Elden teslim konumu
  final bool isAvailable;
  final String? pdfBase64;

  // Paylaşım Türleri
  final bool isDonation; // Bağış
  final bool isSwap; // Takas
  final bool isLoan; // Ödünç

  final DateTime createdAt; // Yüklenme tarihi

  const BookModel({
    required this.id,
    required this.title,
    required this.author,
    required this.description,
    this.publisher = '',
    required this.category,
    required this.condition,
    required this.imageUrls,
    required this.ownerId,
    required this.location,
    this.isDonation = false,
    this.isSwap = false,
    this.isLoan = false,
    this.isAvailable = true,
    required this.createdAt,
    this.pdfBase64,
  });

  // JSON -> Dart
  factory BookModel.fromJson(Map<String, dynamic> json) {
    return BookModel(
      id: json['id'] as String? ?? '',
      title: json['title'] as String? ?? '',
      author: json['author'] as String? ?? '',
      description: json['description'] as String? ?? '',
      publisher: json['publisher'] as String? ?? '',
      category: json['category'] as String? ?? '',
      condition: json['condition'] as String? ?? '',
      imageUrls: List<String>.from(json['imageUrls'] ?? []),
      ownerId: json['ownerId'] as String? ?? '',
      location: json['location'] as String? ?? '',
      isDonation: json['isDonation'] as bool? ?? false,
      isSwap: json['isSwap'] as bool? ?? false,
      isLoan: json['isLoan'] as bool? ?? false,
      isAvailable: (json['isAvailable'] as bool?) ?? true,
      createdAt: (json['createdAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
      pdfBase64: json['pdfBase64'] as String?,
    );
  }

  // Dart  -> JSON
  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'title': title,
      'author': author,
      'description': description,
      'publisher': publisher,
      'category': category,
      'condition': condition,
      'imageUrls': imageUrls,
      'ownerId': ownerId,
      'location': location,
      'isDonation': isDonation,
      'isSwap': isSwap,
      'isLoan': isLoan,
      'isAvailable': isAvailable,
      'createdAt': Timestamp.fromDate(createdAt), // DateTime -> Timestamp
      'pdfBase64': pdfBase64,
    };
  }

  @override
  List<Object?> get props => [
    id,
    title,
    author,
    ownerId,
    createdAt,
    isAvailable,
    pdfBase64,
  ];
}
