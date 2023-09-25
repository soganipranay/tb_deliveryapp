import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:tb_deliveryapp/services/firebase_service.dart';
import 'package:tb_deliveryapp/views/packaging/packed_qr_view.dart';

class CountPackedOrders extends StatefulWidget {
  CountPackedOrders({Key? key}) : super(key: key);

  @override
  State<CountPackedOrders> createState() => _CountPackedOrdersState();
}

class _CountPackedOrdersState extends State<CountPackedOrders> {
  final FirebaseService firebaseService = FirebaseService();

  late String profileType = "";
  late int totalPackedOrders = 0;
  late int totalOrders = 0;
  @override
  void initState() {
    super.initState();
    countPackedOrders(); // Call the function to fetch the data
    firebaseService.fetchTotalOrders(totalOrders, profileType).then((value) {
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
            Text('Welcome to Tummy Box Partner App'),
            Text('You have total of $totalOrders orders to pack today'),
            // if(y>0):
            ElevatedButton(
              onPressed: () {
                Navigator.push(context,
                    MaterialPageRoute(builder: (context) => PackedQRView()));
              },
              child: Text('You have packed $totalPackedOrders orders today'),
            ),
            Text(
                "You have packed $totalPackedOrders orders today and ${(totalOrders - totalPackedOrders) < 0 ? 0 : (totalOrders - totalPackedOrders)} orders is remaining"),
          ],
        )));
  }

  // Count the total number of orders packed today
  Future<void> countPackedOrders() async {
    // Fetch the total packed orders
    final orders =
        await firebaseService.fetchOrderByPackedStatus('Order Packed');

    setState(() {
      // Update the totalPackedOrders variable and trigger a UI update
      totalPackedOrders = orders.length;
    });
  }
}
