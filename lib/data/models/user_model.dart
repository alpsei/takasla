import 'package:equatable/equatable.dart';

class UserModel extends Equatable {
  final String id;
  final String email;
  final String name;
  final String? photoUrl;
  final String? location;
  final int points; // Takas puanı

  final double ratingSum;
  final int ratingCount;

  const UserModel({
    required this.id,
    required this.email,
    required this.name,
    this.photoUrl,
    this.location,
    this.points = 0,
    this.ratingSum = 0.0,
    this.ratingCount = 0,
  });

  // JSON -> Dart
  factory UserModel.fromJson(Map<String, dynamic> json) {
    return UserModel(
      id: json['id'] as String? ?? '',
      email: json['email'] as String? ?? '',
      name: json['name'] as String? ?? '',
      photoUrl: json['photoUrl'] as String?,
      location: json['location'] as String?,
      points: json['points'] as int? ?? 0,
      ratingSum: (json['ratingSum'] as num?)?.toDouble() ?? 0.0,
      ratingCount: json['ratingCount'] as int? ?? 0,
    );
  }

  // Dart -> JSON
  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'email': email,
      'name': name,
      'photoUrl': photoUrl,
      'location': location,
      'points': points,
      'ratingSum': ratingSum,
      'ratingCount': ratingCount,
    };
  }

  double get averageRating {
    if (ratingCount == 0) return 0.0;
    return ratingSum / ratingCount;
  }

  // BLoC'ta state değişimi kontrolü için
  @override
  List<Object?> get props => [
    id,
    email,
    name,
    photoUrl,
    location,
    points,
    ratingSum,
    ratingCount,
  ];
}
