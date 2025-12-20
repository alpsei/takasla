// lib/features/profile/view/profile_view.dart

import 'dart:convert';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:gap/gap.dart';
import 'package:kitaptakas/features/book_detail/view/book_detail_view.dart';
import 'package:kitaptakas/features/profile/view/edit_profile_view.dart';
import '../../../../core/constants/app_colors.dart';
import '../../../../data/repositories/book_repository.dart';
import '../../home/view/widgets/book_card.dart';
import '../bloc/profile_bloc.dart';
import '../bloc/profile_event.dart';
import '../bloc/profile_state.dart';

class ProfilePage extends StatelessWidget {
  const ProfilePage({super.key});

  @override
  Widget build(BuildContext context) {
    final userId = FirebaseAuth.instance.currentUser?.uid ?? "";

    return BlocProvider(
      create: (context) =>
          ProfileBloc(bookRepository: BookRepository())
            ..add(ProfileLoadUserBooks(userId)),
      child: const ProfileView(),
    );
  }
}

class ProfileView extends StatelessWidget {
  const ProfileView({super.key});

  @override
  Widget build(BuildContext context) {
    final user = FirebaseAuth.instance.currentUser;

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: AppColors.background,
        title: const Text(
          "Profilim",
          style: TextStyle(fontWeight: FontWeight.bold),
        ),
        centerTitle: true,
        actions: [
          IconButton(
            onPressed: () async {
              final result = await Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => const EditProfileView(),
                ),
              );
              if (result == true && context.mounted) {
                context.read<ProfileBloc>().add(
                  ProfileLoadUserBooks(user?.uid ?? ""),
                );
              }
            },
            icon: const Icon(Icons.edit),
          ),
          const Gap(8),
        ],
      ),

      body: CustomScrollView(
        slivers: [
          // 1. BÖLÜM: PROFİL KARTI (StreamBuilder)
          // Burası sadece başlık ve bilgileri içerir. Listeyi içermez!
          SliverToBoxAdapter(
            child: StreamBuilder<DocumentSnapshot>(
              stream: FirebaseFirestore.instance
                  .collection('users')
                  .doc(user?.uid)
                  .snapshots(),
              builder: (context, snapshot) {
                // Varsayılan değerler
                String displayName = user?.email ?? "Misafir";
                String displayLocation = "Konum Belirtilmedi";
                int tradePoints = 0;
                String? photoUrl;

                // Veri geldiyse güncelle
                if (snapshot.hasData &&
                    snapshot.data != null &&
                    snapshot.data!.exists) {
                  final data = snapshot.data!.data() as Map<String, dynamic>;
                  if (data['name'] != null) displayName = data['name'];
                  if (data['location'] != null)
                    displayLocation = data['location'];
                  if (data['tradePoints'] != null)
                    tradePoints = data['tradePoints'];
                  photoUrl = data['photoUrl'];
                }

                return Column(
                  children: [
                    Container(
                      width: double.infinity,
                      padding: const EdgeInsets.all(24),
                      color: Colors.white,
                      child: Column(
                        children: [
                          // PROFİL FOTOĞRAFI
                          CircleAvatar(
                            radius: 40,
                            backgroundColor: AppColors.tagDonationBg,
                            backgroundImage:
                                (photoUrl != null && photoUrl.isNotEmpty)
                                ? (photoUrl.startsWith('http')
                                          ? NetworkImage(photoUrl)
                                          : MemoryImage(base64Decode(photoUrl)))
                                      as ImageProvider
                                : null,
                            child: (photoUrl == null || photoUrl.isEmpty)
                                ? const Icon(
                                    Icons.person,
                                    size: 40,
                                    color: AppColors.primary,
                                  )
                                : null,
                          ),
                          const Gap(16),

                          // İSİM
                          Text(
                            displayName,
                            style: const TextStyle(
                              fontSize: 20,
                              fontWeight: FontWeight.bold,
                              color: AppColors.textPrimary,
                            ),
                          ),
                          const Gap(4),

                          // KONUM
                          Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              const Icon(
                                Icons.location_on,
                                size: 14,
                                color: Colors.grey,
                              ),
                              const Gap(4),
                              Text(
                                displayLocation,
                                style: const TextStyle(color: Colors.grey),
                              ),
                            ],
                          ),
                          const Gap(24),

                          // PUAN KARTI
                          Container(
                            padding: const EdgeInsets.symmetric(
                              vertical: 12,
                              horizontal: 24,
                            ),
                            decoration: BoxDecoration(
                              color: AppColors.tagSwapBg,
                              borderRadius: BorderRadius.circular(12),
                              border: Border.all(
                                color: AppColors.tagSwapText.withOpacity(0.3),
                              ),
                            ),
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                const Icon(
                                  Icons.stars,
                                  color: AppColors.tagSwapText,
                                  size: 28,
                                ),
                                const Gap(12),
                                Column(
                                  children: [
                                    const Text(
                                      "Takas Puanın",
                                      style: TextStyle(
                                        fontSize: 12,
                                        color: Colors.black54,
                                      ),
                                    ),
                                    Text(
                                      "$tradePoints",
                                      style: const TextStyle(
                                        fontSize: 24,
                                        fontWeight: FontWeight.bold,
                                        color: AppColors.textPrimary,
                                      ),
                                    ),
                                  ],
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                    const Gap(16),

                    // BAŞLIK
                    const Padding(
                      padding: EdgeInsets.symmetric(horizontal: 16.0),
                      child: Align(
                        alignment: Alignment.centerLeft,
                        child: Text(
                          "Yüklediğim Kitaplar",
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    ),
                    const Gap(8),
                  ],
                );
              },
            ),
          ),

          // 2. BÖLÜM: KİTAP LİSTESİ (BlocBuilder -> SliverList)
          // Burası ARTIK SliverToBoxAdapter'ın DIŞINDA ve ÖZGÜR!
          BlocBuilder<ProfileBloc, ProfileState>(
            builder: (context, state) {
              if (state is ProfileLoading) {
                return const SliverToBoxAdapter(
                  child: Padding(
                    padding: EdgeInsets.all(20.0),
                    child: Center(child: CircularProgressIndicator()),
                  ),
                );
              }
              if (state is ProfileFailure) {
                return SliverToBoxAdapter(
                  child: Padding(
                    padding: EdgeInsets.all(20.0),
                    child: Center(child: Text("Hata: ${state.error}")),
                  ),
                );
              }
              if (state is ProfileSuccess) {
                if (state.userBooks.isEmpty) {
                  return const SliverToBoxAdapter(
                    child: Padding(
                      padding: EdgeInsets.all(20.0),
                      child: Center(child: Text("Henüz kitap yüklemedin.")),
                    ),
                  );
                }

                // 🔥 DOĞRU KULLANIM: SliverList 🔥
                return SliverList(
                  delegate: SliverChildBuilderDelegate((context, index) {
                    final book = state.userBooks[index];
                    return Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 16.0),
                      child: BookCard(
                        book: book,
                        // Kendi profilim olduğu için fotoyu tekrar yüklemeye gerek yok (veya null geçebiliriz)
                        onTap: () async {
                          final result = await Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (context) => BookDetailPage(book: book),
                            ),
                          );
                          if (result == true && context.mounted) {
                            context.read<ProfileBloc>().add(
                              ProfileLoadUserBooks(user?.uid ?? ""),
                            );
                          }
                        },
                      ),
                    );
                  }, childCount: state.userBooks.length),
                );
              }
              return const SliverToBoxAdapter(child: SizedBox());
            },
          ),

          // En alta boşluk
          const SliverPadding(padding: EdgeInsets.only(bottom: 24)),
        ],
      ),
    );
  }
}
