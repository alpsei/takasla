import 'package:cloud_firestore/cloud_firestore.dart';

class AdminRepository {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  Future<int> getUserCount() async {
    final aggregateQuery = await _firestore.collection('users').count().get();
    return aggregateQuery.count ?? 0;
  }

  Future<int> getBookCount() async {
    final aggregateQuery = await _firestore.collection('books').count().get();
    return aggregateQuery.count ?? 0;
  }

  Future<int> getReportCount() async {
    final aggregateQuery = await _firestore.collection('reports').count().get();
    return aggregateQuery.count ?? 0;
  }

  Future<Map<String, int>> getDashboardStats() async {
    final results = await Future.wait([
      getUserCount(),
      getBookCount(),
      getReportCount(),
    ]);

    return {
      'userCount': results[0],
      'bookCount': results[1],
      'reportCount': results[2],
    };
  }

  Future<QuerySnapshot> getAllUsers() async {
    return await _firestore.collection('users').get();
  }

  Future<void> deleteUser(String userId) async {
    return await _firestore.collection('users').doc(userId).delete();
  }

  Future<QuerySnapshot> getAllBooks() async {
    return await _firestore
        .collection('books')
        .orderBy('createdAt', descending: true)
        .get();
  }

  Future<void> deleteBook(String bookId) async {
    return await _firestore.collection('books').doc(bookId).delete();
  }

  Future<QuerySnapshot> getPendingReports() async {
    return await _firestore
        .collection('reports')
        .where('status', isEqualTo: 'pending')
        .orderBy('createdAt', descending: true)
        .get();
  }

  Future<void> resolveReport(String reportId, String newStatus) async {
    await _firestore.collection('reports').doc(reportId).update({
      'status': newStatus,
      'resolvedAt': FieldValue.serverTimestamp(),
    });
  }
}
