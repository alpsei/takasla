import 'dart:convert';
import 'dart:io';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:file_picker/file_picker.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:get_it/get_it.dart';
import 'package:google_generative_ai/google_generative_ai.dart';
import 'package:kitaptakas/data/models/request_model.dart';
import 'package:kitaptakas/data/models/review_model.dart';
import 'package:uuid/uuid.dart';
import '../models/book_model.dart';
import 'package:image/image.dart' as img;

class BookRepository {
  BookRepository();

  // Kitap Ekleme
  Future<void> addBook({
    required String title,
    required String author,
    required String category,
    required String condition,
    required String ownerId,
    required String location,
    required File? imageFile,
    PlatformFile? pdfFile,
    bool isDonation = false,
    bool isSwap = false,
    bool isLoan = false,
  }) async {
    try {
      final firestore = FirebaseFirestore.instance;
      final storage = FirebaseStorage.instance;

      String bookId = const Uuid().v4();
      List<String> imageUrls = [];
      String? pdfData;

      // Resim Yükleme
      if (imageFile != null) {
        final bytes = await imageFile.readAsBytes();
        img.Image? originalImage = img.decodeImage(bytes);
        if (originalImage != null) {
          img.Image resizedImage = img.copyResize(originalImage, width: 600);
          List<int> compressedByte = img.encodeJpg(resizedImage, quality: 70);
          String base64Image = base64Encode(compressedByte);
          imageUrls.add(base64Image);
        }
      }

      if (pdfFile != null) {
        print("pdf analizi başlıyor..");

        if (pdfFile.size > 500 * 1024) {
          throw Exception("PDF çok büyük! Lütfen 500 KB altı bir dosya seçin");
        }

        final bytes = pdfFile.bytes ?? await File(pdfFile.path!).readAsBytes();

        final apiKey = dotenv.env['GEMINI_API_KEY'];

        if (apiKey != null && apiKey.isNotEmpty) {
          try {
            final model = GenerativeModel(
              model: 'gemini-2.0-flash',
              apiKey: apiKey,
            );

            final prompt = TextPart(
              "Bu PDF dosyasını analiz et.Eğer içeriği ders notu, kitap özeti veya eğitim materyaliyse ve güvenliyse sadece 'ONAY' yaz. Eğer cinsel içerik, nefret söylemi veya yasadışı bir içerik varsa sadece 'RET' yaz.",
            );
            final pdfPart = DataPart('application/pdf', bytes);

            final response = await model.generateContent([
              Content.multi([prompt, pdfPart]),
            ]);

            final resultText = response.text?.trim().toUpperCase() ?? "";
            print("AI Sonucu: $resultText");

            if (resultText.contains("RET")) {
              throw Exception("UYGUNSUZ_ICERIK");
            }
          } catch (e) {
            if (e.toString().contains("UYGUNSUZ_ICERIK")) {
              throw Exception(
                "Bu dosya 'Uygunsuz İçerik' nedeniyle yapay zeka tarafından reddedildi! Yükleme iptal edildi.",
              );
            }
          }
        }
        pdfData = base64Encode(bytes);
      }

      // Modeli Oluştur
      final newBook = BookModel(
        id: bookId,
        title: title,
        author: author,
        description: '',
        category: category,
        condition: condition,
        imageUrls: imageUrls,
        ownerId: ownerId,
        location: location,
        isDonation: isDonation,
        isSwap: isSwap,
        isLoan: isLoan,
        createdAt: DateTime.now(),
        pdfBase64: pdfData,
      );

      // 3. Kaydet
      await firestore.collection('books').doc(bookId).set(newBook.toJson());
    } catch (e) {
      throw Exception("Kitap eklenirken hata: $e");
    }
  }

  // Kitap Getirme
  Future<List<BookModel>> getBooks() async {
    try {
      final firestore = FirebaseFirestore.instance;

      final snapshot = await firestore
          .collection('books')
          .where('isAvailable', isEqualTo: true)
          .orderBy('createdAt', descending: true)
          .get();

      return snapshot.docs
          .map((doc) => BookModel.fromJson(doc.data()))
          .toList();
    } catch (e) {
      throw Exception("Kitaplar getirilemedi: $e");
    }
  }

  Future<List<BookModel>> getUserBooks(String userId) async {
    try {
      final firestore = FirebaseFirestore.instance;

      final snapshot = await firestore
          .collection('books')
          .where('ownerId', isEqualTo: userId)
          .orderBy('createdAt', descending: true)
          .get();

      return snapshot.docs
          .map((doc) => BookModel.fromJson(doc.data()))
          .toList();
    } catch (e) {
      throw Exception("Kullanıcı kitapları getirilemedi: $e");
    }
  }

