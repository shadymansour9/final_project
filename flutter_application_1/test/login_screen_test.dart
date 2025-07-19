import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_application_1/login_screen.dart';

void main() {
  testWidgets('בדיקת התחברות עם שדות ריקים', (WidgetTester tester) async {
    await tester.pumpWidget(MaterialApp(home: LoginScreen()));
    await tester.pumpAndSettle();

    await tester.tap(find.byKey(Key('loginButton')));
    await tester.pump();
    await tester.pump(Duration(seconds: 1));

    expect(find.byType(SnackBar), findsOneWidget);
    expect(find.text('יש למלא גם אימייל וגם סיסמה'), findsOneWidget);
  });

  testWidgets('בדיקת טופס התחברות בסיסי בלי בדיקת רשת', (WidgetTester tester) async {
    await tester.pumpWidget(MaterialApp(home: LoginScreen()));
    await tester.pumpAndSettle();

    await tester.enterText(find.byKey(Key('emailField')), 'test@example.com');
    await tester.enterText(find.byKey(Key('passwordField')), '123456');
    await tester.tap(find.byKey(Key('loginButton')));
    await tester.pump(); // לא בודק מעבר מסך או snackbar

    // בדוק שהכפתור קיים, והטקסטים לא מתרסקים
    expect(find.byKey(Key('loginButton')), findsOneWidget);
  });

  testWidgets('בדיקת טקסטים וכפתורים במסך התחברות', (WidgetTester tester) async {
    await tester.pumpWidget(MaterialApp(home: LoginScreen()));
    await tester.pumpAndSettle();

    expect(find.byKey(Key('emailField')), findsOneWidget);
    expect(find.byKey(Key('passwordField')), findsOneWidget);
    expect(find.byKey(Key('loginButton')), findsOneWidget);
    expect(find.text('התחבר'), findsOneWidget);
    expect(find.text('עדיין אין לך חשבון? הירשם כאן!'), findsOneWidget);
  });
  
}
