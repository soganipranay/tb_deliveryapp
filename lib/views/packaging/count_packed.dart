import 'package:flutter/material.dart';
import 'package:tb_deliveryapp/services/firebase_service.dart';
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
  int totalPackedOrders = 0;
  late String profileType = "";
  Map<String, int> locationPackedOrders = {};
  Map<String, int> locationPendingOrders = {};

  late int totalOrders = 0;
  List<Map<String, dynamic>> packedOrdersList = [];
  List<Map<String, dynamic>> pendingOrdersList = [];

  List<String>? locationNames; // Declare the variable

  @override
  void initState() {
    super.initState();
    locationNames =
        widget.locationNames; // Initialize it with widget.locationNames
    countPackedOrders(); // Call the function to fetch the data
    print("packedOrdersList $packedOrdersList");
    // firebaseService.fetchTotalOrders("AU Bank", widget.meal).then((value) {
    //   if (mounted) {
    //     setState(() {
    //       totalOrders = value;
    //     });
    //   }
    // }
    // );
    // print("totalOrders $totalOrders");
    // print("location names ${widget.locationNames}");
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
      body: SingleChildScrollView(
        child: Column(
          children: locationNames?.map((locationName) {
                final int pendingOrders =
                    locationPendingOrders[locationName] ?? 0;
                final int packedOrders =
                    locationPackedOrders[locationName] ?? 0;

                return ListTile(
                  title: Text(locationName),
                  subtitle: Text(
                    "Pending: $pendingOrders, Packed: $packedOrders",
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      color: Colors.green,
                    ),
                  ),
                  tileColor: Colors.blue.withOpacity(0.1),
                  onTap: () {
                    Navigator.of(context).pushReplacement(MaterialPageRoute(
                        builder: (context) => PackedQRView(
                              pendingOrdersList: pendingOrdersList,
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

  Future<void> countPackedOrders() async {
    for (String location in widget.locationNames ?? []) {
      // Fetch the total packed orders for the current location
      final Map<String, dynamic> packedOrders = await firebaseService
          .fetchOrderByOrderStatus('Packed', location, widget.meal);
      final int totalPackedOrders = packedOrders['totalOrders'];
      final List<Map<String, dynamic>> packedOrdersData = packedOrders[
          'ordersList']; // Use a different variable name to avoid conflict

      // Fetch the total pending orders for the current location
      final Map<String, dynamic> pendingOrders = await firebaseService
          .fetchOrderByOrderStatus('Pending', location, widget.meal);
      final int totalPendingOrders = pendingOrders['totalOrders'];
      final List<Map<String, dynamic>> pendingOrdersData = pendingOrders[
          'ordersList']; // Use a different variable name to avoid conflict

      // Update the locationPackedOrders and locationPendingOrders maps
      setState(() {
        locationPackedOrders[location] = totalPackedOrders;
        locationPendingOrders[location] = totalPendingOrders;

        // Update the lists
        packedOrdersList.addAll(packedOrdersData);
        pendingOrdersList.addAll(pendingOrdersData);

        print(" packedOrdersList $packedOrdersList");
        print(" pendingOrdersList $pendingOrdersList");

        print("locationPackedOrders ${locationPackedOrders[location]}");
        print("locationPendingOrders ${locationPendingOrders[location]}");
      });
    }
  }
}
