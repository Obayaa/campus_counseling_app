// import 'dart:convert';

// import 'package:cloud_firestore/cloud_firestore.dart';
// import 'package:flutter/material.dart';

// class CounselorsScreen extends StatelessWidget {
//   const CounselorsScreen({super.key});

//   @override
//   Widget build(BuildContext context) {
//     return Scaffold(
//       appBar: AppBar(
//         title: const Text('Meet Our Counselors'),
//         backgroundColor: Colors.blue,
//         foregroundColor: Colors.white,
//       ),
//       body: StreamBuilder<QuerySnapshot>(
//         stream: FirebaseFirestore.instance.collection('counselors').snapshots(),
//         builder: (context, snapshot) {
//           if (snapshot.connectionState == ConnectionState.waiting) {
//             return const Center(child: CircularProgressIndicator());
//           }

//           if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
//             return const Center(child: Text('No counselors found.'));
//           }

//           return ListView.builder(
//             padding: const EdgeInsets.all(16),
//             itemCount: snapshot.data!.docs.length,
//             itemBuilder: (context, index) {
//               final doc = snapshot.data!.docs[index];
//               final data = doc.data() as Map<String, dynamic>;
//               final name = data['fullName'] ?? 'Unknown';
//               final email = data['email'] ?? 'N/A';
//               final specialty = data['specialization'] ?? 'General';
//               final imageBase64 = data['profileImageBase64'] ?? '';

//               ImageProvider? profileImage;
//               if (imageBase64.isNotEmpty) {
//                 try {
//                   profileImage = MemoryImage(base64Decode(imageBase64));
//                 } catch (_) {
//                   profileImage = null;
//                 }
//               }

//               return Card(
//                 elevation: 3,
//                 shape: RoundedRectangleBorder(
//                   borderRadius: BorderRadius.circular(12),
//                 ),
//                 margin: const EdgeInsets.only(bottom: 16),
//                 child: ListTile(
//                   contentPadding: const EdgeInsets.all(12),
//                   leading: CircleAvatar(
//                     radius: 30,
//                     backgroundColor: Colors.blueAccent,
//                     backgroundImage: profileImage,
//                     child:
//                         profileImage == null
//                             ? Text(
//                               _getInitials(name),
//                               style: const TextStyle(color: Colors.white),
//                             )
//                             : null,
//                   ),
//                   title: Text(
//                     name,
//                     style: const TextStyle(
//                       fontWeight: FontWeight.bold,
//                       fontSize: 16,
//                     ),
//                   ),
//                   subtitle: Column(
//                     crossAxisAlignment: CrossAxisAlignment.start,
//                     children: [
//                       const SizedBox(height: 4),
//                       Text(specialty),
//                       const SizedBox(height: 2),
//                       Text(email, style: const TextStyle(color: Colors.grey)),
//                     ],
//                   ),
//                 ),
//               );
//             },
//           );
//         },
//       ),
//     );
//   }

//   String _getInitials(String name) {
//     var parts = name.trim().split(' ');
//     if (parts.length >= 2) {
//       return parts[0][0] + parts[1][0];
//     } else if (parts.isNotEmpty) {
//       return parts[0][0];
//     } else {
//       return 'U';
//     }
//   }
// }

import 'dart:convert';

import 'package:campus_counseling_app/book_screen.dart';
import 'package:campus_counseling_app/counselor_bookings_screen.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';

class CounselorDirectoryScreen extends StatefulWidget {
  const CounselorDirectoryScreen({super.key});

  @override
  State<CounselorDirectoryScreen> createState() =>
      _CounselorDirectoryScreenState();
}

class _CounselorDirectoryScreenState extends State<CounselorDirectoryScreen> {
  String selectedSpecialty = 'All';
  final List<String> specialties = ['All'];

  @override
  void initState() {
    super.initState();
    _fetchSpecialties();
  }

