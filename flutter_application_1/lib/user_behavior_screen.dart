import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';

class UserBehaviorScreen extends StatefulWidget {
  final int userId;

  const UserBehaviorScreen({Key? key, required this.userId}) : super(key: key);

  @override
  _UserBehaviorScreenState createState() => _UserBehaviorScreenState();
}

class _UserBehaviorScreenState extends State<UserBehaviorScreen> {
  Map<String, dynamic>? userData;
  bool isLoading = true;
  String? error;

  @override
  void initState() {
    super.initState();
    fetchUserBehavior();
  }

  Future<void> fetchUserBehavior() async {
    final url = Uri.parse('http://localhost:5000/user_behavior/${widget.userId}');
    try {
      final response = await http.get(url);
      if (response.statusCode == 200) {
        setState(() {
          userData = json.decode(response.body);
          isLoading = false;
        });
      } else {
        setState(() {
          error = '❌ המשתמש לא נמצא או שגיאת שרת';
          isLoading = false;
        });
      }
    } catch (e) {
      setState(() {
        error = '❌ שגיאת חיבור: $e';
        isLoading = false;
      });
    }
  }

  Widget buildUserCard() {
    if (userData == null) return Text("לא נמצאו נתונים", style: TextStyle(color: Colors.white));

    return ClipRRect(
      borderRadius: BorderRadius.circular(20),
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
        child: Container(
          padding: EdgeInsets.all(24),
          margin: EdgeInsets.all(24),
          decoration: BoxDecoration(
            color: Colors.white.withOpacity(0.1),
            borderRadius: BorderRadius.circular(20),
            border: Border.all(color: Colors.white.withOpacity(0.3)),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(Icons.person_pin_rounded, size: 60, color: Colors.white),
              SizedBox(height: 12),
              Text("שם: ${userData!['name']}", style: TextStyle(fontSize: 22, color: Colors.white, fontWeight: FontWeight.bold)),
              SizedBox(height: 8),
              Text("תפקיד: ${userData!['role']}", style: TextStyle(fontSize: 18, color: Colors.white70)),
              Text("סטטוס נוכחי: ${userData!['status_now']}", style: TextStyle(fontSize: 18, color: Colors.white70)),
              Text("ציון התנהגות: ${userData!['grade']}", style: TextStyle(fontSize: 18, color: Colors.tealAccent)),
            ],
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text("התנהגות משתמש"),
        backgroundColor: Colors.teal,
      ),
      body: Stack(
        children: [
          Positioned.fill(child: Image.asset("assets/images/cta-bg.jpg", fit: BoxFit.cover)),
          Container(color: Colors.black.withOpacity(0.4)),
          Center(
            child: isLoading
                ? CircularProgressIndicator()
                : error != null
                    ? Text(error!, style: TextStyle(color: Colors.white, fontSize: 18))
                    : buildUserCard(),
          ),
        ],
      ),
    );
  }
}
