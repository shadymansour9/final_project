import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:intl/intl.dart';

class MyReservationsScreen extends StatefulWidget {
  final int userId;

  const MyReservationsScreen({Key? key, required this.userId}) : super(key: key);

  @override
  _MyReservationsScreenState createState() => _MyReservationsScreenState();
}

class _MyReservationsScreenState extends State<MyReservationsScreen> {
  List<dynamic> reservations = [];

  @override
  void initState() {
    super.initState();
    fetchReservations();
  }

  String formatDate(String input) {
    try {
      final dt = DateTime.parse(input);
      return DateFormat('dd/MM/yyyy HH:mm').format(dt);
    } catch (e) {
      return input;
    }
  }

  Future<void> fetchReservations() async {
    try {
      final response = await http.get(
        Uri.parse('http://localhost:5000/my_reservations/${widget.userId}'),
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        setState(() {
          reservations = data['reservations'];
        });
      } else {
        setState(() => reservations = []);
      }
    } catch (e) {
      setState(() => reservations = []);
    }
  }

  Future<void> cancelReservation(int reservationId) async {
    try {
      final response = await http.post(
        Uri.parse('http://localhost:5000/cancel_reservation'),
        headers: {"Content-Type": "application/json"},
        body: jsonEncode({"reservation_id": reservationId}),
      );

      if (response.statusCode == 200) {
        _show("✅ ההזמנה בוטלה");
        fetchReservations();
      } else {
        _show("❌ שגיאה בביטול ההזמנה");
      }
    } catch (e) {
      _show("❌ שגיאה בביטול ההזמנה");
    }
  }

  Future<void> confirmArrival(int reservationId) async {
    try {
      final response = await http.post(
        Uri.parse('http://localhost:5000/confirm_arrival'),
        headers: {"Content-Type": "application/json"},
        body: jsonEncode({"reservation_id": reservationId}),
      );

      if (response.statusCode == 200) {
        _show("🟢 הגעתך אושרה!");
        fetchReservations();
      } else {
        _show("❌ שגיאה באישור ההגעה");
      }
    } catch (e) {
      _show("❌ שגיאה באישור ההגעה");
    }
  }

  Future<void> showEditDialog(int reservationId) async {
    final now = DateTime.now();

    DateTime? pickedDate = await showDatePicker(
      context: context,
      initialDate: now,
      firstDate: now,
      lastDate: now.add(Duration(days: 7)),
    );
    if (pickedDate == null) return;

    TimeOfDay? newStartTime = await showTimePicker(
      context: context,
      initialTime: TimeOfDay.now(),
    );
    if (newStartTime == null) return;

    TimeOfDay? newEndTime = await showTimePicker(
      context: context,
      initialTime: TimeOfDay(hour: newStartTime.hour + 1, minute: newStartTime.minute),
    );
    if (newEndTime == null) return;

    final newStart = DateTime(pickedDate.year, pickedDate.month, pickedDate.day, newStartTime.hour, newStartTime.minute);
    final newEnd = DateTime(pickedDate.year, pickedDate.month, pickedDate.day, newEndTime.hour, newEndTime.minute);

    try {
      final response = await http.post(
        Uri.parse('http://localhost:5000/edit_reservation'),
        headers: {"Content-Type": "application/json"},
        body: jsonEncode({
          "reservation_id": reservationId,
          "start_time": newStart.toIso8601String(),
          "end_time": newEnd.toIso8601String(),
        }),
      );

      if (response.statusCode == 200) {
        _show("✅ ההזמנה עודכנה בהצלחה");
        fetchReservations();
      } else {
        _show("❌ שגיאה בעדכון ההזמנה");
      }
    } catch (e) {
      _show("❌ שגיאת רשת בעדכון ההזמנה");
    }
  }

