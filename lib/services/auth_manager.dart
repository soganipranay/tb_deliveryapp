import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:tb_deliveryapp/services/firebase_service.dart';
import 'package:tb_deliveryapp/views/home_page.dart';

import '../views/login_page.dart';

class AuthManager{
  FirebaseService firebaseService = FirebaseService();
  final FirebaseAuth _auth = FirebaseAuth.instance;

Future<void> signInWithEmailAndPassword(
      String email, String password, BuildContext context) async {
    try {
      UserCredential userCredential =
          await _auth.signInWithEmailAndPassword(
        email: email,
        password: password,
      );

      // Successful Sign In
      Navigator.of(context).pushReplacement(MaterialPageRoute(
        builder: (context) => const HomeView(isLoggedIn: true),
      ));
    } on FirebaseAuthException catch (e) {
      String message;
      if (e.code == 'user-not-found') {
        message = 'No user found for that email.';
      } else if (e.code == 'wrong-password') {
        message = 'Wrong password provided for that user.';
      } else {
        message = 'Something went wrong. Please try again.';
      }
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(message)));
    }
  }

// Function to store user login state
Future<void> saveUserLoggedIn(bool isLoggedIn) async {
  SharedPreferences prefs = await SharedPreferences.getInstance();
  await prefs.setBool('isLoggedIn', isLoggedIn);
}

// Function to check if user is logged in
Future<bool> isUserLoggedIn() async {
  SharedPreferences prefs = await SharedPreferences.getInstance();
  return prefs.getBool('isLoggedIn') ?? false;
}

Future<void> logoutUser(BuildContext context) async {
  await saveUserLoggedIn(false); // Clear login state
  // Navigate back to the login page
  Navigator.of(context).pushReplacement(MaterialPageRoute(
    builder: (context) => LoginPage(),
  ));
}

}