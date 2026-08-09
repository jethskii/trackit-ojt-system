import 'package:flutter/material.dart';
import 'screens/auth/auth_gate.dart';

void main() {
  // Flutter's default ErrorWidget renders a blank/empty box outside of
  // debug mode (deliberately, to avoid leaking stack traces to end
  // users) -- which looks exactly like "nothing happened" when a single
  // widget's build throws, with no way to tell what went wrong. This app
  // isn't shipping to a public app store, so a visible, readable error
  // in place of just that widget is far more useful than a blank space.
  ErrorWidget.builder = (FlutterErrorDetails details) {
    return Container(
      padding: const EdgeInsets.all(12),
      color: const Color(0xFFFDEAEA),
      alignment: Alignment.center,
      child: Text(
        details.exceptionAsString(),
        style: const TextStyle(color: Color(0xFFB3261E), fontSize: 12),
      ),
    );
  };
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
