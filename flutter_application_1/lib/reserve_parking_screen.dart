import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:intl/intl.dart';

class ReserveParkingScreen extends StatefulWidget {
  final int userId;

  const ReserveParkingScreen({Key? key, required this.userId}) : super(key: key);

  @override
  _ReserveParkingScreenState createState() => _ReserveParkingScreenState();
}

class _ReserveParkingScreenState extends State<ReserveParkingScreen> {
  List<dynamic> parkingSpots = [];
  String userStatus = 'active';

  DateTime? selectedDate;
  TimeOfDay? selectedStartTime;
  TimeOfDay? selectedEndTime;

  @override
  void initState() {
    super.initState();
    fetchUserStatus().then((_) => fetchAvailableSpots());
  }

  Future<void> fetchUserStatus() async {
    final url = Uri.parse('http:/10.0.0.10:5000//users');
    try {
      final response = await http.get(url);
      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        final user = data['users'].firstWhere((u) => u['id'] == widget.userId, orElse: () => null);
        if (user != null) {
          setState(() {
            userStatus = user['status'];
          });
        }
      }
    } catch (e) {
      print("\u274C שגיאה בשליפת סטטוס: $e");
    }
  }

  Future<void> fetchAvailableSpots() async {
    final url = Uri.parse('http://10.0.0.10:5000/available_spots');
    try {
      final response = await http.get(url);
      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        List<dynamic> allSpots = data['parking_spots'];

        if (userStatus == 'blocked') {
          allSpots = allSpots.where((spot) => spot['distance_category'] == 'רחוק').toList();
        }

        setState(() {
          parkingSpots = allSpots;
        });
      } else {
        setState(() => parkingSpots = []);
      }
    } catch (e) {
      print("\u274C שגיאה: $e");
    }
  }

  Future<void> _pickDate(BuildContext context) async {
    final now = DateTime.now();
    final sunday = now.subtract(Duration(days: now.weekday % 7));
    final saturday = sunday.add(Duration(days: 6));

    final picked = await showDatePicker(
      context: context,
      initialDate: now,
      firstDate: sunday,
      lastDate: saturday,
      locale: const Locale('he', 'IL'),
    );

    if (picked != null) {
      setState(() {
        selectedDate = picked;
      });
    }
  }

  Future<void> _pickStartTime(BuildContext context) async {
    final picked = await showTimePicker(
      context: context,
      initialTime: TimeOfDay.now(),
    );
    if (picked != null) {
      setState(() {
        selectedStartTime = picked;
      });
    }
  }

  Future<void> _pickEndTime(BuildContext context) async {
    final picked = await showTimePicker(
      context: context,
      initialTime: TimeOfDay.now().replacing(hour: TimeOfDay.now().hour + 1),
    );
    if (picked != null) {
      setState(() {
        selectedEndTime = picked;
      });
    }
  }

  Future<void> reserveSpot(int spotId) async {
    if (selectedDate == null || selectedStartTime == null || selectedEndTime == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("\u26a0\ufe0f יש לבחור תאריך ושעות")),
      );
      return;
    }

    final startDateTime = DateTime(
      selectedDate!.year,
      selectedDate!.month,
      selectedDate!.day,
      selectedStartTime!.hour,
      selectedStartTime!.minute,
    );

    final endDateTime = DateTime(
      selectedDate!.year,
      selectedDate!.month,
      selectedDate!.day,
      selectedEndTime!.hour,
      selectedEndTime!.minute,
    );

    final url = Uri.parse('http://10.0.0.10:5000/add_reservation');
    final body = jsonEncode({
      "user_id": widget.userId,
      "spot_id": spotId,
      "start_time": startDateTime.toIso8601String(),
      "end_time": endDateTime.toIso8601String(),
    });

    try {
      final response = await http.post(
        url,
        headers: {"Content-Type": "application/json"},
        body: body,
      );

      if (response.statusCode == 201) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text("\u2705 ההזמנה בוצעה בהצלחה!")),
        );
        fetchAvailableSpots();
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text("\u274c שגיאה בהזמנה: ${response.body}")),
        );
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("\u274c שגיאה בחיבור לשרת")),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text("הזמנת חניה")),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            ElevatedButton(
              onPressed: () => _pickDate(context),
              child: Text(selectedDate == null
                  ? "בחר תאריך לשבוע זה"
                  : "תאריך: ${DateFormat('dd/MM/yyyy').format(selectedDate!)}"),
            ),
            ElevatedButton(
              onPressed: () => _pickStartTime(context),
              child: Text(selectedStartTime == null
                  ? "בחר שעת התחלה"
                  : "התחלה: ${selectedStartTime!.format(context)}"),
            ),
            ElevatedButton(
              onPressed: () => _pickEndTime(context),
              child: Text(selectedEndTime == null
                  ? "בחר שעת סיום"
                  : "סיום: ${selectedEndTime!.format(context)}"),
            ),
            SizedBox(height: 20),
            Expanded(
              child: parkingSpots.isEmpty
                  ? Center(child: Text("\u274c אין חניות פנויות"))
                  : ListView.builder(
                      itemCount: parkingSpots.length,
                      itemBuilder: (context, index) {
                        final spot = parkingSpots[index];
                        return Card(
                          child: ListTile(
                            title: Text("\ud83c\udd39 חניה ${spot['spot_number']} - ${spot['lot_name']}"),
                            subtitle: Text("\ud83d\udccf מרחק: ${spot['distance_from_college']} מטר (${spot['distance_category']})"),
                            trailing: ElevatedButton(
                              onPressed: () => reserveSpot(spot['id']),
                              child: Text("\ud83d\uddd3 הזמן"),
                            ),
                          ),
                        );
                      },
                    ),
            ),
          ],
        ),
      ),
    );
  }
}
