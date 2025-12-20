import 'dart:io'; // Dosya (Resim) işlemi için
import 'package:equatable/equatable.dart';
import 'package:file_picker/file_picker.dart';

abstract class AddBookEvent extends Equatable {
  const AddBookEvent();

  @override
  List<Object?> get props => [];
}

// Kullanıcı "Yükle" butonuna bastığında tetiklenen olay
class AddBookSubmitted extends AddBookEvent {
  final String title;
  final String author;
  final String category;
  final String condition;
  final File? imageFile; // Seçilen resim dosyası
  final String location;
  final PlatformFile? pdfFile;

  // Checkbox değerleri
  final bool isDonation;
  final bool isSwap;
  final bool isLoan;

  const AddBookSubmitted({
    required this.title,
    required this.author,
    required this.category,
    required this.condition,
    this.imageFile,
    required this.location,
    required this.isDonation,
    required this.isSwap,
    required this.isLoan,
    this.pdfFile,
  });

  @override
  List<Object?> get props => [
    title,
    author,
    category,
    condition,
    imageFile,
    location,
    isDonation,
    isSwap,
    isLoan,
    pdfFile,
  ];
}
