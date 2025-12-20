import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:gap/gap.dart';
import 'package:kitaptakas/data/models/request_model.dart'; // RequestModel için
import 'package:kitaptakas/features/chat/view/chat_view.dart';
import 'package:kitaptakas/features/requests/bloc/request_bloc.dart';
import 'package:kitaptakas/features/requests/bloc/request_event.dart';
import 'package:kitaptakas/features/requests/bloc/request_state.dart';
import '../../../../core/constants/app_colors.dart';
import '../../../../data/repositories/book_repository.dart';

class RequestsPage extends StatelessWidget {
  const RequestsPage({super.key});

  @override
  Widget build(BuildContext context) {
    final userId = FirebaseAuth.instance.currentUser?.uid ?? "";

    return BlocProvider(
      create: (context) =>
          RequestsBloc(bookRepository: BookRepository())
            ..add(RequestsLoad(userId)),
      child: const RequestsView(),
    );
  }
}

class RequestsView extends StatefulWidget {
  const RequestsView({super.key});

  @override
  State<RequestsView> createState() => _RequestsViewState();
}

class _RequestsViewState extends State<RequestsView> {
  @override
  Widget build(BuildContext context) {
    final userId = FirebaseAuth.instance.currentUser?.uid ?? "";

    return Scaffold(
      appBar: AppBar(title: const Text("Gelen Talepler")),
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
              return const Center(child: Text("Henüz bir talep gelmedi."));
            }

            return ListView.separated(
              padding: const EdgeInsets.all(16),
              itemCount: state.requests.length,
              separatorBuilder: (context, index) => const Gap(12),
              itemBuilder: (context, index) {
                final req = state.requests[index];

                return Card(
                  elevation: 2,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Column(
                    children: [
                      ListTile(
                        contentPadding: const EdgeInsets.all(16),
                        leading: Container(
                          padding: const EdgeInsets.all(10),
                          decoration: BoxDecoration(
                            color: AppColors.tagDonationBg,
                            shape: BoxShape.circle,
                          ),
                          child: const Icon(
                            Icons.menu_book,
                            color: AppColors.primary,
                          ),
                        ),
                        title: Text(
                          req.bookTitle,
                          style: const TextStyle(fontWeight: FontWeight.bold),
                        ),
                        subtitle: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Gap(4),
                            Row(
                              children: [
                                const Icon(
                                  Icons.person,
                                  size: 16,
                                  color: Colors.grey,
                                ),
                                const Gap(4),
                                Text(
                                  req.senderName, // 👈 ARTIK İSİM YAZACAK
                                  style: const TextStyle(
                                    fontWeight: FontWeight.w600,
                                    color: Colors.black87,
                                  ),
                                ),
                              ],
                            ),

                            // 👇 TARİH VARSA GÖSTER (Ödünç İçin)
                            if (req.loanStartDate != null &&
                                req.loanEndDate != null) ...[
                              const Gap(4),
                              Row(
                                children: [
                                  const Icon(
                                    Icons.av_timer,
                                    size: 14,
                                    color: Colors.orange,
                                  ), // İkon değişti (Kronometre)
                                  const Gap(4),
                                  Text(
                                    "Süre: ${_calculateDays(req.loanStartDate!, req.loanEndDate!)}",
                                    style: const TextStyle(
                                      fontSize: 12,
                                      fontWeight: FontWeight.w600,
                                    ),
                                  ),
                                ],
                              ),
                            ],
                            const Gap(8),
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
                        trailing: req.status == 'Beklemede'
                            ? Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  IconButton(
                                    icon: const Icon(
                                      Icons.close,
                                      color: Colors.red,
                                    ),
                                    onPressed: () {
                                      context.read<RequestsBloc>().add(
                                        RequestsUpdateStatus(
                                          requestId: req.id,
                                          newStatus: "Reddedildi",
                                          userId: userId,
                                        ),
                                      );
                                    },
                                  ),
                                  IconButton(
                                    icon: const Icon(
                                      Icons.check,
                                      color: Colors.green,
                                    ),
                                    onPressed: () {
                                      context.read<RequestsBloc>().add(
                                        RequestsUpdateStatus(
                                          requestId: req.id,
                                          newStatus: "Onaylandı",
                                          userId: userId,
                                        ),
                                      );
                                    },
                                  ),
                                ],
                              )
                            : null,
                      ),

                      // 👇 ONAYLANDIYSA BUTONLARI GÖSTER 👇
                      if (req.status == 'Onaylandı') ...[
                        const Divider(height: 1),

                        // 1. Mesaj Butonu
                        Padding(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 16,
                            vertical: 8,
                          ),
                          child: SizedBox(
                            width: double.infinity,
                            child: ElevatedButton.icon(
                              onPressed: () {
                                Navigator.push(
                                  context,
                                  MaterialPageRoute(
                                    builder: (context) => ChatPage(
                                      requestId: req.id,
                                      chatTitle: "Talep Edenle Mesajlaş",
                                    ),
                                  ),
                                );
                              },
                              icon: const Icon(Icons.chat),
                              label: const Text("Alıcıyla Mesajlaş"),
                              style: ElevatedButton.styleFrom(
                                backgroundColor: Colors.green,
                                foregroundColor: Colors.white,
                                elevation: 0,
                              ),
                            ),
                          ),
                        ),

                        // 2. Teslimat Onay Butonu (Satıcı Olduğum İçin true)
                        _buildDeliveryActions(context, req, true),

                        const Gap(8),
                      ],
                    ],
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

  // 👇 ORTAK TESLİMAT BUTONLARI (BURASI ÇOK ÖNEMLİ) 👇
  Widget _buildDeliveryActions(
    BuildContext context,
    RequestModel req,
    bool isSeller,
  ) {
    // İşlem bitmişse gösterme
    if (req.status == 'Tamamlandı' ||
        req.status == 'Reddedildi' ||
        req.status == 'Beklemede')
      return const SizedBox();

    String? myStatus = isSeller ? req.sellerStatus : req.buyerStatus;
    String? otherStatus = isSeller ? req.buyerStatus : req.sellerStatus;

    // DURUM 1: UYUŞMAZLIK VAR
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

    // DURUM 2: BEN ONAYLADIM, KARŞI TARAFI BEKLİYORUM
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
