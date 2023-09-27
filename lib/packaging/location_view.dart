import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class LocationView extends StatefulWidget {
  const LocationView({super.key});

  @override
  State<LocationView> createState() => _LocationViewState();
}

class _LocationViewState extends State<LocationView> {
  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      child: Container(
        height: MediaQuery.of(context).size.height * 0.7,
        child: LocationList(), // Display the list of locations here
      ),
    );
  }
}

class LocationList extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return StreamBuilder<QuerySnapshot>(
      stream: FirebaseFirestore.instance
          .collection('Orders') // Replace with your collection name
          .snapshots(),
      builder: (context, snapshot) {
        if (!snapshot.hasData) {
          return Center(
            child: CircularProgressIndicator(),
          );
        }

        // Process the snapshot data and filter out common locations
        final locations = <String>{};
        snapshot.data!.docs.forEach((doc) {
          final data = doc.data() as Map<String, dynamic>;
          final locationName =
              data['location'] as String?; // Adjust field name as needed
          // Add locationName to the set if it's not common
          if (locationName != null && !isCommonLocation(locationName)) {
            locations.add(locationName);
          }
        });

        // Build the list of locations
        final locationWidgets = locations.map((locationName) {
          // Return a ListTile for each location
          return Padding(
            padding: const EdgeInsets.only( top: 4.0, bottom: 4.0),
            child: ListTile(
              title: Text(locationName),
              // Add borders and "x/y done" text here
              contentPadding: EdgeInsets.all(8.0), // Add padding
              shape: RoundedRectangleBorder(
                // Add border
                borderRadius: BorderRadius.circular(10.0),
                side: BorderSide(color: Colors.blue), // Border color
              ),
              subtitle: Text(
                "x/y done", // Replace x/y with actual values
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                  color: Colors.green, // Text color
                ),
              ),
              // Add more information or actions if needed
            ),
          );
        }).toList();

        return ListView(
          children: locationWidgets,
        );
      },
    );
  }


  Future<Map<String, dynamic>> fetchOrderByOrderStatus(
      String orderStatus) async {
    try {
      final ordersCollection = FirebaseFirestore.instance.collection('Orders');
      final currentDate = DateTime.now();
      final year = currentDate.year;
      final month = currentDate.month;
      final day = currentDate.day;
      final currentDateStart = DateTime(year, month, day);
      final currentDateEnd = currentDateStart.add(Duration(days: 1));

      final querySnapshot = await ordersCollection
          .where('deliveryDate', isGreaterThanOrEqualTo: currentDateStart)
          .where('deliveryDate', isLessThan: currentDateEnd)
          .where('Status', isEqualTo: orderStatus)
          .where('location', isEqualTo: locationName)
          .get();
      final totalOrders = querySnapshot.size;
      
      final ordersList = querySnapshot.docs.map((documentSnapshot) {
        final data = documentSnapshot.data() as Map<String, dynamic>;
        return {
          'orderName': data['orderName'],
          'quantity': data['numberOfItems'],
          'orderType': data['orderType'],
          'orderRef': documentSnapshot.reference.id,
          'orderStatus': data['Status'],
        };
      }).toList();

      return {
      'totalOrders': totalOrders,
      'ordersList': ordersList,
    };
    } catch (e) {
      print("Error fetching order count references: $e");
      return {
        'totalOrders': 0,
        'ordersList': [],
      };
    }
  }

  // Define a function to check if a location is common
  bool isCommonLocation(String locationName) {
    final commonLocations = {'Common Location 1', 'Common Location 2'};
    return commonLocations.contains(locationName);
  }
    bool isTimeInRange(String time, Map<String, String> timeSlot) {
    final startTime = timeSlot['startTime'];
    final endTime = timeSlot['endTime'];
    return DateTime.parse(time).isAfter(DateTime.parse(startTime!)) &&
        DateTime.parse(time).isBefore(DateTime.parse(endTime!));
  }
  String getCurrentTime() {
    final now = DateTime.now();
    return "${now.hour}:${now.minute}:${now.second}";
  }
  Future<Map<String, String>> fetchTimeForScanning() async {
    final timeCollection = FirebaseFirestore.instance.collection('Time');
    final snapshot = await timeCollection.get();
    final timeData = snapshot.docs.fold<Map<String, String>>(
      {},
      (previousValue, doc) {
        final data = doc.data() as Map<String, dynamic>;
        final startTime = data['StartTime'];
        final endTime = data['EndTime'];
        final formattedStartTime = timestampToFormattedTime(startTime);
        final formattedEndTime = timestampToFormattedTime(endTime);
        previousValue[doc.id] = {
          'startTime': formattedStartTime,
          'endTime': formattedEndTime,
        } as String;
        return previousValue;
      },
    );
    return timeData;
  }
  String timestampToFormattedTime(Timestamp timestamp) {
    final dateTime = timestamp.toDate();
    return "${dateTime.hour.toString().padLeft(2, '0')}:${dateTime.minute.toString().padLeft(2, '0')}:${dateTime.second.toString().padLeft(2, '0')}";
  }
}
