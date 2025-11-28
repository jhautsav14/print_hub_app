import 'package:flutter/material.dart';
import 'package:print_app/screens/home_screen.dart';
import 'package:print_app/vendor/vendor_page.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  await Supabase.initialize(
    url: 'https://hzvqsxhizimetrranrsw.supabase.co',
    anonKey:
        'eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6Imh6dnFzeGhpemltZXRycmFucnN3Iiwicm9sZSI6ImFub24iLCJpYXQiOjE3NjQzMTE5NzEsImV4cCI6MjA3OTg4Nzk3MX0.h2I13W4Y_sq5WuQV3sVTbmzE9RL8lKoWVqWHzzT7bsQ',
  );

  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Print App UI',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        useMaterial3: true,
        colorScheme: ColorScheme.fromSeed(
          seedColor: const Color(0xFF2196F3),
          background: const Color(0xFFF5F5F5),
        ),
        scaffoldBackgroundColor: const Color(0xFFF5F5F5),
      ),
      // home: const PrintHomeScreen(),
      home: const VendorDashboardScreen(),
    );
  }
}
