import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:tb_deliveryapp/views/home_page.dart';
import 'package:tb_deliveryapp/services/auth_manager.dart';
import 'package:tb_deliveryapp/views/loginAuth/login_page.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp();
  runApp(MyApp());
}

class MyApp extends StatelessWidget {
  final AuthManager authManager =
      AuthManager(); // Create an instance of AuthManager

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Tummy Box Partner App',
      theme: ThemeData(
          // Define your app's theme here
          // For example, you can set primary colors, fonts, etc.
          ),
      home: FutureBuilder<bool>(
        future: authManager.isUserLoggedIn(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return MaterialApp(
              home: Scaffold(
                body: Center(
                  child: CircularProgressIndicator(),
                ),
              ),
            ); 
          } else {
            final bool isLoggedIn = snapshot.data ?? false;

            return FutureBuilder<String?>(
              future: authManager.getPartnerId(),
              builder: (context, partnerIdSnapshot) {
                final String? partnerId = partnerIdSnapshot.data ?? "";
                print("partnerId $partnerId");

                // Check if the user is authenticated and decide which screen to display
                final Widget initialRoute = isLoggedIn
                    ? HomeView(
                        isLoggedIn: false,
                        partnerId: partnerId ?? "",
                        partnerType: '',
                      )
                    : LoginPage();

                return initialRoute;
              },
            );
          }
        },
      ),
    );
  }
}
