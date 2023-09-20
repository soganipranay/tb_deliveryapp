import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'login_page.dart';

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
