import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';

class ViewUserReservationsScreen extends StatefulWidget {
  @override
  _ViewUserReservationsScreenState createState() => _ViewUserReservationsScreenState();
}

class _ViewUserReservationsScreenState extends State<ViewUserReservationsScreen> {
  List<dynamic> users = [];
  List<dynamic> filteredUsers = [];
  int? selectedUserId;
  List<dynamic> reservations = [];
  bool loading = false;
  final TextEditingController _searchController = TextEditingController();

  @override
  void initState() {
    super.initState();
    fetchAllUsers();
  }

  Future<void> fetchAllUsers() async {
    final response = await http.get(Uri.parse("http://localhost:5000/users"));
    if (response.statusCode == 200) {
      final data = jsonDecode(response.body);
      setState(() {
        users = data['users'];
        filteredUsers = users;
      });
    } else {
      _showError("❌ שגיאה בטעינת משתמשים");
    }
  }

  void _filterUsers(String query) {
    final lowerQuery = query.toLowerCase();
    setState(() {
      filteredUsers = users.where((user) {
        final name = user['name'].toLowerCase();
        final email = user['email'].toLowerCase();
        return name.contains(lowerQuery) || email.contains(lowerQuery);
      }).toList();
    });
  }

  Future<void> fetchUserReservations(int userId) async {
    setState(() {
      loading = true;
      reservations = [];
      selectedUserId = userId;
    });

    final response = await http.get(Uri.parse("http://localhost:5000/my_reservations/$userId"));
    if (response.statusCode == 200) {
      final data = jsonDecode(response.body);
      setState(() {
        reservations = data['reservations'];
      });
    } else {
      _showError("❌ לא נמצאו הזמנות למשתמש הזה");
    }

    setState(() => loading = false);
  }

  Future<void> cancelReservation(int reservationId) async {
    final response = await http.post(
      Uri.parse('http://localhost:5000/cancel_reservation'),
      headers: {"Content-Type": "application/json"},
      body: jsonEncode({"reservation_id": reservationId}),
    );

    if (response.statusCode == 200) {
      _showMessage("✅ ההזמנה בוטלה בהצלחה");
      if (selectedUserId != null) {
        fetchUserReservations(selectedUserId!);
      }
    } else {
      _showError("❌ שגיאה בביטול ההזמנה");
    }
  }

  void _showMessage(String msg) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(msg)),
    );
  }

  void _showError(String msg) {
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text("שגיאה"),
        content: Text(msg),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text("סגור"),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("ניהול הזמנות לפי משתמש"), backgroundColor: Colors.teal),
      body: Stack(
        children: [
          Positioned.fill(child: Image.asset("assets/images/cta-bg.jpg", fit: BoxFit.cover)),
          Container(color: Colors.black.withOpacity(0.4)),
          Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              children: [
                TextField(
                  controller: _searchController,
                  onChanged: _filterUsers,
                  style: const TextStyle(color: Colors.white),
                  decoration: InputDecoration(
                    hintText: 'חפש לפי שם או אימייל...',
                    hintStyle: const TextStyle(color: Colors.white70),
                    prefixIcon: const Icon(Icons.search, color: Colors.white),
                    filled: true,
                    fillColor: Colors.white.withOpacity(0.1),
                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                  ),
                ),
                const SizedBox(height: 12),
                Expanded(
                  child: filteredUsers.isEmpty
                      ? const Center(child: Text("לא נמצאו משתמשים", style: TextStyle(color: Colors.white)))
                      : ListView.builder(
                          itemCount: filteredUsers.length,
                          itemBuilder: (context, index) {
                            final user = filteredUsers[index];
                            return Card(
                              color: Colors.white.withOpacity(0.8),
                              child: ListTile(
                                title: Text("${user['name']} (${user['email']})"),
                                trailing: ElevatedButton(
                                  onPressed: () => fetchUserReservations(user['id']),
                                  style: ElevatedButton.styleFrom(backgroundColor: Colors.teal),
                                  child: const Text("הצג הזמנות"),
                                ),
                              ),
                            );
                          },
                        ),
                ),
                if (selectedUserId != null) const SizedBox(height: 16),
                if (selectedUserId != null)
                  loading
                      ? const CircularProgressIndicator()
                      : Expanded(
                          child: reservations.isEmpty
                              ? const Center(child: Text("אין הזמנות להצגה", style: TextStyle(color: Colors.white)))
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
        ],
      ),
    );
  }
}
