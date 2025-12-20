// lib/features/book_detail/view/book_detail_view.dart

import 'dart:convert';
import 'dart:io';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:gap/gap.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';

// 👇 SADECE KENDİ BLOC DOSYALARI
import 'package:kitaptakas/features/book_detail/bloc/request_bloc.dart';
import 'package:kitaptakas/features/book_detail/bloc/request_event.dart';
import 'package:kitaptakas/features/book_detail/bloc/request_state.dart';
import 'package:open_filex/open_filex.dart';
import 'package:path_provider/path_provider.dart';

import '../../../../core/constants/app_colors.dart';
import '../../../../data/models/book_model.dart';
import '../../../../data/repositories/book_repository.dart';
import '../../auth/view/welcome_view.dart';

class BookDetailPage extends StatelessWidget {
  final BookModel book;
  const BookDetailPage({super.key, required this.book});

  @override
  Widget build(BuildContext context) {
    final userId = FirebaseAuth.instance.currentUser?.uid;

    return BlocProvider(
      create: (context) => RequestBloc(bookRepository: BookRepository())
        // Sayfa açılırken kontrol et: Talep var mı?
        ..add(RequestCheckStatus(bookId: book.id, userId: userId ?? "")),
      child: BookDetailView(book: book),
    );
  }
}

class BookDetailView extends StatelessWidget {
  final BookModel book;

  const BookDetailView({super.key, required this.book});

