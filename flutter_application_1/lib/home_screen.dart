import 'package:flutter/material.dart';
import 'user_behavior_screen.dart'; // 👈 תוודא שהקובץ קיים במיקום נכון

class HomeScreen extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text('דף הבית')),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text('ברוך הבא!', style: TextStyle(fontSize: 24)),
            SizedBox(height: 24),
            ElevatedButton(
              onPressed: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => UserBehaviorScreen(userId: 1), // שנה ל־ID אמיתי אצלך
                  ),
                );
              },
              child: Text('הצג התנהגות משתמש'),
            ),
          ],
        ),
      ),
    );
  }
}
