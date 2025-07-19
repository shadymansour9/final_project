import 'dart:ui';
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

  String selectedRole = 'student';
  bool _loading = false;

  bool isValidEmail(String email) => RegExp(r'^[\w-\.]+@([\w-]+\.)+[\w-]{2,4}$').hasMatch(email);
  bool isValidPhone(String phone) => RegExp(r'^\d{9,10}$').hasMatch(phone);
  bool isValidPassword(String password) => password.length >= 6;

  void _showError(String msg) {
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(msg)));
  }

  Future<void> register() async {
    final name = _nameController.text.trim();
    final email = _emailController.text.trim();
    final phone = _phoneController.text.trim();
    final password = _passwordController.text;

    if (name.isEmpty || email.isEmpty || phone.isEmpty || password.isEmpty) return _showError("אנא מלא את כל השדות");
    if (!isValidEmail(email)) return _showError("כתובת אימייל לא תקינה");
    if (!isValidPhone(phone)) return _showError("מספר טלפון לא תקין");
    if (!isValidPassword(password)) return _showError("הסיסמה צריכה להכיל לפחות 6 תווים");

    setState(() => _loading = true);

    try {
      final response = await http.post(
        Uri.parse('http://localhost:5000/register'),
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
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('✅ נרשמת בהצלחה!')));
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

  Widget _buildTextField(TextEditingController controller, String label, {bool obscure = false, TextInputType? type}) {
    return TextField(
      controller: controller,
      obscureText: obscure,
      keyboardType: type,
      style: TextStyle(color: Colors.white),
      decoration: InputDecoration(
        labelText: label,
        labelStyle: TextStyle(color: Colors.white70),
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
        filled: true,
        fillColor: Colors.white.withOpacity(0.1),
        enabledBorder: OutlineInputBorder(borderSide: BorderSide(color: Colors.white30)),
        focusedBorder: OutlineInputBorder(borderSide: BorderSide(color: Colors.tealAccent)),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text('הרשמה'), backgroundColor: Colors.teal),
      body: Stack(
        children: [
          Positioned.fill(child: Image.asset("assets/images/cta-bg.jpg", fit: BoxFit.cover)),
          Container(color: Colors.black.withOpacity(0.4)),
          Center(
            child: ClipRRect(
              borderRadius: BorderRadius.circular(20),
              child: BackdropFilter(
                filter: ImageFilter.blur(sigmaX: 12, sigmaY: 12),
                child: Container(
                  padding: EdgeInsets.all(24),
                  width: 420,
                  decoration: BoxDecoration(
                    color: Colors.white.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(color: Colors.white.withOpacity(0.3)),
                  ),
                  child: SingleChildScrollView(
                    child: Column(
                      children: [
                        Text('טופס הרשמה', style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold, color: Colors.white), textAlign: TextAlign.center),
                        SizedBox(height: 24),
                        _buildTextField(_nameController, 'שם מלא'),
                        SizedBox(height: 12),
                        _buildTextField(_emailController, 'אימייל', type: TextInputType.emailAddress),
                        SizedBox(height: 12),
                        _buildTextField(_phoneController, 'טלפון', type: TextInputType.phone),
                        SizedBox(height: 12),
                        _buildTextField(_passwordController, 'סיסמה', obscure: true),
                        SizedBox(height: 12),
                        DropdownButtonFormField<String>(
                          dropdownColor: Colors.grey[900],
                          style: TextStyle(color: Colors.white),
                          decoration: InputDecoration(
                            labelText: 'בחר תפקיד',
                            labelStyle: TextStyle(color: Colors.white70),
                            filled: true,
                            fillColor: Colors.white.withOpacity(0.1),
                            border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                          ),
                          value: selectedRole,
                          items: ['admin', 'lecturer', 'visitor', 'student'].map((role) {
                            return DropdownMenuItem(value: role, child: Text(role));
                          }).toList(),
                          onChanged: (val) => setState(() => selectedRole = val!),
                        ),
                        SizedBox(height: 20),
                        _loading
                            ? CircularProgressIndicator()
                            : ElevatedButton.icon(
                                icon: Icon(Icons.check),
                                label: Text('הירשם'),
                                onPressed: register,
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: Colors.teal,
                                  padding: EdgeInsets.symmetric(vertical: 14),
                                  minimumSize: Size(double.infinity, 50),
                                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                                ),
                              ),
                      ],
                    ),
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