  // Silme Fonksiyonu
  Future<void> _deleteBook(BuildContext context) async {
    final repo = BookRepository();
    try {
      await repo.deleteBook(book.id);
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text("Kitap silindi."),
            backgroundColor: Colors.red,
          ),
        );
        Navigator.pop(context, true);
      }
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text("Hata: $e")));
      }
    }
  }

  void _showDeleteConfirmDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text("Kitabı Sil"),
        content: const Text(
          "Bu kitabı silmek istediğine emin misin? Bu işlem geri alınamaz.",
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text("Vazgeç", style: TextStyle(color: Colors.grey)),
          ),
          TextButton(
            onPressed: () {
              Navigator.pop(ctx);
              _deleteBook(context);
            },
            child: const Text(
              "Sil",
              style: TextStyle(color: Colors.red, fontWeight: FontWeight.bold),
            ),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final currentUserId = FirebaseAuth.instance.currentUser?.uid;
    final isMyBook = book.ownerId == currentUserId;

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: AppColors.background,
        title: const Text(
          "Kitap Detayları",
          style: TextStyle(fontWeight: FontWeight.bold),
        ),
        centerTitle: true,
        actions: [
          if (isMyBook)
            IconButton(
              onPressed: () => _showDeleteConfirmDialog(context),
              icon: const Icon(Icons.delete_outline, color: Colors.red),
            ),
          const Gap(8),
        ],
      ),

      // lib/features/book_detail/view/book_detail_view.dart
      bottomNavigationBar: Container(
        padding: const EdgeInsets.all(16),
        decoration: const BoxDecoration(
          color: Colors.white,
          border: Border(top: BorderSide(color: Colors.black12)),
        ),
        child: isMyBook
            // 1. DURUM: KİTAP BENİMSE
            ? SizedBox(
                height: 56,
                child: Center(
                  child: Text(
                    "Bu senin kendi kitabın 📚",
                    style: TextStyle(
                      color: AppColors.textSecondary,
                      fontWeight: FontWeight.bold,
                      fontSize: 16,
                    ),
                  ),
                ),
              )
            // 👇 2. YENİ DURUM: KİTAP MÜSAİT DEĞİLSE (ONAYLANMIŞSA)
            : (!book.isAvailable)
            ? SizedBox(
                height: 56,
                child: Container(
                  color: Colors.grey.shade300, // Sönük arka plan
                  child: const Center(
                    child: Text(
                      "Bu Kitap Artık Mevcut Değil 🔒",
                      style: TextStyle(
                        color: Colors.black54,
                        fontWeight: FontWeight.bold,
                        fontSize: 16,
                      ),
                    ),
                  ),
                ),
              )
            // 3. DURUM: KİTAP BENİM DEĞİLSE VE MÜSAİTSE
            : (FirebaseAuth.instance.currentUser == null)
            // A. MİSAFİR İSEM
            ? SizedBox(
                width: double.infinity,
                height: 56,
                child: ElevatedButton(
                  onPressed: () {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                        content: Text("İşlem yapmak için giriş yapmalısınız."),
                        backgroundColor: Colors.orange,
                      ),
                    );
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => const WelcomeView(),
                      ),
                    );
                  },
                  style: ElevatedButton.styleFrom(backgroundColor: Colors.grey),
                  child: const Text(
                    "Giriş Yapmalısın",
                    style: TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              )
            // B. GİRİŞ YAPMIŞSAM
            : (book.pdfBase64 != null && book.pdfBase64!.isNotEmpty)
            // 🔥 YENİ EKLENEN KISIM: PDF VARSA İNDİR BUTONU 🔥
            ? SizedBox(
                width: double.infinity,
                height: 56,
                child: ElevatedButton.icon(
                  icon: const Icon(Icons.file_open),
                  label: const Text("PDF'i Görüntüle"),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.red.shade600,
                    foregroundColor: Colors.white,
                  ),
                  onPressed: () async {
                    try {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(
                          content: Text("PDF hazırlanıyor... ⏳"),
                          duration: Duration(seconds: 1),
                        ),
                      );

                      // 1. Base64 Çöz
                      final bytes = base64Decode(book.pdfBase64!);

                      // 2. Klasör Bul
                      final dir = await getTemporaryDirectory();

                      // 3. Dosya Oluştur (İsimdeki boşlukları temizle)
                      final safeTitle = book.title.replaceAll(' ', '_');
                      final file = File('${dir.path}/$safeTitle.pdf');

                      // 4. Yaz
                      await file.writeAsBytes(bytes, flush: true);

                      // 5. Aç
                      final result = await OpenFilex.open(file.path);

                      if (result.type != ResultType.done) {
                        if (context.mounted) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(
                              content: Text(
                                "Dosya açılamadı: ${result.message}",
                              ),
                              backgroundColor: Colors.red,
                            ),
                          );
                        }
                      }
                    } catch (e) {
                      if (context.mounted) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(
                            content: Text("Hata: $e"),
                            backgroundColor: Colors.red,
                          ),
                        );
                      }
                    }
                  },
                ),
              )
            // C. PDF YOKSA TALEP BUTONU (ESKİ BLOC CONSUMER)
            : BlocConsumer<RequestBloc, RequestState>(
                listener: (context, state) {
                  if (state is RequestActionSuccess) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                        content: Text("Talep Başarıyla Gönderildi! 🎉"),
                        backgroundColor: Colors.green,
                      ),
                    );
                  } else if (state is RequestFailure) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: Text("Hata: ${state.error}"),
                        backgroundColor: Colors.red,
                      ),
                    );
                  }
                },
                builder: (context, state) {
                  bool hasRequest = false;
                  bool isLoading = (state is RequestLoading);

                  if (state is RequestStatusLoaded)
                    hasRequest = state.hasRequest;
                  if (state is RequestActionSuccess) hasRequest = true;

                  return SizedBox(
                    width: double.infinity,
                    height: 56,
                    child: ElevatedButton(
                      // Buton zaten griyse veya yükleniyorsa tıklanmasın
                      onPressed: (isLoading || hasRequest)
                          ? null
                          : () async {
                              // 👈 async yaptık çünkü takvim açılacak
                              final currentUserId =
                                  FirebaseAuth.instance.currentUser?.uid;

                              // Ekstra güvenlik (Zaten yukarıda kontrol ediliyor ama olsun)
                              if (currentUserId == null) return;

                              DateTime? start;
                              DateTime? end;

                              // 🗓️ 1. EĞER KİTAP "ÖDÜNÇ" İSE TAKVİM AÇ
                              if (book.isLoan) {
                                final DateTimeRange?
                                dateRange = await showDateRangePicker(
                                  context: context,
                                  firstDate: DateTime.now(), // Geçmiş seçilemez
                                  lastDate: DateTime.now().add(
                                    const Duration(days: 90),
                                  ), // Max 90 gün
                                  helpText: "Ödünç Alma Aralığı Seçin",
                                  cancelText: "İPTAL",
                                  confirmText: "SEÇ",
                                  saveText: "TAMAM",
                                  builder: (context, child) {
                                    return Theme(
                                      data: ThemeData.light().copyWith(
                                        primaryColor: AppColors.primary,
                                        colorScheme: const ColorScheme.light(
                                          primary: AppColors.primary,
                                        ),
                                      ),
                                      child: child!,
                                    );
                                  },
                                );

                                // Kullanıcı tarih seçmeden (İptal) kapatırsa işlemi durdur
                                if (dateRange == null) return;

                                start = dateRange.start;
                                end = dateRange.end;
                              }

                              // 2. TARİHLERLE (VEYA NULL) BİRLİKTE GÖNDER
                              if (context.mounted) {
                                context.read<RequestBloc>().add(
                                  RequestSent(
                                    bookId: book.id,
                                    bookTitle: book.title,
                                    receiverId: book.ownerId,
                                    startDate:
                                        start, // Ödünç ise dolu, değilse null gider
                                    endDate:
                                        end, // Ödünç ise dolu, değilse null gider
                                  ),
                                );
                              }
                            },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: hasRequest
                            ? Colors.grey
                            : AppColors.primary,
                        disabledBackgroundColor: Colors.grey.shade300,
                      ),
                      child: isLoading
                          ? const CircularProgressIndicator(color: Colors.white)
                          : Text(
                              hasRequest
                                  ? "Talep Gönderildi ✅"
                                  : "Talep Gönder",
                              style: TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.bold,
                                color: hasRequest
                                    ? Colors.black54
                                    : Colors.white,
                              ),
                            ),
                    ),
                  );
                },
              ),
      ),

      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            // RESİM
            Center(
              child: Container(
                height: 250,
                width: 170,
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(12),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.1),
                      blurRadius: 4,
                      offset: const Offset(0, 4),
                    ),
                  ],
                ),
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(12),
                  child: Builder(
                    builder: (context) {
                      if (book.imageUrls.isEmpty)
                        return const Icon(Icons.book, size: 50);
                      String imgData = book.imageUrls.first;

                      // URL mi Base64 mü kontrolü
                      if (imgData.startsWith('http')) {
                        return Image.network(imgData, fit: BoxFit.cover);
                      }
                      try {
                        return Image.memory(
                          base64Decode(imgData),
                          fit: BoxFit.cover,
                        );
                      } catch (e) {
                        return const Icon(Icons.broken_image);
                      }
                    },
                  ),
                ),
              ),
            ),
            const Gap(24),
            Text(
              book.title,
              textAlign: TextAlign.center,
              style: const TextStyle(
                fontSize: 22,
                fontWeight: FontWeight.bold,
                color: AppColors.textPrimary,
              ),
            ),
            const Gap(8),
            Text(
              book.author,
              textAlign: TextAlign.center,
              style: const TextStyle(
                fontSize: 16,
                color: AppColors.textSecondary,
                fontWeight: FontWeight.w500,
              ),
            ),
            const Gap(24),
            const Align(
              alignment: Alignment.centerLeft,
              child: Text(
                "Açıklama",
                style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
              ),
            ),
            const Gap(8),
            Text(
              book.description.isEmpty ? "Açıklama yok." : book.description,
              style: TextStyle(
                fontSize: 14,
                color: Colors.grey[700],
                height: 1.5,
              ),
            ),
            const Gap(12),
            // PDF TARAMA SONUCU
            if (book.pdfBase64 != null)
              Container(
                margin: const EdgeInsets.symmetric(vertical: 16),
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.green.shade50,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: Colors.green),
                ),
                child: Row(
                  children: const [
                    Icon(Icons.verified_user, color: Colors.green),
                    SizedBox(width: 12),
                    Expanded(
                      child: Text(
                        "Bu dosya yapay zeka tarafından taranmış ve güvenli bulunmuştur. ✅",
                        style: TextStyle(
                          color: Colors.green,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ],
                ),
              ),

            const Gap(24),
            // Kategori ve Durum
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: [
                _buildInfoBadge(Icons.category, book.category),
                _buildInfoBadge(Icons.thumb_up, book.condition),
              ],
            ),
            const Gap(24),

            // Seçenekler
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: Colors.grey.shade200),
              ),
              child: Column(
                children: [
                  if (book.isDonation)
                    _buildOptionTile(
                      "Bağış",
                      "Bu kitap bağışlanmıştır.",
                      AppColors.tagDonationText,
                      AppColors.tagDonationBg,
                      FontAwesomeIcons.handHoldingHeart,
                    ),
                  if (book.isSwap)
                    _buildOptionTile(
                      "Takas",
                      "Takas edilebilir.",
                      AppColors.tagSwapText,
                      AppColors.tagSwapBg,
                      FontAwesomeIcons.rotate,
                    ),
                  if (book.isLoan)
                    _buildOptionTile(
                      "Ödünç",
                      "Ödünç alabilirsin.",
                      AppColors.tagLoanText,
                      AppColors.tagLoanBg,
                      FontAwesomeIcons.clock,
                    ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildInfoBadge(IconData icon, String text) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: Colors.grey.shade200,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        children: [
          Icon(icon, size: 16, color: Colors.black54),
          const Gap(6),
          Text(text, style: const TextStyle(fontWeight: FontWeight.bold)),
        ],
      ),
    );
  }

  Widget _buildOptionTile(
    String title,
    String subtitle,
    Color color,
    Color bg,
    IconData icon,
  ) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12.0),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(color: bg, shape: BoxShape.circle),
            child: Icon(icon, color: color, size: 20),
          ),
          const Gap(12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: const TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 15,
                  ),
                ),
                Text(
                  subtitle,
                  style: TextStyle(fontSize: 12, color: Colors.grey[600]),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
