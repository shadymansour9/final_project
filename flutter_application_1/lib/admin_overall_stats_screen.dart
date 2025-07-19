import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:fl_chart/fl_chart.dart';

class AdminOverallStatsScreen extends StatefulWidget {
  @override
  _AdminOverallStatsScreenState createState() => _AdminOverallStatsScreenState();
}

class _AdminOverallStatsScreenState extends State<AdminOverallStatsScreen> {
  int reservations = 0;
  int arrived = 0;
  int canceled = 0;
  int illegal = 0;
  bool isLoading = false;

  @override
  void initState() {
    super.initState();
    fetchStats();
  }

  int safeInt(dynamic value) {
    if (value == null) return 0;
    if (value is int) return value;
    if (value is double) return value.toInt();
    if (value is String) return int.tryParse(value) ?? 0;
    return 0;
  }

  Future<void> fetchStats() async {
    setState(() => isLoading = true);
    try {
      final response = await http.get(Uri.parse('http://localhost:5000/stats'));
      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        print("📊 Data from server: $data");

        setState(() {
          reservations = safeInt(data['reservations']);
          arrived = safeInt(data['arrived']);
          canceled = safeInt(data['canceled']);
          illegal = safeInt(data['illegal']);
        });
      } else {
        throw Exception('שגיאה בטעינת הנתונים');
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('שגיאה: $e')),
      );
    } finally {
      setState(() => isLoading = false);
    }
  }

  List<BarChartGroupData> _buildBarGroups() {
    final values = [reservations, arrived, canceled, illegal];
    return List.generate(values.length, (index) {
      return BarChartGroupData(
        x: index,
        barRods: [
          BarChartRodData(toY: values[index].toDouble(), width: 20, color: Colors.teal),
        ],
      );
    });
  }

  final List<String> _labels = ['הזמנות', 'הגיעו', 'ביטולים חוקיים', 'לא חוקיות'];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('סטטיסטיקות כלליות'),
        backgroundColor: Colors.teal,
        actions: [
          IconButton(
            icon: Icon(Icons.calendar_month),
            onPressed: () {
              Navigator.pushNamed(context, '/admin_monthly_stats');
            },
          )
        ],
      ),
      body: Padding(
        padding: const EdgeInsets.all(20.0),
        child: isLoading
            ? Center(child: CircularProgressIndicator())
            : BarChart(
                BarChartData(
                  barGroups: _buildBarGroups(),
                  titlesData: FlTitlesData(
                    bottomTitles: AxisTitles(
                      sideTitles: SideTitles(
                        showTitles: true,
                        getTitlesWidget: (value, meta) => Padding(
                          padding: const EdgeInsets.only(top: 8.0),
                          child: Text(_labels[value.toInt()], style: TextStyle(fontSize: 12)),
                        ),
                      ),
                    ),
                    leftTitles: AxisTitles(
                      sideTitles: SideTitles(showTitles: true),
                    ),
                  ),
                ),
              ),
      ),
    );
  }
}