  Future<void> sendBookRequest({
    required String bookId,
    required String bookTitle,
    required String senderId,
    required String receiverId,
    DateTime? startDate,
    DateTime? endDate,
  }) async {
    final firestore = FirebaseFirestore.instance;
    final existingRequest = await firestore
        .collection('requests')
        .where('bookId', isEqualTo: bookId)
        .where('senderId', isEqualTo: senderId)
        .get();

    if (existingRequest.docs.isNotEmpty) {
      throw Exception("Bu kitap için zaten bir talebiniz var!");
    }
    final userRef = firestore.collection('users').doc(senderId);
    final requestRef = firestore.collection('requests').doc();

    try {
      await firestore.runTransaction((transaction) async {
        final userSnapshot = await transaction.get(userRef);
        if (!userSnapshot.exists) {
          throw Exception("Kullanıcı Bulunamadı");
        }
        final currentPoints = userSnapshot.data()?['tradePoints'] ?? 0;
        final senderName = userSnapshot.data()?['name'] ?? 'Kitap Sever';

        if (currentPoints < 20) {
          throw Exception("Yetersiz puan! Talep için en az 20 puanın olmalı.");
        }

        final newRequest = RequestModel(
          id: requestRef.id,
          bookId: bookId,
          bookTitle: bookTitle,
          senderId: senderId,
          receiverId: receiverId,
          sentAt: DateTime.now(),
          status: "Beklemede",
          loanStartDate: startDate,
          loanEndDate: endDate,
          senderName: senderName,
        );
        transaction.update(userRef, {'tradePoints': currentPoints - 20});
        transaction.set(requestRef, newRequest.toJson());
      });
    } catch (e) {
      throw Exception("Talep gönderilirken hata oluştu: $e");
    }
  }

  Future<List<RequestModel>> getIncomingRequests(String userId) async {
    try {
      final firestore = FirebaseFirestore.instance;
      final snapshot = await firestore
          .collection('requests')
          .where('receiverId', isEqualTo: userId)
          .orderBy('sentAt', descending: true)
          .get();
      return snapshot.docs
          .map((doc) => RequestModel.fromJson(doc.data()))
          .toList();
    } catch (e) {
      throw Exception("Talepler getirilemedi: $e");
    }
  }

  Future<void> updateRequestStatus(String requestId, String newStatus) async {
    final firestore = FirebaseFirestore.instance;
    final requestRef = firestore.collection('requests').doc(requestId);

    try {
      await firestore.runTransaction((transaction) async {
        // 1. Talebin güncel halini çek (Kimin gönderdiğini bulmamız lazım)
        final requestSnapshot = await transaction.get(requestRef);

        if (!requestSnapshot.exists) {
          throw Exception("Talep bulunamadı!");
        }

        final senderId = requestSnapshot.data()?['senderId'];
        final bookId = requestSnapshot.data()?['bookId'];
        // 2. Eğer reddedildi ise puanı iade et
        if (newStatus == 'Reddedildi') {
          final userRef = firestore.collection('users').doc(senderId);
          final userSnapshot = await transaction.get(userRef);

          if (userSnapshot.exists) {
            final currentPoints = userSnapshot.data()?['tradePoints'] ?? 0;
            // 20 Puanı geri ver
            transaction.update(userRef, {'tradePoints': currentPoints + 20});
          }
        }
        if (newStatus == 'Onaylandı') {
          final bookRef = firestore.collection('books').doc(bookId);
          transaction.update(bookRef, {'isAvailable': false});
        }

        // Talebin durumunu güncelle
        transaction.update(requestRef, {'status': newStatus});
      });
    } catch (e) {
      throw Exception("İşlem sırasında hata: $e");
    }
  }

  Future<List<RequestModel>> getSentRequests(String userId) async {
    try {
      final snapshot = await FirebaseFirestore.instance
          .collection('requests')
          .where('senderId', isEqualTo: userId)
          .orderBy('sentAt', descending: true)
          .get();

      return snapshot.docs
          .map((doc) => RequestModel.fromJson(doc.data()))
          .toList();
    } catch (e) {
      throw Exception("Giden talepler alınamadı: $e");
    }
  }

  Future<void> deleteBook(String bookId) async {
    try {
      final firestore = FirebaseFirestore.instance;
      await firestore.collection("books").doc(bookId).delete();
    } catch (e) {
      throw Exception("Kitap silinirken hata oluştu $e");
    }
  }

  Future<bool> checkIfRequestExists(String bookId, String userId) async {
    try {
      final firestore = FirebaseFirestore.instance;
      final snapshot = await firestore
          .collection('requests')
          .where('bookId', isEqualTo: bookId)
          .where('senderId', isEqualTo: userId)
          .limit(1)
          .get();

      return snapshot.docs.isNotEmpty;
    } catch (e) {
      return false;
    }
  }

