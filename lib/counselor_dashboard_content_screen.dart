import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

class CounselorDashboardContentScreen extends StatefulWidget {
  const CounselorDashboardContentScreen({super.key});

  @override
  State<CounselorDashboardContentScreen> createState() =>
      _CounselorDashboardContentScreenState();
}

class _CounselorDashboardContentScreenState
    extends State<CounselorDashboardContentScreen> {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;

  // Data state
  String counselorName = "Counselor";
  String counselorId = "";
  List<QueryDocumentSnapshot> todaysAppointments = [];
  List<QueryDocumentSnapshot> overdueAppointments = [];
  List<QueryDocumentSnapshot> allAppointments = [];
  List<QueryDocumentSnapshot> activeChats = [];

  // Loading state
  bool _isLoading = true;
  String? _errorMessage;

  @override
  void initState() {
    super.initState();
    _loadAllDashboardData();
  }

  Future<void> _loadAllDashboardData() async {
    try {
      setState(() {
        _isLoading = true;
        _errorMessage = null;
      });

      final user = _auth.currentUser;
      if (user == null) {
        throw Exception('No authenticated user found');
      }

      counselorId = user.uid;

      final results = await Future.wait([
        _loadCounselorInfo(user.uid),
        _loadAppointments(user.uid),
        _loadActiveChats(user.uid),
      ]);

      counselorName = results[0] as String;
      final appointments = results[1] as List<QueryDocumentSnapshot>;
      activeChats = results[2] as List<QueryDocumentSnapshot>;

      final now = DateTime.now();
      // final today = DateTime(now.year, now.month, now.day);

      // Filter appointments
      // Filter upcoming appointments (from now onwards and approved)
      todaysAppointments =
          appointments.where((doc) {
            final data = doc.data() as Map<String, dynamic>;
            if (data['status'] != 'approved') return false;
            final startTimestamp = data['startTime'] as Timestamp?;
            if (startTimestamp == null) return false;

            final appointmentDate = startTimestamp.toDate();
            return appointmentDate.isAfter(now) ||
                appointmentDate.isAtSameMomentAs(now);
          }).toList();

      // Filter overdue appointments (past date + approved/pending status)
      overdueAppointments =
          appointments.where((doc) {
            final data = doc.data() as Map<String, dynamic>;
            // final status = data['status'] ?? '';
            // if (status == 'declined') return false;

            final startTimestamp = data['startTime'] as Timestamp?;
            if (startTimestamp == null) return false;

            final appointmentDate = startTimestamp.toDate();
            return appointmentDate.isBefore(now);
          }).toList();

      allAppointments = appointments;

      setState(() {
        _isLoading = false;
      });
    } catch (e) {
      print('Error loading dashboard data: $e');
      setState(() {
        _isLoading = false;
        _errorMessage = 'Failed to load dashboard data. Please try again.';
      });
    }
  }

  Future<String> _loadCounselorInfo(String uid) async {
    try {
      final counselorDoc =
          await _firestore.collection('counselors').doc(uid).get();
      if (counselorDoc.exists) {
        final data = counselorDoc.data() as Map<String, dynamic>;
        return data['fullName'] ?? data['firstName'] ?? "Counselor";
      }
      return "Counselor";
    } catch (e) {
      print('Error loading counselor info: $e');
      return "Counselor";
    }
  }

  Future<List<QueryDocumentSnapshot>> _loadAppointments(
    String counselorId,
  ) async {
    try {
      final snapshot =
          await _firestore
              .collection('appointments')
              .where('counselorId', isEqualTo: counselorId)
              .get();
      return snapshot.docs;
    } catch (e) {
      print('Error loading appointments: $e');
      return [];
    }
  }

  Future<List<QueryDocumentSnapshot>> _loadActiveChats(
    String counselorId,
  ) async {
    try {
      final snapshot =
          await _firestore
              .collection('chats')
              .where('counselorId', isEqualTo: counselorId)
              .get();
      return snapshot.docs;
    } catch (e) {
      print('Error loading chats: $e');
      return [];
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return const Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            CircularProgressIndicator(),
            SizedBox(height: 16),
            Text('Loading dashboard...'),
          ],
        ),
      );
    }

    if (_errorMessage != null) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.error_outline, size: 48, color: Colors.red),
            SizedBox(height: 16),
            Text(_errorMessage!),
            SizedBox(height: 16),
            ElevatedButton(
              onPressed: _loadAllDashboardData,
              child: Text('Retry'),
            ),
          ],
        ),
      );
    }

    return Padding(
      padding: const EdgeInsets.all(16.0),
      child: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              "Hello, $counselorName",
              style: const TextStyle(fontSize: 22, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 16),

            Container(
              height: 100,
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(12),
                image: const DecorationImage(
                  image: AssetImage('assets/images/university.jpeg'),
                  fit: BoxFit.cover,
                ),
              ),
            ),
            const SizedBox(height: 16),

            // Overdue appointments (show first if any)
            if (overdueAppointments.isNotEmpty) ...[
              Row(
                children: [
                  const Text(
                    "Overdue Appointments",
                    style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(width: 8),
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 8,
                      vertical: 4,
                    ),
                    decoration: BoxDecoration(
                      color: Colors.red,
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Text(
                      '${overdueAppointments.length}',
                      style: const TextStyle(color: Colors.white, fontSize: 12),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              _buildOverdueAppointments(),
              const SizedBox(height: 16),
            ],

            const Text(
              "Upcoming Appointments",
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),
            _buildTodaysAppointments(),

            const SizedBox(height: 16),
            _buildStatisticsCards(),

            const SizedBox(height: 16),
            const Text(
              "Weekly Appointments Overview",
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),
            _buildWeeklyChart(),
          ],
        ),
      ),
    );
  }

  Widget _buildOverdueAppointments() {
    return Column(
      children:
          overdueAppointments.map((doc) {
            final data = doc.data() as Map<String, dynamic>;
            final startTimestamp = data['startTime'] as Timestamp;
            final appointmentDate = startTimestamp.toDate();
            final timeSlot = data['time'] ?? 'Time not set';
            final daysOverdue =
                DateTime.now().difference(appointmentDate).inDays;

            return Card(
              color: Colors.red.shade100,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
                side: BorderSide(color: Colors.red.shade300),
              ),
              margin: const EdgeInsets.only(bottom: 8),
              child: ListTile(
                leading: CircleAvatar(
                  backgroundColor: Colors.red,
                  child: Icon(Icons.warning, color: Colors.white),
                ),
                title: Text(
                  data['studentName'] ?? 'Anonymous Student',
                  style: TextStyle(fontWeight: FontWeight.bold),
                ),
                subtitle: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(data['counselingType'] ?? 'General Counseling'),
                    Text(
                      'Status: ${data['status']?.toUpperCase() ?? 'UNKNOWN'}',
                      style: TextStyle(
                        color: Colors.red.shade700,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),
                trailing: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    Text(
                      _formatDate(appointmentDate),
                      style: TextStyle(
                        fontSize: 12,
                        color: Colors.red.shade700,
                      ),
                    ),
                    Text(
                      timeSlot,
                      style: TextStyle(
                        fontSize: 12,
                        color: Colors.red.shade700,
                      ),
                    ),
                    Text(
                      '$daysOverdue days ago',
                      style: TextStyle(
                        fontSize: 10,
                        color: Colors.red.shade600,
                      ),
                    ),
                  ],
                ),
              ),
            );
          }).toList(),
    );
  }

  Widget _buildTodaysAppointments() {
    if (todaysAppointments.isEmpty) {
      return Card(
        color: Colors.grey.shade100,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        child: const Padding(
          padding: EdgeInsets.all(16.0),
          child: Center(
            child: Text(
              "No appointments scheduled",
              style: TextStyle(color: Colors.grey),
            ),
          ),
        ),
      );
    }

    return Column(
      children:
          todaysAppointments.map((doc) {
            final data = doc.data() as Map<String, dynamic>;
            final startTimestamp = data['startTime'] as Timestamp;
            final appointmentDate = startTimestamp.toDate();
            final timeSlot = data['time'] ?? 'Time not set';

            return Card(
              color: Colors.blue.shade700,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
              margin: const EdgeInsets.only(bottom: 8),
              child: ListTile(
                leading: const CircleAvatar(
                  backgroundColor: Colors.white,
                  child: Icon(Icons.person, color: Colors.blue),
                ),
                title: Text(
                  data['studentName'] ?? 'Anonymous Student',
                  style: const TextStyle(color: Colors.white),
                ),
                subtitle: Text(
                  data['counselingType'] ?? 'General Counseling',
                  style: const TextStyle(color: Colors.white70),
                ),
                trailing: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    Text(
                      _formatDate(appointmentDate),
                      style: const TextStyle(color: Colors.white, fontSize: 12),
                    ),
                    Text(
                      timeSlot,
                      style: const TextStyle(color: Colors.white, fontSize: 12),
                    ),
                  ],
                ),
              ),
            );
          }).toList(),
    );
  }

  Widget _buildStatisticsCards() {
    return Row(
      children: [
        Expanded(child: _buildAppointmentStatsCard()),
        const SizedBox(width: 8),
        Expanded(child: _buildOverdueStatsCard()),
        const SizedBox(width: 8),
        Expanded(child: _buildMessageStatsCard()),
      ],
    );
  }

  Widget _buildAppointmentStatsCard() {
    final count = allAppointments.length;
    return _buildStatCard('Total\nAppointments', count, Icons.calendar_today);
  }

  Widget _buildOverdueStatsCard() {
    final count = overdueAppointments.length;
    return _buildStatCard(
      'Overdue\nAppointments',
      count,
      Icons.warning,
      color: count > 0 ? Colors.red : null,
    );
  }

  Widget _buildMessageStatsCard() {
    final count = activeChats.length;
    return _buildStatCard('Active\nChats', count, Icons.message);
  }

  Widget _buildStatCard(
    String title,
    int count,
    IconData icon, {
    Color? color,
  }) {
    final cardColor = color ?? Colors.blue.shade700;
    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Container(
        padding: const EdgeInsets.all(12),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, color: cardColor, size: 24),
            const SizedBox(height: 8),
            Text(
              '$count',
              style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 4),
            Text(
              title,
              textAlign: TextAlign.center,
              style: TextStyle(fontSize: 12, color: Colors.grey.shade600),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildWeeklyChart() {
    final weeklyData = _generateWeeklyData(allAppointments);

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            SizedBox(
              height: 150,
              child: LineChart(
                LineChartData(
                  gridData: FlGridData(
                    show: true,
                    drawVerticalLine: false,
                    horizontalInterval: 1,
                    getDrawingHorizontalLine: (value) {
                      return FlLine(
                        color: Colors.grey.shade300,
                        strokeWidth: 1,
                      );
                    },
                  ),
                  borderData: FlBorderData(show: false),
                  titlesData: FlTitlesData(
                    leftTitles: AxisTitles(
                      sideTitles: SideTitles(
                        showTitles: true,
                        reservedSize: 30,
                        getTitlesWidget: (value, meta) {
                          return Text(
                            value.toInt().toString(),
                            style: const TextStyle(fontSize: 10),
                          );
                        },
                      ),
                    ),
                    bottomTitles: AxisTitles(
                      sideTitles: SideTitles(
                        showTitles: true,
                        getTitlesWidget: (value, meta) {
                          const days = [
                            'Sun',
                            'Mon',
                            'Tue',
                            'Wed',
                            'Thu',
                            'Fri',
                            'Sat',
                          ];
                          final index = value.toInt();
                          if (index >= 0 && index < days.length) {
                            return Text(
                              days[index],
                              style: const TextStyle(fontSize: 10),
                            );
                          }
                          return const Text('');
                        },
                      ),
                    ),
                    topTitles: AxisTitles(
                      sideTitles: SideTitles(showTitles: false),
                    ),
                    rightTitles: AxisTitles(
                      sideTitles: SideTitles(showTitles: false),
                    ),
                  ),
                  lineBarsData: [
                    LineChartBarData(
                      spots:
                          weeklyData
                              .asMap()
                              .entries
                              .map(
                                (e) => FlSpot(
                                  e.key.toDouble(),
                                  e.value.toDouble(),
                                ),
                              )
                              .toList(),
                      isCurved: true,
                      barWidth: 3,
                      color: Colors.blue.shade700,
                      dotData: FlDotData(
                        show: true,
                        getDotPainter: (spot, percent, barData, index) {
                          return FlDotCirclePainter(
                            radius: 4,
                            color: Colors.blue.shade700,
                            strokeWidth: 2,
                            strokeColor: Colors.white,
                          );
                        },
                      ),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 8),
            const Text(
              "Appointments this week",
              style: TextStyle(fontSize: 12, color: Colors.grey),
            ),
          ],
        ),
      ),
    );
  }

  List<int> _generateWeeklyData(List<QueryDocumentSnapshot> appointments) {
    final now = DateTime.now();
    final startOfWeek = now.subtract(Duration(days: now.weekday % 7));
    final weeklyData = List<int>.filled(7, 0);

    for (var doc in appointments) {
      final data = doc.data() as Map<String, dynamic>;
      final appointmentDate = (data['startTime'] as Timestamp).toDate();

      if (appointmentDate.isAfter(startOfWeek) &&
          appointmentDate.isBefore(startOfWeek.add(const Duration(days: 7)))) {
        final dayIndex = appointmentDate.weekday % 7;
        weeklyData[dayIndex]++;
      }
    }

    return weeklyData;
  }

  String _formatDate(DateTime date) {
    const months = [
      'Jan',
      'Feb',
      'Mar',
      'Apr',
      'May',
      'Jun',
      'Jul',
      'Aug',
      'Sep',
      'Oct',
      'Nov',
      'Dec',
    ];
    const days = ['Sun', 'Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat'];
    return '${days[date.weekday % 7]}, ${date.day} ${months[date.month - 1]}';
  }
}
