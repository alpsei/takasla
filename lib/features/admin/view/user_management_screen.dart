import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:kitaptakas/data/repositories/admin_repositories.dart';

class UserManagementScreen extends StatefulWidget {
  const UserManagementScreen({super.key});

  @override
  State<UserManagementScreen> createState() => _UserManagementScreenState();
}

class _UserManagementScreenState extends State<UserManagementScreen> {
  final AdminRepository _adminRepository = AdminRepository();
  void _confirmDelete(String userId, String email) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text("Kullanıcıyı Sil"),
        content: Text(
          "$email hesabını silmek istediğine emin misin? Bu işlem geri alınamaz.",
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text("İptal"),
          ),
          TextButton(
            onPressed: () async {
              Navigator.pop(context);
              await _adminRepository.deleteUser(userId);
              setState(() {});
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text("Kullanıcı silindi.")),
              );
            },
            child: const Text("Sil", style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("Kullanıcı Yönetimi")),
      body: FutureBuilder<QuerySnapshot>(
        future: _adminRepository.getAllUsers(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }
          if (snapshot.hasError) {
            return Center(child: Text("Hata: ${snapshot.error}"));
          }
          if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
            return const Center(child: Text("Hiç kullanıcı yok."));
          }

          final users = snapshot.data!.docs;

          return ListView.separated(
            itemCount: users.length,
            separatorBuilder: (context, index) => const Divider(),
            itemBuilder: (context, index) {
              var user = users[index];
              var userData = user.data() as Map<String, dynamic>;

              // Veritabanında 'email' ve 'role' alanları olduğunu varsayıyoruz
              String email = userData['email'] ?? 'Email Yok';
              String role = userData['role'] ?? 'user';
              String uid = user.id;

              return ListTile(
                leading: CircleAvatar(
                  backgroundColor: role == 'admin' ? Colors.red : Colors.blue,
                  child: Icon(
                    role == 'admin' ? Icons.admin_panel_settings : Icons.person,
                    color: Colors.white,
                  ),
                ),
                title: Text(
                  email,
                  style: const TextStyle(fontWeight: FontWeight.bold),
                ),
                subtitle: Text("UID: $uid\nRol: $role"),
                isThreeLine: true,
                trailing: IconButton(
                  icon: const Icon(Icons.delete, color: Colors.grey),
                  onPressed: () => _confirmDelete(uid, email),
                ),
              );
            },
          );
        },
      ),
    );
  }
}