  void _fetchSpecialties() async {
    final snapshot =
        await FirebaseFirestore.instance.collection('counselors').get();
    final fetched =
        snapshot.docs
            .map((doc) => doc['specialization'] as String?)
            .where((s) => s != null && s!.isNotEmpty)
            .map((s) => s!)
            .toSet()
            .toList();
    setState(() {
      specialties.addAll(fetched);
    });
  }

  Stream<QuerySnapshot> _counselorsStream() {
    final base = FirebaseFirestore.instance.collection('counselors');
    return selectedSpecialty == 'All'
        ? base.snapshots()
        : base
            .where('specialization', isEqualTo: selectedSpecialty)
            .snapshots();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        automaticallyImplyLeading: false,
        backgroundColor: Colors.blue,
        foregroundColor: Colors.white,
        title: const Text('Meet Our Counselors'),
      ),
      body: Column(
        children: [
          // Filter dropdown
          Padding(
            padding: const EdgeInsets.all(12.0),
            child: Row(
              children: [
                const Text(
                  "Filter by: ",
                  style: TextStyle(fontWeight: FontWeight.bold),
                ),
                const SizedBox(width: 8),
                DropdownButton<String>(
                  value: selectedSpecialty,
                  items:
                      specialties
                          .map(
                            (specialty) => DropdownMenuItem(
                              value: specialty,
                              child: Text(specialty),
                            ),
                          )
                          .toList(),
                  onChanged:
                      (value) => setState(() => selectedSpecialty = value!),
                ),
              ],
            ),
          ),
          Expanded(
            child: StreamBuilder<QuerySnapshot>(
              stream: _counselorsStream(),
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const Center(child: CircularProgressIndicator());
                }
                if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
                  return const Center(child: Text('No counselors found.'));
                }

                return ListView.builder(
                  itemCount: snapshot.data!.docs.length,
                  itemBuilder: (context, index) {
                    final doc = snapshot.data!.docs[index];
                    final data = doc.data() as Map<String, dynamic>;
                    final fullName = data['fullName'] ?? 'Unnamed';
                    final contact =
                        (data['phone']?.toString().trim().isEmpty ?? true)
                            ? 'No contact'
                            : data['phone'];
                    final specialization =
                        (data['specialization']?.toString().trim().isEmpty ??
                                true)
                            ? 'General'
                            : data['specialization'];
                    final imageBase64 = data['profileImageBase64'];

                    return Card(
                      color: Colors.blue.shade50,
                      margin: const EdgeInsets.symmetric(
                        horizontal: 12,
                        vertical: 8,
                      ),
                      elevation: 0.5,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: ListTile(
                        leading:
                            imageBase64 != null
                                ? CircleAvatar(
                                  backgroundImage: MemoryImage(
                                    base64Decode(imageBase64),
                                  ),
                                  radius: 28,
                                )
                                : const CircleAvatar(
                                  backgroundColor: Colors.blue,
                                  foregroundColor: Colors.white,
                                  radius: 28,
                                  child: Icon(Icons.person),
                                ),
                        title: Text(fullName),
                        subtitle: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text('Specialty: $specialization'),
                            Text('Contact: $contact'),
                          ],
                        ),
                        // isThreeLine: true,
                        // trailing: ElevatedButton(
                        //   style: ButtonStyle(
                        //     backgroundColor: MaterialStateProperty.all(
                        //       Colors.white,
                        //     ),
                        //     foregroundColor: MaterialStateProperty.all(
                        //       Colors.blue,
                        //     ),
                        //   ),
                        //   onPressed: () {
                        //     Navigator.push(
                        //       context,
                        //       MaterialPageRoute(
                        //         builder:
                        //             (_) => BookScreen(
                        //               // counselorId: doc.id,
                        //               // counselorName: fullName,
                        //             ),
                        //       ),
                        //     );
                        //   },
                        //   child: const Text("Book"),
                        // ),
                      ),
                    );
                  },
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}
