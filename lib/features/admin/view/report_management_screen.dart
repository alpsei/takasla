import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:kitaptakas/data/repositories/admin_repositories.dart';

class ReportManagementScreen extends StatefulWidget {
  const ReportManagementScreen({super.key});

  @override
  State<ReportManagementScreen> createState() => _ReportManagementScreenState();
}

class _ReportManagementScreenState extends State<ReportManagementScreen> {
  final AdminRepository _adminRepository = AdminRepository();

  // Şikayeti Reddet
  Future<void> _ignoreReport(String reportId) async {
    await _adminRepository.resolveReport(reportId, 'rejected');
    setState(() {});
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Şikayet reddedildi/kapatıldı.")),
      );
    }
  }

  // Şikayeti Onayla
  Future<void> _approveAndPunish(
    String reportId,
    String reportedId,
    String type,
  ) async {
    try {
      // Önce içeriği sil
      if (type == 'book') {
        await _adminRepository.deleteBook(reportedId);
      } else if (type == 'user') {
        await _adminRepository.deleteUser(reportedId);
      }

      // Raporu 'resolved' (çözüldü) olarak işaretle
      await _adminRepository.resolveReport(reportId, 'resolved');

      setState(() {});
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text("İçerik silindi ve rapor kapatıldı. 🔨"),
            backgroundColor: Colors.red,
          ),
        );
      }
    } catch (e) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text("Hata: $e")));
    }
  }

  // Onay Dialogu
  void _showActionDialog(
    BuildContext context,
    String reportId,
    String reportedId,
    String type,
  ) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text("Karar Ver"),
        content: Text(
          type == 'book'
              ? "Bu kitabı sistemden silmek istediğine emin misin?"
              : "Bu kullanıcıyı ve tüm verilerini silmek istediğine emin misin?",
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text("Vazgeç"),
          ),
          TextButton(
            onPressed: () {
              Navigator.pop(ctx);
              _approveAndPunish(reportId, reportedId, type);
            },
            child: const Text(
              "EVET, SİL",
              style: TextStyle(color: Colors.red, fontWeight: FontWeight.bold),
            ),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("Şikayet Yönetimi")),
      body: FutureBuilder<QuerySnapshot>(
        future: _adminRepository.getPendingReports(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }
          if (snapshot.hasError) {
            return Center(child: Text("Hata: ${snapshot.error}"));
          }
          if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: const [
                  Icon(
                    Icons.check_circle_outline,
                    size: 80,
                    color: Colors.green,
                  ),
                  SizedBox(height: 16),
                  Text(
                    "Bekleyen şikayet yok! 🎉",
                    style: TextStyle(fontSize: 18),
                  ),
                ],
              ),
            );
          }

          final reports = snapshot.data!.docs;

          return ListView.builder(
            padding: const EdgeInsets.all(12),
            itemCount: reports.length,
            itemBuilder: (context, index) {
              final report = reports[index];
              final data = report.data() as Map<String, dynamic>;

              final String type = data['type'] ?? 'unknown';
              final String reason = data['reason'] ?? 'Belirtilmemiş';
              final String description = data['description'] ?? '';
              final String reporterEmail = data['reporterEmail'] ?? 'Anonim';
              final String reportedId = data['reportedId'] ?? '';
              final date =
                  (data['createdAt'] as Timestamp?)
                      ?.toDate()
                      .toString()
                      .substring(0, 16) ??
                  '-';

              return Card(
                color: Colors.red.shade50,
                elevation: 3,
                margin: const EdgeInsets.only(bottom: 12),
                child: Padding(
                  padding: const EdgeInsets.all(12.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Başlık: Şikayet Türü
                      Row(
                        children: [
                          Icon(
                            type == 'book' ? Icons.book : Icons.person,
                            color: type == 'book' ? Colors.orange : Colors.blue,
                          ),
                          const SizedBox(width: 8),
                          Text(
                            type == 'book'
                                ? "KİTAP ŞİKAYETİ"
                                : "KULLANICI ŞİKAYETİ",
                            style: const TextStyle(
                              fontWeight: FontWeight.bold,
                              fontSize: 16,
                            ),
                          ),
                          const Spacer(),
                          Text(
                            date,
                            style: const TextStyle(
                              fontSize: 12,
                              color: Colors.grey,
                            ),
                          ),
                        ],
                      ),
                      const Divider(),

                      // Detaylar
                      Text(
                        "Sebep: $reason",
                        style: const TextStyle(fontWeight: FontWeight.bold),
                      ),
                      if (description.isNotEmpty) ...[
                        const SizedBox(height: 4),
                        Text(
                          "Açıklama: \"$description\"",
                          style: const TextStyle(fontStyle: FontStyle.italic),
                        ),
                      ],
                      const SizedBox(height: 8),
                      Text(
                        "Şikayet Eden: $reporterEmail",
                        style: const TextStyle(
                          fontSize: 12,
                          color: Colors.grey,
                        ),
                      ),
                      Text(
                        "ID: $reportedId",
                        style: const TextStyle(
                          fontSize: 10,
                          color: Colors.grey,
                        ),
                      ),

                      const SizedBox(height: 12),

                      // Butonlar
                      Row(
                        mainAxisAlignment: MainAxisAlignment.end,
                        children: [
                          OutlinedButton(
                            onPressed: () => _ignoreReport(report.id),
                            child: const Text("Yoksay / Reddet"),
                          ),
                          const SizedBox(width: 12),
                          ElevatedButton.icon(
                            onPressed: () => _showActionDialog(
                              context,
                              report.id,
                              reportedId,
                              type,
                            ),
                            style: ElevatedButton.styleFrom(
                              backgroundColor: Colors.red,
                              foregroundColor: Colors.white,
                            ),
                            icon: const Icon(Icons.gavel),
                            label: Text(
                              type == 'book'
                                  ? "Kitabı Sil"
                                  : "Kullanıcıyı Banla",
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              );
            },
          );
        },
      ),
    );
  }
}
