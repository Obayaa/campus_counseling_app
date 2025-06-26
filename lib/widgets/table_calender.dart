import 'package:flutter/material.dart';
import 'package:table_calendar/table_calendar.dart';

class CustomCalendar extends StatelessWidget {
  final DateTime selectedDate;
  final Function(DateTime) onDateSelected;
  final List<DateTime> appointmentDates;

  const CustomCalendar({
    super.key,
    required this.selectedDate,
    required this.onDateSelected,
    required this.appointmentDates,
  });

  bool _hasAppointment(DateTime day) {
    return appointmentDates.any(
      (d) => d.year == day.year && d.month == day.month && d.day == day.day,
    );
  }

  @override
  Widget build(BuildContext context) {
    return TableCalendar(
      focusedDay: selectedDate,
      firstDay: DateTime.now(),
      lastDay: DateTime.now().add(const Duration(days: 60)),
      selectedDayPredicate: (day) => isSameDay(selectedDate, day),
      onDaySelected: (selectedDay, focusedDay) => onDateSelected(selectedDay),
      calendarBuilders: CalendarBuilders(
        defaultBuilder: (context, day, focusedDay) {
          if (_hasAppointment(day)) {
            return Container(
              margin: const EdgeInsets.all(6.0),
              decoration: BoxDecoration(
                color: Colors.greenAccent.withOpacity(0.6),
                shape: BoxShape.circle,
              ),
              alignment: Alignment.center,
              child: Text(
                '${day.day}',
                style: const TextStyle(color: Colors.black),
              ),
            );
          }
          return null;
        },
      ),
      calendarStyle: CalendarStyle(
        selectedDecoration: BoxDecoration(
          color: Colors.blueAccent,
          shape: BoxShape.circle,
        ),
        todayDecoration: BoxDecoration(
          color: Colors.orangeAccent,
          shape: BoxShape.circle,
        ),
        weekendTextStyle: const TextStyle(color: Colors.red),
        selectedTextStyle: const TextStyle(color: Colors.white),
      ),
      headerStyle: const HeaderStyle(
        titleCentered: true,
        formatButtonVisible: false,
      ),
    );
  }
}
