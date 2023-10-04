import 'package:flutter/material.dart';
import 'package:tb_deliveryapp/services/auth_manager.dart';
import 'package:tb_deliveryapp/views/process_view.dart';
import 'package:tb_deliveryapp/services/firebase_service.dart';

class HomeView extends StatefulWidget {
  final bool isLoggedIn;
  final String partnerId;
  const HomeView({Key? key, required this.isLoggedIn, required this.partnerId})
      : super(key: key);

  @override
  State<HomeView> createState() => _HomeViewState();
}

class _HomeViewState extends State<HomeView> {
  List<dynamic>? deliveryPartnerLocations = []; // Change the data type here
  Map<String, dynamic> partnerDetails = {};
  @override
  void initState() {
    super.initState();
    initializeData();
  }

  Future<void> initializeData() async {
    FirebaseService firebaseService = FirebaseService();
    List<dynamic>? locations =
        await firebaseService.getLocationsForPartnerId(widget.partnerId);
    Map<String, dynamic> details =
        await firebaseService.getPartnerDetails(widget.partnerId);

    if (locations != null) {
      setState(() {
        deliveryPartnerLocations = locations;
        partnerDetails = details; // Store the details in the state
        print("Partner Details: $partnerDetails");
        print("Home deliveryPartnerLocations $deliveryPartnerLocations");
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Tummy Box Partner App'),
        leading: Padding(
          padding: const EdgeInsets.all(6.0),
          child: Image.asset(
            'assets/TummyBox_Logo_wbg.png',
            width: 40,
            height: 40,
          ),
        ),
        actions: [
          IconButton(onPressed: 
          (){
             AuthManager().logoutUser(context);
          }, icon: Icon(Icons.logout))
        ],
      ),
      body: Container(
        child: Column(
          children: [

                    Text('Name: ${partnerDetails['display_name']}'),
                    Text('Email: ${partnerDetails['email']}'),
                    Text('Phone Number: ${partnerDetails['phone_number']}'),
                    // Add more details as needed
                  
            ElevatedButton(
              onPressed: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => ProcessView(
                      meal: "Breakfast",
                      locations: deliveryPartnerLocations,
                    ),
                  ),
                );
              },
              child: const Text('Breakfast'),
            ),
            ElevatedButton(
              onPressed: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => ProcessView(
                      meal: "Lunch",
                      locations: deliveryPartnerLocations,
                    ),
                  ),
                );
              },
              child: const Text('Lunch'),
            ),
            ElevatedButton(
              onPressed: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => ProcessView(
                      meal: "Dinner",
                      locations: deliveryPartnerLocations,
                    ),
                  ),
                );
              },
              child: const Text('Dinner'),
            ),
          ],
        ),
      ),
    );
  }
}
