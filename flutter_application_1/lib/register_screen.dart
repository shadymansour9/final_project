import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';

class RegisterScreen extends StatefulWidget {
  @override
  _RegisterScreenState createState() => _RegisterScreenState();
}

class _RegisterScreenState extends State<RegisterScreen> {
  final TextEditingController _nameController = TextEditingController();
  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _phoneController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();

  String selectedRole = 'student'; // ברירת מחדל
  bool _loading = false;

  /// בדיקת אימייל
  bool isValidEmail(String email) {
    final emailRegExp = RegExp(r'^[\w-\.]+@([\w-]+\.)+[\w-]{2,4}$');
    return emailRegExp.hasMatch(email);
  }

  /// בדיקת טלפון (רק מספרים, באורך 9-10)
  bool isValidPhone(String phone) {
    final phoneRegExp = RegExp(r'^\d{9,10}$');
    return phoneRegExp.hasMatch(phone);
  }

  /// בדיקת סיסמה (לפחות 6 תווים)
  bool isValidPassword(String password) {
    return password.length >= 6;
  }

  void _showError(String msg) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(msg)),
    );
  }

  Future<void> register() async {
    final name = _nameController.text.trim();
    final email = _emailController.text.trim();
    final phone = _phoneController.text.trim();
    final password = _passwordController.text;

    if (name.isEmpty || email.isEmpty || phone.isEmpty || password.isEmpty) {
      _showError("אנא מלא את כל השדות");
      return;
    }

    if (!isValidEmail(email)) {
      _showError("כתובת אימייל לא תקינה");
      return;
    }

    if (!isValidPhone(phone)) {
      _showError("מספר טלפון לא תקין");
      return;
    }

    if (!isValidPassword(password)) {
      _showError("הסיסמה צריכה להכיל לפחות 6 תווים");
      return;
    }

    setState(() => _loading = true);

    try {
      final response = await http.post(
        Uri.parse('http://10.0.0.10:5000/register'),
        headers: {"Content-Type": "application/json"},
        body: jsonEncode({
          "name": name,
          "email": email,
          "phone": phone,
          "password": password,
          "role": selectedRole,
        }),
      );

      final data = jsonDecode(response.body);

      if (response.statusCode == 201) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('✅ נרשמת בהצלחה!')),
        );
        Navigator.pushReplacementNamed(context, '/');
      } else {
        _showError(data['message'] ?? "שגיאה בהרשמה");
      }
    } catch (e) {
      _showError("שגיאת חיבור: $e");
    } finally {
      setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text('הרשמה')),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            TextField(controller: _nameController, decoration: InputDecoration(labelText: 'שם מלא')),
            TextField(controller: _emailController, decoration: InputDecoration(labelText: 'אימייל')),
            TextField(controller: _phoneController, decoration: InputDecoration(labelText: 'טלפון')),
            TextField(controller: _passwordController, decoration: InputDecoration(labelText: 'סיסמה'), obscureText: true),

            SizedBox(height: 10),
            DropdownButtonFormField<String>(
              value: selectedRole,
              items: ['admin', 'lecturer', 'visitor', 'student'].map((String role) {
                return DropdownMenuItem<String>(
                  value: role,
                  child: Text(role),
                );
              }).toList(),
              onChanged: (String? newValue) {
                setState(() {
                  selectedRole = newValue!;
                });
              },
              decoration: InputDecoration(labelText: 'בחר תפקיד'),
            ),

            SizedBox(height: 20),
            _loading
                ? CircularProgressIndicator()
                : ElevatedButton(onPressed: register, child: Text('הירשם')),
          ],
        ),
      ),
    );
  }
}
