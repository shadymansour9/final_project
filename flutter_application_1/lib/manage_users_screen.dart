import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'user_behavior_screen.dart';

class ManageUsersScreen extends StatefulWidget {
  @override
  _ManageUsersScreenState createState() => _ManageUsersScreenState();
}

class _ManageUsersScreenState extends State<ManageUsersScreen> {
  List<dynamic> users = [];
  bool loading = false;

  @override
  void initState() {
    super.initState();
    fetchUsers();
  }

  Future<void> fetchUsers() async {
    setState(() => loading = true);
    final response = await http.get(Uri.parse("http://localhost:5000/users"));

    if (response.statusCode == 200) {
      final data = jsonDecode(response.body);
      setState(() {
        users = data['users'];
        loading = false;
      });
    } else {
      setState(() => loading = false);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("❌ שגיאה בטעינת משתמשים")),
      );
    }
  }

  Future<void> toggleUserStatus(int userId, String currentStatus) async {
    final newStatus = currentStatus == 'active' ? 'blocked' : 'active';

    final response = await http.post(
      Uri.parse("http://localhost:5000/update_user_status"),
      headers: {"Content-Type": "application/json"},
      body: jsonEncode({"user_id": userId, "status": newStatus}),
    );

    if (response.statusCode == 200) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("🟢 סטטוס עודכן ל: $newStatus")),
      );
      fetchUsers();
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("❌ שגיאה בעדכון סטטוס")),
      );
    }
  }

  Future<void> resetOverride(int userId) async {
    final response = await http.post(
      Uri.parse("http://localhost:5000/reset_override"),
      headers: {"Content-Type": "application/json"},
      body: jsonEncode({"user_id": userId}),
    );

    if (response.statusCode == 200) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("🔄 השליטה הידנית אופסה")),
      );
      fetchUsers();
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("❌ שגיאה באיפוס override")),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text("ניהול משתמשים"), backgroundColor: Colors.teal),
      body: Stack(
        children: [
          Positioned.fill(
            child: Image.asset("assets/images/cta-bg.jpg", fit: BoxFit.cover),
          ),
          Container(color: Colors.black.withOpacity(0.4)),
          loading
              ? Center(child: CircularProgressIndicator())
              : ListView.builder(
                  padding: EdgeInsets.all(12),
                  itemCount: users.length,
                  itemBuilder: (context, index) {
                    final user = users[index];
                    final status = user['status']?.toLowerCase() ?? 'active';
                    final isForceOverride = user['force_status_override'] == true;
                    final isBlocked = status == 'blocked';

                    return ClipRRect(
                      borderRadius: BorderRadius.circular(20),
                      child: BackdropFilter(
                        filter: ImageFilter.blur(sigmaX: 8, sigmaY: 8),
                        child: Card(
                          color: Colors.white.withOpacity(0.15),
                          elevation: 6,
                          margin: EdgeInsets.symmetric(vertical: 8),
                          child: ListTile(
                            title: Text(
                              user['name'],
                              style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
                            ),
                            subtitle: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text("📧 ${user['email']}", style: TextStyle(color: Colors.white70)),
                                if (user.containsKey('phone'))
                                  Text("📱 ${user['phone']}", style: TextStyle(color: Colors.white70)),
                              ],
                            ),
                            trailing: Wrap(
                              direction: Axis.vertical,
                              spacing: 6,
                              children: [
                                ElevatedButton.icon(
                                  onPressed: () => toggleUserStatus(user['id'], status),
                                  icon: Icon(
                                    isBlocked ? Icons.lock_open : Icons.block,
                                    size: 18,
                                  ),
                                  label: Text(
                                    isBlocked
                                        ? (isForceOverride ? "בטל חסימה" : "שחרור אוטומטי")
                                        : "חסום",
                                    style: TextStyle(fontSize: 13),
                                  ),
                                  style: ElevatedButton.styleFrom(
                                    backgroundColor: isBlocked ? Colors.green : Colors.red,
                                    minimumSize: Size(100, 35),
                                  ),
                                ),
                                if (isForceOverride)
                                  OutlinedButton.icon(
                                    onPressed: () => resetOverride(user['id']),
                                    icon: Icon(Icons.refresh, color: Colors.amber),
                                    label: Text(
                                      "איפוס ידני",
                                      style: TextStyle(fontSize: 13, color: Colors.amber),
                                    ),
                                  ),
                                OutlinedButton.icon(
                                  onPressed: () => Navigator.push(
                                    context,
                                    MaterialPageRoute(
                                      builder: (_) => UserBehaviorScreen(userId: user['id']),
                                    ),
                                  ),
                                  icon: Icon(Icons.analytics, color: Colors.blue),
                                  label: Text(
                                    "דירוג",
                                    style: TextStyle(fontSize: 13, color: Colors.blue),
                                  ),
                                ),
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
    );
  }
}