  void _show(String msg) {
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(msg)));
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text("ההזמנות שלי"),
        backgroundColor: Colors.teal,
      ),
      body: Stack(
        children: [
          Positioned.fill(
            child: Image.asset("assets/images/cta-bg.jpg", fit: BoxFit.cover),
          ),
          Container(color: Colors.black.withOpacity(0.4)),
          reservations.isEmpty
              ? Center(child: Text("אין לך הזמנות", style: TextStyle(color: Colors.white, fontSize: 20)))
              : ListView.builder(
                  padding: EdgeInsets.all(12),
                  itemCount: reservations.length,
                  itemBuilder: (context, index) {
                    final reservation = reservations[index];
                    final isConfirmed = reservation['status'] == 'confirmed';
                    final startTime = DateTime.parse(reservation['start_time']);
                    final now = DateTime.now();
                    final canConfirm = now.isAfter(startTime.subtract(Duration(minutes: 10))) &&
                        now.isBefore(startTime.add(Duration(minutes: 10)));
                    final canEdit = startTime.difference(now) > Duration(hours: 12);

                    return ClipRRect(
                      borderRadius: BorderRadius.circular(20),
                      child: BackdropFilter(
                        filter: ImageFilter.blur(sigmaX: 8, sigmaY: 8),
                        child: Card(
                          color: Colors.white.withOpacity(0.12),
                          elevation: 6,
                          margin: EdgeInsets.symmetric(vertical: 10),
                          child: Padding(
                            padding: EdgeInsets.all(16),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text("חניה: ${reservation['spot_number']}", style: TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold)),
                                SizedBox(height: 4),
                                Text("מתאריך: ${formatDate(reservation['start_time'])}", style: TextStyle(color: Colors.white70)),
                                Text("עד תאריך: ${formatDate(reservation['end_time'])}", style: TextStyle(color: Colors.white70)),
                                Text("סטטוס: ${reservation['status']}", style: TextStyle(color: Colors.white70)),
                                SizedBox(height: 12),
                                if (isConfirmed) ...[
                                  if (canConfirm)
                                    _actionButton("אשר הגעה", Icons.check, Colors.green, () => confirmArrival(reservation['id'])),
                                  if (canEdit)
                                    _actionButton("ערוך", Icons.edit, Colors.blue, () => showEditDialog(reservation['id'])),
                                  _actionButton("בטל", Icons.cancel, Colors.red, () => cancelReservation(reservation['id'])),
                                ] else
                                  Text("⛔ לא ניתן לבצע שינויים", style: TextStyle(color: Colors.white54)),
                              ],
                            ),
                          ),
                        ),
                      ),
                    );
                  },
                ),
        ],
      ),
      bottomNavigationBar: BottomNavigationBar(
        selectedItemColor: Colors.teal,
        unselectedItemColor: Colors.grey,
        backgroundColor: Colors.white.withOpacity(0.95),
        items: const [
          BottomNavigationBarItem(icon: Icon(Icons.home), label: 'בית'),
          BottomNavigationBarItem(icon: Icon(Icons.edit), label: 'פרופיל'),
          BottomNavigationBarItem(icon: Icon(Icons.logout), label: 'יציאה'),
        ],
        onTap: (index) {
          if (index == 0) {
            Navigator.pushNamedAndRemoveUntil(context, '/dashboard', (route) => false, arguments: {
              "user_id": widget.userId,
            });
          } else if (index == 1) {
            Navigator.pushNamed(context, '/edit_profile', arguments: {
              "user_id": widget.userId,
            });
          } else if (index == 2) {
            Navigator.pushNamedAndRemoveUntil(context, '/', (route) => false);
          }
        },
      ),
    );
  }

  Widget _actionButton(String label, IconData icon, Color color, VoidCallback onPressed) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4.0),
      child: ElevatedButton.icon(
        onPressed: onPressed,
        icon: Icon(icon),
        label: Text(label),
        style: ElevatedButton.styleFrom(
          backgroundColor: color,
          foregroundColor: Colors.white,
          minimumSize: Size(double.infinity, 45),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        ),
      ),
    );
  }
}
