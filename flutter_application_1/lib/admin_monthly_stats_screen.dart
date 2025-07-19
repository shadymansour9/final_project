import 'dart:convert';
import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:http/http.dart' as http;

class AdminMonthlyStatsScreen extends StatefulWidget {
  @override
  _AdminMonthlyStatsScreenState createState() => _AdminMonthlyStatsScreenState();
}

class _AdminMonthlyStatsScreenState extends State<AdminMonthlyStatsScreen> {
  String? selectedMonth;
  bool isLoading = false;
  int reservations = 0, approved = 0, canceled = 0, illegal = 0, arrived = 0;

  List<String> months = [
    '2025-01', '2025-02', '2025-03', '2025-04', '2025-05', '2025-06',
    '2025-07', '2025-08', '2025-09', '2025-10', '2025-11', '2025-12',
  ];

  Future<void> fetchStatsForMonth(String month) async {
    setState(() => isLoading = true);
    try {
      final response = await http.post(
        Uri.parse('http://localhost:5000/monthly_stats'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({'month': month}),
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        setState(() {
          reservations = data['reservations'];
          approved = data['approved'];
          canceled = data['canceled'];
          illegal = data['illegal'];
          arrived = data['arrived'];
        });
      } else {
        _show("שגיאה בטעינת נתונים");
      }
    } catch (e) {
      _show("שגיאה: $e");
    } finally {
      setState(() => isLoading = false);
    }
  }

  void _show(String msg) {
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(msg)));
  }

  List<PieChartSectionData> _buildChartSections() {
    final total = approved + canceled + illegal + arrived;

    if (total == 0) {
      return [
        PieChartSectionData(
          color: Colors.grey,
          value: 1,
          title: 'אין נתונים',
          titleStyle: TextStyle(color: Colors.white, fontSize: 14),
        ),
      ];
    }

    return [
      PieChartSectionData(
        color: Colors.green,
        value: approved.toDouble(),
        title: 'מאושרות\n$approved',
        titleStyle: TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: Colors.white),
      ),
      PieChartSectionData(
        color: Colors.orange,
        value: canceled.toDouble(),
        title: 'בוטלו\n$canceled',
        titleStyle: TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: Colors.white),
      ),
      PieChartSectionData(
        color: Colors.red,
        value: illegal.toDouble(),
        title: 'לא חוקיות\n$illegal',
        titleStyle: TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: Colors.white),
      ),
      PieChartSectionData(
        color: Colors.blue,
        value: arrived.toDouble(),
        title: 'הגיעו\n$arrived',
        titleStyle: TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: Colors.white),
      ),
    ];
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('סטטיסטיקה חודשית'),
        backgroundColor: Colors.teal,
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
                  padding: EdgeInsets.all(24),
                  margin: EdgeInsets.all(20),
                  decoration: BoxDecoration(
                    color: Colors.white.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(color: Colors.white.withOpacity(0.3)),
                  ),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text("בחר חודש להצגת סטטיסטיקה", style: TextStyle(color: Colors.white, fontSize: 18)),
                      SizedBox(height: 10),
                      DropdownButton<String>(
                        dropdownColor: Colors.grey[900],
                        value: selectedMonth,
                        hint: Text('בחר חודש', style: TextStyle(color: Colors.white)),
                        style: TextStyle(color: Colors.white),
                        iconEnabledColor: Colors.white,
                        items: months.map((month) {
                          return DropdownMenuItem(value: month, child: Text(month));
                        }).toList(),
                        onChanged: (value) {
                          setState(() => selectedMonth = value);
                          if (value != null) fetchStatsForMonth(value);
                        },
                      ),
                      SizedBox(height: 20),
                      if (isLoading)
                        CircularProgressIndicator(color: Colors.white)
                      else
                        Container(
                          height: 300,
                          child: PieChart(
                            PieChartData(
                              sections: _buildChartSections(),
                              sectionsSpace: 5,
                              centerSpaceRadius: 40,
                              borderData: FlBorderData(show: false),
                            ),
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
}
