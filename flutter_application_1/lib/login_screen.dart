import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';

class LoginScreen extends StatefulWidget {
  @override
  _LoginScreenState createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();

  Future<void> login() async {
    final email = _emailController.text.trim();
    final password = _passwordController.text.trim();

    if (email.isEmpty || password.isEmpty) {
      _showError("יש למלא גם אימייל וגם סיסמה");
      return;
    }

    try {
      final response = await http.post(
        Uri.parse('http://10.0.0.10:5000/login'),
        headers: {"Content-Type": "application/json"},
        body: jsonEncode({
          "email": email,
          "password": password,
        }),
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        print('🔹 תגובת השרת: $data');

        if (data['role'] == 'admin') {
          Navigator.pushReplacementNamed(context, '/admin_dashboard', arguments: {
            "user_id": data['user_id'],
            "name": data['name'],
            "email": data['email'],
            "phone": data['phone'],
          });
        } else {
          Navigator.pushReplacementNamed(context, '/dashboard', arguments: {
            "user_id": data['user_id'],
            "role": data['role'],
            "name": data['name'],
            "email": data['email'],
            "phone": data['phone'],
            "status": data['status'],
          });
        }
      } else {
        final errorData = jsonDecode(response.body);
        _showError(errorData["message"] ?? 'שגיאת שרת: ${response.statusCode}');
      }
    } catch (e) {
      _showError('שגיאת חיבור לשרת: $e');
    }
  }

  void _showError(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message, style: TextStyle(color: Colors.white)),
        backgroundColor: Colors.red,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        decoration: const BoxDecoration(
          image: DecorationImage(
            image: AssetImage("assets/images/cta-bg.jpg"),
            fit: BoxFit.cover,
          ),
        ),
        child: Center(
          child: Card(
            elevation: 12,
            color: Colors.white.withOpacity(0.9), // שקיפות לקופסה
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
            margin: const EdgeInsets.symmetric(horizontal: 24),
            child: Padding(
              padding: const EdgeInsets.all(24.0),
              child: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text('התחברות',
                        style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold, color: Colors.teal)),
                    SizedBox(height: 24),
                    TextField(
                      controller: _emailController,
                      decoration: InputDecoration(
                        labelText: 'אימייל',
                        border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                        prefixIcon: Icon(Icons.email),
                      ),
                      keyboardType: TextInputType.emailAddress,
                    ),
                    SizedBox(height: 16),
                    TextField(
                      controller: _passwordController,
                      decoration: InputDecoration(
                        labelText: 'סיסמה',
                        border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                        prefixIcon: Icon(Icons.lock),
                      ),
                      obscureText: true,
                    ),
                    SizedBox(height: 24),
                    ElevatedButton(
                      onPressed: login,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.teal,
                        minimumSize: Size(double.infinity, 50),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                      child: Text('התחבר', style: TextStyle(fontSize: 18)),
                    ),
                    SizedBox(height: 20),
                    TextButton(
                      onPressed: () {
                        Navigator.pushNamed(context, '/register');
                      },
                      child: Text(
                        'עדיין אין לך חשבון? הירשם כאן!',
                        style: TextStyle(color: Colors.black87, fontSize: 16),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
