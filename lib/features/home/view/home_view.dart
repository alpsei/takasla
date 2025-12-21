import 'dart:convert';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:gap/gap.dart';
import 'package:kitaptakas/core/constants/app_constants.dart';
import 'package:kitaptakas/core/constants/tr_cities.dart';
import 'package:kitaptakas/data/repositories/auth_repository.dart';
import 'package:kitaptakas/features/admin/view/admin_dashboard.dart';
import 'package:kitaptakas/features/auth/bloc/auth_bloc.dart';
import 'package:kitaptakas/features/auth/bloc/auth_event.dart';
import 'package:kitaptakas/features/auth/bloc/auth_state.dart';
import 'package:kitaptakas/features/auth/view/welcome_view.dart';
import 'package:kitaptakas/features/book_detail/view/book_detail_view.dart';
import 'package:kitaptakas/features/profile/view/profile_view.dart';
import 'package:kitaptakas/features/profile/view/public_profile_view.dart';
import 'package:kitaptakas/features/requests/view/request_view.dart';
import 'package:kitaptakas/features/requests/view/sent_requests_view.dart';
import 'package:kitaptakas/features/settings/view/settings_view.dart';
import '../../../../core/constants/app_colors.dart';
import '../../../../data/repositories/book_repository.dart';
import '../../add_book/view/add_book_view.dart';
import '../bloc/home_bloc.dart';
import '../bloc/home_event.dart';
import '../bloc/home_state.dart';
import 'widgets/book_card.dart';

class HomePage extends StatelessWidget {
  const HomePage({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (context) => HomeBloc(
        bookRepository: BookRepository(),
        authRepository: AuthRepository(),
      )..add(HomeBooksRequested()),
      child: const HomeView(),
    );
  }
}

class HomeView extends StatelessWidget {
  const HomeView({super.key});

  @override
  Widget build(BuildContext context) {
    final user = FirebaseAuth.instance.currentUser;
    final isGuest = user == null;
    return BlocListener<AuthBloc, AuthState>(
      listener: (context, state) {
        if (state is AuthInitial || state is AuthUnauthenticated) {
          Navigator.pushAndRemoveUntil(
            context,
            MaterialPageRoute(builder: (context) => const WelcomeView()),
            (route) => false,
          );
        }
      },
      child: Scaffold(
        drawer: Drawer(
          child: StreamBuilder<DocumentSnapshot>(
            stream: (isGuest || user == null)
                ? null
                : FirebaseFirestore.instance
                      .collection('users')
                      .doc(user.uid)
                      .snapshots(),
            builder: (context, snapshot) {
              String userName = "Kitap Sever";
              String userMail = "Misafir";
              String? photoData;
              String userRole = "user";
              if (user != null) {
                userMail = user.email ?? "";
                if (snapshot.hasData &&
                    snapshot.data != null &&
                    snapshot.data!.exists) {
                  final data = snapshot.data!.data() as Map<String, dynamic>;
                  userName = data['name'] ?? userName;
                  photoData = data['photoUrl'];
                  userRole = data['role'] ?? "user";
                }
              } else {
                userName = "Misafir Kullanıcı";
                userMail = "Giriş Yapılmadı";
              }

              return Column(
                children: [
                  // --- HEADER ---
                  UserAccountsDrawerHeader(
                    decoration: const BoxDecoration(color: AppColors.primary),
                    accountName: Text(
                      userName,
                      style: const TextStyle(fontWeight: FontWeight.bold),
                    ),
                    accountEmail: Text(userMail),
                    currentAccountPicture: CircleAvatar(
                      backgroundColor: Colors.white,
                      backgroundImage:
                          (photoData != null && photoData.isNotEmpty)
                          ? (photoData.startsWith('http')
                                    ? NetworkImage(photoData)
                                    : MemoryImage(base64Decode(photoData)))
                                as ImageProvider
                          : null,
                      child: photoData == null
                          ? const Icon(
                              Icons.person,
                              color: AppColors.primary,
                              size: 40,
                            )
                          : null,
                    ),
                  ),

                  // --- MENÜ ÖĞELERİ ---
                  if (!isGuest) ...[
                    if (userRole == 'admin') ...[
                      ListTile(
                        leading: const Icon(
                          Icons.admin_panel_settings,
                          color: Colors.redAccent,
                        ),
                        title: const Text(
                          'Yönetici Paneli',
                          style: TextStyle(
                            color: Colors.redAccent,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        onTap: () {
                          Navigator.pop(context);
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (context) =>
                                  const AdminDashboardScreen(),
                            ),
                          );
                        },
                      ),
                      const Divider(),
                    ],
                    ListTile(
                      leading: const Icon(Icons.person_outline),
                      title: const Text("Profilim"),
                      onTap: () {
                        Navigator.pop(context);
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (context) => const ProfilePage(),
                          ),
                        );
                      },
                    ),
                    ListTile(
                      leading: const Icon(Icons.settings_outlined),
                      title: const Text("Ayarlar"),
                      onTap: () {
                        Navigator.pop(context);
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (context) => const SettingsView(),
                          ),
                        );
                      },
                    ),
                    ListTile(
                      leading: const Icon(Icons.notifications_outlined),
                      title: const Text("Gelen Talepler"),
                      onTap: () {
                        Navigator.pop(context);
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (context) => const RequestsPage(),
                          ),
                        );
                      },
                    ),
                    ListTile(
                      leading: const Icon(Icons.send_outlined),
                      title: const Text("Gönderdiğim Talepler"),
                      onTap: () {
                        Navigator.pop(context);
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (context) => const SentRequestsPage(),
                          ),
                        );
                      },
                    ),

                    const Spacer(),
                    const Divider(),
                  ],

