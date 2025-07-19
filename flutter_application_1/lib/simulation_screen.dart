import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';

class SimulationScreen extends StatefulWidget {
  @override
  _SimulationScreenState createState() => _SimulationScreenState();
}

class _SimulationScreenState extends State<SimulationScreen> {
  double pointsArrived = 10;
  double pointsCancelled = 0;
  double pointsIllegal = -20;
  Map<String, dynamic>? result;

  Future<void> runSimulation() async {
    final response = await http.post(
      Uri.parse('http://localhost:5000/real_efficiency_with_params'),
      headers: {"Content-Type": "application/json"},
      body: jsonEncode({
        "points_arrived": pointsArrived,
        "points_cancelled": pointsCancelled,
        "points_illegal": pointsIllegal,
      }),
    );

    if (response.statusCode == 200) {
      setState(() {
        result = jsonDecode(response.body);
      });
    } else {
      setState(() {
        result = {"error": "Failed to run simulation"};
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text("Simulation Tool")),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: SingleChildScrollView(
          child: Column(
            children: [
              Card(
                color: Colors.white.withOpacity(0.1),
                elevation: 4,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        "\ud83d\udcd8 \u05e0\u05d5\u05e1\u05db\u05ea \u05d7\u05d9\u05e9\u05d5\u05d1 \u05e6\u05d9\u05d5\u05df (Grade)",
                        style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Colors.white),
                      ),
                      SizedBox(height: 8),
                      Text("Grade = (Score / Max Score) \u00d7 100", style: TextStyle(color: Colors.white)),
                      Text("Score = (Arrived \u00d7 \u05e0\u05e7\u05d5\u05d3\u05d5\u05ea \u05d4\u05d2\u05e2\u05d4) + (Cancelled \u00d7 \u05e0\u05e7\u05d5\u05d3\u05d5\u05ea \u05d1\u05d9\u05d8\u05d5\u05dc \u05d7\u05d5\u05e7\u05d9) + (Illegal \u00d7 \u05e0\u05e7\u05d5\u05d3\u05d5\u05ea \u05d1\u05d9\u05d8\u05d5\u05dc \u05dc\u05d0 \u05d7\u05d5\u05e7\u05d9)", style: TextStyle(color: Colors.white)),
                      Text("Max Score = Total Reservations \u00d7 \u05e0\u05e7\u05d5\u05d3\u05d5\u05ea \u05d4\u05d2\u05e2\u05d4", style: TextStyle(color: Colors.white)),
                    ],
                  ),
                ),
              ),
              SizedBox(height: 20),
              Text("\u05e0\u05e7\u05d5\u05d3\u05d5\u05ea \u05e2\u05d1\u05d5\u05e8 \u05d4\u05d2\u05e2\u05d4: ${pointsArrived.toStringAsFixed(0)}"),
              Slider(
                value: pointsArrived,
                onChanged: (v) => setState(() => pointsArrived = v),
                min: 0,
                max: 20,
                divisions: 20,
                label: pointsArrived.toStringAsFixed(0),
              ),
              Text("\u05e0\u05e7\u05d5\u05d3\u05d5\u05ea \u05e2\u05d1\u05d5\u05e8 \u05d1\u05d9\u05d8\u05d5\u05dc \u05d7\u05d5\u05e7\u05d9: ${pointsCancelled.toStringAsFixed(0)}"),
              Slider(
                value: pointsCancelled,
                onChanged: (v) => setState(() => pointsCancelled = v),
                min: -10,
                max: 10,
                divisions: 20,
                label: pointsCancelled.toStringAsFixed(0),
              ),
              Text("\u05e0\u05e7\u05d5\u05d3\u05d5\u05ea \u05e2\u05d1\u05d5\u05e8 \u05d1\u05d9\u05d8\u05d5\u05dc \u05dc\u05d0 \u05d7\u05d5\u05e7\u05d9: ${pointsIllegal.toStringAsFixed(0)}"),
              Slider(
                value: pointsIllegal,
                onChanged: (v) => setState(() => pointsIllegal = v),
                min: -50,
                max: 0,
                divisions: 50,
                label: pointsIllegal.toStringAsFixed(0),
              ),
              ElevatedButton(
                onPressed: runSimulation,
                child: Text("Run Simulation"),
              ),
              SizedBox(height: 20),
              if (result != null && result!["error"] == null) ...[
                Text("Grade: ${result!["avg_grade"]}"),
                Text("Blocked %: ${result!["blocked_percent"]}"),
                Text("Arrived: ${result!["arrived"]}"),
                Text("Cancelled: ${result!["cancelled"]}"),
                Text("Illegal Cancelled: ${result!["illegal_cancelled"]}"),
                Text("Total Reservations: ${result!["total_reservations"]}"),
              ] else if (result != null) ...[
                Text(result!["error"], style: TextStyle(color: Colors.red))
              ]
            ],
          ),
        ),
      ),
    );
  }
}
