import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

// --- RAPOR SERVİSİ ---
class ReportService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;

  Future<void> submitReport({
    required String reportedId,
    required String type,
    required String reason,
    required String description,
  }) async {
    final user = _auth.currentUser;
    if (user == null) throw Exception("Giriş yapmalısınız.");

    await _firestore.collection('reports').add({
      'reporterId': user.uid,
      'reporterEmail': user.email,
      'reportedId': reportedId,
      'type': type,
      'reason': reason,
      'description': description,
      'status': 'pending',
      'createdAt': FieldValue.serverTimestamp(),
    });
  }
}

// --- ORTAK ŞİKAYET PENCERESİ FONKSİYONU ---
void showReportDialog(
  BuildContext context, {
  required String reportedId,
  required String type,
}) {
  final TextEditingController descriptionController = TextEditingController();
  String? selectedReason;
  final ReportService reportService = ReportService();

  // Şikayet Sebepleri Listesi
  final List<String> reasons = [
    'Uygunsuz İçerik / Görsel',
    'Dolandırıcılık / Sahte İlan',
    'Hakaret / Taciz',
    'Spam / Reklam',
    'Diğer',
  ];

  showDialog(
    context: context,
    builder: (ctx) => StatefulBuilder(
      builder: (context, setState) {
        bool isLoading = false;

        return AlertDialog(
          title: Text(type == 'book' ? "İlanı Bildir" : "Kullanıcıyı Bildir"),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Text("Lütfen bir sebep seçiniz:"),
                const SizedBox(height: 10),
                DropdownButton<String>(
                  isExpanded: true,
                  value: selectedReason,
                  hint: const Text("Sebep Seçin"),
                  items: reasons
                      .map((r) => DropdownMenuItem(value: r, child: Text(r)))
                      .toList(),
                  onChanged: (value) => setState(() => selectedReason = value),
                ),
                const SizedBox(height: 10),
                TextField(
                  controller: descriptionController,
                  decoration: const InputDecoration(
                    labelText: "Açıklama (İsteğe bağlı)",
                    border: OutlineInputBorder(),
                  ),
                  maxLines: 3,
                ),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(ctx),
              child: const Text("İptal"),
            ),
            ElevatedButton(
              onPressed: (selectedReason == null || isLoading)
                  ? null
                  : () async {
                      // Yükleniyor durumuna geçir
                      setState(() => isLoading = true);
                      try {
                        await reportService.submitReport(
                          reportedId: reportedId,
                          type: type,
                          reason: selectedReason!,
                          description: descriptionController.text,
                        );
                        if (ctx.mounted) {
                          Navigator.pop(ctx); // Pencereyi kapat
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(
                              content: Text(
                                "Bildiriminiz alındı. Teşekkürler! ✅",
                              ),
                            ),
                          );
                        }
                      } catch (e) {
                        setState(() => isLoading = false);
                        ScaffoldMessenger.of(
                          context,
                        ).showSnackBar(SnackBar(content: Text("Hata: $e")));
                      }
                    },
              child: isLoading
                  ? const SizedBox(
                      width: 20,
                      height: 20,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    )
                  : const Text("Gönder"),
            ),
          ],
        );
      },
    ),
  );
}
