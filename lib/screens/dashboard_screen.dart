import 'package:flutter/material.dart';
import '../models/account.dart';

class DashboardScreen extends StatelessWidget {
  const DashboardScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final account = ModalRoute.of(context)!.settings.arguments as Account;
    return Scaffold(
      backgroundColor: Colors.black,
      body: Center(
        child: Text(
          'ID: ${account.id}',
          style: const TextStyle(color: Colors.white, fontSize: 32, letterSpacing: 2),
        ),
      ),
    );
  }
}
