import 'package:tb_deliveryapp/all.dart';


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
      List? deliveryPartnerId =
          await firebaseService.getDeliveryPartnerId(email, context);
      List? representativeId =
          await firebaseService.getRepresentativeId(email, context);
      print("deliveryPartnerId $deliveryPartnerId");
      print("representativeId $representativeId");

      if (deliveryPartnerId?[0][1] != null) {
        await saveUserLoggedIn(true);
        SharedPreferences prefs = await SharedPreferences.getInstance();
        await prefs.setString('partnerId', deliveryPartnerId?[0][1]);
        await prefs.setString('userType', deliveryPartnerId?[0][0]);

        Navigator.of(context).pushReplacement(MaterialPageRoute(
          builder: (context) => HomeView(
              isLoggedIn: true,
              partnerId: deliveryPartnerId?[0][1],
              partnerType: deliveryPartnerId?[0][0]),
        ));
      } else if (representativeId?[0][1] != null) {
        await saveUserLoggedIn(true);
        SharedPreferences prefs = await SharedPreferences.getInstance();
        await prefs.setString('partnerId', representativeId?[0][1]);
        await prefs.setString('userType', representativeId?[0][0]);

        Navigator.of(context).pushReplacement(MaterialPageRoute(
          builder: (context) => HomeView(
              isLoggedIn: true,
              partnerId: representativeId?[0][1],
              partnerType: representativeId?[0][0]),
        ));
      } else {
           print('No partner found for that email.');
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
    SharedPreferences prefs = await SharedPreferences.getInstance();
    await prefs.remove('partnerId'); // Remove partnerId
    await prefs.remove('userType');
    Navigator.of(context).pushReplacement(MaterialPageRoute(
      builder: (context) => LoginPage(),
    ));
  }

  Future<String> getPartnerId() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    return prefs.getString('partnerId') ?? "";
  }

  Future<String> getPartnerUserType() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    return prefs.getString('userType') ?? "";
  }
}
