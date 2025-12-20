// lib/features/add_book/view/add_book_view.dart

import 'dart:io';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:file_picker/file_picker.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:gap/gap.dart';
import 'package:image_picker/image_picker.dart';
import 'package:kitaptakas/core/constants/app_constants.dart';
import 'package:kitaptakas/core/constants/tr_cities.dart';
import 'package:kitaptakas/features/add_book/bloc/add_book_bloc.dart';
import '../../../../core/constants/app_colors.dart';
import '../../../../data/repositories/book_repository.dart';
import '../bloc/add_book_event.dart';
import '../bloc/add_book_state.dart';

class AddBookPage extends StatelessWidget {
  const AddBookPage({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (context) => AddBookBloc(bookRepository: BookRepository()),
      child: const AddBookView(),
    );
  }
}

class AddBookView extends StatefulWidget {
  const AddBookView({super.key});

  @override
  State<AddBookView> createState() => _AddBookViewState();
}

class _AddBookViewState extends State<AddBookView> {
  final TextEditingController _titleController = TextEditingController();
  final TextEditingController _authorController = TextEditingController();

  String? _selectedMainCategory;
  String? _selectedSubCategory;
  String? selectedCondition;
  String _selectedShareType = "Takas";

  File? _selectedImage;
  final ImagePicker _picker = ImagePicker();
  PlatformFile? _selectedPdf;

  // 📸 RESİM SEÇME
  Future<void> _pickImage() async {
    final XFile? pickedFile = await _picker.pickImage(
      source: ImageSource.gallery,
    );
    if (pickedFile != null) {
      setState(() {
        _selectedImage = File(pickedFile.path);
        _selectedPdf = null;

        // Alanları manuel giriş için sıfırla
        _titleController.clear();
        _selectedMainCategory = null;
        _selectedSubCategory = null;
        selectedCondition = null;
      });
    }
  }

  // 📄 PDF SEÇME
  Future<void> _pickPdf() async {
    FilePickerResult? result = await FilePicker.platform.pickFiles(
      type: FileType.custom,
      allowedExtensions: ['pdf'],
      withData: true,
    );

    if (result != null) {
      setState(() {
        _selectedPdf = result.files.first;
        _selectedImage = null;

        // Otomatik Doldurma
        _titleController.text = _selectedPdf!.name.replaceAll('.pdf', '');
        _selectedMainCategory = "Diğer";
        _selectedSubCategory = "Ders Notu / PDF";
        selectedCondition = "Yeni";
      });
    }
  }

  // KALDIRMA FONKSİYONLARI
  void _removeImage() {
    setState(() {
      _selectedImage = null;
    });
  }

  void _removePdf() {
    setState(() {
      _selectedPdf = null;
      _titleController.clear();
      _selectedMainCategory = null;
      _selectedSubCategory = null;
      selectedCondition = null;
    });
  }

