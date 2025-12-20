// lib/features/auth/view/complete_profile_view.dart

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:gap/gap.dart';
import 'package:mask_text_input_formatter/mask_text_input_formatter.dart';
import 'package:kitaptakas/core/utils/location_helper.dart';
import 'package:kitaptakas/features/home/view/home_view.dart';
import '../../../../core/constants/app_colors.dart';
import '../../../../data/repositories/auth_repository.dart';

class CompleteProfileView extends StatefulWidget {
  const CompleteProfileView({super.key});

  @override
  State<CompleteProfileView> createState() => _CompleteProfileViewState();
}

class _CompleteProfileViewState extends State<CompleteProfileView> {
  final _nameController = TextEditingController();
  final _surnameController = TextEditingController();
  final _phoneController = TextEditingController();
  final _schoolController = TextEditingController();

  String? _detectedLocation;
  bool _isLoading = false;

  // 🔒 SMS İÇİN GEREKLİ DEĞİŞKENLER (Şimdilik Kapalı)
  // bool _isPhoneVerified = false;
  // String? _verificationId;

  // 👇 TELEFON FORMATLAYICI
  final maskFormatter = MaskTextInputFormatter(
    mask: '### ### ## ##',
    filter: {"#": RegExp(r'[0-9]')},
    type: MaskAutoCompletionType.lazy,
  );

