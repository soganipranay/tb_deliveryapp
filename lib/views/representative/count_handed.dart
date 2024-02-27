import 'package:flutter/material.dart';
import 'package:tb_deliveryapp/all.dart';


class RepresentativeOrders extends StatefulWidget {
  final String meal;
  final List<dynamic>? locationNames;

  RepresentativeOrders({Key? key, required this.meal, required this.locationNames})
      : super(key: key);

  @override
  State<RepresentativeOrders> createState() => _RepresentativeOrdersState();
}

class _RepresentativeOrdersState extends State<RepresentativeOrders> {
  final FirebaseService firebaseService = FirebaseService();
  int totalDeliveredOrders = 0;
  late String profileType = "";
  Map<String, int> locationDeliveredOrders = {};
  Map<String, int> locationHandlingOrders = {};

  late int totalOrders = 0;
  List<Map<String, dynamic>> handedOrdersList = [];
  List<Map<String, dynamic>> deliveredOrdersList = [];

  List<dynamic>? locationNames; // Declare the variable

  @override
  void initState() {
    super.initState();
    locationNames =
        widget.locationNames; // Initialize it with widget.locationNames
    countDeliveredOrders(); // Call the function to fetch the data
    print("handedOrdersList $handedOrdersList");
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Packaging for ${widget.meal}'),
        leading: Padding(
          padding: const EdgeInsets.all(6.0),
          child: Image.asset(
            'assets/TummyBox_Logo_wbg.png', // Replace with the actual path to your logo image
            width: 40, // Adjust the width as needed
            height: 40, // Adjust the height as needed
          ),
        ),
      ),
      body: SingleChildScrollView(
        child: Column(
          children: locationNames?.map((locationName) {
                final int deliveredOrders =
                    locationHandlingOrders[locationName] ?? 0;
                final int handedOrders =
                    locationDeliveredOrders[locationName] ?? 0;

                return ListTile(
                  title: Text(locationName),
                  subtitle: Text(
                    "Handling: $handedOrders, Delivered: $deliveredOrders",
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      color: Colors.green,
                    ),
                  ),
                  tileColor: Colors.blue.withOpacity(0.1),
                  onTap: () {
                    Navigator.of(context).pushReplacement(MaterialPageRoute(
                        builder: (context) => HandlingQRView(
                              deliveredOrdersList: deliveredOrdersList,
                            ))); // Pass locationNames
                    // Handle tap event if needed
                  },
                );
              }).toList() ??
              [],
        ),
      ),
    );
  }

  Future<void> countDeliveredOrders() async {
    for (String location in widget.locationNames ?? []) {
      // Fetch the total handed orders for the current location
      final Map<String, dynamic> handedOrders = await firebaseService
          .fetchOrderByOrderStatus('Delivered', location, widget.meal);
      final int totalDeliveredOrders = handedOrders['totalOrders'];
      final List<Map<String, dynamic>> handedOrdersData = handedOrders[
          'ordersList']; // Use a different variable name to avoid conflict

      // Fetch the total delivered orders for the current location
      final Map<String, dynamic> deliveredOrders = await firebaseService
          .fetchOrderByOrderStatus('Handling', location, widget.meal);
      final int totalHandlingOrders = deliveredOrders['totalOrders'];
      final List<Map<String, dynamic>> deliveredOrdersData = deliveredOrders[
          'ordersList']; // Use a different variable name to avoid conflict

      // Update the locationDeliveredOrders and locationHandlingOrders maps
      setState(() {
        locationDeliveredOrders[location] = totalDeliveredOrders;
        locationHandlingOrders[location] = totalHandlingOrders;

        // Update the lists
        handedOrdersList.addAll(handedOrdersData);
        deliveredOrdersList.addAll(deliveredOrdersData);

        print(" handedOrdersList $handedOrdersList");
        print(" deliveredOrdersList $deliveredOrdersList");

        print("locationDeliveredOrders ${locationDeliveredOrders[location]}");
        print("locationHandlingOrders ${locationHandlingOrders[location]}");
      });
    }
  }
}
