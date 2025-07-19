import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';

class RealEfficiencyScreen extends StatefulWidget {
  final int userId;
  final String name;
  final String email;
  final String phone;

  RealEfficiencyScreen({
    Key? key,
    required this.userId,
    required this.name,
    required this.email,
    required this.phone,
  }) : super(key: key);

  @override
  _RealEfficiencyScreenState createState() => _RealEfficiencyScreenState();
}

class _RealEfficiencyScreenState extends State<RealEfficiencyScreen> {
  DateTime? startDate;
  DateTime? endDate;
  Map<String, dynamic>? result;

  Future<void> pickDate(bool isStart) async {
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: DateTime.now(),
      firstDate: DateTime(2023),
      lastDate: DateTime.now(),
      locale: const Locale('he', 'IL'),
    );
    if (picked != null) {
      setState(() {
        if (isStart) {
          startDate = picked;
        } else {
          endDate = picked;
        }
      });
    }
  }

  Future<void> fetchEfficiency() async {
    if (startDate == null || endDate == null) return;
    final url = Uri.parse('http://localhost:5000/real_efficiency');
    final response = await http.post(
      url,
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode({
        'start_date': DateFormat('yyyy-MM-dd').format(startDate!),
        'end_date': DateFormat('yyyy-MM-dd').format(endDate!),
      }),
    );
    if (response.statusCode == 200) {
      setState(() {
        result = jsonDecode(response.body);
      });
    } else {
      setState(() {
        result = {"message": "שגיאה בקבלת נתונים"};
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      body: Stack(
        children: [
          // ✅ רקע זהה ללוח ניהול
          Image.asset(
            "assets/images/cta-bg.jpg",
            fit: BoxFit.cover,
            width: double.infinity,
            height: double.infinity,
          ),

          // ✅ שכבת טשטוש ותוכן
          BackdropFilter(
            filter: ImageFilter.blur(sigmaX: 8, sigmaY: 8),
            child: Align(
              alignment: Alignment.center,
              child: Container(
                margin: EdgeInsets.symmetric(horizontal: 16),
                padding: EdgeInsets.all(24),
                color: Colors.black.withOpacity(0.5),
                child: SingleChildScrollView(
                  child: Column(
                    children: [
                      Container(
                        padding: EdgeInsets.all(20),
                        decoration: BoxDecoration(
                          color: Colors.white.withOpacity(0.1),
                          borderRadius: BorderRadius.circular(20),
                          border: Border.all(color: Colors.white.withOpacity(0.3)),
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              '📊 נוסחת יעילות (Efficiency)',
                              style: TextStyle(color: Colors.white, fontSize: 20, fontWeight: FontWeight.bold),
                            ),
                            SizedBox(height: 10),
                            Text(
                              'Efficiency = (Arrived / Total) - γ × (Illegal / Total)\nכאשר γ הוא פרמטר עונש (למשל: 2)\n\n'
                              'הנוסחה בודקת עד כמה המשתמשים הגיעו בפועל, מול כמות ההזמנות הכוללת, עם קיזוז על ביטולים לא חוקיים.',
                              style: TextStyle(color: Colors.white70, fontSize: 14),
                            ),
                          ],
                        ),
                      ),
                      SizedBox(height: 30),

                      // תאריכים
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                        children: [
                          OutlinedButton.icon(
                            onPressed: () => pickDate(true),
                            icon: Icon(Icons.date_range, color: Colors.white),
                            label: Text(
                              startDate != null
                                  ? 'התחלה: ${DateFormat('dd/MM/yyyy').format(startDate!)}'
                                  : 'בחר תאריך התחלה',
                              style: TextStyle(color: Colors.black),
                            ),
                            style: OutlinedButton.styleFrom(
                              backgroundColor: const Color.fromARGB(255, 0, 255, 234),
                              side: BorderSide(color: Colors.black),
                            ),
                          ),
                          OutlinedButton.icon(
                            onPressed: () => pickDate(false),
                            icon: Icon(Icons.date_range, color: Colors.white),
                            label: Text(
                              endDate != null
                                  ? 'סיום: ${DateFormat('dd/MM/yyyy').format(endDate!)}'
                                  : 'בחר תאריך סיום',
                              style: TextStyle(color: Colors.black),
                            ),
                            style: OutlinedButton.styleFrom(
                              backgroundColor: const Color.fromARGB(255, 0, 255, 234),
                              side: BorderSide(color: Colors.black),
                            ),
                          ),
                        ],
                      ),
                      SizedBox(height: 20),

                      // כפתור חישוב
                      ElevatedButton(
                        onPressed: fetchEfficiency,
                        child: Text('חשב יעילות'),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: const Color.fromARGB(255, 0, 255, 234),
                          padding: EdgeInsets.symmetric(horizontal: 30, vertical: 15),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(20),
                          ),
                        ),
                      ),
                      SizedBox(height: 30),

                      // תוצאה
                      if (result != null && result!.isNotEmpty)
                        Container(
                          width: double.infinity,
                          padding: EdgeInsets.all(24),
                          decoration: BoxDecoration(
                            color: Colors.white.withOpacity(0.1),
                            borderRadius: BorderRadius.circular(16),
                            border: Border.all(color: Colors.white30),
                          ),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                '🔎 תוצאות החישוב',
                                style: TextStyle(color: Colors.white, fontSize: 20, fontWeight: FontWeight.bold),
                              ),
                              SizedBox(height: 10),
                              ...result!.entries.map((entry) => Text(
                                    '${entry.key} : ${entry.value}',
                                    style: TextStyle(color: Colors.white70, fontSize: 16),
                                  )),
                            ],
                          ),
                        ),
                    ],
                  ),
                ),
              ),
            ),
          ),

          // כפתור חזרה
          Positioned(
            top: 16,
            right: 16,
            child: GestureDetector(
              onTap: () => Navigator.pop(context),
              child: Container(
                padding: EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                decoration: BoxDecoration(
                  color: Colors.white.withOpacity(0.2),
                  borderRadius: BorderRadius.circular(30),
                  border: Border.all(color: Colors.white30),
                ),
                child: Row(
                  children: const [
                    Icon(Icons.arrow_back, color: Colors.white),
                    SizedBox(width: 6),
                    Text(
                      'חזרה',
                      style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
