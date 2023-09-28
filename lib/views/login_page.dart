import '../services/auth_manager.dart'; 
import 'package:flutter/material.dart';
import 'package:tb_deliveryapp/widgets/bgWidget.dart';
import 'package:tb_deliveryapp/views/home_page.dart';
import 'package:firebase_auth/firebase_auth.dart';


class LoginPage extends StatefulWidget {
  @override
  _LoginPageState createState() => _LoginPageState();
}

class _LoginPageState extends State<LoginPage> {

final AuthManager _authManager = AuthManager();
  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();

  void _signIn() {
    final String email = _emailController.text.trim();
    final String password = _passwordController.text.trim();
    _authManager.signInWithEmailAndPassword(email, password, context);
  }
 
  
  @override
  Widget build(BuildContext context) {
    return Scaffold(
        appBar: AppBar(
          title: const Text('Tummy Box Partner App'),
          leading: Padding(
            padding: const EdgeInsets.all(6.0),
            child: Image.asset(
              'assets/TummyBox_Logo_wbg.png', // Replace with the actual path to your logo image
              width: 40, // Adjust the width as needed
              height: 40, // Adjust the height as needed
            ),
          ),
        ),
        body: Stack(
          children: [
            const BackgroundWidget(),
            Center(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Text(
                    'Login',
                    style: TextStyle(
                      fontSize: 24,
                      fontWeight: FontWeight.bold,
                      color: Colors.black,
                    ),
                  ),
                  const SizedBox(height: 30),
                  TextFormField(
                    controller: _emailController,
                    decoration: InputDecoration(
                      labelText: 'Email',
                      labelStyle: const TextStyle(color: Colors.black),
                      filled: true,
                      fillColor: Colors.white.withOpacity(0.2),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(10),
                      ),
                    ),
                  ),
                  const SizedBox(height: 20),
                  TextFormField(
                    controller: _passwordController,
                    obscureText: false,
                    decoration: InputDecoration(
                      labelText: 'Password',
                      labelStyle: const TextStyle(color: Colors.black),
                      filled: true,
                      fillColor: Colors.white.withOpacity(0.2),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(10),
                      ),
                    ),
                  ),
                  const SizedBox(height: 30),
                  ElevatedButton(
                    onPressed: _signIn,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.orange,
                      padding: const EdgeInsets.symmetric(
                          horizontal: 40, vertical: 15),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(10),
                      ),
                    ),
                    child: const Text(
                      'Login',
                      style: TextStyle(
                        fontSize: 18,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          )
        ]
  )
  );
  }
  
}
  
  
  // String email = '';
  // String password = '';
  
  // void _loginCheck(){
  //   print('Email: $email');
  //   print('Password: $password');
  //   if (email == "abc@tummybox.in" && password == "password"){
  //     Navigator.of(context).push(MaterialPageRoute
  //                   (
  //                     builder: (context) => const PackedQRView(),
  //                   ));
  //   }
  //   else{
  //     print('Wrong Email ID or Password');
  //     showDialog(
  //             context: context,
  //             builder: (BuildContext context) {
  //               return AlertDialog(
  //                 title: const Text('Unable to Login'),
  //                 content: const Text('Wrong Email ID or Passoword was entered. Please try again.'),
  //                 actions: <Widget>[
  //                   // TextButton(
  //                   //   onPressed: () {
  //                   //     Navigator.of(context).pop(); // Close the dialog
  //                   //   },
  //                   //   child: Text('Cancel'),
  //                   // ),
  //                   ElevatedButton(
  //                     onPressed: () {
  //                       // Perform the retry action
  //                       Navigator.of(context).pop(); // Close the dialog
  //                     },
  //                     style: ElevatedButton.styleFrom(
  //                       backgroundColor: Colors.orange, // Use the accent color
  //                     ),child: const Text('Retry'),
  //                   )
  //                 ]
  //               );
  //             }
  //     );
  //   }
  // }
