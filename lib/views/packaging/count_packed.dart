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

  late String profileType = "";
  Map<String, int> locationPackedOrders = {};
  Map<String, int> locationPendingOrders = {};

  late int totalOrders = 0;
  @override
  void initState() {
    super.initState();
    countPackedOrders(); // Call the function to fetch the data

    firebaseService.fetchTotalOrders("AU Bank", widget.meal).then((value) {
      if (mounted) {
        setState(() {
          totalOrders = value;
        });
      }
    });
    print("totalOrders $totalOrders");
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
          children: widget.locationNames?.map((locationName) {
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
                        builder: (context) => PackedQRView()));
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
          .fetchOrderByOrderStatus('Order Packed', location, widget.meal);
      print("packedOrders: $packedOrders");
      final int totalpackedOrders = packedOrders['totalOrders'];

      // Fetch the total pending orders for the current location
      final Map<String, dynamic> pendingOrders = await firebaseService
          .fetchOrderByOrderStatus('Pending', location, widget.meal);
      print("pendingOrders $pendingOrders");
      final int totalPendingOrders = pendingOrders['totalOrders'];

      // Update the locationPackedOrders and locationPendingOrders maps
      setState(() {
        locationPackedOrders[location] = totalpackedOrders;
        locationPendingOrders[location] = totalPendingOrders;
        print("locationPackedOrders ${locationPackedOrders[location]}");
        print("locationPendingOrders ${locationPendingOrders[location]}");
      });
    }
  }
}