  Future<void> addReview({
    required String reviewerId,
    required String reviewerName,
    required String targetUserId,
    required String bookId,
    required double rating,
    required String comment,
    required String requestId,
  }) async {
    final firestore = FirebaseFirestore.instance;

    // 1. Referansları Hazırla
    final userRef = firestore.collection('users').doc(targetUserId);
    final reviewRef = firestore.collection('reviews').doc();

    try {
      await firestore.runTransaction((transaction) async {
        final userSnapshot = await transaction.get(userRef);

        if (!userSnapshot.exists) {
          throw Exception("Kullanıcı bulunamadı!");
        }
        final currentSum =
            (userSnapshot.data()?['ratingSum'] as num?)?.toDouble() ?? 0.0;
        final currentCount = (userSnapshot.data()?['ratingCount'] as int?) ?? 0;
        final newSum = currentSum + rating;
        final newCount = currentCount + 1;
        transaction.update(userRef, {
          'ratingSum': newSum,
          'ratingCount': newCount,
        });
        final newReview = ReviewModel(
          id: reviewRef.id,
          reviewerId: reviewerId,
          reviewerName: reviewerName,
          targetUserId: targetUserId,
          bookId: bookId,
          rating: rating,
          comment: comment,
          timestamp: DateTime.now(),
          requestId: requestId,
        );

        transaction.set(reviewRef, newReview.toJson());
      });
    } catch (e) {
      throw Exception("Yorum eklenirken hata oluştu: $e");
    }
  }

  Future<List<ReviewModel>> getUserReviews(String userId) async {
    try {
      final snapshot = await FirebaseFirestore.instance
          .collection('reviews')
          .where('targetUserId', isEqualTo: userId) // O kişiye yapılanlar
          .orderBy('timestamp', descending: true) // En yeniden eskiye
          .get();

      return snapshot.docs
          .map((doc) => ReviewModel.fromJson(doc.data()))
          .toList();
    } catch (e) {
      throw Exception("Yorumlar getirilemedi: $e");
    }
  }

  // lib/data/repositories/book_repository.dart

  // --- TESLİMAT ONAYLA (DÜZELTİLMİŞ VERSİYON) ---
  Future<void> confirmDelivery({
    required String requestId,
    required bool isSeller,
    required String status,
  }) async {
    final firestore = FirebaseFirestore.instance;
    final requestRef = firestore.collection('requests').doc(requestId);

    try {
      await firestore.runTransaction((transaction) async {
        // 1. ÖNCE TÜM OKUMALARI YAP (READS FIRST) 📖
        final snapshot = await transaction.get(requestRef);
        if (!snapshot.exists) throw Exception("Talep bulunamadı.");

        final data = snapshot.data()!;
        final senderId = data['senderId'];
        final bookId = data['bookId'];

        // Karşı tarafın durumunu şimdiden öğren
        String otherStatus = isSeller
            ? (data['buyerStatus'] ?? '')
            : (data['sellerStatus'] ?? '');

        // Puan iadesi için gönderen kullanıcının verisini de şimdiden okuyalım
        // (Lazım olmasa bile okumak transaction kuralını bozmaz, ama yazmadan önce olmalı)
        final senderRef = firestore.collection('users').doc(senderId);
        final senderSnap = await transaction.get(senderRef);
        final currentPoints = senderSnap.data()?['tradePoints'] ?? 0;

        // 2. MANTIĞI KUR VE DEĞİŞKENLERİ HAZIRLA 🧠
        Map<String, dynamic> requestUpdates = {};
        Map<String, dynamic> userUpdates = {};
        Map<String, dynamic> bookUpdates = {};
        bool isCompleted = false;

        // Benim durumumu güncelle
        if (isSeller) {
          requestUpdates['sellerStatus'] = status;
        } else {
          requestUpdates['buyerStatus'] = status;
        }

        // Eğer İKİMİZ DE "success" dediysek işlem tamamlanacak
        if (status == 'success' && otherStatus == 'success') {
          isCompleted = true;
          requestUpdates['status'] = 'Tamamlandı';
          bookUpdates['isAvailable'] = false;
          userUpdates['tradePoints'] = currentPoints + 20;
        }

        // 3. ŞİMDİ YAZMA İŞLEMLERİNİ YAP (WRITES LAST) ✍️

        // A. Talebi Güncelle
        transaction.update(requestRef, requestUpdates);

        // B. İşlem Tamamlandıysa Diğerlerini Güncelle
        if (isCompleted) {
          final bookRef = firestore.collection('books').doc(bookId);
          transaction.update(bookRef, bookUpdates); // Kitabı kapat
          transaction.update(senderRef, userUpdates); // Puanı iade et
        }
      });
    } catch (e) {
      throw Exception("Onaylama hatası: $e");
    }
  }

  Future<bool> hasUserReviewed(String requestId) async {
    try {
      final snapshot = await FirebaseFirestore.instance
          .collection('reviews')
          .where('requestId', isEqualTo: requestId)
          .limit(1)
          .get();
      return snapshot.docs.isNotEmpty;
    } catch (e) {
      return false;
    }
  }
}
