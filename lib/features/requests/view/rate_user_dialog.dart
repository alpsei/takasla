// lib/features/requests/view/widgets/rate_user_dialog.dart

import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_rating_bar/flutter_rating_bar.dart'; // 👈 YENİ PAKET
import 'package:gap/gap.dart';
import 'package:kitaptakas/features/requests/bloc/request_bloc.dart';
import 'package:kitaptakas/features/requests/bloc/request_event.dart';

class RateUserDialog extends StatefulWidget {
  final String targetUserId; // Kime puan veriyoruz? (Kitap Sahibi)
  final String bookId; // Hangi kitap için?
  final String requestId;

  const RateUserDialog({
    super.key,
    required this.targetUserId,
    required this.bookId,
    required this.requestId,
  });

  @override
  State<RateUserDialog> createState() => _RateUserDialogState();
}

class _RateUserDialogState extends State<RateUserDialog> {
  double _rating = 5.0; // Varsayılan 5 yıldız
  final _commentController = TextEditingController();

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text("İşlemi Değerlendir", textAlign: TextAlign.center),
      content: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text(
              "Kitap sahibine puan ver ve deneyimini paylaş.",
              textAlign: TextAlign.center,
              style: TextStyle(color: Colors.grey, fontSize: 13),
            ),
            const Gap(20),

            // ⭐ YILDIZ SEÇİCİ
            RatingBar.builder(
              initialRating: 5,
              minRating: 1,
              direction: Axis.horizontal,
              allowHalfRating: true,
              itemCount: 5,
              itemPadding: const EdgeInsets.symmetric(horizontal: 2.0),
              itemBuilder: (context, _) =>
                  const Icon(Icons.star, color: Colors.amber),
              onRatingUpdate: (rating) {
                setState(() => _rating = rating);
              },
            ),
            const Gap(20),

            // 💬 YORUM ALANI
            TextField(
              controller: _commentController,
              maxLines: 3,
              decoration: InputDecoration(
                hintText: "Yorumun nedir? (Opsiyonel)",
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                filled: true,
                fillColor: Colors.grey.shade50,
              ),
            ),
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text("Vazgeç", style: TextStyle(color: Colors.grey)),
        ),
        ElevatedButton(
          onPressed: () {
            // Yorum boşsa bile gönderilsin mi? Evet.
            final currentUser = FirebaseAuth.instance.currentUser;

            if (currentUser != null) {
              // BLoC'a Gönder
              context.read<RequestsBloc>().add(
                RequestsSubmitReview(
                  reviewerId: currentUser.uid,
                  reviewerName:
                      currentUser.displayName ??
                      "Kitap Sever", // İsim yoksa varsayılan
                  targetUserId: widget.targetUserId,
                  bookId: widget.bookId,
                  rating: _rating,
                  comment: _commentController.text.trim(),
                  requestId: widget.requestId,
                ),
              );

              Navigator.pop(context); // Pencereyi kapat

              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  content: Text("Değerlendirmen alındı! Teşekkürler ⭐"),
                  backgroundColor: Colors.green,
                ),
              );
            }
          },
          child: const Text("Gönder"),
        ),
      ],
    );
  }
}
