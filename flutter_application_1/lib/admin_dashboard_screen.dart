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
      body: Stack(
        children: [
          // ✅ רקע עם תמונה
          Container(
            decoration: const BoxDecoration(
              image: DecorationImage(
                image: AssetImage("assets/images/cta-bg.jpg"),
                fit: BoxFit.cover,
              ),
            ),
          ),
          // ✅ תוכן שקוף על הרקע
          Center(
            child: SingleChildScrollView(
              child: Card(
                color: Colors.white.withOpacity(0.85),
                elevation: 12,
                margin: const EdgeInsets.symmetric(horizontal: 24),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Padding(
                  padding: const EdgeInsets.all(24.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      Text(
                        "שלום ${widget.name}!",
                        style: const TextStyle(
                          fontSize: 24,
                          fontWeight: FontWeight.bold,
                          color: Colors.teal,
                        ),
                        textAlign: TextAlign.center,
                      ),
                      const SizedBox(height: 24),

                      ElevatedButton.icon(
                        icon: const Icon(Icons.manage_search),
                        label: const Text("ניהול הזמנות לפי משתמש"),
                        onPressed: () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (_) => ViewUserReservationsScreen(),
                            ),
                          );
                        },
                        style: _buttonStyle(),
                      ),
                      const SizedBox(height: 16),

                      ElevatedButton.icon(
                        icon: const Icon(Icons.person),
                        label: const Text("עריכת פרופיל מנהל"),
                        onPressed: () {
                          Navigator.pushNamed(
                            context,
                            '/edit_profile',
                            arguments: {
                              "user_id": widget.userId,
                              "name": widget.name,
                              "email": widget.email,
                              "phone": widget.phone,
                            },
                          );
                        },
                        style: _buttonStyle(),
                      ),
                      const SizedBox(height: 16),

                      ElevatedButton.icon(
                        icon: const Icon(Icons.lock),
                        label: const Text("ניהול משתמשים"),
                        onPressed: () {
                          Navigator.pushNamed(context, '/manage_users');
                        },
                        style: _buttonStyle(),
                      ),
                      const SizedBox(height: 16),

                      ElevatedButton.icon(
                        icon: const Icon(Icons.add),
                        label: const Text("ביצוע הזמנה"),
                        onPressed: () {
                          Navigator.pushNamed(
                            context,
                            '/reserve_parking',
                            arguments: widget.userId,
                          );
                        },
                        style: _buttonStyle(),
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

  // ✅ פונקציה שחוזרת על עיצוב כפתורים
  ButtonStyle _buttonStyle() {
    return ElevatedButton.styleFrom(
      backgroundColor: Colors.teal,
      foregroundColor: Colors.white,
      padding: const EdgeInsets.symmetric(vertical: 16),
      textStyle: const TextStyle(fontSize: 16),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
      ),
    );
  }
}
