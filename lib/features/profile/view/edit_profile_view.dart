import 'dart:convert';
import 'dart:io';

import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:gap/gap.dart';
import 'package:image_picker/image_picker.dart';
import 'package:kitaptakas/core/constants/tr_cities.dart';
import 'package:kitaptakas/core/utils/location_helper.dart';
import '../../../../core/constants/app_colors.dart';
import '../../../../data/repositories/auth_repository.dart';
import 'package:image/image.dart' as img;

class EditProfileView extends StatefulWidget {
  const EditProfileView({super.key});

  @override
  State<EditProfileView> createState() => _EditProfileViewState();
}

class _EditProfileViewState extends State<EditProfileView> {
  final _nameController = TextEditingController();
  final _locationController = TextEditingController();
  bool _isLoading = false;
  final _repo = AuthRepository();
  File? _selectedImage;
  String? _currentPhotoBase64;
  final ImagePicker _picker = ImagePicker();
  bool _isPhotoRemoved = false;
  Key _autocompleteKey = UniqueKey();

  @override
  void initState() {
    super.initState();
    _loadUserData(); // Sayfa açılınca mevcut veriyi çek
  }

  // Mevcut veriyi çekip kutulara doldur
  Future<void> _loadUserData() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user != null) {
      final data = await _repo.getUserData(user.uid);
      if (data != null) {
        setState(() {
          _nameController.text = data['name'] ?? "";
          _locationController.text = data['location'] ?? "";
          _currentPhotoBase64 = data['photoUrl'];
        });
      }
    }
  }

  // Kaydetme İşlemi
  Future<void> _saveProfile() async {
    String inputLocation = _locationController.text.trim();
    String cityToCheck = inputLocation;

    if (inputLocation.contains(',')) {
      cityToCheck = inputLocation.split(',').last.trim();
    }

    if (!TrCities.cities.contains(cityToCheck)) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text("Lütfen listeden geçerli bir şehir seçin."),
          backgroundColor: Colors.orange,
        ),
      );
      return;
    }

    if (_nameController.text.isEmpty || _locationController.text.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Lütfen tüm alanları doldurun.")),
      );
      return;
    }

    setState(() => _isLoading = true);

    try {
      final user = FirebaseAuth.instance.currentUser;
      String? based64Image;

      if (_selectedImage != null) {
        final bytes = await _selectedImage!.readAsBytes();
        img.Image? originalImage = img.decodeImage(bytes);
        if (originalImage != null) {
          img.Image resizedImage = img.copyResize(originalImage, width: 600);
          List<int> compressedByte = img.encodeJpg(resizedImage, quality: 70);
          based64Image = base64Encode(compressedByte);
        }
      }

      if (user != null) {
        await _repo.saveUserData(
          userId: user.uid,
          email: user.email ?? "",
          name: _nameController.text.trim(),
          location: inputLocation,
          photoBase64: based64Image,
          deletePhoto: _isPhotoRemoved,
        );

        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text("Profil Güncellendi! ✅"),
              backgroundColor: Colors.green,
            ),
          );
          Navigator.pop(context, true);
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text("Hata: $e")));
      }
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  // Profil fotoğrafı kaldırma
  void _removePhoto() {
    setState(() {
      _selectedImage = null;
      _currentPhotoBase64 = null;
      _isPhotoRemoved = true;
    });
  }

  Future<void> _pickImage() async {
    final XFile? pickerFile = await _picker.pickImage(
      source: ImageSource.gallery,
    );
    if (pickerFile != null) {
      setState(() {
        _selectedImage = File(pickerFile.path);
        _isPhotoRemoved = false;
      });
    }
  }

  Future<void> _findLocation() async {
    setState(() => _isLoading = true);

    try {
      // Şehri Getirmeye Çalış
      final city = await LocationHelper.getCurrentLocation();

      if (city != null) {
        if (!mounted) return;

        // Bulursa Diyalog Aç
        showDialog(
          context: context,
          builder: (ctx) => AlertDialog(
            title: const Text("Konum Bulundu 📍"),
            content: Text(
              "Algılanan Şehir: **$city**\n\nBu konumu kaydetmek istiyor musunuz?",
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(ctx),
                child: const Text(
                  "Vazgeç",
                  style: TextStyle(color: Colors.grey),
                ),
              ),
              ElevatedButton(
                onPressed: () {
                  // Güncelleme İşlemi
                  setState(() {
                    _locationController.text = city;
                    // Autocomplete widget'ını yenilemek için key değiştiriyoruz
                    _autocompleteKey = UniqueKey();
                  });

                  // İmleci sona taşı
                  _locationController.selection = TextSelection.fromPosition(
                    TextPosition(offset: _locationController.text.length),
                  );

                  Navigator.pop(ctx);
                },
                child: const Text("Evet, Kaydet"),
              ),
            ],
          ),
        );
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text("Konum alınamadı (Null döndü)."),
            backgroundColor: Colors.orange,
          ),
        );
      }
    } catch (e) {
      // HATAYI BURADA GÖRECEĞİZ
      print("KONUM HATASI: $e"); // Konsola yazdır
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text("Hata: $e"),
          backgroundColor: Colors.red,
          duration: const Duration(seconds: 5),
        ),
      );
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("Profili Düzenle")),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: Column(
          children: [
            // Profil fotoğrafı
            Center(
              child: GestureDetector(
                onTap: _pickImage,
                child: CircleAvatar(
                  radius: 60,
                  backgroundColor: AppColors.tagDonationBg,
                  backgroundImage: _selectedImage != null
                      ? FileImage(_selectedImage!) as ImageProvider
                      : (_currentPhotoBase64 != null &&
                                _currentPhotoBase64!.isNotEmpty
                            ? MemoryImage(base64Decode(_currentPhotoBase64!))
                            : null),
                  child:
                      (_selectedImage == null &&
                          (_currentPhotoBase64 == null ||
                              _currentPhotoBase64!.isEmpty))
                      ? const Icon(
                          Icons.add_a_photo,
                          size: 40,
                          color: AppColors.primary,
                        )
                      : null,
                ),
              ),
            ),
            const Gap(16),
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                TextButton.icon(
                  onPressed: _pickImage,
                  icon: const Icon(Icons.edit, size: 18),
                  label: Text(
                    _currentPhotoBase64 == null && _selectedImage == null
                        ? "Fotoğraf Ekle"
                        : "Değiştir",
                  ),
                ),
                if (_currentPhotoBase64 != null || _selectedImage != null) ...[
                  const Gap(8),
                  TextButton.icon(
                    onPressed: _removePhoto,
                    icon: const Icon(
                      Icons.delete_outline,
                      size: 18,
                      color: Colors.red,
                    ),
                    label: const Text(
                      "Kaldır",
                      style: TextStyle(color: Colors.red),
                    ),
                  ),
                ],
              ],
            ),
            const Gap(32),

            // AD SOYAD
            TextField(
              controller: _nameController,
              decoration: InputDecoration(
                labelText: "Ad Soyad",
                prefixIcon: const Icon(Icons.person_outline),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
            ),
            const Gap(20),

            // ŞEHİR / KONUM
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                RawAutocomplete<String>(
                  key: _autocompleteKey,
                  textEditingController: _locationController,
                  focusNode: FocusNode(),
                  fieldViewBuilder:
                      (
                        BuildContext context,
                        TextEditingController textEditingController,
                        FocusNode focusNode,
                        VoidCallback onFieldSubmitted,
                      ) {
                        return TextField(
                          controller: textEditingController,
                          focusNode: focusNode,
                          decoration: InputDecoration(
                            labelText: "Şehir Seçiniz",
                            prefixIcon: const Icon(Icons.location_on_outlined),
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                            suffixIcon: IconButton(
                              onPressed: () => textEditingController.clear(),
                              icon: const Icon(Icons.clear, color: Colors.grey),
                            ),
                          ),
                        );
                      },
                  optionsBuilder: (TextEditingValue textEditingValue) {
                    if (textEditingValue.text == '') {
                      return const Iterable<String>.empty();
                    }
                    return TrCities.cities.where((String option) {
                      return option.toLowerCase().contains(
                        textEditingValue.text.toLowerCase(),
                      );
                    });
                  },
                  optionsViewBuilder:
                      (
                        BuildContext context,
                        AutocompleteOnSelected<String> onSelected,
                        Iterable<String> options,
                      ) {
                        return Align(
                          alignment: Alignment.topLeft,
                          child: Material(
                            elevation: 4.0,
                            borderRadius: BorderRadius.circular(12),
                            child: Container(
                              width: MediaQuery.of(context).size.width - 48,
                              constraints: const BoxConstraints(maxHeight: 200),
                              color: Colors.white,
                              child: ListView.builder(
                                padding: EdgeInsets.zero,
                                itemCount: options.length,
                                itemBuilder: (BuildContext context, int index) {
                                  final String option = options.elementAt(
                                    index,
                                  );
                                  return ListTile(
                                    title: Text(option),
                                    onTap: () => onSelected(option),
                                  );
                                },
                              ),
                            ),
                          ),
                        );
                      },
                ),
                const Gap(8),
                Align(
                  alignment: Alignment.centerRight,
                  child: TextButton.icon(
                    icon: _isLoading
                        ? const SizedBox(
                            width: 16,
                            height: 16,
                            child: CircularProgressIndicator(strokeWidth: 2),
                          )
                        : const Icon(Icons.my_location, size: 18),
                    onPressed: _isLoading ? null : _findLocation,
                    label: Text(_isLoading ? "Bulunuyor..." : "Konumumu Bul"),
                  ),
                ),
              ],
            ),
            const Gap(40),

            // KAYDET BUTONU
            SizedBox(
              width: double.infinity,
              height: 50,
              child: ElevatedButton(
                onPressed: _isLoading ? null : _saveProfile,
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.primary,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                child: _isLoading
                    ? const CircularProgressIndicator(color: Colors.white)
                    : const Text(
                        "Değişiklikleri Kaydet",
                        style: TextStyle(
                          fontSize: 16,
                          color: Colors.white,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
