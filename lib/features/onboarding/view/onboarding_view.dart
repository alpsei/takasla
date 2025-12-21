import 'package:flutter/material.dart';
import 'package:gap/gap.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:smooth_page_indicator/smooth_page_indicator.dart';
import '../../../../core/constants/app_colors.dart';
import '../../auth/view/auth_gate.dart';

class OnboardingView extends StatefulWidget {
  const OnboardingView({super.key});

  @override
  State<OnboardingView> createState() => _OnboardingViewState();
}

class _OnboardingViewState extends State<OnboardingView> {
  final PageController _controller = PageController();
  bool _isLastPage = false;

  // Tanıtımı bitir ve hafızaya kaydet
  Future<void> _finishOnboarding() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('showOnboarding', false); // "Artık gösterme" de

    if (mounted) {
      // AuthGate'e yönlendir
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (context) => const AuthGate()),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: Container(
        padding: const EdgeInsets.only(bottom: 80), // Alt butonlar için boşluk
        child: PageView(
          controller: _controller,
          onPageChanged: (index) {
            setState(() => _isLastPage = index == 2);
          },
          children: [
            // SAYFA 1: TAKAS
            _buildPage(
              icon: Icons.swap_horizontal_circle,
              color: Colors.orange,
              title: "Kitaplarını Takasla",
              description:
                  "Okuduğun kitapları rafa kaldırma. Onları başka kitaplarla takas et, yeni dünyalar keşfet.",
            ),
            // SAYFA 2: PUAN
            _buildPage(
              icon: Icons.shield_outlined,
              color: AppColors.primary,
              title: "Güvenilir Depozito",
              description:
                  "Başlangıçta sana 100 puan hediye ediyoruz! \n\nHer talep gönderdiğinde 20 puanın 'Depozito' olarak ayrılır. Kitabı teslim alıp işlemi onayladığında puanın hesabına iade edilir.",
            ),
            // SAYFA 3: DOĞA
            _buildPage(
              icon: Icons.eco,
              color: Colors.green,
              title: "Doğayı Koru",
              description:
                  "Kağıt israfını önle. Kitapları döngüye sokarak hem cebini hem de gezegenimizi koru.",
            ),
          ],
        ),
      ),

      // ALT KONTROLLER
      bottomSheet: Container(
        padding: const EdgeInsets.symmetric(horizontal: 20),
        height: 80,
        color: Colors.white,
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            // GEÇ BUTONU
            _isLastPage
                ? const SizedBox(width: 50)
                : TextButton(
                    onPressed: _finishOnboarding,
                    child: const Text(
                      "Atla",
                      style: TextStyle(color: Colors.grey),
                    ),
                  ),

            // NOKTALAR
            SmoothPageIndicator(
              controller: _controller,
              count: 3,
              effect: const WormEffect(
                spacing: 16,
                dotColor: Colors.black12,
                activeDotColor: AppColors.primary,
              ),
              onDotClicked: (index) => _controller.animateToPage(
                index,
                duration: const Duration(milliseconds: 500),
                curve: Curves.easeIn,
              ),
            ),

            // İLERİ / BAŞLA BUTONU
            _isLastPage
                ? TextButton(
                    onPressed: _finishOnboarding,
                    child: const Text(
                      "BAŞLA",
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        color: AppColors.primary,
                      ),
                    ),
                  )
                : TextButton(
                    onPressed: () => _controller.nextPage(
                      duration: const Duration(milliseconds: 500),
                      curve: Curves.easeInOut,
                    ),
                    child: const Text("İleri"),
                  ),
          ],
        ),
      ),
    );
  }

  // Sayfa Tasarımı
  Widget _buildPage({
    required IconData icon,
    required Color color,
    required String title,
    required String description,
  }) {
    return Padding(
      padding: const EdgeInsets.all(40.0),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(icon, size: 150, color: color),
          const Gap(40),
          Text(
            title,
            style: const TextStyle(
              fontSize: 28,
              fontWeight: FontWeight.bold,
              color: AppColors.textPrimary,
            ),
          ),
          const Gap(20),
          Text(
            description,
            textAlign: TextAlign.center,
            style: const TextStyle(
              fontSize: 16,
              color: Colors.grey,
              height: 1.5,
            ),
          ),
        ],
      ),
    );
  }
}
