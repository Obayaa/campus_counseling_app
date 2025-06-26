import 'dart:convert';

import 'package:campus_counseling_app/Unnecessary/student_in_chat_screen.dart';
import 'package:campus_counseling_app/student_counselor_screen.dart';
import 'package:campus_counseling_app/student_feedback_screen.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'book_screen.dart';
import 'student_chat_screen.dart';

class StudentDashboardScreen extends StatefulWidget {
  const StudentDashboardScreen({super.key});

  @override
  State<StudentDashboardScreen> createState() => _StudentDashboardScreenState();
}

class _StudentDashboardScreenState extends State<StudentDashboardScreen> {
  final user = FirebaseAuth.instance.currentUser;
  DateTime selectedDate = DateTime.now();
  int _selectedIndex = 0;

  void _onItemTapped(int index) {
    setState(() {
      _selectedIndex = index;
    });
  }

  Stream<QuerySnapshot> _getAppointmentsStream() async* {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    String? savedUid = prefs.getString('anonymous_uid');
    String currentUid = FirebaseAuth.instance.currentUser?.uid ?? '';

    String queryUid = savedUid ?? currentUid;

    // Modified to show ALL appointments, not just future ones
    yield* FirebaseFirestore.instance
        .collection("appointments")
        .where("studentId", isEqualTo: queryUid)
        .orderBy("startTime")
        .snapshots();
  }

