import 'package:flutter/material.dart';

class NotFoundScreen extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text('שגיאה')),
      body: Center(
        child: Text(
          'העמוד לא נמצא',
          style: TextStyle(fontSize: 18),
        ),
      ),
    );
  }
}
