import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter_application_1/view_user_reservations_screen.dart';

class AdminDashboardScreen extends StatefulWidget {
  final int userId;
  final String name;
  final String email;
  final String phone;

  const AdminDashboardScreen({
    Key? key,
    required this.userId,
    required this.name,
    required this.email,
    required this.phone,
  }) : super(key: key);

  @override
  _AdminDashboardScreenState createState() => _AdminDashboardScreenState();
}

class _AdminDashboardScreenState extends State<AdminDashboardScreen> {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("לוח ניהול", style: TextStyle(fontWeight: FontWeight.bold)),
        actions: [
          IconButton(
            icon: const Icon(Icons.logout),
            tooltip: 'התנתקות',
            onPressed: () {
              Navigator.pushNamedAndRemoveUntil(context, '/', (route) => false);
            },
          ),
        ],
        backgroundColor: Colors.teal,
        elevation: 0,
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
                  width: 450,
                  padding: const EdgeInsets.all(24),
                  decoration: BoxDecoration(
                    color: Colors.white.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(color: Colors.white.withOpacity(0.3)),
                  ),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      Text(
                        "שלום ${widget.name}!",
                        style: const TextStyle(
                          fontSize: 26,
                          fontWeight: FontWeight.bold,
                          color: Colors.white,
                        ),
                        textAlign: TextAlign.center,
                      ),
                      const SizedBox(height: 24),

                      _buildButton(
                        icon: Icons.manage_search,
                        label: "ניהול הזמנות לפי משתמש",
                        onPressed: () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(builder: (_) => ViewUserReservationsScreen()),
                          );
                        },
                      ),
                      _buildButton(
                        icon: Icons.person,
                        label: "עריכת פרופיל מנהל",
                        onPressed: () {
                          Navigator.pushNamed(
                            context,
                            '/edit_profile',
                            arguments: {
                              "user_id": widget.userId,
                              "name": widget.name,
                              "email": widget.email,
                              "phone": widget.phone,
                              "role": 'admin',
                            },
                          );
                        },
                      ),
                      _buildButton(
                        icon: Icons.lock,
                        label: "ניהול משתמשים",
                        onPressed: () {
                          Navigator.pushNamed(context, '/manage_users');
                        },
                      ),
                      _buildButton(
                        icon: Icons.add,
                        label: "ביצוע הזמנה",
                        onPressed: () {
                          Navigator.pushNamed(context, '/reserve_parking', arguments: widget.userId);
                        },
                      ),
                      _buildButton(
                        icon: Icons.bar_chart,
                        label: "סטטיסטיקות כלליות",
                        onPressed: () {
                          Navigator.pushNamed(context, '/admin_stats');
                        },
                      ),
                      _buildButton(
                        icon: Icons.science,
                        label: "סימולציית יעילות אלגוריתם",
                        onPressed: () {
                          Navigator.pushNamed(context, '/simulation');
                        },
                      ),
                      _buildButton(
  icon: Icons.query_stats,
  label: "יעילות מנתונים אמיתיים",
  onPressed: () {
   Navigator.pushNamed(
  context,
  '/real_efficiency',
  arguments: {
    'user_id': widget.userId,
    'name': widget.name,
    'email': widget.email,
    'phone': widget.phone,
  },
);

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

  Widget _buildButton({required IconData icon, required String label, required VoidCallback onPressed}) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8.0),
      child: ElevatedButton.icon(
        icon: Icon(icon, size: 20),
        label: Text(label, style: TextStyle(fontSize: 16)),
        onPressed: onPressed,
        style: ElevatedButton.styleFrom(
          backgroundColor: Colors.teal,
          foregroundColor: Colors.white,
          padding: const EdgeInsets.symmetric(vertical: 14),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        ),
      ),
    );
  }
}
