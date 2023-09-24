import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class VerifyCountUpdate extends StatefulWidget {
  const VerifyCountUpdate({super.key});

  @override
  State<VerifyCountUpdate> createState() => _VerifyCountUpdateState();
}

class _VerifyCountUpdateState extends State<VerifyCountUpdate> {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Verify Count Update'),
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
          Text('Total number of orders for this locatio: '),
          ListTile(
            title: Text('Order 1'),
            subtitle: Text('Order 1 details'),
            trailing: Text('Order 1 count'),
            // Add an input field to enter the count
          ),
        ],
      )),
    );
  }

  Widget count 
  Future<List<Map<String, dynamic>>> fetchOrderByPackedStatus(
      orderStatus) async {
    try {
      CollectionReference ordersCollection =
          FirebaseFirestore.instance.collection('Orders');
      DateTime currentDate = DateTime.now();
      int year = currentDate.year; // Year component
      int month = currentDate.month; // Month component (1 to 12)
      int day = currentDate.day; // Day component

      currentDate = DateTime(year, month, day);

      DateTime nextDate = currentDate.add(const Duration(days: 1));
      print('Current Date: $currentDate');
      print('Next Date: $nextDate');
      QuerySnapshot querySnapshot = await ordersCollection
          .where('deliveryDate', isGreaterThanOrEqualTo: currentDate)
          .where('deliveryDate', isLessThan: nextDate).where('Status', isEqualTo: orderStatus)
          .where('Status', isEqualTo: orderStatus)
          .get();
      querySnapshot.docs.forEach((QueryDocumentSnapshot documentSnapshot) {
        // Get the reference of each document
        DocumentReference documentReference = documentSnapshot.reference;

        // Now, you can use this reference as needed
        // For example, you can print the path of the document:
        print('Document Path: ${documentReference.path}');
      });

      List<Map<String, dynamic>> ordersList = [];
      querySnapshot.docs.forEach((documentSnapshot) {
        Map<String, dynamic> data =
            documentSnapshot.data() as Map<String, dynamic>;
        String orderName = data['orderName'];
        int quantity = data['numberOfItems'];
        String orderType = data['orderType'];
        String orderStatus = data['Status'];

        Map<String, dynamic> orderMap = {
          'orderName': orderName,
          'quantity': quantity,
          'orderType': orderType,
          'orderRef': documentSnapshot.reference.id,
          'orderStatus': orderStatus
        };
        ordersList.add(orderMap);
      });

      return ordersList;
    } catch (e) {
      print("Error fetching order count references: $e");
      return [];
    }
  }
}
