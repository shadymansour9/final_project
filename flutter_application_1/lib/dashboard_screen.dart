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
                color: Colors.white.withOpacity(0.88),
                elevation: 10,
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
                        'דשבורד - ${role.toUpperCase()}',
                        style: const TextStyle(
                          fontSize: 22,
                          fontWeight: FontWeight.bold,
                          color: Colors.teal,
                        ),
                        textAlign: TextAlign.center,
                      ),
                      const SizedBox(height: 16),
                      Text(
                        'ברוך הבא, $name!',
                        style: const TextStyle(fontSize: 18),
                        textAlign: TextAlign.center,
                      ),
                      const SizedBox(height: 24),

                      ElevatedButton.icon(
                        icon: const Icon(Icons.history),
                        label: const Text('ההזמנות שלי'),
                        onPressed: () {
                          Navigator.pushNamed(
                            context,
                            '/my_reservations',
                            arguments: userId,
                          );
                        },
                        style: _buttonStyle(Colors.blue),
                      ),
                      const SizedBox(height: 16),

                      ElevatedButton.icon(
                        icon: const Icon(Icons.add),
                        label: const Text('בצע הזמנה'),
                        onPressed: status.toLowerCase() == 'blocked'
                            ? null
                            : () {
                                Navigator.pushNamed(
                                  context,
                                  '/reserve_parking',
                                  arguments: userId,
                                );
                              },
                        style: _buttonStyle(Colors.green),
                      ),
                      const SizedBox(height: 16),

                      ElevatedButton.icon(
                        icon: const Icon(Icons.edit),
                        label: const Text('עריכת פרופיל'),
                        onPressed: () {
                          Navigator.pushNamed(
                            context,
                            '/edit_profile',
                            arguments: {
                              "user_id": userId,
                              "name": name,
                              "email": email,
                              "phone": phone,
                            },
                          );
                        },
                        style: _buttonStyle(Colors.deepOrange),
                      ),
                      const SizedBox(height: 16),

                      ElevatedButton.icon(
                        icon: const Icon(Icons.logout),
                        label: const Text('התנתק'),
                        onPressed: () {
                          Navigator.pushNamedAndRemoveUntil(context, '/', (route) => false);
                        },
                        style: _buttonStyle(Colors.red),
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

  // ✅ כפתורים עם צבע רקע מותאם
  ButtonStyle _buttonStyle(Color color) {
    return ElevatedButton.styleFrom(
      backgroundColor: color,
      foregroundColor: Colors.white,
      padding: const EdgeInsets.symmetric(vertical: 16),
      textStyle: const TextStyle(fontSize: 16),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
      ),
    );
  }
}
