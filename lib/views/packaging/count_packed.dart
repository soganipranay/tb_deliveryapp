import 'package:flutter/material.dart';
import 'package:tb_deliveryapp/services/firebase_service.dart';
import 'package:tb_deliveryapp/views/packaging/location_view.dart';
import 'package:tb_deliveryapp/views/packaging/packed_qr_view.dart';

class CountPackedOrders extends StatefulWidget {
  final String meal;
  final List<String>? locationNames;

  CountPackedOrders({Key? key, required this.meal, required this.locationNames})
      : super(key: key);

  @override
  State<CountPackedOrders> createState() => _CountPackedOrdersState();
}

class _CountPackedOrdersState extends State<CountPackedOrders> {
  final FirebaseService firebaseService = FirebaseService();

  late String profileType = "";
  Map<String, int> locationPackedOrders = {};
  Map<String, int> locationPendingOrders = {};

  late int totalOrders = 0;
  @override
  void initState() {
    super.initState();
    countPackedOrders(); // Call the function to fetch the data
    firebaseService
        .fetchTotalOrders(widget.locationNames, widget.meal)
        .then((value) {
      setState(() {
        totalOrders = value;
      });
    });
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
        body: Container(
            child: Column(
          children: [

            LocationView(
              locationNames: widget.locationNames,
              mealType: widget.meal,
              locationPackedOrders:
                  locationPackedOrders, // Pass the location-specific data
              locationPendingOrders:
                  locationPendingOrders, // Pass the location-specific data
            ),
          ],
        )));
  }

  // Count the total number of orders packed today
  Future<void> countPackedOrders() async {
    for (String location in widget.locationNames ?? []) {
      // Fetch the total packed orders for the current location
      final packedOrders = await firebaseService.fetchOrderByOrderStatus(
          'Order Packed', location, widget.meal);

      // Fetch the total pending orders for the current location
      final pendingOrders = await firebaseService.fetchOrderByOrderStatus(
          'Pending', location, widget.meal);

      // Update the locationPackedOrders and locationPendingOrders maps
      setState(() {
        locationPackedOrders[location] = packedOrders.length;
        locationPendingOrders[location] = pendingOrders.length;
        print(locationPackedOrders );
        print(locationPendingOrders);

      });
    }
  }
}
