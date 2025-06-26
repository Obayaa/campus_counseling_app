import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import '../services/chat_service.dart';

class StudentInChatScreen extends StatefulWidget {
  final String appointmentId;
  final String studentId;

  const StudentInChatScreen({
    required this.appointmentId,
    required this.studentId,
    super.key,
  });

  @override
  State<StudentInChatScreen> createState() => _StudentInChatScreenState();
}

class _StudentInChatScreenState extends State<StudentInChatScreen> {
  final TextEditingController _messageController = TextEditingController();
  final ChatService _chatService = ChatService();

  void _sendMessage() {
    final text = _messageController.text.trim();
    if (text.isNotEmpty) {
      _chatService.sendMessage(
        appointmentId: widget.appointmentId,
        senderId: widget.studentId,
        message: text,
        isCounselor: false,
      );
      _messageController.clear();
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Student Chat')),
      body: SafeArea(
        child: Column(
          children: [
            Expanded(
              child: StreamBuilder<QuerySnapshot>(
                stream: _chatService.getMessages(widget.appointmentId),
                builder: (context, snapshot) {
                  if (snapshot.connectionState == ConnectionState.waiting) {
                    return const Center(child: CircularProgressIndicator());
                  }
                  final messages = snapshot.data?.docs ?? [];
                  return ListView.builder(
                    padding: const EdgeInsets.all(10),
                    itemCount: messages.length,
                    itemBuilder: (context, index) {
                      final data =
                          messages[index].data() as Map<String, dynamic>;
                      final isMe = data['senderId'] == widget.studentId;
                      return Align(
                        alignment:
                            isMe ? Alignment.centerRight : Alignment.centerLeft,
                        child: Container(
                          padding: const EdgeInsets.all(10),
                          margin: const EdgeInsets.symmetric(vertical: 4),
                          decoration: BoxDecoration(
                            color: isMe ? Colors.teal[200] : Colors.grey[300],
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Text(data['message'] ?? ''),
                        ),
                      );
                    },
                  );
                },
              ),
            ),
            const Divider(height: 1),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
              child: Row(
                children: [
                  Expanded(
                    child: TextField(
                      controller: _messageController,
                      decoration: const InputDecoration(
                        hintText: 'Type a message',
                      ),
                    ),
                  ),
                  IconButton(
                    icon: const Icon(Icons.send),
                    onPressed: _sendMessage,
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
