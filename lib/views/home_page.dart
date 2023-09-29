import 'package:flutter/material.dart';
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

  @override
  void initState() {
    super.initState();
    initializeData();
  }

  Future<void> initializeData() async {
    FirebaseService firebaseService = FirebaseService();
        print("deliveryPartnerLocations $deliveryPartnerLocations");

    List<dynamic>? locations = await firebaseService
        .getDeliveryLocationsForPartnerId(widget.partnerId);

    if (locations != null) {
      setState(() {
        deliveryPartnerLocations = locations;
        print("deliveryPartnerLocations $deliveryPartnerLocations");
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
      ),
      body: Container(
        child: Column(
          children: [
            ElevatedButton(
              onPressed: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => ProcessView(
                      meal: "breakfast",
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
                      meal: "lunch",
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
                      meal: "dinner",
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
