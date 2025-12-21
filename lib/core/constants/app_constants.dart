class AppConstants {
  static const Map<String, List<String>> bookCategories = {
    "Sınav Kitapları": [
      "YKS (TYT/AYT)",
      "KPSS",
      "ALES",
      "DGS",
      "LGS",
      "YDS / YÖKDİL",
      "TUS / DUS",
      "Diğer Sınavlar",
    ],
    "Edebiyat & Okuma": [
      "Roman",
      "Hikaye (Öykü)",
      "Şiir",
      "Deneme / İnceleme",
      "Biyografi",
      "Tarih",
      "Felsefe",
      "Kişisel Gelişim",
      "Psikoloji",
      "Din / Mitoloji",
      "Çizgi Roman",
      "Çocuk Kitapları",
      "Yabancı Dil",
    ],
    "Diğer": ["Ansiklopedi", "Dergi", "Diğer"],
  };

  // KİTAP DURUMLARI
  static const List<String> bookConditions = [
    "Yeni (Sıfır)",
    "Çok İyi",
    "İyi",
    "İdare Eder",
    "Yıpranmış",
  ];

  // Helper: Ana Kategorileri Getir
  static List<String> getMainCategories() => bookCategories.keys.toList();

  // Helper: Alt Kategorileri Getir
  static List<String> getSubCategories(String mainCat) =>
      bookCategories[mainCat] ?? [];
}
