import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_application_1/real_efficiency_screen.dart';
import 'login_screen.dart';
import 'home_screen.dart';
import 'register_screen.dart';
import 'dashboard_screen.dart';
import 'my_reservations_screen.dart';
import 'not_found_screen.dart';
import 'edit_profile_screen.dart';
import 'admin_dashboard_screen.dart';
import 'view_user_reservations_screen.dart';
import 'manage_users_screen.dart';
import 'modern_reservation_screen.dart';
import 'package:flutter_application_1/admin_stats_screen.dart';
import 'package:flutter_application_1/admin_monthly_stats_screen.dart' as monthly;
import 'package:flutter_application_1/admin_overall_stats_screen.dart' as overall;
import 'package:flutter_application_1/simulation_screen.dart'; // שים את הנתיב המתאים

void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Parking App',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        scaffoldBackgroundColor: Colors.transparent,
        textTheme: const TextTheme(bodyMedium: TextStyle(color: Colors.white)),
        appBarTheme: const AppBarTheme(
          backgroundColor: Colors.black54,
          centerTitle: true,
          elevation: 0,
        ),
      ),
      locale: const Locale('he', 'IL'),
      supportedLocales: const [
        Locale('he', 'IL'),
        Locale('en', 'US'),
      ],
      localizationsDelegates: const [
        GlobalMaterialLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
      ],
      home: BackgroundWrapper(child: LoginScreen()),
      onGenerateRoute: (settings) {
        Widget page = NotFoundScreen();

        switch (settings.name) {
          case '/':
            page = LoginScreen();
            break;
          case '/home':
            page = HomeScreen();
            break;
          case '/register':
            page = RegisterScreen();
            break;
          case '/admin_stats':
            page = AdminStatsScreen();
            break;
          case '/admin_monthly_stats':
            page = monthly.AdminMonthlyStatsScreen();
            break;
          case '/real_efficiency':
  if (settings.arguments is Map<String, dynamic>) {
    final args = settings.arguments as Map<String, dynamic>;
    page = RealEfficiencyScreen(
      userId: args['user_id'],
      name: args['name'],
      email: args['email'],
      phone: args['phone'],
    );
  }
  break;

          case '/admin_overall_stats':
            page = overall.AdminOverallStatsScreen();
            break;
          case '/simulation':
  page = SimulationScreen();
  break;

          case '/dashboard':
            if (settings.arguments is Map<String, dynamic>) {
              final args = settings.arguments as Map<String, dynamic>;
              page = DashboardScreen(
                role: args['role'],
                name: args['name'],
                userId: args['user_id'],
                email: args['email'],
                phone: args['phone'],
                status: args['status'],
              );
            }
            break;
          case '/admin_dashboard':
            if (settings.arguments is Map<String, dynamic>) {
              final args = settings.arguments as Map<String, dynamic>;
              page = AdminDashboardScreen(
                userId: args['user_id'],
                name: args['name'],
                email: args['email'],
                phone: args['phone'],
              );
            }
            break;
          case '/edit_profile':
  if (settings.arguments is Map<String, dynamic>) {
    final args = settings.arguments as Map<String, dynamic>;
    page = EditProfileScreen(
      userId: args['user_id'] ?? 0,
      name: args['name'] ?? "",
      email: args['email'] ?? "",
      phone: args['phone'] ?? "",
      role: args['role'] ?? "student", // ✅ חובה – אם לא admin, ברירת מחדל
    );
  }
  break;

          case '/my_reservations':
            if (settings.arguments is int) {
              page = MyReservationsScreen(userId: settings.arguments as int);
            }
            break;
          case '/reserve_parking':
            if (settings.arguments is int) {
              page = ModernReservationScreen(userId: settings.arguments as int);
            }
            break;
          case '/manage_users':
            page = ManageUsersScreen();
            break;
        }

        return MaterialPageRoute(builder: (_) => BackgroundWrapper(child: page));
      },
    );
  }
}

class BackgroundWrapper extends StatelessWidget {
  final Widget child;

  const BackgroundWrapper({Key? key, required this.child}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Stack(
        children: [
          Positioned.fill(
            child: Image.asset(
              "assets/images/cta-bg.jpg",
              fit: BoxFit.cover,
            ),
          ),
          Container(color: Colors.black.withOpacity(0.4)),
          Positioned.fill(
            child: SafeArea(child: child),
          ),
        ],
      ),
    );
  }
}
