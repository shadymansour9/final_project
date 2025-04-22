import 'package:flutter/material.dart';

class StudentLecturerScreen extends StatelessWidget {
  final String role; // 'student' או 'lecturer'
  final int userId;
  final String name;
  final String email;
  final String phone;

  const StudentLecturerScreen({
    Key? key,
    required this.role,
    required this.userId,
    required this.name,
    required this.email,
    required this.phone,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text(role == 'student' ? 'דף סטודנט' : 'דף מרצה')),
      body: Center(
        child: GridView.count(
          crossAxisCount: 1,
          padding: EdgeInsets.all(20),
          crossAxisSpacing: 15,
          mainAxisSpacing: 15,
          childAspectRatio: 3,
          children: [
            _buildCard(context, 'הזמנת חניה', Icons.local_parking, '/reserve_parking'),
            _buildCard(context, 'ההזמנות שלי', Icons.list, '/my_reservations'),
            _buildCard(context, 'עריכת פרופיל', Icons.person, '/edit_profile'),
          ],
        ),
      ),
    );
  }

  Widget _buildCard(BuildContext context, String title, IconData icon, String route) {
    return GestureDetector(
      onTap: () {
        if (route == '/edit_profile') {
          Navigator.pushNamed(context, route, arguments: {
            "user_id": userId,
            "name": name,
            "email": email,
            "phone": phone,
          });
        } else if (route == '/my_reservations' || route == '/reserve_parking') {
          Navigator.pushNamed(context, route, arguments: userId);
        }
      },
      child: Card(
        elevation: 5,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
        child: Container(
          padding: EdgeInsets.all(20),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(icon, size: 30, color: Colors.blue),
              SizedBox(width: 10),
              Text(title, style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
            ],
          ),
        ),
      ),
    );
  }
}
