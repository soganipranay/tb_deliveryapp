import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class FirebaseService {
  final CollectionReference ordersCollection =
      FirebaseFirestore.instance.collection('Orders');
  final CollectionReference timeCollection =
      FirebaseFirestore.instance.collection('Time');
  final CollectionReference userPartners =
      FirebaseFirestore.instance.collection('Users');
  final CollectionReference<Map<String, dynamic>> officeLocation =
      FirebaseFirestore.instance.collection('Office');

  final CollectionReference<Map<String, dynamic>> schoolLocation =
      FirebaseFirestore.instance.collection('School');

  Future<int> fetchTotalOrders(String locations, String orderType) async {
    try {
      final CollectionReference ordersCollection =
          FirebaseFirestore.instance.collection('Orders');
      DateTime currentDate = DateTime.now();
      int year = currentDate.year; // Year component
      int month = currentDate.month; // Month component (1 to 12)
      int day = currentDate.day; // Day component
      late int totalOrders = 0;

      currentDate = DateTime(year, month, day);

      DateTime nextDate = currentDate.add(const Duration(days: 1));

      print('Current Date: $currentDate');
      print('Next Date: $nextDate');

      QuerySnapshot querySnapshot = await ordersCollection
          .where('deliveryDate', isGreaterThanOrEqualTo: currentDate)
          .where('deliveryDate', isLessThan: nextDate)
          .where('orderType', isEqualTo: orderType)
          .where('location', isEqualTo: locations)
          .get();

      querySnapshot.docs.forEach((QueryDocumentSnapshot documentSnapshot) {
        // Get the reference of each document
        DocumentReference documentReference = documentSnapshot.reference;
        print('Document Path: ${documentReference.path}');
        // get the count of the documents
        totalOrders = querySnapshot.docs.length;
        print('Total Orders: $totalOrders');
      });

      return totalOrders;
    } catch (e) {
      print("Error fetching total order references: $e");
      return 0;
    }
  }

  Future<Map<String, dynamic>> fetchOrderByOrderStatus(
      String orderStatus, String location, String orderType) async {
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
          .where('location', isEqualTo: location)
          .where('orderType', isEqualTo: orderType)
          .get();
      final totalOrders = querySnapshot.size;

      final ordersList = querySnapshot.docs.map((documentSnapshot) {
        final data = documentSnapshot.data();
        return {
          'orderRef': documentSnapshot.reference.id,
          'orderName': data['orderName'],
          'quantity': data['numberOfItems'],
          'orderType': data['orderType'],
          'orderStatus': data['Status'],
          'orderLocation': data['location'],
          'pid': data['pid'],
        };
      }).toList();
      print(ordersList);
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

  Future<void> updateOrderStatus(String orderId, String newStatus) async {
    try {
      final orderDocRef = ordersCollection.doc(orderId);

      await orderDocRef.update({'Status': newStatus});
      print('Order status updated to: $newStatus');
    } catch (e) {
      print('Error updating order status: $e');
    }
  }

  Future<void> updateOrdersInFirestore(
      List<Map<String, dynamic>> ordersToUpdate) async {
    final firestore = FirebaseFirestore.instance;

    // Create a batch to perform multiple updates in a single transaction
    WriteBatch batch = firestore.batch();

    for (var orderDetails in ordersToUpdate) {
      String orderRef = orderDetails['orderRef'];
      String newStatus = orderDetails['orderStatus'];

      // Reference to the order document in Firestore
      DocumentReference orderDocRef =
          firestore.collection('orders').doc(orderRef);

      // Update the order status
      batch.update(orderDocRef, {'orderStatus': newStatus});
    }

    try {
      // Commit the batch to update all orders in a single transaction
      await batch.commit();
      print('Orders updated in Firestore successfully');
    } catch (e) {
      print('Error updating orders in Firestore: $e');
      // Handle the error as needed
    }
  }

  Future<Map<String, dynamic>> fetchTimeForScanning() async {
    final timeDocs = await timeCollection.get();

    final Map<String, dynamic> timeSlots = {};
    String timestampToFormattedTime(Timestamp timestamp) {
      DateTime dateTime = timestamp.toDate();
      String formattedTime =
          "${dateTime.hour.toString().padLeft(2, '0')}:${dateTime.minute.toString().padLeft(2, '0')}:${dateTime.second.toString().padLeft(2, '0')}";
      return formattedTime;
    }

    timeDocs.docs.forEach((doc) {
      final data = doc.data() as Map<String, dynamic>;
      final slotName = doc.id;
      timeSlots[slotName] = {
        'startTime': timestampToFormattedTime(data['StartTime']),
        'endTime': timestampToFormattedTime(data['EndTime']),
      };
    });

    print('Time Slots: $timeSlots');
    return timeSlots;
  }

  Future<String?> getDeliveryPartnerId(
      String userEmail, BuildContext context) async {
    try {
      QuerySnapshot querySnapshot = await userPartners
          .where('email', isEqualTo: userEmail)
          .where('userType', isEqualTo: "Delivery Partner")
          .get();

      if (querySnapshot.docs.isNotEmpty) {
        // Assuming that userEmail is unique and only one document will match
        DocumentSnapshot documentSnapshot = querySnapshot.docs.first;
        if (documentSnapshot['adminApproved'] == "Approved") {
          return documentSnapshot.id; // Return the document id
        } else {
          // Show a dialog since the user is not approved
          showDialog(
            context: context,
            builder: (BuildContext context) {
              return AlertDialog(
                title: Text('Awaiting Approval'),
                content: Text(
                    'Your account is still awaiting approval. Please contact the admin for further assistance.'),
                actions: <Widget>[
                  TextButton(
                    child: Text('OK'),
                    onPressed: () {
                      Navigator.of(context).pop();
                    },
                  ),
                ],
              );
            },
          );
          return null;
        }
      } else {
        print('No matching deliveryId found');
        return null;
      }
    } catch (e) {
      print('Error: $e');
      return null;
    }
  }

  Future<String?> getRepresentativeId(
      String userEmail, BuildContext context) async {
    try {
      QuerySnapshot querySnapshot = await userPartners
          .where('email', isEqualTo: userEmail)
          .where('userType', isEqualTo: "Representative")
          .get();

      if (querySnapshot.docs.isNotEmpty) {
        // Assuming that userEmail is unique and only one document will match
        DocumentSnapshot documentSnapshot = querySnapshot.docs.first;
        if (documentSnapshot['adminApproved'] == "Approved") {
          return documentSnapshot.id; // Return the document id
        } else {
          // Show a dialog since the user is not approved
          showDialog(
            context: context,
            builder: (BuildContext context) {
              return AlertDialog(
                title: Text('Awaiting Approval'),
                content: Text(
                    'Your account is still awaiting approval. Please contact the admin for further assistance.'),
                actions: <Widget>[
                  TextButton(
                    child: Text('OK'),
                    onPressed: () {
                      Navigator.of(context).pop();
                    },
                  ),
                ],
              );
            },
          );
          return null;
        }
      } else {
        print('No matching representativeId found');
        return null;
      }
    } catch (e) {
      print('Error: $e');
      return null;
    }
  }

  Future<List<dynamic>?> getLocationsForPartnerId(String partnerId) async {
    try {
      DocumentReference docRef = userPartners.doc(partnerId);
      DocumentSnapshot docSnapshot = await docRef.get();
      print("partnerId $docSnapshot");
      List<String> locationsForDeliveryPartner =
          List<String>.from(docSnapshot['locations'] ?? []);

      return locationsForDeliveryPartner;
    } catch (e) {
      print('Error: $e');
      return null;
    }
  }

  Future<List<String>?> fetchLocationNamesByLocationIds(
      List<dynamic>? locations) async {
    List<String> locationNames = [];
    List<String> extracteResults = [];
    for (String locationRef in locations ?? []) {
      List<String> parts = locationRef.split('/');
      if (parts.length > 2) {
        String result = parts.sublist(2).join('/');
        extracteResults.add(result);
        print("result $result"); // This will print the extracted substring
      } else {
        return null;
      }
    }
    print(
        "extracteResults $extracteResults"); // This will print the extracted substring
    // extracteResults [R3whnAMDi374RJBvE67t, nYTz12ahki2R0rAwZzqz, MJrR2geqczDf3kRTiOxt]
    try {
      for ( String? locationRef in extracteResults) {
        // Check if the location is in the officeLocation collection
        DocumentSnapshot<Map<String, dynamic>> officeDoc =
            await officeLocation.doc(locationRef).get();
        print("locationRef $locationRef");
        if (officeDoc.exists) {
          locationNames.add("${officeDoc.data()!['name']}");
        } else {
          // Check if the location is in the schoolLocation collection
          DocumentSnapshot<Map<String, dynamic>> schoolDoc =
              await schoolLocation.doc(locationRef).get();
          if (schoolDoc.exists) {
            locationNames.add("${schoolDoc.data()!['name']}");
          } else {
            // Print a message when neither officeDoc nor schoolDoc exists
            print("Neither officeDoc nor schoolDoc exists for $locationRef");
          }
        }
        print("locationNames: $locationNames");
      }
    } catch (e) {
      print('Error: $e');
    }

    return locationNames;
  }
}

      // if (DateTime.parse(currentTime)
      //         .isAfter(DateTime.parse(timeSlots['breakfast']['startTime'])) &&
      //     DateTime.parse(currentTime)
      //         .isBefore(DateTime.parse(timeSlots['breakfast']['endTime']))) {
      //   print('Current Time: ${DateTime.parse(currentTime)}');
      //   if (profileType == "Child") {
      //     QuerySnapshot querySnapshot = await ordersCollection
      //         .where('deliveryDate', isGreaterThanOrEqualTo: currentDate)
      //         .where('deliveryDate', isLessThan: nextDate)
      //         .where('orderType', whereIn: ['breakfast', 'lunch'])
      //         .where('location')
      //         .where('profileType', isEqualTo: profileType)
      //         .get();

      //     querySnapshot.docs.forEach((QueryDocumentSnapshot documentSnapshot) {
      //       // Get the reference of each document
      //       DocumentReference documentReference = documentSnapshot.reference;
      //       print('Document Path: ${documentReference.path}');
      //       // get the count of the documents
      //       totalOrders = querySnapshot.docs.length;
      //     });
      //   } else if (profileType == "Adult") {
      //     QuerySnapshot querySnapshot = await ordersCollection
      //         .where('deliveryDate', isGreaterThanOrEqualTo: currentDate)
      //         .where('deliveryDate', isLessThan: nextDate)
      //         .where('orderType', isEqualTo: 'breakfast')
      //         .where('profileType', isEqualTo: profileType)
      //         .get();
      //     querySnapshot.docs.forEach((QueryDocumentSnapshot documentSnapshot) {
      //       // Get the reference of each document
      //       DocumentReference documentReference = documentSnapshot.reference;
      //       print('Document Path: ${documentReference.path}');
      //       // get the count of the documents
      //       totalOrders = querySnapshot.docs.length;
      //     });
      //   }
      // } else if (DateTime.parse(currentTime)
      //         .isAfter(DateTime.parse(timeSlots['lunch']['startTime'])) &&
      //     DateTime.parse(currentTime)
      //         .isBefore(DateTime.parse(timeSlots['lunch']['endTime']))) {
      //   QuerySnapshot querySnapshot = await ordersCollection
      //       .where('deliveryDate', isGreaterThanOrEqualTo: currentDate)
      //       .where('deliveryDate', isLessThan: nextDate)
      //       .where('orderType', isEqualTo: 'lunch')
      //       .where('profileType', isEqualTo: 'Adult')
      //       .get();

      //   querySnapshot.docs.forEach((QueryDocumentSnapshot documentSnapshot) {
      //     // Get the reference of each document
      //     DocumentReference documentReference = documentSnapshot.reference;
      //     print('Document Path: ${documentReference.path}');
      //     // get the count of the documents
      //     totalOrders = querySnapshot.docs.length;
      //   });
      // } else if (DateTime.parse(currentTime)
      //         .isAfter(DateTime.parse(timeSlots['dinner']['startTime'])) &&
      //     DateTime.parse(currentTime)
      //         .isBefore(DateTime.parse(timeSlots['dinner']['endTime']))) {
      //   QuerySnapshot querySnapshot = await ordersCollection
      //       .where('deliveryDate', isGreaterThanOrEqualTo: currentDate)
      //       .where('deliveryDate', isLessThan: nextDate)
      //       .where('orderType', isEqualTo: 'dinner')
      //       .where('profileType', isEqualTo: 'Adult')
      //       .get();

      //   querySnapshot.docs.forEach((QueryDocumentSnapshot documentSnapshot) {
      //     // Get the reference of each document
      //     DocumentReference documentReference = documentSnapshot.reference;
      //     print('Document Path: ${documentReference.path}');
      //     // get the count of the documents
      //     totalOrders = querySnapshot.docs.length;
      //   });
      // }