  Future<String> _getCurrentStudentId() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    String? savedUid = prefs.getString('anonymous_uid');
    return savedUid ?? FirebaseAuth.instance.currentUser!.uid;
  }

  Future<void> _handleLogout() async {
    final user = FirebaseAuth.instance.currentUser;

    if (user?.isAnonymous == true) {
      // Don't clear SharedPreferences for anonymous users
      // Just sign out but keep the UID saved
      await FirebaseAuth.instance.signOut();
    } else {
      // For regular users, clear everything
      SharedPreferences prefs = await SharedPreferences.getInstance();
      await prefs.remove('anonymous_uid');
      await FirebaseAuth.instance.signOut();
    }
  }

  Widget _buildHomeTab() {
    return SingleChildScrollView(
      padding: const EdgeInsets.symmetric(horizontal: 20.0, vertical: 12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header greeting
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Expanded(
                child: Text(
                  "Hello there!",
                  overflow: TextOverflow.ellipsis,
                  maxLines: 2,
                  softWrap: true,
                  style: const TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                    color: Colors.black87,
                  ),
                ),
              ),
              const SizedBox(width: 12),
              GestureDetector(
                onTap: () {
                  showModalBottomSheet(
                    context: context,
                    builder:
                        (context) => SafeArea(
                          child: Column(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              ListTile(
                                leading: const Icon(
                                  Icons.logout,
                                  color: Colors.red,
                                ),
                                title: const Text('Logout'),
                                onTap: () async {
                                  if (context.mounted) {
                                    Navigator.pushNamedAndRemoveUntil(
                                      context,
                                      '/role-selection',
                                      (route) => false,
                                    );
                                  }
                                  await _handleLogout();
                                },
                              ),
                            ],
                          ),
                        ),
                  );
                },
                child: const CircleAvatar(
                  radius: 25,
                  backgroundColor: Colors.blueAccent,
                  child: Icon(Icons.person, color: Colors.white, size: 28),
                ),
              ),
            ],
          ),

          const SizedBox(height: 20),

          // University Banner
          ClipRRect(
            borderRadius: BorderRadius.circular(12),
            child: Stack(
              children: [
                Image.asset("assets/images/university_banner.png"),
                Positioned(
                  left: 10,
                  top: 10,
                  child: Image.asset("assets/images/logo.png", width: 50),
                ),
              ],
            ),
          ),

          const SizedBox(height: 20),

          const Text(
            "All Appointments",
            style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
          ),
          const SizedBox(height: 12),

          StreamBuilder<QuerySnapshot>(
            stream: _getAppointmentsStream(),
            builder: (context, snapshot) {
              // Add debugging

              if (snapshot.hasError) {
                return Text("Error: ${snapshot.error}");
              }

              if (snapshot.connectionState == ConnectionState.waiting) {
                return const Center(child: CircularProgressIndicator());
              }

              if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
                return const Text("No appointments found.");
              }
              return ListView.builder(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                itemCount: snapshot.data!.docs.length,
                itemBuilder: (context, index) {
                  final doc = snapshot.data!.docs[index];
                  final counselor = doc['counselorName'] ?? 'Unknown Counselor';
                  final counselorId = doc['counselorId'] ?? '';

                  final date = (doc['startTime'] as Timestamp).toDate();
                  final status = doc['status'] ?? 'pending'; // Get status field
                  final timeRange =
                      "${DateFormat('hh:mm a').format(date)} - ${DateFormat('hh:mm a').format(date.add(const Duration(hours: 1)))}";

                  // Check if appointment is approved and in the future for chat access
                  final isApproved = status.toLowerCase() == 'approved';
                  final isFuture = date.isAfter(DateTime.now());
                  final canChat = isApproved && isFuture;

                  // Get status color
                  Color getStatusColor(String status) {
                    switch (status.toLowerCase()) {
                      case 'approved':
                        return Colors.green;
                      case 'rejected':
                        return Colors.red;
                      case 'pending':
                      default:
                        return Colors.orange;
                    }
                  }

                  return Container(
                    margin: const EdgeInsets.only(bottom: 12),
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: const Color(0xFF2C509D),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Row(
                      children: [
                        FutureBuilder<DocumentSnapshot>(
                          future:
                              FirebaseFirestore.instance
                                  .collection('counselors')
                                  .doc(counselorId)
                                  .get(),
                          builder: (context, snapshot) {
                            if (!snapshot.hasData) {
                              return const CircleAvatar(
                                radius: 30,
                                backgroundColor: Colors.grey,
                                child: Icon(Icons.person, color: Colors.white),
                              );
                            }

                            final counselorData =
                                snapshot.data!.data() as Map<String, dynamic>?;

                            final imageBase64 =
                                counselorData?['profileImageBase64'] ?? '';
                            ImageProvider? imageProvider;

                            if (imageBase64.isNotEmpty) {
                              try {
                                imageProvider = MemoryImage(
                                  base64Decode(imageBase64),
                                );
                              } catch (_) {
                                imageProvider = null;
                              }
                            }

                            if (imageProvider != null) {
                              return CircleAvatar(
                                radius: 30,
                                backgroundImage: imageProvider,
                              );
                            } else {
                              // Use initials or icon if no image
                              String initials = '';
                              if (counselor.isNotEmpty) {
                                var names = counselor.split(' ');
                                if (names.length > 1) {
                                  initials = names[0][0] + names[1][0];
                                } else {
                                  initials = names[0][0];
                                }
                              }

                              return CircleAvatar(
                                radius: 30,
                                backgroundColor: Colors.blueAccent,
                                child: Text(
                                  initials.toUpperCase(),
                                  style: const TextStyle(color: Colors.white),
                                ),
                              );
                            }
                          },
                        ),

                        const SizedBox(width: 12),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                mainAxisAlignment:
                                    MainAxisAlignment.spaceBetween,
                                children: [
                                  Expanded(
                                    child: Text(
                                      counselor,
                                      style: const TextStyle(
                                        color: Colors.white,
                                        fontWeight: FontWeight.bold,
                                        fontSize: 16,
                                      ),
                                    ),
                                  ),
                                  // Status badge
                                  Container(
                                    padding: const EdgeInsets.symmetric(
                                      horizontal: 8,
                                      vertical: 4,
                                    ),
                                    decoration: BoxDecoration(
                                      color: getStatusColor(status),
                                      borderRadius: BorderRadius.circular(12),
                                    ),
                                    child: Text(
                                      status.toUpperCase(),
                                      style: const TextStyle(
                                        color: Colors.white,
                                        fontSize: 12,
                                        fontWeight: FontWeight.bold,
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                              const Text(
                                "Counselor",
                                style: TextStyle(color: Colors.white70),
                              ),
                              const SizedBox(height: 8),
                              Row(
                                children: [
                                  const Icon(
                                    Icons.calendar_today,
                                    color: Colors.white,
                                    size: 16,
                                  ),
                                  const SizedBox(width: 5),
                                  Flexible(
                                    child: Text(
                                      DateFormat('EEEE, d MMM').format(date),
                                      style: const TextStyle(
                                        color: Colors.white,
                                      ),
                                      overflow: TextOverflow.ellipsis,
                                      softWrap: false,
                                    ),
                                  ),
                                  const SizedBox(width: 10),
                                  const Icon(
                                    Icons.access_time,
                                    color: Colors.white,
                                    size: 16,
                                  ),
                                  const SizedBox(width: 5),
                                  Text(
                                    timeRange,
                                    style: const TextStyle(color: Colors.white),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 8),
                              ElevatedButton.icon(
                                icon: Icon(
                                  canChat ? Icons.chat : Icons.chat_outlined,
                                ),
                                label: Text(
                                  canChat ? "Go to Chat" : "Chat Unavailable",
                                ),
                                style: ElevatedButton.styleFrom(
                                  backgroundColor:
                                      canChat
                                          ? Colors.white
                                          : Colors.grey.shade400,
                                  foregroundColor:
                                      canChat
                                          ? const Color(0xFF2C509D)
                                          : Colors.grey.shade600,
                                ),
                                onPressed:
                                    canChat
                                        ? () async {
                                          final appointmentId = doc.id;
                                          final studentId =
                                              await _getCurrentStudentId();
                                          Navigator.push(
                                            context,
                                            MaterialPageRoute(
                                              builder:
                                                  (_) => StudentInChatScreen(
                                                    appointmentId:
                                                        appointmentId,
                                                    studentId: studentId,
                                                  ),
                                            ),
                                          );
                                        }
                                        : () {
                                          // Show message explaining why chat is disabled
                                          String message;
                                          if (!isApproved) {
                                            message =
                                                "Chat will be available once your appointment is approved.";
                                          } else if (!isFuture) {
                                            message =
                                                "Chat is only available for upcoming appointments.";
                                          } else {
                                            message =
                                                "Chat is currently unavailable.";
                                          }

                                          ScaffoldMessenger.of(
                                            context,
                                          ).showSnackBar(
                                            SnackBar(
                                              content: Text(message),
                                              backgroundColor: Colors.orange,
                                            ),
                                          );
                                        },
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  );
                },
              );
            },
          ),
          const SizedBox(height: 24),

          // Horizontal date selector
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: List.generate(7, (index) {
              DateTime date = DateTime.now().add(Duration(days: index));
              return GestureDetector(
                onTap: () => setState(() => selectedDate = date),
                child: Container(
                  width: 48,
                  padding: const EdgeInsets.symmetric(vertical: 8),
                  decoration: BoxDecoration(
                    color:
                        selectedDate.day == date.day
                            ? Colors.blueAccent
                            : Colors.white,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: Colors.grey.shade300),
                  ),
                  child: Column(
                    children: [
                      Text(
                        DateFormat('d').format(date),
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          color:
                              selectedDate.day == date.day
                                  ? Colors.white
                                  : Colors.black,
                        ),
                      ),
                      Text(
                        DateFormat('E').format(date),
                        style: TextStyle(
                          fontSize: 12,
                          color:
                              selectedDate.day == date.day
                                  ? Colors.white70
                                  : Colors.grey,
                        ),
                      ),
                    ],
                  ),
                ),
              );
            }),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final List<Widget> tabs = [
      _buildHomeTab(),
      const CounselorDirectoryScreen(),
      const BookScreen(),
      const StudentChatScreen(),
      const StudentFeedbackScreen(),
    ];

    return Scaffold(
      backgroundColor: Colors.white,

      body: SafeArea(child: tabs[_selectedIndex]),
      bottomNavigationBar: BottomNavigationBar(
        elevation: 3,
        currentIndex: _selectedIndex,
        selectedItemColor: Colors.blue,
        unselectedItemColor: Colors.grey,
        onTap: _onItemTapped,
        items: const [
          BottomNavigationBarItem(icon: Icon(Icons.home), label: 'Home'),
          BottomNavigationBarItem(
            icon: Icon(Icons.supervised_user_circle_rounded),
            label: 'Counselors',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.calendar_today),
            label: 'Book',
          ),
          BottomNavigationBarItem(icon: Icon(Icons.chat), label: 'Chat'),
          BottomNavigationBarItem(
            icon: Icon(Icons.feedback),
            label: 'Feedback',
          ),
        ],
      ),
    );
  }
}
