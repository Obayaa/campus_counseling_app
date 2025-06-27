// ignore_for_file: unused_local_variable

import 'dart:convert';

import 'package:campus_counseling_app/counselor_profile_screen.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:campus_counseling_app/CounselorChatScreen.dart';
import 'package:campus_counseling_app/counselor_bookings_screen.dart';
import 'package:campus_counseling_app/counselor_dashboard_content_screen.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';

class CounselorDashboardScreen extends StatefulWidget {
  const CounselorDashboardScreen({super.key});

  @override
  State<CounselorDashboardScreen> createState() =>
      _CounselorDashboardScreenState();
}

class _CounselorDashboardScreenState extends State<CounselorDashboardScreen> {
  int _currentIndex = 0;

  List<Widget> _getScreens(String counselorId) {
    return [
      CounselorDashboardContentScreen(),
      CounselorBookingsScreen(counselorId: counselorId),
      CounselorChatScreen(counselorId: counselorId),
    ];
  }

  final List<String> _titles = [
    'Counselor Dashboard',
    'Appointment Bookings',
    'Chat History',
  ];

  void _showProfileMenu(
    BuildContext context,
    String counselorName,
    String counselorInitials,
    ImageProvider? profileImage,
  ) {
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder:
          (_) => Padding(
            padding: const EdgeInsets.all(20),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                CircleAvatar(
                  radius: 30,
                  backgroundColor: Colors.blue.shade100,
                  backgroundImage: profileImage,
                  child:
                      profileImage == null
                          ? Text(
                            counselorInitials,
                            style: const TextStyle(
                              fontWeight: FontWeight.bold,
                              color: Colors.blue,
                            ),
                          )
                          : null,
                ),

                const SizedBox(height: 8),
                Text(
                  counselorName,
                  style: const TextStyle(fontWeight: FontWeight.bold),
                ),
                const Text("Counselor", style: TextStyle(color: Colors.grey)),
                const Divider(height: 30),
                ListTile(
                  leading: const Icon(Icons.person),
                  title: const Text("My Profile"),
                  onTap: () {
                    Navigator.pop(context); // Close the bottom sheet
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (_) => const CounselorProfileScreen(),
                      ),
                    );
                  },
                ),
                ListTile(
                  leading: const Icon(Icons.notifications),
                  title: const Text("Notification"),
                  trailing: const Text(
                    "Allow",
                    style: TextStyle(color: Colors.grey),
                  ),
                  onTap: () {
                    // Handle notification settings
                  },
                ),
                ListTile(
                  leading: const Icon(Icons.logout),
                  title: const Text("Log Out"),
                  onTap: () async {
                    await FirebaseAuth.instance.signOut();
                    if (context.mounted) {
                      Navigator.pushNamedAndRemoveUntil(
                        context,
                        '/role-selection',
                        (route) => false,
                      );
                    }
                  },
                ),
              ],
            ),
          ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final currentUser = FirebaseAuth.instance.currentUser;

    if (currentUser == null) {
      return const Scaffold(body: Center(child: Text('Not logged in')));
    }

    return StreamBuilder<DocumentSnapshot>(
      stream:
          FirebaseFirestore.instance
              .collection('counselors')
              .doc(currentUser.uid)
              .snapshots(),
      builder: (context, snapshot) {
        if (!snapshot.hasData) {
          return const Scaffold(
            body: Center(child: CircularProgressIndicator()),
          );
        }

        final counselorData = snapshot.data!.data() as Map<String, dynamic>?;
        final base64Image = counselorData?['profileImageBase64'] ?? '';

        final counselorName = counselorData?['fullName'] ?? 'Unknown Counselor';
        final counselorInitials =
            counselorData?['fullName']?.substring(0, 2)?.toUpperCase() ?? 'UN';

        ImageProvider? profileImage;
        if (base64Image.isNotEmpty) {
          try {
            final bytes = base64Decode(base64Image);
            profileImage = MemoryImage(bytes);
          } catch (e) {
            debugPrint("Invalid base64 image: $e");
          }
        }

        return Scaffold(
          appBar: AppBar(
            automaticallyImplyLeading: false,
            backgroundColor: Colors.blue.shade50,
            elevation: 3,
            title: Text(_titles[_currentIndex]),
            actions: [
              GestureDetector(
                onTap:
                    () => _showProfileMenu(
                      context,
                      counselorName,
                      counselorInitials,
                      profileImage,
                    ),
                child: Padding(
                  padding: const EdgeInsets.all(8.0),
                  child:
                      profileImage != null
                          ? CircleAvatar(backgroundImage: profileImage)
                          : CircleAvatar(
                            backgroundColor: Colors.blue,
                            child: Text(
                              counselorInitials,
                              style: const TextStyle(color: Colors.white),
                            ),
                          ),
                ),
              ),
            ],
          ),
          body: _getScreens(currentUser.uid)[_currentIndex],
          bottomNavigationBar: BottomNavigationBar(
            elevation: 3,
            backgroundColor: Colors.blue.shade50,
            selectedItemColor: Colors.blue,
            currentIndex: _currentIndex,
            onTap: (index) => setState(() => _currentIndex = index),
            items: const [
              BottomNavigationBarItem(
                icon: Icon(Icons.dashboard),
                label: "Dashboard",
              ),
              BottomNavigationBarItem(
                icon: Icon(Icons.calendar_today),
                label: "Bookings",
              ),
              BottomNavigationBarItem(icon: Icon(Icons.chat), label: "Chat"),
            ],
          ),
        );
      },
    );
  }
}