                  // --- ÇIKIŞ YAP / GİRİŞ YAP ---
                  ListTile(
                    leading: Icon(
                      isGuest ? Icons.login : Icons.logout,
                      color: isGuest ? Colors.green : Colors.red,
                    ),
                    title: Text(
                      isGuest ? "Giriş Yap" : "Çıkış Yap",
                      style: TextStyle(
                        color: isGuest ? Colors.green : Colors.red,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    onTap: () {
                      if (isGuest) {
                        Navigator.pushAndRemoveUntil(
                          context,
                          MaterialPageRoute(
                            builder: (context) => const WelcomeView(),
                          ),
                          (route) => false,
                        );
                      } else {
                        context.read<AuthBloc>().add(AuthLogoutRequested());
                      }
                    },
                  ),
                  const Gap(20),
                ],
              );
            },
          ),
        ),
        appBar: AppBar(
          title: const Text("Takasla!"),
          actions: [
            // Misafir değilse ve Kullanıcı VARSA puanı göster
            if (!isGuest && FirebaseAuth.instance.currentUser != null)
              StreamBuilder<DocumentSnapshot>(
                stream: FirebaseFirestore.instance
                    .collection('users')
                    .doc(user.uid)
                    .snapshots(),
                builder: (context, snapshot) {
                  int points = 0;
                  if (snapshot.hasData &&
                      snapshot.data != null &&
                      snapshot.data!.exists) {
                    final data = snapshot.data!.data() as Map<String, dynamic>;
                    points = data['tradePoints'] ?? 0;
                  }

                  return Container(
                    margin: const EdgeInsets.only(right: 14),
                    padding: const EdgeInsets.symmetric(
                      horizontal: 12,
                      vertical: 6,
                    ),
                    decoration: BoxDecoration(
                      color: AppColors.tagSwapBg,
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(
                        color: AppColors.tagSwapText.withOpacity(0.5),
                      ),
                    ),
                    child: Row(
                      children: [
                        const Icon(
                          Icons.stars,
                          color: AppColors.tagSwapText,
                          size: 15,
                        ),
                        const Gap(6),
                        Text(
                          "$points Puan",
                          style: const TextStyle(
                            color: AppColors.tagSwapText,
                            fontWeight: FontWeight.bold,
                            fontSize: 12,
                          ),
                        ),
                      ],
                    ),
                  );
                },
              ),
            const Gap(8),
          ],
        ),

        // --- BODY (LİSTE VE ARAMA) ---
        body: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16.0),
          child: Column(
            children: [
              const Gap(10),
              // Arama Çubuğu
              TextField(
                onChanged: (query) {
                  context.read<HomeBloc>().add(HomeSearchQueryChanged(query));
                },
                decoration: InputDecoration(
                  hintText: "Kitap, yazar veya konu ara...",
                  hintStyle: const TextStyle(color: Colors.grey),
                  prefixIcon: const Icon(Icons.search, color: Colors.grey),
                  filled: true,
                  fillColor: Colors.white,
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(30),
                    borderSide: BorderSide.none,
                  ),
                  contentPadding: const EdgeInsets.symmetric(vertical: 0),
                ),
              ),
              const Gap(16),

              // Arama Modu Seçimi
              BlocBuilder<HomeBloc, HomeState>(
                builder: (context, state) {
                  if (state is! HomeSuccess) return const SizedBox();

                  return Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      _buildSearchTypeChip(
                        context,
                        label: "Kitap Ara 📚",
                        isSelected: !state.isUserSearchMode,
                        onTap: () => context.read<HomeBloc>().add(
                          const HomeSearchModeChanged(false),
                        ),
                      ),
                      const Gap(12),
                      _buildSearchTypeChip(
                        context,
                        label: "Kullanıcı Ara 👤",
                        isSelected: state.isUserSearchMode,
                        onTap: () => context.read<HomeBloc>().add(
                          const HomeSearchModeChanged(true),
                        ),
                      ),
                    ],
                  );
                },
              ),
              const Gap(12),

              // Filtreler
              BlocBuilder<HomeBloc, HomeState>(
                builder: (context, state) {
                  if (state is HomeSuccess && state.isUserSearchMode)
                    return const SizedBox();

                  if (state is! HomeSuccess) return const SizedBox();
                  return SingleChildScrollView(
                    scrollDirection: Axis.horizontal,
                    child: Row(
                      children: [
                        _buildFilterMenu(
                          context: context,
                          label: state.activeTakasTuru ?? "Takas Türü",
                          icon: Icons.tune,
                          options: ["Bağış", "Takas", "Ödünç"],
                          isSelected: state.activeTakasTuru != null,
                          onSelected: (val) {
                            context.read<HomeBloc>().add(
                              HomeFilterChanged(takasTuru: val),
                            );
                          },
                        ),
                        const Gap(8),
                        _buildFilterMenu(
                          context: context,
                          label: state.activeKitapTuru ?? "Kategori",
                          icon: Icons.menu_book,
                          options: AppConstants.getMainCategories(),
                          isSelected: state.activeKitapTuru != null,
                          onSelected: (val) {
                            context.read<HomeBloc>().add(
                              HomeFilterChanged(kitapTuru: val),
                            );
                          },
                        ),
                        const Gap(8),
                        _buildFilterMenu(
                          context: context,
                          label: state.activeKonum ?? "Konum",
                          icon: Icons.location_on_outlined,
                          isSelected: state.activeKonum != null,
                          options: TrCities.cities,
                          onSelected: (val) {
                            context.read<HomeBloc>().add(
                              HomeFilterChanged(konum: val),
                            );
                          },
                        ),
                        const Gap(8),
                        if (state.activeTakasTuru != null ||
                            state.activeKitapTuru != null ||
                            state.activeKonum != null)
                          IconButton(
                            onPressed: () {
                              context.read<HomeBloc>().add(
                                const HomeFilterChanged(),
                              );
                            },
                            icon: const Icon(Icons.refresh, color: Colors.grey),
                            tooltip: "Filtreleri Temizle",
                          ),
                      ],
                    ),
                  );
                },
              ),

              const Gap(16),

              // --- LİSTE KISMI ---
              Expanded(
                child: BlocBuilder<HomeBloc, HomeState>(
                  builder: (context, state) {
                    if (state is HomeLoading) {
                      return const Center(child: CircularProgressIndicator());
                    }

                    if (state is HomeFailure) {
                      return Center(child: Text("Hata: ${state.error}"));
                    }

                    if (state is HomeSuccess) {
                      // A. KULLANICI ARAMA MODU
                      if (state.isUserSearchMode) {
                        if (state.userResults.isEmpty) {
                          return Center(
                            child: Text(
                              state.activeSearchQuery?.isEmpty ?? true
                                  ? "Kullanıcı aramak için isim yazın."
                                  : "Kullanıcı bulunamadı.",
                              style: const TextStyle(color: Colors.grey),
                            ),
                          );
                        }

                        return ListView.separated(
                          itemCount: state.userResults.length,
                          padding: const EdgeInsets.all(16),
                          separatorBuilder: (context, index) => const Gap(12),
                          itemBuilder: (context, index) {
                            final userItem = state.userResults[index];
                            return Card(
                              elevation: 0,
                              color: Colors.white,
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(12),
                                side: BorderSide(color: Colors.grey.shade200),
                              ),
                              child: ListTile(
                                contentPadding: const EdgeInsets.symmetric(
                                  horizontal: 16,
                                  vertical: 8,
                                ),
                                leading: CircleAvatar(
                                  backgroundColor: AppColors.tagDonationBg,
                                  backgroundImage:
                                      (userItem.photoUrl != null &&
                                          userItem.photoUrl!.isNotEmpty)
                                      ? (userItem.photoUrl!.startsWith('http')
                                                ? NetworkImage(
                                                    userItem.photoUrl!,
                                                  )
                                                : MemoryImage(
                                                    base64Decode(
                                                      userItem.photoUrl!,
                                                    ),
                                                  ))
                                            as ImageProvider
                                      : null,
                                  child:
                                      (userItem.photoUrl == null ||
                                          userItem.photoUrl!.isEmpty)
                                      ? const Icon(
                                          Icons.person,
                                          color: AppColors.primary,
                                        )
                                      : null,
                                ),
                                title: Text(
                                  userItem.name,
                                  style: const TextStyle(
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                                subtitle: Text(
                                  userItem.location ?? "Konum Yok",
                                  style: const TextStyle(
                                    fontSize: 12,
                                    color: Colors.grey,
                                  ),
                                ),
                                trailing: const Icon(
                                  Icons.arrow_forward_ios,
                                  size: 16,
                                  color: Colors.grey,
                                ),
                                onTap: () {
                                  Navigator.push(
                                    context,
                                    MaterialPageRoute(
                                      builder: (context) => PublicProfileView(
                                        targetUser: userItem,
                                      ),
                                    ),
                                  );
                                },
                              ),
                            );
                          },
                        );
                      }
                      // B. KİTAP ARAMA MODU
                      else {
                        if (state.books.isEmpty) {
                          return const Center(
                            child: Text(
                              "Aradığınız kriterlere uygun kitap bulunamadı.",
                              style: TextStyle(color: Colors.grey),
                            ),
                          );
                        }

                        return RefreshIndicator(
                          color: AppColors.primary,
                          onRefresh: () async {
                            context.read<HomeBloc>().add(HomeBooksRequested());
                            await Future.delayed(const Duration(seconds: 1));
                          },
                          child: ListView.builder(
                            physics: const AlwaysScrollableScrollPhysics(),
                            itemCount: state.books.length,
                            itemBuilder: (context, index) {
                              final book = state.books[index];
                              return BookCard(
                                book: book,
                                onTap: () async {
                                  final result = await Navigator.push(
                                    context,
                                    MaterialPageRoute(
                                      builder: (context) =>
                                          BookDetailPage(book: book),
                                    ),
                                  );
                                  if (result == true && context.mounted) {
                                    context.read<HomeBloc>().add(
                                      HomeBooksRequested(),
                                    );
                                  }
                                },
                              );
                            },
                          ),
                        );
                      }
                    }
                    return const Center(child: Text("Yükleniyor..."));
                  },
                ),
              ),
            ],
          ),
        ),

        // --- EKLE BUTONU ---
        floatingActionButton: isGuest
            ? null
            : SizedBox(
                width: 60,
                height: 60,
                child: FloatingActionButton(
                  onPressed: () async {
                    await Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => const AddBookPage(),
                      ),
                    );
                    if (context.mounted) {
                      context.read<HomeBloc>().add(HomeBooksRequested());
                    }
                  },
                  backgroundColor: AppColors.primary,
                  shape: const CircleBorder(),
                  elevation: 4,
                  child: const Icon(Icons.add, size: 32, color: Colors.white),
                ),
              ),
      ),
    );
  }

  // YARDIMCI WIDGETLAR
  Widget _buildFilterMenu({
    required BuildContext context,
    required String label,
    required IconData icon,
    required List<String> options,
    required Function(String?) onSelected,
    bool isSelected = false,
  }) {
    return PopupMenuButton<String>(
      onSelected: onSelected,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      itemBuilder: (context) {
        return options.map((String option) {
          return PopupMenuItem<String>(value: option, child: Text(option));
        }).toList();
      },
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        decoration: BoxDecoration(
          color: isSelected ? AppColors.primary : Colors.white,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: AppColors.primary.withOpacity(0.5)),
        ),
        child: Row(
          children: [
            Icon(
              icon,
              size: 18,
              color: isSelected ? Colors.white : AppColors.primary,
            ),
            const Gap(6),
            Text(
              label,
              style: const TextStyle(
                color: AppColors.textPrimary,
                fontWeight: FontWeight.w500,
              ),
            ),
            const Gap(4),
            const Icon(Icons.keyboard_arrow_down, size: 18, color: Colors.grey),
          ],
        ),
      ),
    );
  }

  Widget _buildSearchTypeChip(
    BuildContext context, {
    required String label,
    required bool isSelected,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        decoration: BoxDecoration(
          color: isSelected ? AppColors.primary : Colors.grey.shade200,
          borderRadius: BorderRadius.circular(20),
        ),
        child: Text(
          label,
          style: TextStyle(
            color: isSelected ? Colors.white : Colors.black87,
            fontWeight: FontWeight.bold,
          ),
        ),
      ),
    );
  }
}
