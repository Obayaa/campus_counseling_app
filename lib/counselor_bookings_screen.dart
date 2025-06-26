import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:timeago/timeago.dart' as timeago;

class CounselorBookingsScreen extends StatefulWidget {
  final String counselorId;

  const CounselorBookingsScreen({super.key, required this.counselorId});

  @override
  State<CounselorBookingsScreen> createState() =>
      _CounselorBookingsScreenState();
}

class _CounselorBookingsScreenState extends State<CounselorBookingsScreen> {
  bool _initialLoadingComplete = false;

  @override
  void initState() {
    super.initState();
    // Add a minimum delay before showing content
    Future.delayed(const Duration(milliseconds: 800), () {
      if (mounted) {
        setState(() {
          _initialLoadingComplete = true;
        });
      }
    });
  }

  void _showDeleteConfirmation(
    BuildContext context,
    String docId,
    String studentName,
  ) {
    showDialog(
      context: context,
      builder:
          (context) => AlertDialog(
            title: const Text('Delete Appointment'),
            content: Text(
              'Are you sure you want to delete the appointment with $studentName? This action cannot be undone.',
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context),
                child: const Text('Cancel'),
              ),
              ElevatedButton(
                onPressed: () {
                  FirebaseFirestore.instance
                      .collection('appointments')
                      .doc(docId)
                      .delete();
                  Navigator.pop(context);
                },
                style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
                child: const Text(
                  'Delete',
                  style: TextStyle(color: Colors.white),
                ),
              ),
            ],
          ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final firestore = FirebaseFirestore.instance;

    return Scaffold(
      body: StreamBuilder<QuerySnapshot>(
        stream:
            firestore
                .collection('appointments')
                .where('counselorId', isEqualTo: widget.counselorId)
                .snapshots(),
        builder: (context, snapshot) {
          // Show loading if initial delay hasn't completed OR if we don't have data yet
          if (!_initialLoadingComplete || !snapshot.hasData) {
            return const Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  CircularProgressIndicator(),
                  SizedBox(height: 16),
                  Text('Loading appointments...'),
                ],
              ),
            );
          }

          // Handle errors
          if (snapshot.hasError) {
            return Center(child: Text('Error: ${snapshot.error}'));
          }

          final docs = snapshot.data!.docs;

          if (docs.isEmpty) {
            return const Center(child: Text('No bookings yet.'));
          }

          return ListView.builder(
            padding: const EdgeInsets.all(16),
            itemCount: docs.length,
            itemBuilder: (context, index) {
              final data = docs[index].data() as Map<String, dynamic>;
              final studentName = data['studentName'] ?? 'Anonymous';
              // debugPrint('Appointment data for $data');
              final startTime = data['startTime'] as Timestamp?;
              final appointmentDate = startTime?.toDate() ?? DateTime.now();
              final timeSlot = data['time'] ?? data['timeSlot'] ?? '';
              final subject =
                  data['counselingType'] ??
                  data['subject'] ??
                  'General Counseling';
              final status = data['status'] ?? 'pending';
              final createdAt = data['createdAt']?.toDate() ?? appointmentDate;
              final timeAgo = timeago.format(createdAt);
              final isApproved = status.toLowerCase() == 'approved';
              final isDeclined = status.toLowerCase() == 'declined';

              // Check if overdue
              final isOverdue = appointmentDate.isBefore(
                DateTime.now().subtract(const Duration(days: 0)),
              );

              return Card(
                margin: const EdgeInsets.only(bottom: 16),
                color:
                    isOverdue
                        ? Colors.red.shade50
                        : isApproved
                        ? Colors.green.shade50
                        : isDeclined
                        ? Colors.red.shade50
                        : Colors.blue.shade50,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                  side:
                      isOverdue
                          ? BorderSide(color: Colors.red.shade200)
                          : isApproved
                          ? BorderSide(color: Colors.green.shade200)
                          : isDeclined
                          ? BorderSide(color: Colors.red.shade200)
                          : BorderSide(color: Colors.blue.shade200),
                ),
                child: Padding(
                  padding: const EdgeInsets.all(12),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      ListTile(
                        contentPadding: EdgeInsets.zero,
                        leading: CircleAvatar(
                          backgroundColor:
                              isOverdue
                                  ? Colors.red
                                  : isApproved
                                  ? Colors.green
                                  : isDeclined
                                  ? Colors.red
                                  : Colors.blue,
                          child: Text(
                            studentName[0].toUpperCase(),
                            style: TextStyle(color: Colors.white),
                          ),
                        ),
                        title: Row(
                          children: [
                            Expanded(
                              child: Text(
                                studentName,
                                style: const TextStyle(
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ),
                            if (isOverdue)
                              Container(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 6,
                                  vertical: 2,
                                ),
                                decoration: BoxDecoration(
                                  color: Colors.red,
                                  borderRadius: BorderRadius.circular(8),
                                ),
                                child: const Text(
                                  'OVERDUE',
                                  style: TextStyle(
                                    color: Colors.white,
                                    fontSize: 10,
                                  ),
                                ),
                              ),
                          ],
                        ),
                        subtitle: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const SizedBox(height: 4),
                            const Text("wants to schedule an appointment"),
                            const SizedBox(height: 4),
                            Text(
                              "${appointmentDate.day}/${appointmentDate.month}/${appointmentDate.year} - $timeSlot",
                              style: const TextStyle(
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                            Text(
                              "Subject: $subject",
                              style: const TextStyle(fontSize: 12),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              "Status: ${status.toUpperCase()}",
                              style: TextStyle(
                                color:
                                    status == 'approved'
                                        ? Colors.green
                                        : status == 'declined'
                                        ? Colors.red
                                        : Colors.blue,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ],
                        ),
                        trailing: Text(
                          timeAgo,
                          style: const TextStyle(color: Colors.grey),
                        ),
                      ),
                      const SizedBox(height: 8),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                        children: [
                          ElevatedButton(
                            onPressed:
                                status == 'approved'
                                    ? null
                                    : () {
                                      firestore
                                          .collection('appointments')
                                          .doc(docs[index].id)
                                          .update({'status': 'approved'});
                                    },
                            style: ElevatedButton.styleFrom(
                              backgroundColor:
                                  status == 'approved'
                                      ? Colors.grey
                                      : Colors.green,
                            ),
                            child: Text(
                              status == 'approved' ? 'Approved' : 'Approve',
                              style: const TextStyle(color: Colors.white),
                            ),
                          ),
                          ElevatedButton(
                            onPressed:
                                status == 'declined'
                                    ? null
                                    : () {
                                      firestore
                                          .collection('appointments')
                                          .doc(docs[index].id)
                                          .update({'status': 'declined'});
                                    },
                            style: ElevatedButton.styleFrom(
                              backgroundColor:
                                  status == 'declined'
                                      ? Colors.grey
                                      : Colors.orange,
                            ),
                            child: Text(
                              status == 'declined' ? 'Declined' : 'Decline',
                              style: const TextStyle(color: Colors.white),
                            ),
                          ),
                          IconButton(
                            onPressed:
                                () => _showDeleteConfirmation(
                                  context,
                                  docs[index].id,
                                  studentName,
                                ),
                            icon: const Icon(Icons.delete, color: Colors.red),
                            tooltip: 'Delete appointment',
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              );
            },
          );
        },
      ),
    );
  }
}
