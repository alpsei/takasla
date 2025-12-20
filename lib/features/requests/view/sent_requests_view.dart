import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:gap/gap.dart';
import 'package:kitaptakas/data/models/request_model.dart';
import 'package:kitaptakas/features/chat/view/chat_view.dart';
import 'package:kitaptakas/features/requests/bloc/request_bloc.dart';
import 'package:kitaptakas/features/requests/bloc/request_event.dart';
import 'package:kitaptakas/features/requests/bloc/request_state.dart';
import 'package:kitaptakas/features/requests/view/rate_user_dialog.dart';
import '../../../../data/repositories/book_repository.dart';

class SentRequestsPage extends StatelessWidget {
  const SentRequestsPage({super.key});

  @override
  Widget build(BuildContext context) {
    final userId = FirebaseAuth.instance.currentUser?.uid ?? "";
    return BlocProvider(
      create: (context) =>
          RequestsBloc(bookRepository: BookRepository())
            ..add(RequestsLoadSent(userId)),
      child: const SentRequestsView(),
    );
  }
}

class SentRequestsView extends StatelessWidget {
  const SentRequestsView({super.key});

  // Tarih Formatlayıcı
  String _formatDate(DateTime date) {
    return "${date.day}/${date.month}/${date.year}";
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("Gönderdiğim Talepler")),
      body: BlocBuilder<RequestsBloc, RequestsState>(
        builder: (context, state) {
          if (state is RequestsLoading) {
            return const Center(child: CircularProgressIndicator());
          }
          if (state is RequestsFailure) {
            return Center(child: Text("Hata: ${state.error}"));
          }

          if (state is RequestsSuccess) {
            if (state.requests.isEmpty) {
              return const Center(child: Text("Henüz talep göndermediniz."));
            }

            return ListView.separated(
              padding: const EdgeInsets.all(16),
              itemCount: state.requests.length,
              separatorBuilder: (context, index) => const Gap(12),
              itemBuilder: (context, index) {
                final req = state.requests[index];
                final isAccepted = req.status == 'Onaylandı';

                return Card(
                  elevation: 2,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Padding(
                    padding: const EdgeInsets.all(16),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // BAŞLIK VE DURUM
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Expanded(
                              child: Text(
                                req.bookTitle,
                                style: const TextStyle(
                                  fontWeight: FontWeight.bold,
                                  fontSize: 16,
                                ),
                              ),
                            ),
                            Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 8,
                                vertical: 4,
                              ),
                              decoration: BoxDecoration(
                                color: _getStatusColor(
                                  req.status,
                                ).withOpacity(0.1),
                                borderRadius: BorderRadius.circular(8),
                              ),
                              child: Text(
                                req.status,
                                style: TextStyle(
                                  color: _getStatusColor(req.status),
                                  fontWeight: FontWeight.bold,
                                  fontSize: 12,
                                ),
                              ),
                            ),
                          ],
                        ),

                        // 👇 TARİH ARALIĞI GÖSTERİMİ (YENİ EKLENEN KISIM) 👇
                        if (req.loanStartDate != null &&
                            req.loanEndDate != null) ...[
                          const Gap(8),
                          Row(
                            children: [
                              const Icon(
                                Icons.av_timer,
                                size: 14,
                                color: Colors.orange,
                              ),
                              const Gap(6),
                              Text(
                                "Ödünç Süresi: ${_calculateDays(req.loanStartDate!, req.loanEndDate!)}",
                                style: const TextStyle(
                                  fontSize: 12,
                                  color: Colors.black87,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ],
                          ),
                        ],

                        // İŞLEM BUTONLARI
                        if (isAccepted) ...[
                          const Divider(height: 24),
                          Row(
                            children: [
                              Expanded(
                                child: ElevatedButton.icon(
                                  onPressed: () {
                                    Navigator.push(
                                      context,
                                      MaterialPageRoute(
                                        builder: (context) => ChatPage(
                                          requestId: req.id,
                                          chatTitle: req.bookTitle,
                                        ),
                                      ),
                                    );
                                  },
                                  icon: const Icon(Icons.chat, size: 18),
                                  label: const Text("Satıcıyla İletişime Geç"),
                                  style: ElevatedButton.styleFrom(
                                    backgroundColor: Colors.green,
                                    foregroundColor: Colors.white,
                                  ),
                                ),
                              ),
                              const Gap(8),

                              // PUANLA BUTONU
                              Expanded(
                                child: FutureBuilder<bool>(
                                  // Bu işlem için yorum var mı kontrol et
                                  future: BookRepository().hasUserReviewed(
                                    req.id,
                                  ),
                                  builder: (context, snapshot) {
                                    // Henüz yükleniyorsa veya hata varsa
                                    if (!snapshot.hasData) {
                                      return const SizedBox(); // Veya loading
                                    }

                                    final isRated = snapshot.data!;

                                    return ElevatedButton.icon(
                                      onPressed: isRated
                                          ? null // Puanlandıysa tıklanmasın
                                          : () async {
                                              await showDialog(
                                                context: context,
                                                builder: (_) => BlocProvider.value(
                                                  value: context
                                                      .read<RequestsBloc>(),
                                                  child: RateUserDialog(
                                                    requestId: req
                                                        .id, // 👈 ID'yi gönder
                                                    targetUserId:
                                                        req.receiverId,
                                                    bookId: req.bookId,
                                                  ),
                                                ),
                                              );
                                              // Dialog kapanınca sayfayı yenile (Buton güncellensin)
                                              if (context.mounted) {
                                                final currentUserId =
                                                    FirebaseAuth
                                                        .instance
                                                        .currentUser
                                                        ?.uid ??
                                                    "";
                                                context
                                                    .read<RequestsBloc>()
                                                    .add(
                                                      RequestsLoadSent(
                                                        currentUserId,
                                                      ),
                                                    );
                                              }
                                            },
                                      icon: isRated
                                          ? const Icon(Icons.check, size: 18)
                                          : const Icon(Icons.star, size: 18),
                                      label: Text(
                                        isRated ? "Puanlandı" : "Puanla",
                                      ),
                                      style: ElevatedButton.styleFrom(
                                        backgroundColor: isRated
                                            ? Colors.grey.shade300
                                            : Colors.amber,
                                        foregroundColor: isRated
                                            ? Colors.grey.shade700
                                            : Colors.black87,
                                        elevation: isRated ? 0 : 2,
                                      ),
                                    );
                                  },
                                ),
                              ),
                            ],
                          ),
                          // TESLİMAT ONAY BUTONU (Alıcı İçin - false)
                          _buildDeliveryActions(context, req, false),
                        ],
                      ],
                    ),
                  ),
                );
              },
            );
          }
          return const SizedBox();
        },
      ),
    );
  }

  Color _getStatusColor(String status) {
    switch (status) {
      case 'Onaylandı':
        return Colors.green;
      case 'Reddedildi':
        return Colors.red;
      default:
        return Colors.orange;
    }
  }

  // Ortak Teslimat Butonları
  Widget _buildDeliveryActions(
    BuildContext context,
    RequestModel req,
    bool isSeller,
  ) {
    if (req.status == 'Tamamlandı' ||
        req.status == 'Reddedildi' ||
        req.status == 'Beklemede')
      return const SizedBox();

    String? myStatus = isSeller ? req.sellerStatus : req.buyerStatus;
    String? otherStatus = isSeller ? req.buyerStatus : req.sellerStatus;

    // DURUM 1: UYUŞMAZLIK (Biri Başarılı, Biri Başarısız)
    if (myStatus != null && otherStatus != null && myStatus != otherStatus) {
      return InkWell(
        onTap: () {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text("Durum Admin'e bildirildi. İnceleniyor... 👮‍♂️"),
              backgroundColor: Colors.orange,
            ),
          );
        },
        child: Container(
          width: double.infinity,
          margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: Colors.red.shade50,
            borderRadius: BorderRadius.circular(8),
            border: Border.all(color: Colors.red.shade200),
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: const [
              Icon(Icons.report_problem, color: Colors.red),
              Gap(8),
              Expanded(
                child: Text(
                  "UYUŞMAZLIK VAR! Tıklayıp Raporla.",
                  style: TextStyle(
                    color: Colors.red,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ],
          ),
        ),
      );
    }

    // DURUM 2: BEN ONAYLADIM, KARŞI TARAF BEKLENİYOR
    if (myStatus != null && otherStatus == null) {
      return const Padding(
        padding: EdgeInsets.all(8.0),
        child: Center(
          child: Text(
            "Karşı tarafın onayı bekleniyor... ⏳",
            style: TextStyle(color: Colors.grey, fontStyle: FontStyle.italic),
          ),
        ),
      );
    }

    // DURUM 3: HENÜZ ONAYLAMADIM (Butonu Göster)
    if (myStatus == null) {
      return Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        child: SizedBox(
          width: double.infinity,
          child: ElevatedButton(
            onPressed: () {
              showDialog(
                context: context,
                builder: (ctx) => AlertDialog(
                  title: const Text("Teslimat Durumu"),
                  content: const Text(
                    "Teslimat işlemini nasıl değerlendiriyorsunuz?",
                  ),
                  actions: [
                    TextButton(
                      onPressed: () {
                        Navigator.pop(ctx);
                        context.read<RequestsBloc>().add(
                          RequestsConfirmDelivery(
                            requestId: req.id,
                            isSeller: isSeller,
                            status: 'failed',
                          ),
                        );
                      },
                      child: const Text(
                        "Başarısız ❌",
                        style: TextStyle(color: Colors.red),
                      ),
                    ),
                    ElevatedButton(
                      onPressed: () {
                        Navigator.pop(ctx);
                        context.read<RequestsBloc>().add(
                          RequestsConfirmDelivery(
                            requestId: req.id,
                            isSeller: isSeller,
                            status: 'success',
                          ),
                        );
                      },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.green,
                      ),
                      child: const Text("Başarılı ✅"),
                    ),
                  ],
                ),
              );
            },
            style: ElevatedButton.styleFrom(backgroundColor: Colors.orange),
            child: const Text("Teslimatı Bitir / Onayla"),
          ),
        ),
      );
    }

    return const SizedBox();
  }

  String _calculateDays(DateTime start, DateTime end) {
    final difference = end.difference(start).inDays;
    return "$difference Gün";
  }
}
