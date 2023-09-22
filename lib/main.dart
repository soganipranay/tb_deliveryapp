import 'login_page.dart';
import 'auth_manager.dart';
import 'package:flutter/material.dart';
import 'package:tb_deliveryapp/home_page.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:tb_deliveryapp/packed_qr_view.dart';


void main() async {
  // Initialize Firebase
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp();
  bool isLoggedIn = await isUserLoggedIn();

  runApp(MyHome(isLoggedIn: isLoggedIn));
  // runApp(MaterialApp(home: MyHome()));
}

class MyHome extends StatelessWidget {
  final bool isLoggedIn;

  const MyHome({Key? key, required this.isLoggedIn}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Tummy Box Partner App',
      home:const HomeView(isLoggedIn: true),
    );
  }
}
