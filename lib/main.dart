import 'package:budget_manage/pages/available_budget.dart';
import 'package:flutter/material.dart';

void main() {
  runApp(MyApp());
}

class MyApp extends StatelessWidget {
  // This widget is the root of your application.
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Manage your Budget',
      debugShowCheckedModeBanner: false,
      // home: SqliteExample(),
      home: AvailableBudget(),
    );
  }
}
