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

  /// פונקציית עזר לעיצוב תאריך
  String formatDate(String input) {
    try {
      final dt = DateTime.parse(input);
      return DateFormat('dd/MM/yyyy HH:mm').format(dt);
    } catch (e) {
      return input;
    }
  }

  /// שליפת ההזמנות מהשרת
  Future<void> fetchReservations() async {
    try {
      final response = await http.get(
        Uri.parse('http://10.0.0.10:5000/my_reservations/${widget.userId}')
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        setState(() {
          reservations = data['reservations'];
        });
      } else {
        setState(() {
          reservations = [];
        });
      }
    } catch (e) {
      print("❌ שגיאה בשליפת ההזמנות: $e");
      setState(() {
        reservations = [];
      });
    }
  }

  /// ביטול הזמנה
  Future<void> cancelReservation(int reservationId) async {
    try {
      final response = await http.post(
        Uri.parse('http://10.0.0.10:5000/cancel_reservation'),
        headers: {"Content-Type": "application/json"},
        body: jsonEncode({"reservation_id": reservationId}),
      );

      if (response.statusCode == 200) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text("✅ ההזמנה בוטלה והחניה זמינה מחדש!"))
        );
        fetchReservations();
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text("❌ שגיאה בביטול ההזמנה"))
        );
      }
    } catch (e) {
      print("❌ שגיאה בביטול ההזמנה: $e");
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("❌ שגיאה בביטול ההזמנה"))
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text("ההזמנות שלי")),
      body: reservations.isEmpty
          ? Center(child: Text("אין לך הזמנות"))
          : ListView.builder(
              itemCount: reservations.length,
              itemBuilder: (context, index) {
                final reservation = reservations[index];
                return Card(
                  child: ListTile(
                    title: Text("חניה ${reservation['spot_number']}"),
                    subtitle: Text(
                      "מתאריך: ${formatDate(reservation['start_time'])}\n"
                      "עד: ${formatDate(reservation['end_time'])}\n"
                      "סטטוס: ${reservation['status']}"
                    ),
                    trailing: reservation['status'] == 'confirmed'
                        ? ElevatedButton(
                            onPressed: () => cancelReservation(reservation['id']),
                            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
                            child: Text("בטל", style: TextStyle(color: Colors.white)),
                          )
                        : Text("🔒 לא ניתן לבטל", style: TextStyle(color: Colors.grey)),
                  ),
                );
              },
            ),
    );
  }
}
