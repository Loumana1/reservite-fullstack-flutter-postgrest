import 'package:flutter/material.dart';

void main() {
  runApp(TestPage());
}

class TestPage extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      theme: ThemeData(
        useMaterial3: true,
        colorScheme: .fromSeed(seedColor: Colors.blue),
      ),
      home: Scaffold(
        appBar: AppBar(title: Text('Test Page')),
        body: Center(
          child: Text('Welcome group c06!', style: TextStyle(fontSize: 24)),
        ),
      ),
    );
  }
}
