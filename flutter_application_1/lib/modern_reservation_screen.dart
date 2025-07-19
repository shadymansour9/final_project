import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:intl/intl.dart';

class ModernReservationScreen extends StatefulWidget {
  final int userId;
  const ModernReservationScreen({Key? key, required this.userId}) : super(key: key);

  @override
  State<ModernReservationScreen> createState() => _ModernReservationScreenState();
}

class _ModernReservationScreenState extends State<ModernReservationScreen> {
  DateTime selectedDate = DateTime.now();
  TimeOfDay? startTime;
  TimeOfDay? endTime;
  List<dynamic> availableSpots = [];
  bool isLoading = false;

  Future<void> fetchAvailableSpots() async {
    if (startTime == null || endTime == null) return;

    DateTime start = DateTime(selectedDate.year, selectedDate.month, selectedDate.day, startTime!.hour, startTime!.minute);
    DateTime end = DateTime(selectedDate.year, selectedDate.month, selectedDate.day, endTime!.hour, endTime!.minute);

    final response = await http.post(
      Uri.parse('http://localhost:5000/available_spots_range'),
      headers: {"Content-Type": "application/json"},
      body: jsonEncode({
        "start_time": start.toIso8601String(),
        "end_time": end.toIso8601String(),
        "user_id": widget.userId,
      }),
    );

    if (response.statusCode == 200) {
      final data = jsonDecode(response.body);
      setState(() {
        availableSpots = data['parking_spots'];
      });
    } else {
      setState(() {
        availableSpots = [];
      });
    }
  }

  Future<void> reserveSpot(int spotId) async {
    if (startTime == null || endTime == null) return;

    DateTime now = DateTime.now();
    DateTime start = DateTime(selectedDate.year, selectedDate.month, selectedDate.day, startTime!.hour, startTime!.minute);
    DateTime end = DateTime(selectedDate.year, selectedDate.month, selectedDate.day, endTime!.hour, endTime!.minute);

    if (start.isBefore(now)) {
      _show("❌ לא ניתן להזמין לשעה שכבר עברה");
      return;
    }
    if (end.isBefore(start)) {
      _show("❌ שעת הסיום צריכה להיות אחרי שעת ההתחלה");
      return;
    }

    final response = await http.post(
      Uri.parse('http://localhost:5000/add_reservation'),
      headers: {"Content-Type": "application/json"},
      body: jsonEncode({
        "user_id": widget.userId,
        "spot_id": spotId,
        "start_time": start.toIso8601String(),
        "end_time": end.toIso8601String(),
      }),
    );

    if (response.statusCode == 201) {
      _show("✅ ההזמנה נוספה!");
      fetchAvailableSpots();
    } else {
      final msg = jsonDecode(response.body)['message'];
      _show("❌ $msg");
    }
  }
void _show(String msg) {
  showDialog(
    context: context,
    builder: (context) => AlertDialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
      backgroundColor: Colors.white, // רקע לבהירות (תוכל לשנות)
      title: const Text(
        "שימו לב",
        style: TextStyle(
          color: Colors.black,
          fontWeight: FontWeight.bold,
        ),
      ),
      content: Row(
        children: [
          const Icon(Icons.error_outline, color: Colors.red),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              msg,
              style: TextStyle(color: Colors.black87, fontSize: 16),
            ),
          ),
        ],
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text(
            "סגור",
            style: TextStyle(color: Colors.teal, fontWeight: FontWeight.bold),
          ),
        ),
      ],
    ),
  );
}



  Future<void> pickDate() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: selectedDate,
      firstDate: DateTime.now(),
      lastDate: DateTime.now().add(Duration(days: 7)),
      locale: Locale('he', 'IL'),
    );
    if (picked != null) {
      setState(() => selectedDate = picked);
      fetchAvailableSpots();
    }
  }

  Future<void> pickTime({required bool isStart}) async {
    final picked = await showTimePicker(
      context: context,
      initialTime: isStart ? TimeOfDay(hour: 8, minute: 0) : TimeOfDay(hour: 9, minute: 0),
    );

    if (picked != null) {
      setState(() {
        if (isStart) {
          startTime = picked;
        } else {
          endTime = picked;
        }
      });
      fetchAvailableSpots();
    }
  }

  String formatTime(TimeOfDay time) => time.format(context);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text("הזמנת חניה"), backgroundColor: Colors.teal),
      body: Stack(
        children: [
          Positioned.fill(child: Image.asset("assets/images/cta-bg.jpg", fit: BoxFit.cover)),
          Container(color: Colors.black.withOpacity(0.4)),
          Center(
            child: ClipRRect(
              borderRadius: BorderRadius.circular(20),
              child: BackdropFilter(
                filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
                child: Container(
                  padding: EdgeInsets.all(20),
                  margin: EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: Colors.white.withOpacity(0.15),
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(color: Colors.white.withOpacity(0.3)),
                  ),
                  child: Column(
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                        children: [
                          ElevatedButton(onPressed: pickDate, child: Text(DateFormat('dd/MM/yyyy').format(selectedDate))),
                          ElevatedButton(onPressed: () => pickTime(isStart: true), child: Text(startTime != null ? "מ ${formatTime(startTime!)}" : "בחר התחלה")),
                          ElevatedButton(onPressed: () => pickTime(isStart: false), child: Text(endTime != null ? "עד ${formatTime(endTime!)}" : "בחר סיום")),
                        ],
                      ),
                      const SizedBox(height: 20),
                      Expanded(
                        child: availableSpots.isEmpty
                            ? Center(child: Text("אין חניות פנויות לטווח שבחרת", style: TextStyle(color: Colors.white)))
                            : ListView.builder(
                                itemCount: availableSpots.length,
                                itemBuilder: (context, index) {
                                  final spot = availableSpots[index];
                                  return Card(
                                    color: Colors.white.withOpacity(0.8),
                                    child: ListTile(
                                      title: Text("חניה ${spot['spot_number']} - ${spot['lot_name']}"),
                                      subtitle: Text("מרחק: ${spot['distance_from_college']} מטר (${spot['distance_category']})"),
                                      trailing: ElevatedButton(
                                        onPressed: () => reserveSpot(spot['id']),
                                        child: Text("הזמן"),
                                      ),
                                    ),
                                  );
                                },
                              ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
