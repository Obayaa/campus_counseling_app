import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'Unnecessary/student_in_chat_screen.dart';

class StudentChatScreen extends StatefulWidget {
  const StudentChatScreen({super.key});

  @override
  State<StudentChatScreen> createState() => _StudentChatScreenState();
}

class _StudentChatScreenState extends State<StudentChatScreen> {
  final _auth = FirebaseAuth.instance;
  String? _studentId;
  bool _isLoadingStudentId = true; // Specific flag for student ID loading

  @override
  void initState() {
    super.initState();
    _initializeStudentId();
  }

  Future<void> _initializeStudentId() async {
    try {
      SharedPreferences prefs = await SharedPreferences.getInstance();
      String? savedUid = prefs.getString('anonymous_uid');
      String? currentUserUid = _auth.currentUser?.uid;

      setState(() {
        _studentId = savedUid ?? currentUserUid;
        _isLoadingStudentId = false; // Student ID is now determined
      });
    } catch (e) {
      // Handle potential errors during shared_preferences or FirebaseAuth access
      print('Error initializing student ID: $e');
      setState(() {
        _studentId = null; // Ensure null if there's an error
        _isLoadingStudentId = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    // --- Initial Loading State for _studentId ---
    if (_isLoadingStudentId) {
      return const Scaffold(
        backgroundColor: Colors.white,
        body: Center(
          child: CircularProgressIndicator(
            valueColor: AlwaysStoppedAnimation<Color>(Colors.blue),
          ),
        ),
      );
    }

    // --- Not Logged In State (if _studentId remains null) ---
    if (_studentId == null) {
      return Scaffold(
        backgroundColor: Colors.white,
        body: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                Icons.person_off_outlined,
                size: 64,
                color: Colors.grey[400],
              ),
              const SizedBox(height: 16),
              Text(
                "No user session found", // More precise message
                style: TextStyle(
                  fontSize: 18,
                  color: Colors.grey[600],
                  fontWeight: FontWeight.w500,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                "Please ensure you are logged in or an anonymous session exists.",
                style: TextStyle(fontSize: 14, color: Colors.grey[500]),
                textAlign: TextAlign.center,
              ),
            ],
          ),
        ),
      );
    }

    // --- Main UI with StreamBuilder once _studentId is available ---
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        automaticallyImplyLeading: false,
        title: const Text(
          "Your Chats",
          style: TextStyle(fontWeight: FontWeight.w600, color: Colors.black87),
        ),
        backgroundColor: Colors.white,
        elevation: 0,
        surfaceTintColor: Colors.white,
        iconTheme: const IconThemeData(color: Colors.black87),
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(1),
          child: Container(height: 1, color: Colors.grey[200]),
        ),
      ),
      body: StreamBuilder<QuerySnapshot>(
        stream:
            FirebaseFirestore.instance
                .collection('appointments')
                .where('studentId', isEqualTo: _studentId)
                .where('status', isEqualTo: 'approved')
                .snapshots(),
        builder: (context, snapshot) {
          // --- StreamBuilder Loading State (for messages) ---
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(
              child: CircularProgressIndicator(
                valueColor: AlwaysStoppedAnimation<Color>(Colors.blue),
              ),
            );
          }

          // --- StreamBuilder Error State ---
          if (snapshot.hasError) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.error_outline, size: 64, color: Colors.red[300]),
                  const SizedBox(height: 16),
                  Text(
                    "Something went wrong fetching chats",
                    style: TextStyle(
                      fontSize: 18,
                      color: Colors.grey[600],
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    "${snapshot.error}",
                    style: TextStyle(fontSize: 12, color: Colors.red[400]),
                    textAlign: TextAlign.center,
                  ),
                ],
              ),
            );
          }

          final appointments = snapshot.data!.docs;

          if (appointments.isEmpty) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    Icons.chat_bubble_outline,
                    size: 80,
                    color: Colors.grey[300],
                  ),
                  const SizedBox(height: 24),
                  Text(
                    "No approved appointments",
                    style: TextStyle(
                      fontSize: 20,
                      color: Colors.grey[600],
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    "Your chats will appear here once you have approved appointments",
                    style: TextStyle(fontSize: 14, color: Colors.grey[500]),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 16),
                  Text(
                    "Debug: StudentId = $_studentId",
                    style: TextStyle(fontSize: 10, color: Colors.grey[400]),
                  ),
                ],
              ),
            );
          }

          // Group appointments by counselor to avoid duplicates
          Map<String, Map<String, dynamic>> counselorChats = {};

          for (var appointment in appointments) {
            final data = appointment.data() as Map<String, dynamic>;
            final counselorName = data['counselorName'] ?? 'Unknown Counselor';
            final counselorId = data['counselorId'];

            // Ensure counselorId exists before processing
            if (counselorId == null) {
              debugPrint('Appointment ${appointment.id} missing counselorId.');
              continue; // Skip this appointment
            }

            // Use the most recent approved appointment for each counselor
            if (!counselorChats.containsKey(counselorId) ||
                (data['startTime'] as Timestamp).compareTo(
                      counselorChats[counselorId]!['startTime'] as Timestamp,
                    ) >
                    0) {
              // Ensure comparison is between Timestamps
              counselorChats[counselorId] = {
                'appointmentId': appointment.id,
                'counselorName': counselorName,
                'counselorId': counselorId,
                'startTime': data['startTime'],
              };
            }
          }

          if (counselorChats.isEmpty) {
            // This might happen if all appointments had a null counselorId
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    Icons.chat_bubble_outline,
                    size: 80,
                    color: Colors.grey[300],
                  ),
                  const SizedBox(height: 24),
                  Text(
                    "No valid chats found",
                    style: TextStyle(
                      fontSize: 20,
                      color: Colors.grey[600],
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    "Appointments must have an assigned counselor to start a chat.",
                    style: TextStyle(fontSize: 14, color: Colors.grey[500]),
                    textAlign: TextAlign.center,
                  ),
                ],
              ),
            );
          }

          return ListView.separated(
            padding: const EdgeInsets.all(16),
            itemCount: counselorChats.length,
            separatorBuilder: (context, index) => const SizedBox(height: 8),
            itemBuilder: (context, index) {
              final counselorData = counselorChats.values.elementAt(index);
              final appointmentId = counselorData['appointmentId'];
              final counselorName = counselorData['counselorName'];

              return FutureBuilder<QuerySnapshot>(
                future:
                    FirebaseFirestore.instance
                        .collection('appointments')
                        .doc(appointmentId)
                        .collection('messages')
                        .orderBy('timestamp', descending: true)
                        .limit(1)
                        .get(),
                builder: (context, messageSnapshot) {
                  // --- FutureBuilder (for last message) Loading State ---
                  if (messageSnapshot.connectionState ==
                      ConnectionState.waiting) {
                    return _buildChatTileSkeleton(); // Show a loading skeleton for individual chat tiles
                  }

                  String lastMessage = "No messages yet - Start a conversation";
                  dynamic timestamp;
                  bool hasMessages = false;

                  if (messageSnapshot.hasData &&
                      messageSnapshot.data!.docs.isNotEmpty) {
                    final lastMessageData =
                        messageSnapshot.data!.docs.first.data()
                            as Map<String, dynamic>;
                    lastMessage = lastMessageData['message'] ?? 'No message';
                    timestamp = lastMessageData['timestamp'];
                    hasMessages = true;
                  }

                  return _buildChatTile(
                    counselorName: counselorName,
                    lastMessage: lastMessage,
                    timestamp: timestamp,
                    hasMessages: hasMessages,
                    onTap: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder:
                              (_) => StudentInChatScreen(
                                appointmentId: appointmentId,
                                studentId: _studentId!,
                              ),
                        ),
                      );
                    },
                  );
                },
              );
            },
          );
        },
      ),
    );
  }

  // A skeleton widget for individual chat tiles while their last message loads
  Widget _buildChatTileSkeleton() {
    return Container(
      decoration: BoxDecoration(
        color: Colors.grey[50],
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.02),
            blurRadius: 4,
            offset: const Offset(0, 1),
          ),
        ],
      ),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Row(
          children: [
            Container(
              width: 48,
              height: 48,
              decoration: BoxDecoration(
                color: Colors.grey[200],
                shape: BoxShape.circle,
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Container(
                    width: double.infinity,
                    height: 16,
                    color: Colors.grey[200],
                  ),
                  const SizedBox(height: 8),
                  Container(
                    width: double.infinity,
                    height: 14,
                    color: Colors.grey[100],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildChatTile({
    required String counselorName,
    required String lastMessage,
    required dynamic timestamp,
    required bool hasMessages,
    required VoidCallback onTap,
  }) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.04),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
        border: Border.all(
          color: hasMessages ? Colors.blue[200]! : Colors.grey[200]!,
          width: hasMessages ? 1.5 : 1,
        ),
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(12),
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Row(
              children: [
                Container(
                  width: 48,
                  height: 48,
                  decoration: BoxDecoration(
                    color: hasMessages ? Colors.blue[50] : Colors.grey[50],
                    shape: BoxShape.circle,
                  ),
                  child: Icon(
                    hasMessages ? Icons.chat : Icons.chat_bubble_outline,
                    color: hasMessages ? Colors.blue[600] : Colors.grey[500],
                    size: 24,
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Expanded(
                            child: Text(
                              counselorName,
                              style: const TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.w600,
                                color: Colors.black87,
                              ),
                            ),
                          ),
                          if (!hasMessages)
                            Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 8,
                                vertical: 2,
                              ),
                              decoration: BoxDecoration(
                                color: Colors.green[100],
                                borderRadius: BorderRadius.circular(12),
                              ),
                              child: Text(
                                "NEW",
                                style: TextStyle(
                                  fontSize: 10,
                                  fontWeight: FontWeight.bold,
                                  color: Colors.green[700],
                                ),
                              ),
                            ),
                        ],
                      ),
                      const SizedBox(height: 4),
                      Text(
                        lastMessage,
                        style: TextStyle(
                          fontSize: 14,
                          color:
                              hasMessages ? Colors.grey[600] : Colors.grey[500],
                          fontStyle:
                              hasMessages ? FontStyle.normal : FontStyle.italic,
                        ),
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 12),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    if (hasMessages)
                      Text(
                        _formatTimestamp(timestamp),
                        style: TextStyle(
                          fontSize: 12,
                          color: Colors.grey[500],
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    const SizedBox(height: 4),
                    Icon(
                      Icons.chevron_right,
                      color: Colors.grey[400],
                      size: 20,
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  String _formatTimestamp(dynamic timestamp) {
    if (timestamp == null) return '';
    final dt = (timestamp as Timestamp).toDate();
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final messageDate = DateTime(dt.year, dt.month, dt.day);

    if (messageDate == today) {
      return "${dt.hour}:${dt.minute.toString().padLeft(2, '0')}";
    } else if (messageDate == today.subtract(const Duration(days: 1))) {
      return "Yesterday";
    } else if (now.difference(dt).inDays < 7) {
      const days = ['Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat', 'Sun'];
      return days[dt.weekday - 1];
    } else {
      return "${dt.day}/${dt.month}";
    }
  }
}
