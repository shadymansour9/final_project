import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';

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

    final response = await http.get(Uri.parse("http://10.0.0.10:5000/users"));

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
      Uri.parse("http://10.0.0.10:5000/update_user_status"),
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

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text("ניהול משתמשים")),
      body: loading
          ? Center(child: CircularProgressIndicator())
          : ListView.builder(
              itemCount: users.length,
              itemBuilder: (context, index) {
                final user = users[index];
                final status = user['status']?.toLowerCase() ?? 'active';

                return Card(
                  child: ListTile(
                    title: Text(user['name']),
                    subtitle: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text("אימייל: ${user['email']}"),
                        if (user.containsKey('phone'))
                          Text("טלפון: ${user['phone']}"),
                      ],
                    ),
                    trailing: ElevatedButton(
                      style: ElevatedButton.styleFrom(
                        backgroundColor:
                            status == 'active' ? Colors.red : Colors.green,
                      ),
                      onPressed: () => toggleUserStatus(user['id'], status),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(status == 'active'
                              ? Icons.block
                              : Icons.lock_open,
                              color: Colors.white),
                          SizedBox(width: 6),
                          Text(
                            status == 'active' ? "חסום" : "בטל חסימה",
                            style: TextStyle(color: Colors.white),
                          ),
                        ],
                      ),
                    ),
                  ),
                );
              },
            ),
    );
  }
}
