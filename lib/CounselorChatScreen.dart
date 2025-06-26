import 'package:campus_counseling_app/CounselorInChatScreen.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';

class CounselorChatScreen extends StatelessWidget {
  final String counselorId;
  const CounselorChatScreen({super.key, required this.counselorId});

  String _generateStudentDisplayName(String studentId, int index) {
    return "Anonymous ${index + 1}";
  }

  Future<List<Map<String, dynamic>>> _fetchChats() async {
    final appointmentQuery =
        await FirebaseFirestore.instance
            .collection('appointments')
            .where('counselorId', isEqualTo: counselorId)
            .where('status', isEqualTo: 'approved')
            .get();

    final List<Map<String, dynamic>> chats = [];

    for (int i = 0; i < appointmentQuery.docs.length; i++) {
      final doc = appointmentQuery.docs[i];
      final appointmentId = doc.id;
      final data = doc.data();

      // Fetch last message
      final messageQuery =
          await FirebaseFirestore.instance
              .collection('appointments')
              .doc(appointmentId)
              .collection('messages')
              .orderBy('timestamp', descending: true)
              .limit(1)
              .get();

      if (messageQuery.docs.isEmpty) continue; // Skip if no messages

      final lastMessage = messageQuery.docs.first.data();

      final studentName =
          data['studentName'] != null && data['studentName'] != 'Anonymous'
              ? data['studentName']
              : _generateStudentDisplayName(data['studentId'], i);

      chats.add({
        'appointmentId': appointmentId,
        'studentId': data['studentId'],
        'studentName': studentName,
        'lastMessage': lastMessage['message'] ?? '',
      });
    }

    return chats;
  }

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<List<Map<String, dynamic>>>(
      future: _fetchChats(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }

        final chats = snapshot.data ?? [];

        if (chats.isEmpty) {
          return const Center(
            child: Text('No chats yet', style: TextStyle(fontSize: 16)),
          );
        }

        return ListView.separated(
          padding: const EdgeInsets.all(12),
          itemCount: chats.length,
          separatorBuilder: (_, __) => const Divider(),
          itemBuilder: (context, index) {
            final chat = chats[index];

            return GestureDetector(
              onTap: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder:
                        (_) => CounselorInChatScreen(
                          studentName: chat['studentName'],
                          chatId: chat['appointmentId'],
                          appointmentId: chat['appointmentId'],
                          counselorId: counselorId,
                        ),
                  ),
                );
              },
              child: Card(
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                  side: BorderSide(
                    color: Colors.blue.shade100,
                    width: 1,
                  ),
                ),
                margin: const EdgeInsets.symmetric(vertical: 6),
                child: Padding(
                  padding: const EdgeInsets.symmetric(
                    vertical: 12,
                    horizontal: 16,
                  ),
                  child: Row(
                    children: [
                      CircleAvatar(
                        radius: 24,
                        backgroundColor: Colors.blue.shade100,
                        child: Text(
                          chat['studentName'].isNotEmpty
                              ? chat['studentName'][0].toUpperCase()
                              : '?',
                          style: const TextStyle(
                            fontSize: 20,
                            fontWeight: FontWeight.bold,
                            color: Colors.blue,
                          ),
                        ),
                      ),
                      const SizedBox(width: 16),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              chat['studentName'],
                              style: const TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              chat['lastMessage'],
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: TextStyle(
                                fontSize: 14,
                                color: Colors.grey.shade700,
                              ),
                            ),
                          ],
                        ),
                      ),
                      const Icon(
                        Icons.arrow_forward_ios_rounded,
                        size: 16,
                        color: Colors.grey,
                      ),
                    ],
                  ),
                ),
              ),
            );
          },
        );
      },
    );
  }
}
