// lib/features/settings/view/settings_view.dart

import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:gap/gap.dart';
import '../../../../core/constants/app_colors.dart';
import '../../auth/view/welcome_view.dart'; // Çıkış yapınca/silince buraya dönecek

class SettingsView extends StatefulWidget {
  const SettingsView({super.key});

  @override
  State<SettingsView> createState() => _SettingsViewState();
}

class _SettingsViewState extends State<SettingsView> {
  bool _notificationsEnabled = true; // Bildirim anahtarı durumu

  // HESAP SİLME DİYALOGU
  void _showDeleteAccountDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text("Hesabı Sil"),
        content: const Text(
          "Hesabını kalıcı olarak silmek istediğine emin misin? Bu işlem geri alınamaz ve tüm verilerin (kitaplar, mesajlar) silinir.",
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context), // Vazgeç
            child: const Text("Vazgeç", style: TextStyle(color: Colors.grey)),
          ),
          ElevatedButton(
            onPressed: () async {
              // BURAYA SİLME MANTIĞI GELECEK (Repo'ya yazacağız)
              // Şimdilik sadece çıkış yapıp ana ekrana atalım:
              await FirebaseAuth.instance.signOut();

              if (mounted) {
                Navigator.pushAndRemoveUntil(
                  context,
                  MaterialPageRoute(builder: (context) => const WelcomeView()),
                  (route) => false,
                );
              }
            },
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
            child: const Text(
              "Evet, Sil",
              style: TextStyle(color: Colors.white),
            ),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: const Text(
          "Ayarlar",
          style: TextStyle(
            fontWeight: FontWeight.bold,
            color: AppColors.textPrimary,
          ),
        ),
        centerTitle: true,
        backgroundColor: AppColors.background,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: AppColors.textPrimary),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: ListView(
        children: [
          const Gap(10),

          // --- BÖLÜM 1: BİLDİRİMLER ---
          Padding(
            padding: const EdgeInsets.symmetric(
              horizontal: 16.0,
              vertical: 8.0,
            ),
            child: const Text(
              "Bildirimler",
              style: TextStyle(
                fontSize: 14,
                color: Colors.grey,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
          Container(
            color: Colors.white,
            child: SwitchListTile(
              title: const Text(
                "Bildirimleri Aç",
                style: TextStyle(fontWeight: FontWeight.w500),
              ),
              subtitle: const Text(
                "Talep onayları hakkında bildirim al",
                style: TextStyle(fontSize: 12, color: Colors.grey),
              ),
              value: _notificationsEnabled,
              activeColor: AppColors.primary, // Mavi renk
              onChanged: (bool value) {
                setState(() {
                  _notificationsEnabled = value;
                });
                // Burada veritabanına veya SharedPreferences'a kaydedebiliriz
              },
            ),
          ),

          const Gap(24),

          // --- BÖLÜM 2: GENEL LİNKLER ---
          Container(
            color: Colors.white,
            child: Column(
              children: [
                _buildSettingsTile(
                  icon: Icons.lock_outline,
                  title: "Gizlilik Politikası",
                  onTap: () {
                    // Linke gitme kodu buraya
                  },
                ),
                _buildDivider(),
                _buildSettingsTile(
                  icon: Icons.help_outline,
                  title: "Yardım Merkezi",
                  onTap: () {},
                ),
                _buildDivider(),
                _buildSettingsTile(
                  icon: Icons.info_outline,
                  title: "Uygulama Hakkında",
                  onTap: () {},
                ),
              ],
            ),
          ),

          const Gap(24),

          // --- BÖLÜM 3: TEHLİKELİ BÖLGE (SİLME) ---
          Container(
            color: Colors.white,
            child: ListTile(
              leading: const Icon(Icons.delete_outline, color: Colors.red),
              title: const Text(
                "Hesabı Sil",
                style: TextStyle(
                  color: Colors.red,
                  fontWeight: FontWeight.w600,
                ),
              ),
              onTap: _showDeleteAccountDialog, // Diyalogu aç
            ),
          ),
        ],
      ),
    );
  }

  // Yardımcı Widget: Ayar Satırı
  Widget _buildSettingsTile({
    required IconData icon,
    required String title,
    required VoidCallback onTap,
  }) {
    return ListTile(
      leading: Icon(icon, color: Colors.black87),
      title: Text(title, style: const TextStyle(fontWeight: FontWeight.w500)),
      trailing: const Icon(
        Icons.arrow_forward_ios,
        size: 16,
        color: Colors.grey,
      ),
      onTap: onTap,
    );
  }

  // Yardımcı Widget: İnce Çizgi
  Widget _buildDivider() {
    return const Divider(
      height: 1,
      thickness: 0.5,
      indent: 56, // İkonun hizasından başlasın diye
      endIndent: 0,
      color: Colors.grey, // Hafif gri
    );
  }
}
