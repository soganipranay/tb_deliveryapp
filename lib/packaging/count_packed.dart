import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:tb_deliveryapp/packaging/packed_qr_view.dart';

class CountPackedOrders extends StatefulWidget {
  CountPackedOrders({Key? key}) : super(key: key);

  @override
  State<CountPackedOrders> createState() => _CountPackedOrdersState();
}

class _CountPackedOrdersState extends State<CountPackedOrders> {
  late String profileType;
  late int totalPackedOrders = 0;
  late int totalOrders = 0;
  @override
  void initState() {
    super.initState();
    countPackedOrders(); // Call the function to fetch the data
    fetchTotalOrders().then((value) {
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
                "You have packed $totalPackedOrders orders today and ${totalOrders - totalPackedOrders} orders is remaining"),
          ],
        )));
  }

  // Count the total number of orders packed today
 Future<void> countPackedOrders() async {
    // Fetch the total packed orders
    final orders = await fetchOrderByPackedStatus('Order Packed');

    setState(() {
      // Update the totalPackedOrders variable and trigger a UI update
      totalPackedOrders = orders.length;
    });
  }

  String getCurrentTime() {
    DateTime now = DateTime.now();
    String formattedTime = "${now.hour}:${now.minute}:${now.second}";
    return formattedTime;
  }

  Future<Map<String, dynamic>> fetchTimeForScanning() async {
    CollectionReference timeCollection =
        FirebaseFirestore.instance.collection('Time');

    // Query the 'Breakfast' document
    DocumentSnapshot breakfastSnapshot =
        await timeCollection.doc('breakfast').get();
    // Extract startTime and endTime from 'Breakfast' document
    Map<String, dynamic> breakfastData =
        breakfastSnapshot.data() as Map<String, dynamic>;

    // Query the 'Lunch' document
    DocumentSnapshot lunchSnapshot = await timeCollection.doc('lunch').get();
    // Extract startTime and endTime from 'Lunch' document
    Map<String, dynamic> lunchData =
        lunchSnapshot.data() as Map<String, dynamic>;

    // Query the 'Dinner' document
    DocumentSnapshot dinnerSnapshot = await timeCollection.doc('dinner').get();
    // Extract startTime and endTime from 'Dinner' document
    Map<String, dynamic> dinnerData =
        dinnerSnapshot.data() as Map<String, dynamic>;

    // Function to convert Firestore Timestamp to DateTime and format as HH:mm:ss
    String timestampToFormattedTime(Timestamp timestamp) {
      DateTime dateTime = timestamp.toDate();
      String formattedTime =
          "${dateTime.hour.toString().padLeft(2, '0')}:${dateTime.minute.toString().padLeft(2, '0')}:${dateTime.second.toString().padLeft(2, '0')}";
      return formattedTime;
    }

    // Create a map to hold the start and end times for each slot
    Map<String, dynamic> timeSlots = {
      'Breakfast': {
        'startTime': timestampToFormattedTime(breakfastData['StartTime']),
        'endTime': timestampToFormattedTime(breakfastData['EndTime']),
      },
      'Lunch': {
        'startTime': timestampToFormattedTime(lunchData['StartTime']),
        'endTime': timestampToFormattedTime(lunchData['EndTime']),
      },
      'Dinner': {
        'startTime': timestampToFormattedTime(dinnerData['StartTime']),
        'endTime': timestampToFormattedTime(dinnerData['EndTime']),
      },
    };
    print('Time Slots: $timeSlots');
    return timeSlots;
  }


  Future<int> fetchTotalOrders() async {
    
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

      Map<String, dynamic> timeSlots = await fetchTimeForScanning();
      String currentTime = getCurrentTime();

      if (DateTime.parse(currentTime)
              .isAfter(DateTime.parse(timeSlots['breakfast']['startTime'])) &&
          DateTime.parse(currentTime)
              .isBefore(DateTime.parse(timeSlots['breakfast']['endTime']))) {
                print('Current Time: ${DateTime.parse(currentTime)}');
        if (profileType == "Child") {
          QuerySnapshot querySnapshot = await ordersCollection
              .where('deliveryDate', isGreaterThanOrEqualTo: currentDate)
              .where('deliveryDate', isLessThan: nextDate)
              .where('orderType', whereIn: ['breakfast', 'lunch'])
              .where('profileType', isEqualTo: profileType)
              .get();

          querySnapshot.docs.forEach((QueryDocumentSnapshot documentSnapshot) {
            // Get the reference of each document
            DocumentReference documentReference = documentSnapshot.reference;
            print('Document Path: ${documentReference.path}');
            // get the count of the documents
            totalOrders = querySnapshot.docs.length;
          });
        } else if (profileType == "Adult") {
          QuerySnapshot querySnapshot = await ordersCollection
              .where('deliveryDate', isGreaterThanOrEqualTo: currentDate)
              .where('deliveryDate', isLessThan: nextDate)
              .where('orderType', isEqualTo: 'breakfast')
              .where('profileType', isEqualTo: profileType)
              .get();
          querySnapshot.docs.forEach((QueryDocumentSnapshot documentSnapshot) {
            // Get the reference of each document
            DocumentReference documentReference = documentSnapshot.reference;
            print('Document Path: ${documentReference.path}');
            // get the count of the documents
            totalOrders = querySnapshot.docs.length;
          });
        }
      } else if (DateTime.parse(currentTime)
              .isAfter(DateTime.parse(timeSlots['lunch']['startTime'])) &&
          DateTime.parse(currentTime)
              .isBefore(DateTime.parse(timeSlots['lunch']['endTime']))) {
        QuerySnapshot querySnapshot = await ordersCollection
            .where('deliveryDate', isGreaterThanOrEqualTo: currentDate)
            .where('deliveryDate', isLessThan: nextDate)
            .where('orderType', isEqualTo: 'lunch')
            .where('profileType', isEqualTo: 'Adult')
            .get();

        querySnapshot.docs.forEach((QueryDocumentSnapshot documentSnapshot) {
          // Get the reference of each document
          DocumentReference documentReference = documentSnapshot.reference;
          print('Document Path: ${documentReference.path}');
          // get the count of the documents
          totalOrders = querySnapshot.docs.length;
        });
      } else if (DateTime.parse(currentTime)
              .isAfter(DateTime.parse(timeSlots['dinner']['startTime'])) &&
          DateTime.parse(currentTime)
              .isBefore(DateTime.parse(timeSlots['dinner']['endTime']))) {
        QuerySnapshot querySnapshot = await ordersCollection
            .where('deliveryDate', isGreaterThanOrEqualTo: currentDate)
            .where('deliveryDate', isLessThan: nextDate)
            .where('orderType', isEqualTo: 'dinner')
            .where('profileType', isEqualTo: 'Adult')
            .get();

        querySnapshot.docs.forEach((QueryDocumentSnapshot documentSnapshot) {
          // Get the reference of each document
          DocumentReference documentReference = documentSnapshot.reference;
          print('Document Path: ${documentReference.path}');
          // get the count of the documents
          totalOrders = querySnapshot.docs.length;
        });
      }

      print('Total Orders: $totalOrders');
      return totalOrders;
    } catch (e) {
      print("Error fetching total order references: $e");
      return totalOrders;
    }
  }

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
          .where('deliveryDate', isLessThan: nextDate)
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
      print("Error fetching order references: $e");
      return [];
    }
  }
}
