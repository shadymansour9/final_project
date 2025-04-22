import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';

class EditProfileScreen extends StatefulWidget {
  final int userId;
  final String name;
  final String email;
  final String phone;

  const EditProfileScreen({
    Key? key,
    required this.userId,
    required this.name,
    required this.email,
    required this.phone,
  }) : super(key: key);

  @override
  _EditProfileScreenState createState() => _EditProfileScreenState();
}

class _EditProfileScreenState extends State<EditProfileScreen> {
  final TextEditingController _nameController = TextEditingController();
  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _phoneController = TextEditingController();
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    _nameController.text = widget.name;
    _emailController.text = widget.email;
    _phoneController.text = widget.phone;
  }

  Future<void> _updateProfile() async {
    setState(() => _isLoading = true);

    if (_nameController.text.trim().isEmpty ||
        _emailController.text.trim().isEmpty ||
        _phoneController.text.trim().isEmpty) {
      _showMessage("יש למלא את כל השדות!", Colors.orange);
      setState(() => _isLoading = false);
      return;
    }

    try {
      final response = await http.post(
        Uri.parse('http://10.0.0.10:5000/update_profile'),
        headers: {"Content-Type": "application/json"},
        body: jsonEncode({
          "user_id": widget.userId,
          "name": _nameController.text.trim(),
          "email": _emailController.text.trim(),
          "phone": _phoneController.text.trim(),
        }),
      );

      final data = jsonDecode(response.body);
      if (response.statusCode == 200) {
        _showMessage("✅ הפרטים עודכנו בהצלחה!", Colors.green);
      } else {
        _showMessage(data["message"], Colors.red);
      }
    } catch (e) {
      _showMessage("❌ שגיאת חיבור: $e", Colors.red);
    } finally {
      setState(() => _isLoading = false);
    }
  }

  void _showMessage(String text, Color color) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(text, style: const TextStyle(color: Colors.white)),
        backgroundColor: color,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Stack(
        children: [
          // ✅ רקע תמונה
          Container(
            decoration: const BoxDecoration(
              image: DecorationImage(
                image: AssetImage("assets/images/cta-bg.jpg"),
                fit: BoxFit.cover,
              ),
            ),
          ),
          // ✅ תוכן מעוצב
          Center(
            child: SingleChildScrollView(
              child: Card(
                color: Colors.white.withOpacity(0.90),
                margin: const EdgeInsets.symmetric(horizontal: 24),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
                elevation: 10,
                child: Padding(
                  padding: const EdgeInsets.all(24.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      const Text(
                        'עריכת פרופיל',
                        style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold, color: Colors.teal),
                        textAlign: TextAlign.center,
                      ),
                      const SizedBox(height: 24),
                      _buildTextField(_nameController, 'שם', Icons.person),
                      const SizedBox(height: 16),
                      _buildTextField(_emailController, 'אימייל', Icons.email, TextInputType.emailAddress),
                      const SizedBox(height: 16),
                      _buildTextField(_phoneController, 'טלפון', Icons.phone, TextInputType.phone),
                      const SizedBox(height: 24),
                      _isLoading
                          ? const Center(child: CircularProgressIndicator())
                          : ElevatedButton.icon(
                              onPressed: _updateProfile,
                              icon: const Icon(Icons.save),
                              label: const Text('עדכן פרטים'),
                              style: ElevatedButton.styleFrom(
                                backgroundColor: Colors.teal,
                                padding: const EdgeInsets.symmetric(vertical: 14),
                                textStyle: const TextStyle(fontSize: 16),
                                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                              ),
                            ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  // ✅ שדה קלט עם עיצוב אחיד
  Widget _buildTextField(TextEditingController controller, String label, IconData icon,
      [TextInputType type = TextInputType.text]) {
    return TextField(
      controller: controller,
      keyboardType: type,
      decoration: InputDecoration(
        labelText: label,
        prefixIcon: Icon(icon),
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
        filled: true,
        fillColor: Colors.grey.shade100,
      ),
    );
  }
}
