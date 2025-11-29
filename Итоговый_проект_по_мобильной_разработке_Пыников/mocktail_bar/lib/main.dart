import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import 'router.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  await Supabase.initialize(
    url: 'https://ldlwabeugwhohaqrgcek.supabase.co',
    anonKey: 'eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6ImxkbHdhYmV1Z3dob2hhcXJnY2VrIiwicm9sZSI6ImFub24iLCJpYXQiOjE3NjQzNjM4MzYsImV4cCI6MjA3OTkzOTgzNn0.wMLzmSjmBTJOzt0XcafHceoXU8dVrO1e0JVy0r4Yyh8',
  );

  runApp(const MocktailBarApp());
}

class MocktailBarApp extends StatelessWidget {
  const MocktailBarApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp.router(
      title: 'Безалкогольный бар',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        useMaterial3: true,
        colorSchemeSeed: Colors.teal,
      ),
      routerConfig: appRouter,
    );
  }
}
