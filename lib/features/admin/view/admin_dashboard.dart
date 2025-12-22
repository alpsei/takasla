import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:kitaptakas/data/repositories/admin_repositories.dart';
import 'package:kitaptakas/features/admin/bloc/admin_dashboard_bloc.dart';
import 'package:kitaptakas/features/admin/view/book_management_screen.dart';
import 'package:kitaptakas/features/admin/view/report_management_screen.dart';
import 'package:kitaptakas/features/admin/view/user_management_screen.dart';
import 'package:kitaptakas/features/auth/bloc/auth_bloc.dart';
import 'package:kitaptakas/features/auth/bloc/auth_event.dart';
import 'package:kitaptakas/features/auth/view/welcome_view.dart';

class AdminDashboardScreen extends StatelessWidget {
  const AdminDashboardScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (context) =>
          AdminDashboardBloc(AdminRepository())..add(LoadDashboardStats()),
      child: Scaffold(
        backgroundColor: Colors.white,
        appBar: AppBar(
          title: const Text(
            "Yönetici Paneli",
            style: TextStyle(color: Colors.black, fontWeight: FontWeight.bold),
          ),
          centerTitle: true,
          backgroundColor: Colors.white,
          elevation: 0,
          iconTheme: const IconThemeData(color: Colors.black),
        ),
        body: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                "Genel Bakış",
                style: TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                  color: Colors.black87,
                ),
              ),
              const SizedBox(height: 16),

              // Grid Yapısı ve State Yönetimi
              Expanded(
                child: BlocBuilder<AdminDashboardBloc, AdminDashboardState>(
                  builder: (context, state) {
                    // YÜKLENİYOR
                    if (state is AdminDashboardLoading) {
                      return const Center(child: CircularProgressIndicator());
                    }

                    // HATA VARSA
                    if (state is AdminDashboardError) {
                      return Center(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            const Icon(
                              Icons.error_outline,
                              color: Colors.red,
                              size: 40,
                            ),
                            const SizedBox(height: 10),
                            Text(
                              "İstatistikler alınamadı:\n${state.message}",
                              textAlign: TextAlign.center,
                            ),
                            const SizedBox(height: 10),
                            ElevatedButton(
                              onPressed: () {
                                context.read<AdminDashboardBloc>().add(
                                  LoadDashboardStats(),
                                );
                              },
                              child: const Text("Tekrar Dene"),
                            ),
                          ],
                        ),
                      );
                    }

                    // 3. VERİLER GELDİYSE (Loaded)
                    String userCount = "0";
                    String bookCount = "0";
                    String reportCount = "0";

                    if (state is AdminDashboardLoaded) {
                      userCount = state.userCount.toString();
                      bookCount = state.bookCount.toString();
                      reportCount = state.reportCount.toString();
                    }

                    return GridView.count(
                      crossAxisCount: 2,
                      crossAxisSpacing: 16,
                      mainAxisSpacing: 16,
                      childAspectRatio: 1.0,
                      children: [
                        // KULLANICILAR KARTI
                        _buildSimpleCard(
                          context,
                          title: "Kullanıcılar",
                          count: userCount,
                          icon: Icons.group_outlined,
                          themeColor: Colors.blue,
                          onTap: () => Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (_) => const UserManagementScreen(),
                            ),
                          ),
                        ),

                        // KİTAPLAR KARTI
                        _buildSimpleCard(
                          context,
                          title: "Kitaplar",
                          count: bookCount,
                          icon: Icons.menu_book_outlined,
                          themeColor: Colors.orange,
                          onTap: () => Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (_) => const BookManagementScreen(),
                            ),
                          ),
                        ),

                        // RAPORLAR KARTI
                        _buildSimpleCard(
                          context,
                          title: "Şikayetler",
                          count: reportCount,
                          icon: Icons.warning_amber_rounded,
                          themeColor: Colors.red,
                          onTap: () => Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (_) => const ReportManagementScreen(),
                            ),
                          ),
                        ),

                        // ÇIKIŞ KARTI
                        _buildSimpleCard(
                          context,
                          title: "Çıkış Yap",
                          count: "",
                          icon: Icons.logout,
                          themeColor: Colors.grey,
                          isLogout: true,
                          onTap: () {
                            context.read<AuthBloc>().add(AuthLogoutRequested());
                            Navigator.pushAndRemoveUntil(
                              context,
                              MaterialPageRoute(
                                builder: (context) => const WelcomeView(),
                              ),
                              (route) => false,
                            );
                          },
                        ),
                      ],
                    );
                  },
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  // --- KART TASARIMI ---
  Widget _buildSimpleCard(
    BuildContext context, {
    required String title,
    required String count,
    required IconData icon,
    required Color themeColor,
    required VoidCallback onTap,
    bool isLogout = false,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        decoration: BoxDecoration(
          color: themeColor.withOpacity(0.1),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: themeColor.withOpacity(0.2), width: 1),
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            // İkon
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.white,
                shape: BoxShape.circle,
                boxShadow: [
                  BoxShadow(
                    color: themeColor.withOpacity(0.1),
                    blurRadius: 8,
                    offset: const Offset(0, 2),
                  ),
                ],
              ),
              child: Icon(icon, color: themeColor, size: 28),
            ),

            const SizedBox(height: 12),

            // Sayı
            if (!isLogout && count.isNotEmpty) ...[
              Text(
                count,
                style: TextStyle(
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                  color: themeColor,
                ),
              ),
              const SizedBox(height: 4),
            ],

            // Başlık
            Text(
              title,
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w600,
                color: Colors.black87,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
