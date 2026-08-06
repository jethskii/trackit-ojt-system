import 'package:flutter/material.dart';
import 'screens/auth/auth_gate.dart';

void main() {
  runApp(const MainApp());
}

class MainApp extends StatelessWidget {
  const MainApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'TRACKIT',
      theme: ThemeData(useMaterial3: true),
      home: const AuthGate(),
    );
  }
}
