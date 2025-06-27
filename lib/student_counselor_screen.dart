import 'dart:convert';
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
            .where((s) => s != null && s.isNotEmpty)
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
