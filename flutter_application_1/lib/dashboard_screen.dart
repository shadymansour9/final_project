import 'dart:ui';
import 'package:flutter/material.dart';

class DashboardScreen extends StatelessWidget {
  final String role;
  final String name;
  final int userId;
  final String email;
  final String phone;
  final String status;

  const DashboardScreen({
    Key? key,
    required this.role,
    required this.name,
    required this.userId,
    required this.email,
    required this.phone,
    required this.status,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("דשבורד"),
        backgroundColor: Colors.teal,
        actions: [
          IconButton(
            icon: const Icon(Icons.logout),
            tooltip: 'התנתקות',
            onPressed: () {
              Navigator.pushNamedAndRemoveUntil(context, '/', (route) => false);
            },
          ),
        ],
      ),
      body: Stack(
        children: [
          Positioned.fill(
            child: Image.asset("assets/images/cta-bg.jpg", fit: BoxFit.cover),
          ),
          Container(color: Colors.black.withOpacity(0.4)),
          Center(
            child: ClipRRect(
              borderRadius: BorderRadius.circular(20),
              child: BackdropFilter(
                filter: ImageFilter.blur(sigmaX: 12, sigmaY: 12),
                child: Container(
                  width: 420,
                  padding: const EdgeInsets.all(24),
                  decoration: BoxDecoration(
                    color: Colors.white.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(color: Colors.white.withOpacity(0.3)),
                  ),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        'דשבורד - ${role.toUpperCase()}',
                        style: const TextStyle(
                          fontSize: 24,
                          fontWeight: FontWeight.bold,
                          color: Colors.white,
                        ),
                        textAlign: TextAlign.center,
                      ),
                      const SizedBox(height: 12),
                      Text(
                        'ברוך הבא, $name!',
                        style: const TextStyle(fontSize: 18, color: Colors.white70),
                        textAlign: TextAlign.center,
                      ),
                      const SizedBox(height: 24),

                      _buildButton(
                        context,
                        label: "ההזמנות שלי",
                        icon: Icons.history,
                        color: Colors.blue,
                        onPressed: () {
                          Navigator.pushNamed(context, '/my_reservations', arguments: userId);
                        },
                      ),
                      _buildButton(
                        context,
                        label: "בצע הזמנה",
                        icon: Icons.add,
                        color: Colors.green,
                        onPressed: status.toLowerCase() == 'blocked'
                            ? null
                            : () {
                                Navigator.pushNamed(context, '/reserve_parking', arguments: userId);
                              },
                      ),
                      _buildButton(
                        context,
                        label: "עריכת פרופיל",
                        icon: Icons.edit,
                        color: Colors.orange,
                        onPressed: () {
                          Navigator.pushNamed(
                            context,
                            '/edit_profile',
                            arguments: {
                              "user_id": userId,
                              "name": name,
                              "email": email,
                              "phone": phone,
                              "role": role,
                            },
                          );
                        },
                      ),
                      _buildButton(
                        context,
                        label: "התנתק",
                        icon: Icons.logout,
                        color: Colors.red,
                        onPressed: () {
                          Navigator.pushNamedAndRemoveUntil(context, '/', (route) => false);
                        },
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

  Widget _buildButton(BuildContext context,
      {required String label,
      required IconData icon,
      required Color color,
      required VoidCallback? onPressed}) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: ElevatedButton.icon(
        icon: Icon(icon),
        label: Text(label),
        onPressed: onPressed,
        style: ElevatedButton.styleFrom(
          backgroundColor: color,
          foregroundColor: Colors.white,
          minimumSize: Size(double.infinity, 50),
          textStyle: TextStyle(fontSize: 16),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        ),
      ),
    );
  }
}
