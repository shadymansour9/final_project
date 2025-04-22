import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';

class ViewUserReservationsScreen extends StatefulWidget {
  @override
  _ViewUserReservationsScreenState createState() => _ViewUserReservationsScreenState();
}

class _ViewUserReservationsScreenState extends State<ViewUserReservationsScreen> {
  List<dynamic> users = [];
  int? selectedUserId;
  List<dynamic> reservations = [];
  bool loading = false;

  @override
  void initState() {
    super.initState();
    fetchAllUsers();
  }

  /// שליפת כל המשתמשים למנהל
  Future<void> fetchAllUsers() async {
    final response = await http.get(Uri.parse("http://10.0.0.10:5000/users"));

    if (response.statusCode == 200) {
      final data = jsonDecode(response.body);
      setState(() {
        users = data['users'];
      });
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("❌ שגיאה בטעינת משתמשים")),
      );
    }
  }

  /// שליפת ההזמנות של משתמש לפי מזהה
  Future<void> fetchUserReservations(int userId) async {
    setState(() {
      loading = true;
      reservations = [];
    });

    final response = await http.get(
      Uri.parse("http://10.0.0.10:5000/my_reservations/$userId"),
    );

    if (response.statusCode == 200) {
      final data = jsonDecode(response.body);
      setState(() {
        reservations = data['reservations'];
      });
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("❌ לא נמצאו הזמנות למשתמש הזה")),
      );
    }

    setState(() {
      loading = false;
    });
  }

  /// ביטול הזמנה
  Future<void> cancelReservation(int reservationId) async {
    final response = await http.post(
      Uri.parse('http://10.0.0.10:5000/cancel_reservation'),
      headers: {"Content-Type": "application/json"},
      body: jsonEncode({"reservation_id": reservationId}),
    );

    if (response.statusCode == 200) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("✅ ההזמנה בוטלה בהצלחה")),
      );
      if (selectedUserId != null) {
        fetchUserReservations(selectedUserId!);
      }
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("❌ שגיאה בביטול ההזמנה")),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text("ניהול הזמנות לפי משתמש")),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            DropdownButtonFormField<int>(
              value: selectedUserId,
              decoration: InputDecoration(
                labelText: "בחר משתמש",
                border: OutlineInputBorder(),
              ),
              items: users.map<DropdownMenuItem<int>>((user) {
                return DropdownMenuItem<int>(
                  value: user['id'],
                  child: Text("${user['name']} (${user['email']})"),
                );
              }).toList(),
              onChanged: (value) {
                setState(() {
                  selectedUserId = value;
                });
                if (value != null) {
                  fetchUserReservations(value);
                }
              },
            ),
            const SizedBox(height: 16),
            loading
                ? const CircularProgressIndicator()
                : Expanded(
                    child: reservations.isEmpty
                        ? const Text("אין הזמנות להצגה")
                        : ListView.builder(
                            itemCount: reservations.length,
                            itemBuilder: (context, index) {
                              final res = reservations[index];
                              return Card(
                                child: ListTile(
                                  title: Text("חניה: ${res['spot_number']}"),
                                  subtitle: Text(
                                    "מ: ${res['start_time']}\n"
                                    "עד: ${res['end_time']}\n"
                                    "סטטוס: ${res['status']}",
                                  ),
                                  trailing: res['status'] == 'confirmed'
                                      ? ElevatedButton(
                                          onPressed: () => cancelReservation(res['id']),
                                          style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
                                          child: const Text("בטל", style: TextStyle(color: Colors.white)),
                                        )
                                      : const Text("בוטלה", style: TextStyle(color: Colors.grey)),
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
