// ignore_for_file: unused_field

import 'package:campus_counseling_app/services/notification_service.dart';
import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:device_calendar/device_calendar.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:timezone/timezone.dart' as tz;
import 'package:timezone/data/latest.dart' as tzdata;
import 'package:table_calendar/table_calendar.dart';

class BookScreen extends StatefulWidget {
  const BookScreen({super.key});

  @override
  State<BookScreen> createState() => _BookScreenState();
}

class _BookScreenState extends State<BookScreen> {
  final user = FirebaseAuth.instance.currentUser;
  final _formKey = GlobalKey<FormState>();

  String? counselingType = 'Academic counseling';
  String? sessionMode = 'Chat';
  // String? selectedCounselor = 'Prof. Gilbert Asare';
  DateTime selectedDate = DateTime.now();
  TimeOfDay startTime = TimeOfDay.now();
  TimeOfDay endTime = TimeOfDay(
    hour: TimeOfDay.now().hour + 1,
    minute: TimeOfDay.now().minute,
  );
  final DeviceCalendarPlugin _calendarPlugin = DeviceCalendarPlugin();
  int _selectedIndex = 1;
  List<Map<String, dynamic>> counselors = [];
  String? selectedCounselor;
  String? selectedCounselorId;

  @override
  void initState() {
    super.initState();
    tzdata.initializeTimeZones();
    fetchCounselors();
  }

  Future<void> fetchCounselors() async {
    final snapshot =
        await FirebaseFirestore.instance
            .collection('counselors')
            .where('profileComplete', isEqualTo: true)
            .get();
    final data =
        snapshot.docs.map((doc) {
          final d = doc.data();
          d['id'] = doc.id; // 👈 Add Firestore doc ID (counselorId)
          return d;
        }).toList();
    if (mounted) {
      setState(() {
        counselors = data;
        if (counselors.isNotEmpty) {
          selectedCounselor = counselors.first['fullName'];
          selectedCounselorId = counselors.first['id']; // 🔥 Add this line
        }
      });
    }
  }

  Future<void> _bookAppointment() async {
    if (selectedCounselor == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Please select a counselor")),
      );
      return;
    }

    final startDateTime = DateTime(
      selectedDate.year,
      selectedDate.month,
      selectedDate.day,
      startTime.hour,
      startTime.minute,
    );

    final endDateTime = DateTime(
      selectedDate.year,
      selectedDate.month,
      selectedDate.day,
      endTime.hour,
      endTime.minute,
    );

