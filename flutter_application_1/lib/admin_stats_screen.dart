
import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:pdf/widgets.dart' as pw;
import 'package:printing/printing.dart';

class AdminStatsScreen extends StatefulWidget {
  @override
  _AdminStatsScreenState createState() => _AdminStatsScreenState();
}

class _AdminStatsScreenState extends State<AdminStatsScreen> {
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
    final total = reservations.toDouble().clamp(1, double.infinity);

    final List<Map<String, dynamic>> values = [
      {'label': 'הגיעו', 'value': arrived, 'color': Colors.teal},
      {'label': 'ביטולים חוקיים', 'value': canceled, 'color': Colors.orange},
      {'label': 'לא חוקיות', 'value': illegal, 'color': Colors.red},
    ];

    return List.generate(values.length, (index) {
      final count = values[index]['value'];
      final percent = (count / total) * 100;

      return BarChartGroupData(
        x: index,
        barRods: [
          BarChartRodData(
            toY: percent,
            width: 24,
            color: values[index]['color'],
            borderRadius: BorderRadius.circular(6),
          ),
        ],
        showingTooltipIndicators: [0],
      );
    });
  }

  final List<String> _labels = ['הגיעו', 'ביטולים חוקיים', 'לא חוקיות'];

  Future<void> generatePdf() async {
    final pdf = pw.Document();

    pdf.addPage(
      pw.Page(
        build: (pw.Context context) => pw.Column(
          crossAxisAlignment: pw.CrossAxisAlignment.start,
          children: [
            pw.Text('דו"ח סטטיסטיקה כללית', style: pw.TextStyle(fontSize: 24)),
            pw.SizedBox(height: 16),
            pw.Text('סה"כ הזמנות: $reservations'),
            pw.Text('הגיעו: $arrived'),
            pw.Text('ביטולים חוקיים: $canceled'),
            pw.Text('ביטולים לא חוקיים: $illegal'),
          ],
        ),
      ),
    );

    await Printing.layoutPdf(onLayout: (format) => pdf.save());
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('סטטיסטיקות כלליות'),
        backgroundColor: Colors.teal,
        actions: [
          IconButton(
            icon: Icon(Icons.calendar_month),
            tooltip: 'מעבר לסטטיסטיקה חודשית',
            onPressed: () {
              Navigator.pushNamed(context, '/admin_monthly_stats');
            },
          ),
          IconButton(
            icon: Icon(Icons.picture_as_pdf),
            onPressed: generatePdf,
            tooltip: 'ייצוא PDF',
          ),
        ],
      ),
      body: isLoading
          ? Center(child: CircularProgressIndicator())
          : Center(
              child: ClipRRect(
                borderRadius: BorderRadius.circular(30),
                child: BackdropFilter(
                  filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
                  child: Container(
                    width: 620,
                    height: 500,
                    padding: EdgeInsets.all(24),
                    decoration: BoxDecoration(
                      color: Colors.white.withOpacity(0.10),
                      borderRadius: BorderRadius.circular(30),
                      border: Border.all(color: Colors.white.withOpacity(0.3)),
                    ),
                    child: Column(
                      children: [
                        Text(
                          'אחוזים מתוך סה"כ הזמנות',
                          style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.white),
                        ),
                        SizedBox(height: 20),
                        Expanded(
                          child: BarChart(
                            BarChartData(
                              barGroups: _buildBarGroups(),
                              barTouchData: BarTouchData(
                                enabled: true,
                                touchTooltipData: BarTouchTooltipData(
                                  tooltipBgColor: Colors.grey.shade800,
                                  getTooltipItem: (group, groupIndex, rod, rodIndex) {
                                    final count = [arrived, canceled, illegal][group.x.toInt()];
                                    final percent = rod.toY.toStringAsFixed(1);
                                    return BarTooltipItem(
  '$percent%\n$count',
  TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
);

                                    
                                  },
                                ),
                              ),
                              gridData: FlGridData(show: true),
                              borderData: FlBorderData(show: false),
                              titlesData: FlTitlesData(
                                leftTitles: AxisTitles(
                                  sideTitles: SideTitles(
                                    showTitles: true,
                                    reservedSize: 40,
                                    getTitlesWidget: (value, meta) => Text('${value.toInt()}%', style: TextStyle(color: Colors.white)),
                                  ),
                                ),
                                bottomTitles: AxisTitles(
                                  sideTitles: SideTitles(
                                    showTitles: true,
                                    getTitlesWidget: (value, meta) => Padding(
                                      padding: EdgeInsets.only(top: 8.0),
                                      child: Text(
                                        _labels[value.toInt()],
                                        style: TextStyle(fontSize: 12, color: Colors.white),
                                      ),
                                    ),
                                  ),
                                ),
                                topTitles: AxisTitles(sideTitles: SideTitles(showTitles: false)),
                                rightTitles: AxisTitles(sideTitles: SideTitles(showTitles: false)),
                              ),
                            ),
                          ),
                        ),
                        SizedBox(height: 16),
                        Text('סה"כ הזמנות: $reservations', style: TextStyle(color: Colors.white)),
                      ],
                    ),
                  ),
                ),
              ),
            ),
    );
  }
}
