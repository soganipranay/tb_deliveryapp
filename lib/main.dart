import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:tb_deliveryapp/views/loginAuth/login_page.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp();
  runApp(MyApp());
}

class MyApp extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Tummy Box Partner App',
      home: LoginPage(),
    );
  }
}
