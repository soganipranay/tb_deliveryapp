import 'package:tb_deliveryapp/all.dart';



void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  await Firebase.initializeApp(
      options: DefaultFirebaseOptions.currentPlatform // Add thiis.
      );
//       final storageRef = FirebaseStorage.instance.ref().child("files/uid");
// try {
//   final listResult = await storageRef.listAll();
// } on FirebaseException catch (e) {
//   // Caught an exception from Firebase.
//   print("Failed with error '${e.code}': ${e.message}");
// }
  await FirebaseService().initNotifications();
  runApp(MyApp());
}

class MyApp extends StatelessWidget {
  final AuthManager authManager = AuthManager();

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Tummy Box Partner App',
      theme: ThemeData(
          // Define your app's theme here
          // For example, you can set primary colors, fonts, etc.
          ),
      home: FutureBuilder<Map<String, String>>(
        future: getPartnerInfo(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const MaterialApp(
              home: Scaffold(
                body: Center(
                  child: CircularProgressIndicator(),
                ),
              ),
            );
          } else {
            final bool isLoggedIn = snapshot.hasData;
            final String partnerId = snapshot.data?['partnerId'] ?? "";
            final String userType = snapshot.data?['userType'] ?? "";

            return FutureBuilder<String?>(
              future: authManager.getPartnerId(),
              builder: (context, partnerIdSnapshot) {
                // final String? partnerId = partnerIdSnapshot.data ?? "";
                print("partnerId $partnerId");
                print("userType $userType");
                if (partnerId.isEmpty || userType.isEmpty) {
                  // If partnerId or userType is empty, log the user out and show the login page
                  authManager.logoutUser(context);
                  return LoginPage();
                }
                // Check if the user is authenticated and decide which screen to display
                else {
                  final Widget initialRoute = isLoggedIn
                      ? HomeView(
                          isLoggedIn: true,
                          partnerId: partnerId,
                          partnerType: userType,
                        )
                      : LoginPage();

                  return initialRoute;
                }
              },
            );
          }
        },
      ),
    );
  }

  Future<Map<String, String>> getPartnerInfo() async {
    final String partnerId = await authManager.getPartnerId();
    final String userType = await authManager.getPartnerUserType();
    print(userType);
    return {
      'partnerId': partnerId,
      'userType': userType,
    };
  }
}