    // Additional validation: Check if appointment is in the future
    if (startDateTime.isBefore(DateTime.now())) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Please select a future date and time")),
      );
      return;
    }

    // Check if end time is after start time
    if (endDateTime.isBefore(startDateTime) ||
        endDateTime.isAtSameMomentAs(startDateTime)) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("End time must be after start time")),
      );
      return;
    }

    await showLocalNotification(
      title: "New Appointment Request",
      body:
          "Student booked a session with $selectedCounselor ($counselingType)",
    );

    SharedPreferences prefs = await SharedPreferences.getInstance();
    await prefs.setString('anonymous_uid', user!.uid); // Now safe to use !

    await FirebaseFirestore.instance.collection('appointments').add({
      'studentId': user?.uid,
      'studentName': user?.displayName ?? 'Anonymous',
      'counselingType': counselingType,
      'sessionMode': sessionMode,
      'counselorId': selectedCounselorId, // 👈 Add this
      'counselorName': selectedCounselor,
      'startTime': startDateTime,
      'endTime': endDateTime,
      'date': "${selectedDate.year}-${selectedDate.month}-${selectedDate.day}",
      'time': "${startTime.format(context)} - ${endTime.format(context)}",
      'status': 'pending',
      'createdAt': Timestamp.now(),
    });

    await _requestAndAddToCalendar(startDateTime, endDateTime);

    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text("Appointment booked successfully")),
    );
  }

  Future<void> _requestAndAddToCalendar(DateTime start, DateTime end) async {
    var status = await Permission.calendar.status;
    if (!status.isGranted) {
      status = await Permission.calendar.request();
    }
    if (status.isGranted) {
      var calendarsResult = await _calendarPlugin.retrieveCalendars();
      if (calendarsResult.isSuccess && calendarsResult.data!.isNotEmpty) {
        final calendarId = calendarsResult.data!.first.id;
        final location = tz.getLocation(DateTime.now().timeZoneName);
        final tzStart = tz.TZDateTime.from(start, location);
        final tzEnd = tz.TZDateTime.from(end, location);

        final event = Event(
          calendarId!,
          title: 'Counseling Session',
          description:
              'With $selectedCounselor ($counselingType) - $sessionMode',
          start: tzStart,
          end: tzEnd,
        );
        await _calendarPlugin.createOrUpdateEvent(event);
      }
    }
  }

  Widget buildSessionModeButton(String mode) {
    final isSelected = sessionMode == mode;
    return Expanded(
      child: ElevatedButton(
        style: ElevatedButton.styleFrom(
          backgroundColor: isSelected ? Colors.blue : Colors.grey[300],
          foregroundColor: isSelected ? Colors.white : Colors.black,
        ),
        onPressed: () => setState(() => sessionMode = mode),
        child: Text(mode),
      ),
    );
  }

  Widget buildTimePicker(
    String label,
    TimeOfDay time,
    void Function(TimeOfDay) onPicked,
  ) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label),
        InkWell(
          onTap: () async {
            final now = TimeOfDay.now();
            final today = DateTime.now();

            TimeOfDay? picked = await showTimePicker(
              context: context,
              initialTime: time,
            );

            if (picked != null) {
              // Check if selected date is today and time is in the past
              if (isSameDay(selectedDate, today)) {
                final selectedMinutes = picked.hour * 60 + picked.minute;
                final currentMinutes = now.hour * 60 + now.minute;

                if (selectedMinutes <= currentMinutes) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text("Please select a future time"),
                    ),
                  );
                  return;
                }
              }

              onPicked(picked);

              // Auto-adjust end time if it's before start time
              if (label == "Start Time" &&
                  picked.hour * 60 + picked.minute >=
                      endTime.hour * 60 + endTime.minute) {
                setState(() {
                  endTime = TimeOfDay(
                    hour: picked.hour + 1 > 23 ? 23 : picked.hour + 1,
                    minute: picked.minute,
                  );
                });
              }
            }
          },
          child: Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              border: Border.all(color: Colors.grey),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Text(time.format(context)),
          ),
        ),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(20),
          child: ListView(
            children: [
              const SizedBox(height: 10),
              const Text(
                "Book Appointment",
                style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 16),
              const Text("Select Counseling Type:"),
              Wrap(
                spacing: 10,
                children:
                    [
                      'Academic counseling',
                      'Mental Health',
                      'Spiritual Counseling',
                    ].map((type) {
                      final selected = counselingType == type;
                      return ChoiceChip(
                        label: Text(
                          type,
                          // style: TextStyle(color: Colors.white),
                        ),
                        selected: selected,
                        selectedColor: Colors.blue,
                        backgroundColor: Colors.blue.shade50,
                        side: BorderSide(color: Colors.grey.shade500),
                        onSelected:
                            (_) => setState(() => counselingType = type),
                      );
                    }).toList(),
              ),
              const SizedBox(height: 16),
              const Text("Choose Counselor:"),
              const SizedBox(height: 8),
              DropdownButtonFormField<String>(
                decoration: InputDecoration(
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                  hintText: 'Pick a counselor',
                ),
                value: selectedCounselor,
                items:
                    counselors.map((counselor) {
                      final name = counselor['fullName'];
                      return DropdownMenuItem<String>(
                        value: name,
                        child: Text(name),
                      );
                    }).toList(),
                onChanged: (value) {
                  if (value != null) {
                    final counselor = counselors.firstWhere(
                      (c) => c['fullName'] == value,
                    );
                    setState(() {
                      selectedCounselor = counselor['fullName'];
                      selectedCounselorId =
                          counselor['id']; // 🔥 This will now always be set
                    });
                  }
                },
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Please select a counselor';
                  }
                  return null;
                },
              ),

              const SizedBox(height: 16),
              const Text("Pick Date:"),
              TableCalendar(
                focusedDay: selectedDate,
                firstDay: DateTime.now(),
                lastDay: DateTime.now().add(const Duration(days: 30)),
                selectedDayPredicate: (day) => isSameDay(selectedDate, day),
                onDaySelected: (selectedDay, _) {
                  setState(() => selectedDate = selectedDay);
                },
                calendarStyle: const CalendarStyle(
                  selectedDecoration: BoxDecoration(
                    color: Colors.blue,
                    shape: BoxShape.circle,
                  ),
                  todayDecoration: BoxDecoration(
                    color: Colors.orange,
                    shape: BoxShape.circle,
                  ),
                ),
                headerStyle: const HeaderStyle(
                  formatButtonVisible: false,
                  titleCentered: true,
                ),
              ),
              const SizedBox(height: 16),
              Row(
                children: [
                  Expanded(
                    child: buildTimePicker(
                      "Start Time",
                      startTime,
                      (time) => setState(() => startTime = time),
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: buildTimePicker(
                      "End Time",
                      endTime,
                      (time) => setState(() => endTime = time),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              const Text("Session Mode:"),
              Row(
                spacing: 12.0,
                children:
                    ['Chat', 'Voice Call'].map(buildSessionModeButton).toList(),
              ),
              const SizedBox(height: 20),
              ElevatedButton(
                onPressed: _bookAppointment,
                style: ElevatedButton.styleFrom(
                  minimumSize: const Size.fromHeight(50),
                ),
                child: const Text("Confirm Appointment"),
              ),

              const SizedBox(height: 20),
              ElevatedButton(
                onPressed: () {
                  showLocalNotification(
                    title: "Test Notification",
                    body: "This is a local notification test.",
                  );
                },
                child: Text("Send Test Notification"),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
