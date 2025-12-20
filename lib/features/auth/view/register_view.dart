import 'package:email_otp/email_otp.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:gap/gap.dart';
import 'package:kitaptakas/features/auth/view/complete_profile_view.dart';
import '../../../../core/constants/app_colors.dart';
import '../../home/view/home_view.dart';
import '../bloc/auth_bloc.dart';
import '../bloc/auth_event.dart';
import '../bloc/auth_state.dart';

class RegisterPage extends StatefulWidget {
  const RegisterPage({super.key});

  @override
  State<RegisterPage> createState() => _RegisterPageState();
}

class _RegisterPageState extends State<RegisterPage> {
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final _confirmPasswordController = TextEditingController();
  bool _isPasswordVisible = false;

  bool _isOptLoading = false;

  // OTP Gönderme Fonksiyonu
  Future<void> _sendOtp() async {
    if (_emailController.text.isEmpty || _passwordController.text.isEmpty) {
      _showError(context, "Lütfen tüm alanları doldurun.");
      return;
    }
    if (_passwordController.text != _confirmPasswordController.text) {
      _showError(context, "Şifreler eşleşmiyor.");
      return;
    }
    if (_passwordController.text.length < 6) {
      _showError(context, "Şifre en az 6 karakter olmalı.");
      return;
    }
    FocusScope.of(context).unfocus();
    setState(() => _isOptLoading = true);

    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text("Doğrulama kodu gönderiliyor...")),
    );

    try {
      EmailOTP.config(
        appName: 'Takasla',
        otpType: OTPType.numeric,
        emailTheme: EmailTheme.v1,
        otpLength: 6,
      );
      EmailOTP.setTemplate(
        template: '''
          <div style="background-color: #f5f5f5; padding: 20px; font-family: sans-serif;">
            <div style="max-width: 500px; margin: 0 auto; background-color: white; padding: 30px; border-radius: 10px; box-shadow: 0 2px 10px rgba(0,0,0,0.1);">
              
              <h2 style="color: #2979FF; text-align: center;">{{appName}}'ya Hoş Geldin! 🚀</h2>
              
              <p style="font-size: 16px; color: #333;">Merhaba,</p>
              <p style="font-size: 16px; color: #333;">Hesabını doğrulamak için aşağıdaki kodu kullanabilirsin:</p>
              
              <div style="background-color: #e3f2fd; padding: 15px; text-align: center; border-radius: 8px; margin: 20px 0;">
                <span style="font-size: 32px; font-weight: bold; letter-spacing: 5px; color: #1565c0;">{{otp}}</span>
              </div>

              <p style="font-size: 14px; color: #666;">Bu kod güvenlik nedeniyle 5 dakika içinde geçerliliğini yitirecektir.</p>
              <hr style="border: none; border-top: 1px solid #eee; margin: 20px 0;">
              <p style="font-size: 12px; color: #999; text-align: center;">Bu maili sen talep etmediysen lütfen dikkate alma.</p>
            </div>
          </div>
        ''',
      );
      bool result = await EmailOTP.sendOTP(email: _emailController.text.trim());

      if (mounted) setState(() => _isOptLoading = false);

      if (result) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text("Kod gönderildi! Mail kutunu kontrol et."),
              backgroundColor: Colors.green,
            ),
          );
          _showOtpDialog();
        }
      } else {
        _showError(context, "Kod gönderilemedi. Mail adresini kontrol et.");
      }
    } catch (e) {
      if (mounted) setState(() => _isOptLoading = false);
      _showError(context, "Hata: $e");
    }
  }

  // OTP Giriş Penceresi
  void _showOtpDialog() {
    final TextEditingController _otpController = TextEditingController();

    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) {
        return AlertDialog(
          title: const Text("Doğrulama Kodu"),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Text("Mail adresine gelen 6 haneli kodu girin:"),
              const Gap(10),
              TextField(
                controller: _otpController,
                keyboardType: TextInputType.number,
                maxLength: 6,
                textAlign: TextAlign.center,
                style: const TextStyle(
                  fontSize: 24,
                  letterSpacing: 8,
                  fontWeight: FontWeight.bold,
                ),
                decoration: const InputDecoration(
                  counterText: "",
                  border: OutlineInputBorder(),
                ),
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text("İptal", style: TextStyle(color: Colors.red)),
            ),
            ElevatedButton(
              onPressed: () {
                bool isValid = EmailOTP.verifyOTP(otp: _otpController.text);
                if (isValid) {
                  Navigator.pop(context);
                  // Doğrulama başarılı, kayıt işlemini başlat
                  context.read<AuthBloc>().add(
                    AuthRegisterRequested(
                      email: _emailController.text,
                      password: _passwordController.text,
                    ),
                  );
                } else {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text("Hatalı kod! Tekrar dene."),
                      backgroundColor: Colors.red,
                    ),
                  );
                }
              },
              child: const Text("Onayla"),
            ),
          ],
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: AppColors.background,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(
            Icons.arrow_back_ios_new,
            color: AppColors.textPrimary,
          ),
          onPressed: () => Navigator.pop(context),
        ),
        title: const Text(
          "Kayıt Ol",
          style: TextStyle(
            color: AppColors.textPrimary,
            fontWeight: FontWeight.bold,
          ),
        ),
        centerTitle: true,
      ),
      body: BlocConsumer<AuthBloc, AuthState>(
        listener: (context, state) {
          if (state is AuthFailure) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text(state.message),
                backgroundColor: Colors.red,
              ),
            );
          } else if (state is AuthAuthenticated) {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(
                content: Text("Kayıt Başarılı! Hoş geldin. 🎉"),
                backgroundColor: Colors.green,
              ),
            );
            // Kayıt başarılıysa Profil Tamamlama sayfasına yönlendir
            Navigator.pushAndRemoveUntil(
              context,
              MaterialPageRoute(
                builder: (context) => const CompleteProfileView(),
              ),
              (route) => false,
            );
          }
        },
        builder: (context, state) {
          return SingleChildScrollView(
            padding: const EdgeInsets.all(24.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  "Aramıza Katıl! 🚀",
                  style: TextStyle(
                    fontSize: 28,
                    fontWeight: FontWeight.bold,
                    color: AppColors.textPrimary,
                  ),
                ),
                const Gap(8),
                const Text(
                  "Kitaplarını paylaşmak ve yeni dünyalar keşfetmek için hemen hesap oluştur.",
                  style: TextStyle(
                    fontSize: 16,
                    color: AppColors.textSecondary,
                  ),
                ),
                const Gap(32),

                // E-POSTA
                _buildLabel("E-Posta Adresi"),
                TextField(
                  controller: _emailController,
                  keyboardType: TextInputType.emailAddress,
                  decoration: _inputDecoration(
                    "ornek@email.com",
                    Icons.email_outlined,
                  ),
                ),
                const Gap(20),

                // ŞİFRE
                _buildLabel("Şifre"),
                TextField(
                  controller: _passwordController,
                  obscureText: !_isPasswordVisible,
                  decoration: _inputDecoration("********", Icons.lock_outline)
                      .copyWith(
                        suffixIcon: IconButton(
                          icon: Icon(
                            _isPasswordVisible
                                ? Icons.visibility
                                : Icons.visibility_off,
                            color: Colors.grey,
                          ),
                          onPressed: () => setState(
                            () => _isPasswordVisible = !_isPasswordVisible,
                          ),
                        ),
                      ),
                ),
                const Gap(20),

                // ŞİFRE TEKRAR
                _buildLabel("Şifre Tekrar"),
                TextField(
                  controller: _confirmPasswordController,
                  obscureText: !_isPasswordVisible,
                  decoration: _inputDecoration("********", Icons.lock_outline),
                ),
                const Gap(40),

                // KAYIT OL BUTONU (OTP ile çalışır)
                SizedBox(
                  width: double.infinity,
                  height: 56,
                  child: ElevatedButton(
                    onPressed: (state is AuthLoading || _isOptLoading)
                        ? null
                        : _sendOtp,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.primary,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                      elevation: 2,
                    ),
                    child: (state is AuthLoading || _isOptLoading)
                        ? const SizedBox(
                            width: 24,
                            height: 24,
                            child: CircularProgressIndicator(
                              color: Colors.white,
                              strokeWidth: 2,
                            ),
                          )
                        : const Text(
                            "Hesap Oluştur",
                            style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                              color: Colors.white,
                            ),
                          ),
                  ),
                ),

                const Gap(16),

                // GOOGLE İLE KAYIT (İsteğe bağlı)
                SizedBox(
                  width: double.infinity,
                  height: 56,
                  child: OutlinedButton.icon(
                    onPressed: state is AuthLoading
                        ? null
                        : () {
                            context.read<AuthBloc>().add(
                              AuthGoogleLoginRequested(),
                            );
                          },
                    icon: Image.network(
                      "https://upload.wikimedia.org/wikipedia/commons/thumb/c/c1/Google_%22G%22_logo.svg/1200px-Google_%22G%22_logo.svg.png",
                      height: 24,
                    ),
                    label: const Text(
                      "Google ile Devam Et",
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                        color: AppColors.textPrimary,
                      ),
                    ),
                    style: OutlinedButton.styleFrom(
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                      side: const BorderSide(color: Colors.grey),
                    ),
                  ),
                ),
              ],
            ),
          );
        },
      ),
    );
  }

  // Yardımcı Metotlar
  Widget _buildLabel(String text) => Padding(
    padding: const EdgeInsets.only(bottom: 8.0),
    child: Text(text, style: const TextStyle(fontWeight: FontWeight.bold)),
  );

  InputDecoration _inputDecoration(String hint, IconData icon) {
    return InputDecoration(
      hintText: hint,
      prefixIcon: Icon(icon, color: Colors.grey),
      filled: true,
      fillColor: Colors.white,
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: BorderSide.none,
      ),
    );
  }

  void _showError(BuildContext context, String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message), backgroundColor: Colors.red),
    );
  }
}
