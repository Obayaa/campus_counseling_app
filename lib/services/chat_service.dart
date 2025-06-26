import 'package:cloud_firestore/cloud_firestore.dart';

class ChatService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  Stream<QuerySnapshot> getMessages(String appointmentId) {
    return _firestore
        .collection('appointments')
        .doc(appointmentId)
        .collection('messages')
        .orderBy('timestamp', descending: false)
        .snapshots();
  }

  Future<void> sendMessage({
    required String appointmentId,
    required String senderId,
    required String message,
    required bool isCounselor,
  }) async {
    await _firestore
        .collection('appointments')
        .doc(appointmentId)
        .collection('messages')
        .add({
          'senderId': senderId,
          'message': message,
          'timestamp': FieldValue.serverTimestamp(),
          'isCounselor': isCounselor,
        });
  }
}