  // 📍 KONUM BULMA
  Future<void> _getLocation() async {
    setState(() => _isLoading = true);
    try {
      final city = await LocationHelper.getCurrentLocation();
      if (city != null) {
        if (!mounted) return;
        setState(() => _detectedLocation = city);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text("Konum bulundu: $city"),
            backgroundColor: Colors.green,
          ),
        );
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text("Konum bulunamadı, lütfen elle giriniz."),
            backgroundColor: Colors.orange,
          ),
        );
      }
    } catch (e) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text("Hata: $e")));
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  /* 🔒 SMS DOĞRULAMA FONKSİYONLARI (Şimdilik Kapalı)
  Future<void> _verifyPhone() async {
    if (_phoneController.text.isEmpty || _phoneController.text.length < 10) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("Lütfen geçerli bir numara girin.")));
      return;
    }

    setState(() => _isLoading = true);
    String formattedPhone = "+90${_phoneController.text.replaceAll(" ", "")}";

    await FirebaseAuth.instance.verifyPhoneNumber(
      phoneNumber: formattedPhone,
      verificationCompleted: (PhoneAuthCredential credential) async {
        await FirebaseAuth.instance.currentUser?.updatePhoneNumber(credential);
        setState(() {
          _isPhoneVerified = true;
          _isLoading = false;
        });
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("Numara otomatik doğrulandı! ✅"), backgroundColor: Colors.green));
      },
      verificationFailed: (FirebaseAuthException e) {
        setState(() => _isLoading = false);
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text("Doğrulama Hatası: ${e.message}"), backgroundColor: Colors.red));
      },
      codeSent: (String verificationId, int? resendToken) {
        setState(() {
          _verificationId = verificationId;
          _isLoading = false;
        });
        _showSmsDialog();
      },
      codeAutoRetrievalTimeout: (String verificationId) {
        _verificationId = verificationId;
      },
    );
  }

  void _showSmsDialog() {
    final codeController = TextEditingController();
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => AlertDialog(
        title: const Text("Doğrulama Kodu"),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text("Telefonuna gelen 6 haneli kodu gir:"),
            const Gap(10),
            TextField(
              controller: codeController,
              keyboardType: TextInputType.number,
              maxLength: 6,
              textAlign: TextAlign.center,
              decoration: const InputDecoration(hintText: "______", counterText: ""),
            ),
          ],
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text("İptal")),
          ElevatedButton(
            onPressed: () async {
              if (_verificationId == null) return;
              try {
                PhoneAuthCredential credential = PhoneAuthProvider.credential(
                  verificationId: _verificationId!,
                  smsCode: codeController.text.trim(),
                );
                await FirebaseAuth.instance.currentUser?.updatePhoneNumber(credential);
                setState(() => _isPhoneVerified = true);
                Navigator.pop(context);
                ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("Numara Doğrulandı! 🚀"), backgroundColor: Colors.green));
              } catch (e) {
                ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text("Hatalı Kod: $e"), backgroundColor: Colors.red));
              }
            },
            child: const Text("Doğrula"),
          ),
        ],
      ),
    );
  }
  */

  // 💾 KAYDET VE DEVAM ET
  Future<void> _saveAndContinue() async {
    /* 🔒 DOĞRULAMA KONTROLÜ (Şimdilik Kapalı)
    if (!_isPhoneVerified) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("Lütfen önce telefon numaranızı doğrulayın."), backgroundColor: Colors.orange));
      return;
    }
    */

    if (_nameController.text.isEmpty ||
        _surnameController.text.isEmpty ||
        _detectedLocation == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text("Lütfen ad, soyad ve konum bilgilerini doldurun."),
        ),
      );
      return;
    }

    setState(() => _isLoading = true);

    try {
      final user = FirebaseAuth.instance.currentUser;
      if (user != null) {
        final repo = AuthRepository();

        await repo.saveUserData(
          userId: user.uid,
          email: user.email ?? "",
          name:
              "${_nameController.text.trim()} ${_surnameController.text.trim()}",
          location: _detectedLocation!,
          setPoint: 100,
        );

        await FirebaseFirestore.instance
            .collection('users')
            .doc(user.uid)
            .update({
              'phone': _phoneController.text.isNotEmpty
                  ? "+90 ${_phoneController.text.trim()}"
                  : "",
              'school': _schoolController.text.trim(),
              'isProfileComplete': true,
            });

        if (mounted) {
          Navigator.pushAndRemoveUntil(
            context,
            MaterialPageRoute(builder: (context) => const HomePage()),
            (route) => false,
          );
        }
      }
    } catch (e) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text("Hata: $e")));
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("Profili Tamamla"), centerTitle: true),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: Column(
          children: [
            const Text(
              "Son bir adım kaldı! 🚀",
              style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold),
            ),
            const Gap(8),
            const Text(
              "Sana daha iyi hizmet verebilmemiz için bu bilgilere ihtiyacımız var.",
              textAlign: TextAlign.center,
              style: TextStyle(color: Colors.grey),
            ),
            const Gap(32),

            _buildTextField("Ad", _nameController, Icons.person),
            const Gap(16),
            _buildTextField("Soyad", _surnameController, Icons.person_outline),
            const Gap(16),

            // 👇 TELEFON ALANI
            Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: _phoneController,
                    inputFormatters: [maskFormatter],
                    keyboardType: TextInputType.phone,
                    // enabled: !_isPhoneVerified, // 🔒 Şimdilik hep açık kalsın
                    decoration: InputDecoration(
                      labelText: "Telefon Numarası (İsteğe Bağlı)",
                      hintText: "555 555 55 55",
                      prefixIcon: const Icon(Icons.phone, color: Colors.grey),
                      prefixText: "+90 ",
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                      // suffixIcon: _isPhoneVerified ? const Icon(Icons.check_circle, color: Colors.green) : null, // 🔒
                    ),
                  ),
                ),
                const Gap(10),

                /* 🔒 DOĞRULA BUTONU (Şimdilik Kapalı)
                if (!_isPhoneVerified)
                  SizedBox(
                    height: 55,
                    child: ElevatedButton(
                      onPressed: _isLoading ? null : _verifyPhone,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.orange,
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                      ),
                      child: const Text("Doğrula", style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
                    ),
                  ),
                */
              ],
            ),

            const Gap(16),
            _buildTextField(
              "Okul / Üniversite (İsteğe Bağlı)",
              _schoolController,
              Icons.school,
            ),
            const Gap(24),

            // KONUM ALANI
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.blue.shade50,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: Colors.blue.shade200),
              ),
              child: Row(
                children: [
                  const Icon(Icons.location_on, color: AppColors.primary),
                  const Gap(12),
                  Expanded(
                    child: Text(
                      _detectedLocation ?? "Konum bilgisi alınmadı",
                      style: TextStyle(
                        fontWeight: _detectedLocation != null
                            ? FontWeight.bold
                            : FontWeight.normal,
                        color: _detectedLocation != null
                            ? Colors.black
                            : Colors.grey,
                      ),
                    ),
                  ),
                  if (_isLoading)
                    const SizedBox(
                      width: 20,
                      height: 20,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    )
                  else
                    TextButton(
                      onPressed: _getLocation,
                      child: const Text("Konumu Bul"),
                    ),
                ],
              ),
            ),
            const Gap(40),

            SizedBox(
              width: double.infinity,
              height: 50,
              child: ElevatedButton(
                // onPressed: (_isLoading || !_isPhoneVerified) ? null : _saveAndContinue, // 🔒 ESKİSİ
                onPressed: _isLoading ? null : _saveAndContinue, // ✅ YENİSİ
                child: const Text("Kaydet ve Başla"),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildTextField(
    String hint,
    TextEditingController controller,
    IconData icon,
  ) {
    return TextField(
      controller: controller,
      textCapitalization: TextCapitalization.words,
      decoration: InputDecoration(
        labelText: hint,
        prefixIcon: Icon(icon, color: Colors.grey),
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
      ),
    );
  }
}
