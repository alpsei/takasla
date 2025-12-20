// lib/features/home/view/widgets/book_card.dart

import 'dart:convert';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:gap/gap.dart';
import '../../../../core/constants/app_colors.dart';
import '../../../../data/models/book_model.dart';

class BookCard extends StatelessWidget {
  final BookModel book;
  final VoidCallback onTap;

  // 👇 YENİ PARAMETRE (Opsiyonel)
  // Eğer bu dolu gelirse veritabanına gitmeyiz, direkt bunu kullanırız.
  final String? ownerPhotoUrl;

  const BookCard({
    super.key,
    required this.book,
    required this.onTap,
    this.ownerPhotoUrl, // 👈 Constructor'a ekle
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildTag(book),
          const Gap(12),

          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      book.title,
                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                        color: AppColors.textPrimary,
                      ),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const Gap(4),
                    Text(
                      book.author,
                      style: const TextStyle(
                        fontSize: 14,
                        color: AppColors.textSecondary,
                      ),
                    ),
                  ],
                ),
              ),
              const Gap(12),
              ClipRRect(
                borderRadius: BorderRadius.circular(8),
                child: _buildBookImage(),
              ),
            ],
          ),

          const Gap(12),
          Divider(color: Colors.grey.shade200),
          const Gap(8),

          // --- ALT KISIM ---
          Row(
            children: [
              // 👇 PROFİL FOTOĞRAFI (GÜNCELLENDİ) 👇
              // Eğer dışarıdan fotoğraf verildiyse onu kullan, yoksa veritabanından çek (Ana sayfa için)
              ownerPhotoUrl != null
                  ? _buildAvatar(ownerPhotoUrl) // Hazır veri
                  : FutureBuilder<DocumentSnapshot>(
                      // Yoksa mecbur çekeceğiz
                      future: FirebaseFirestore.instance
                          .collection('users')
                          .doc(book.ownerId)
                          .get(),
                      builder: (context, snapshot) {
                        if (snapshot.hasData && snapshot.data!.exists) {
                          final data =
                              snapshot.data!.data() as Map<String, dynamic>;
                          return _buildAvatar(data['photoUrl']);
                        }
                        return _buildAvatar(null);
                      },
                    ),

              const Gap(8),
              Expanded(
                child: Text(
                  _getCityOnly(book.location),
                  style: const TextStyle(
                    fontSize: 12,
                    color: AppColors.textSecondary,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
              SizedBox(
                height: 36,
                child: ElevatedButton(
                  onPressed: onTap,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.primary,
                    elevation: 0,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(20),
                    ),
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                  ),
                  child: const Text(
                    "Detaylar",
                    style: TextStyle(fontSize: 13, color: Colors.white),
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  // 👇 AVATAR ÇİZEN YARDIMCI METOD
  Widget _buildAvatar(String? photoData) {
    return CircleAvatar(
      radius: 14,
      backgroundColor: AppColors.primary.withOpacity(0.1),
      backgroundImage: (photoData != null && photoData.isNotEmpty)
          ? (photoData.startsWith('http')
                    ? NetworkImage(photoData)
                    : MemoryImage(base64Decode(photoData)))
                as ImageProvider
          : null,
      child: (photoData == null || photoData.isEmpty)
          ? const Icon(Icons.person, size: 16, color: AppColors.primary)
          : null,
    );
  }

  // ... (Diğer metodlar: _buildBookImage, _buildTag aynı kalsın) ...
  // _buildBookImage kodunu silme, o lazım!
  Widget _buildBookImage() {
    if (book.pdfBase64 != null && book.pdfBase64!.isNotEmpty) {
      return Container(
        width: 70,
        height: 100,
        color: Colors.red.shade50,
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: const [
            Icon(Icons.picture_as_pdf, color: Colors.red, size: 32),
            SizedBox(height: 4),
            Text(
              "PDF",
              style: TextStyle(
                color: Colors.red,
                fontSize: 10,
                fontWeight: FontWeight.bold,
              ),
            ),
          ],
        ),
      );
    }
    if (book.imageUrls.isEmpty) {
      return const Icon(Icons.book, size: 50, color: Colors.grey);
    }

    String imageString = book.imageUrls.first;
    if (imageString.startsWith('http')) {
      return Image.network(
        imageString,
        width: 70,
        height: 100,
        fit: BoxFit.cover,
      );
    }
    try {
      return Image.memory(
        base64Decode(imageString),
        width: 70,
        height: 100,
        fit: BoxFit.cover,
      );
    } catch (e) {
      return const Icon(Icons.error, color: Colors.red);
    }
  }

  Widget _buildTag(BookModel book) {
    // ... (Eski kodun aynısı) ...
    String text = "Diğer";
    Color bg = Colors.grey.shade200;
    Color txt = Colors.grey.shade800;
    if (book.isDonation) {
      text = "Bağış";
      bg = AppColors.tagDonationBg;
      txt = AppColors.tagDonationText;
    } else if (book.isSwap) {
      text = "Takas";
      bg = AppColors.tagSwapBg;
      txt = AppColors.tagSwapText;
    } else if (book.isLoan) {
      text = "Ödünç";
      bg = AppColors.tagLoanBg;
      txt = AppColors.tagLoanText;
    }
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Text(
        text,
        style: TextStyle(color: txt, fontSize: 12, fontWeight: FontWeight.w600),
      ),
    );
  }

  String _getCityOnly(String fullLocation) {
    if (fullLocation.contains(',')) {
      // "Çankaya, Ankara" -> ["Çankaya", " Ankara"] -> " Ankara" -> "Ankara"
      return fullLocation.split(',').last.trim();
    }
    return fullLocation; // Virgül yoksa olduğu gibi göster
  }
}