  @override
  void dispose() {
    _titleController.dispose();
    _authorController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    bool isPdfMode = _selectedPdf != null;
    bool isImageMode = _selectedImage != null;

    return Scaffold(
      appBar: AppBar(title: const Text("Kitap Ekle")),
      body: BlocListener<AddBookBloc, AddBookState>(
        listener: (context, state) {
          if (state is AddBookSuccess) {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(
                content: Text("Yüklendi! 🎉"),
                backgroundColor: Colors.green,
              ),
            );
            Navigator.pop(context);
          } else if (state is AddBookFailure) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text("Hata: ${state.error}"),
                backgroundColor: Colors.red,
              ),
            );
          }
        },
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // 👇 --- AKILLI SEÇİM ALANI (BURASI DEĞİŞTİ) --- 👇
              if (!isPdfMode && !isImageMode)
                // 1. HİÇBİRİ SEÇİLİ DEĞİLSE: İKİSİNİ YAN YANA GÖSTER
                Row(
                  children: [
                    Expanded(
                      child: _buildSelectionCard(
                        icon: Icons.camera_alt,
                        label: "Fotoğraf",
                        color: AppColors.primary,
                        onTap: _pickImage,
                      ),
                    ),
                    const Gap(16),
                    Expanded(
                      child: _buildSelectionCard(
                        icon: Icons.picture_as_pdf,
                        label: "PDF / Not",
                        color: Colors.red,
                        onTap: _pickPdf,
                        subtitle: "(İsteğe Bağlı)",
                      ),
                    ),
                  ],
                )
              else if (isImageMode)
                // 2. FOTOĞRAF SEÇİLDİYSE: FOTOĞRAFI GÖSTER + KALDIR BUTONU
                Column(
                  children: [
                    Container(
                      height: 200,
                      width: double.infinity,
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(color: AppColors.primary, width: 2),
                        image: DecorationImage(
                          image: FileImage(_selectedImage!),
                          fit: BoxFit.cover,
                        ),
                      ),
                    ),
                    const Gap(8),
                    TextButton.icon(
                      onPressed: _removeImage,
                      icon: const Icon(Icons.delete_outline, color: Colors.red),
                      label: const Text(
                        "Fotoğrafı Kaldır",
                        style: TextStyle(color: Colors.red),
                      ),
                    ),
                  ],
                )
              else if (isPdfMode)
                // 3. PDF SEÇİLDİYSE: PDF KARTI GÖSTER + KALDIR BUTONU
                Column(
                  children: [
                    Container(
                      width: double.infinity,
                      padding: const EdgeInsets.all(24),
                      decoration: BoxDecoration(
                        color: Colors.green.shade50,
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(color: Colors.green, width: 1.5),
                      ),
                      child: Column(
                        children: [
                          const Icon(
                            Icons.check_circle,
                            color: Colors.green,
                            size: 48,
                          ),
                          const Gap(12),
                          Text(
                            _selectedPdf!.name,
                            textAlign: TextAlign.center,
                            style: const TextStyle(
                              fontWeight: FontWeight.bold,
                              fontSize: 16,
                            ),
                          ),
                          const Gap(4),
                          const Text(
                            "Dosya Eklendi",
                            style: TextStyle(color: Colors.green),
                          ),
                        ],
                      ),
                    ),
                    const Gap(8),
                    TextButton.icon(
                      onPressed: _removePdf,
                      icon: const Icon(Icons.delete_outline, color: Colors.red),
                      label: const Text(
                        "PDF'i Kaldır",
                        style: TextStyle(color: Colors.red),
                      ),
                    ),
                  ],
                ),

              const Gap(24),

              // --- FORM ALANLARI (GERİSİ AYNI) ---
              _buildLabel(isPdfMode ? "Dosya Başlığı" : "Kitap Adı"),
              _buildTextField(
                "Ad girin",
                _titleController,
                readOnly: isPdfMode,
              ),
              const Gap(16),

              if (!isPdfMode) ...[
                _buildLabel("Yazar"),
                _buildTextField("Yazar adını girin", _authorController),
                const Gap(16),
              ],

              _buildLabel("Kategori"),
              if (isPdfMode)
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: Colors.grey.shade100,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: Colors.grey.shade300),
                  ),
                  child: const Text(
                    "📂 Ders Notu / PDF",
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      color: Colors.black54,
                    ),
                  ),
                )
              else ...[
                _buildDropdown(
                  value: _selectedMainCategory,
                  hint: "Kategori Seçiniz",
                  items: AppConstants.getMainCategories(),
                  onChanged: (val) => setState(() {
                    _selectedMainCategory = val;
                    _selectedSubCategory = null;
                  }),
                ),
                const Gap(16),
                if (_selectedMainCategory != null) ...[
                  _buildLabel("Kitap Türü"),
                  _buildDropdown(
                    value: _selectedSubCategory,
                    hint: "Tür Seçiniz",
                    items: AppConstants.getSubCategories(
                      _selectedMainCategory!,
                    ),
                    onChanged: (val) =>
                        setState(() => _selectedSubCategory = val),
                  ),
                ],
              ],
              const Gap(16),

              if (!isPdfMode) ...[
                _buildLabel("Kitap Durumu"),
                _buildDropdown(
                  value: selectedCondition,
                  hint: "Seçiniz",
                  items: ["Yeni", "Çok İyi", "İyi", "İdare Eder"],
                  onChanged: (val) => setState(() => selectedCondition = val),
                ),
                const Gap(24),

                const Text(
                  "Nasıl Paylaşmak İstersin?",
                  style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                ),
                const Gap(12),
                _buildRadioTile("Bağış Yap", "Karşılıksız ver.", "Bağış"),
                _buildRadioTile("Takas", "Başka kitapla değiştir.", "Takas"),
                _buildRadioTile("Ödünç", "Geri almak üzere ver.", "Ödünç"),
                const Gap(24),
              ],

              BlocBuilder<AddBookBloc, AddBookState>(
                builder: (context, state) {
                  if (state is AddBookLoading)
                    return const Center(child: CircularProgressIndicator());

                  return SizedBox(
                    width: double.infinity,
                    height: 56,
                    child: ElevatedButton(
                      onPressed: () async {
                        if (_titleController.text.isEmpty) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(content: Text("Başlık zorunludur.")),
                          );
                          return;
                        }
                        if (!isPdfMode &&
                            (_authorController.text.isEmpty ||
                                selectedCondition == null)) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(
                              content: Text("Tüm alanları doldurun."),
                            ),
                          );
                          return;
                        }

                        final userDoc = await FirebaseFirestore.instance
                            .collection('users')
                            .doc(FirebaseAuth.instance.currentUser!.uid)
                            .get();
                        final userLocation =
                            userDoc.data()?['location'] ?? "Bilinmiyor";

                        if (context.mounted) {
                          context.read<AddBookBloc>().add(
                            AddBookSubmitted(
                              title: _titleController.text,
                              author: isPdfMode
                                  ? "Dijital İçerik"
                                  : _authorController.text,
                              category:
                                  _selectedSubCategory ?? "Ders Notu / PDF",
                              condition: selectedCondition ?? "Yeni",
                              location: userLocation,
                              imageFile: _selectedImage,
                              isDonation:
                                  isPdfMode || _selectedShareType == "Bağış",
                              isSwap:
                                  !isPdfMode && _selectedShareType == "Takas",
                              isLoan:
                                  !isPdfMode && _selectedShareType == "Ödünç",
                              pdfFile: _selectedPdf,
                            ),
                          );
                        }
                      },
                      child: const Text("Yükle"),
                    ),
                  );
                },
              ),
              const Gap(30),
            ],
          ),
        ),
      ),
    );
  }

  // --- YARDIMCI WIDGETLAR ---

  // Kart Tasarımı (Boş Durum İçin)
  Widget _buildSelectionCard({
    required IconData icon,
    required String label,
    required Color color,
    required VoidCallback onTap,
    String? subtitle,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        height: 150,
        decoration: BoxDecoration(
          color: AppColors.background,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: Colors.grey.shade300, width: 1.5),
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: color.withOpacity(0.1),
                shape: BoxShape.circle,
              ),
              child: Icon(icon, color: color, size: 32),
            ),
            const Gap(12),
            Text(
              label,
              style: TextStyle(fontWeight: FontWeight.bold, color: color),
            ),
            if (subtitle != null)
              Text(
                subtitle,
                style: const TextStyle(fontSize: 10, color: Colors.grey),
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildLabel(String text) => Padding(
    padding: const EdgeInsets.only(bottom: 8),
    child: Text(text, style: const TextStyle(fontWeight: FontWeight.w600)),
  );

  Widget _buildTextField(
    String hint,
    TextEditingController controller, {
    bool readOnly = false,
  }) {
    return TextField(
      controller: controller,
      readOnly: readOnly,
      decoration: InputDecoration(
        hintText: hint,
        filled: true,
        fillColor: readOnly ? Colors.grey.shade100 : Colors.white,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: Colors.grey.shade300),
        ),
      ),
    );
  }

  Widget _buildDropdown({
    required String? value,
    required String hint,
    required List<String> items,
    required Function(String?) onChanged,
  }) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.grey.shade300),
      ),
      child: DropdownButtonHideUnderline(
        child: DropdownButton<String>(
          value: value,
          hint: Text(hint),
          isExpanded: true,
          items: items
              .map((e) => DropdownMenuItem(value: e, child: Text(e)))
              .toList(),
          onChanged: onChanged,
        ),
      ),
    );
  }

  Widget _buildRadioTile(String title, String subtitle, String value) {
    return RadioListTile<String>(
      title: Text(title, style: const TextStyle(fontWeight: FontWeight.w600)),
      subtitle: Text(subtitle, style: const TextStyle(fontSize: 12)),
      value: value,
      groupValue: _selectedShareType,
      activeColor: AppColors.primary,
      contentPadding: EdgeInsets.zero,
      onChanged: (val) => setState(() => _selectedShareType = val!),
    );
  }
}
