import 'package:flutter/material.dart';
import '../views/loginAuth/login_page.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:tb_deliveryapp/views/home_page.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:tb_deliveryapp/services/firebase_service.dart';

class AuthManager {
  FirebaseService firebaseService = FirebaseService();
  final FirebaseAuth _auth = FirebaseAuth.instance;

  Future<void> signInWithEmailAndPassword(
      String email, String password, BuildContext context) async {
    try {
      String message;
      UserCredential userCredential = await _auth.signInWithEmailAndPassword(
        email: email,
        password: password,
      );

      // Retrieve the delivery partner ID based on the logged-in user's email
      String? deliveryPartnerId =
          await firebaseService.getDeliveryPartnerId(email, context);
      String? representativeId =
          await firebaseService.getRepresentativeId(email, context);

      if (deliveryPartnerId != null) {

        await saveUserLoggedIn(true);
      SharedPreferences prefs = await SharedPreferences.getInstance();
      await prefs.setString('partnerId', deliveryPartnerId);
        Navigator.of(context).pushReplacement(MaterialPageRoute(
          builder: (context) =>
              HomeView(isLoggedIn: true, partnerId: deliveryPartnerId),
        ));
      } else if (representativeId != null) {
        await saveUserLoggedIn(true);
        Navigator.of(context).pushReplacement(MaterialPageRoute(
          builder: (context) =>
              HomeView(isLoggedIn: true, partnerId: representativeId),
        ));
      } else {
        // No partner found for that email
        ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('No partner found for that email.')));
      }
    } on FirebaseAuthException catch (e) {
      // Handle Firebase Authentication errors (e.g., user-not-found, wrong-password)
      String message;
      if (e.code == 'user-not-found') {
        message = 'No user found for that email.';
      } else if (e.code == 'wrong-password') {
        message = 'Wrong password provided for that user.';
      } else {
        message = 'Something went wrong. Please try again.';
      }
      ScaffoldMessenger.of(context)
          .showSnackBar(SnackBar(content: Text(message)));
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
    Future<String> getPartnerId() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    return prefs.getString('partnerId')?? "";
  }
}
