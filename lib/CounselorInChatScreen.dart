// ignore_for_file: unused_import

import 'dart:io';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:file_picker/file_picker.dart';
import 'package:firebase_auth/firebase_auth.dart';
// import 'package:firebase_storage/firebase_storage.dart';
import 'package:flutter/material.dart';

class CounselorInChatScreen extends StatefulWidget {
  final String studentName;
  final String chatId;
  final String appointmentId;

  const CounselorInChatScreen({
    super.key,
    required this.studentName,
    required this.chatId,
    required this.appointmentId,
    required String counselorId,
  });

  @override
  State<CounselorInChatScreen> createState() => _CounselorInChatScreenState();
}

class _CounselorInChatScreenState extends State<CounselorInChatScreen> {
  final TextEditingController _messageController = TextEditingController();
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;

  void _sendMessage({String? fileUrl}) async {
    final text = _messageController.text.trim();
    if (text.isEmpty && fileUrl == null) return;

    final currentUserId = _auth.currentUser?.uid;
    final timestamp = FieldValue.serverTimestamp();

    final messageData = {
      'message': fileUrl != null ? '📎 File sent' : text,
      'senderId': currentUserId,
      'timestamp': timestamp,
    };

    // Save message to appointment's messages subcollection
    await _firestore
        .collection('appointments')
        .doc(widget.appointmentId)
        .collection('messages')
        .add(messageData);

    _messageController.clear();
  }

  Future<void> _sendFile() async {
    final result = await FilePicker.platform.pickFiles(type: FileType.any);
    if (result == null || result.files.single.path == null) return;

    // final file = File(result.files.single.path!);
    // final fileName = result.files.single.name;

    try {
      // // Upload file to Firebase Storage
      // final storageRef = FirebaseStorage.instance.ref().child(
      //   'chat_files/${widget.appointmentId}/$fileName',
      // );

      // final uploadTask = await storageRef.putFile(file);
      // final fileUrl = await uploadTask.ref.getDownloadURL();

      // Send the message with file URL
      // _sendMessage(fileUrl: fileUrl);
    } catch (e) {
      debugPrint('File upload failed: $e');
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('Failed to upload file')));
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text("Chat with ${widget.studentName}"),
        backgroundColor: Colors.blue.shade50,
        elevation: 3,
      ),
      body: SafeArea(
        child: Column(
          children: [
            Expanded(
              child: StreamBuilder<QuerySnapshot>(
                stream:
                    _firestore
                        .collection('appointments')
                        .doc(widget.appointmentId)
                        .collection('messages')
                        .orderBy('timestamp')
                        .snapshots(),
                builder: (context, snapshot) {
                  if (!snapshot.hasData) {
                    return const Center(child: CircularProgressIndicator());
                  }

                  final messages = snapshot.data!.docs;
                  return ListView.builder(
                    itemCount: messages.length,
                    itemBuilder: (_, index) {
                      final data =
                          messages[index].data() as Map<String, dynamic>;
                      final isCounselor =
                          data['senderId'] == _auth.currentUser?.uid;
                      return Align(
                        alignment:
                            isCounselor
                                ? Alignment.centerRight
                                : Alignment.centerLeft,
                        child: Container(
                          margin: const EdgeInsets.all(8),
                          padding: const EdgeInsets.all(12),
                          decoration: BoxDecoration(
                            color:
                                isCounselor
                                    ? Colors.teal[100]
                                    : Colors.grey[300],
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child:
                              data['fileUrl'] != null
                                  ? InkWell(
                                    onTap:
                                        () => print(
                                          "Open file: ${data['fileUrl']}",
                                        ),
                                    child: Text(
                                      '📎 File: ${data['fileUrl'].toString().split('/').last}',
                                      style: const TextStyle(
                                        fontWeight: FontWeight.bold,
                                      ),
                                    ),
                                  )
                                  : Text(data['message'] ?? ''),
                        ),
                      );
                    },
                  );
                },
              ),
            ),
            Row(
              children: [
                IconButton(
                  icon: const Icon(Icons.attach_file),
                  onPressed: _sendFile,
                ),
                Expanded(
                  child: TextField(
                    controller: _messageController,
                    decoration: const InputDecoration(
                      hintText: "Type your message...",
                    ),
                  ),
                ),
                IconButton(
                  icon: const Icon(Icons.send),
                  onPressed: () => _sendMessage(),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
