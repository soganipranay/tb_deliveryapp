import 'package:tb_deliveryapp/all.dart';


// ignore_for_file: avoid_print

// ignore_for_file: use_build_context_synchronously
Timer? locationUpdateTimer;

class FirebaseService {
  final CollectionReference ordersCollection =
      FirebaseFirestore.instance.collection('Orders');
  final CollectionReference timeCollection =
      FirebaseFirestore.instance.collection('Time');
  final CollectionReference userPartners =
      FirebaseFirestore.instance.collection('Users');
  final CollectionReference<Map<String, dynamic>> officeLocation =
      FirebaseFirestore.instance.collection('Offices');

  final CollectionReference<Map<String, dynamic>> schoolLocation =
      FirebaseFirestore.instance.collection('Schools');
  final CollectionReference<Map<String, dynamic>> deliveryPartner =
      FirebaseFirestore.instance.collection("DeliveryPartners");

  Future<Map<String, dynamic>> fetchOrderforPickingStatus(
      String orderStatus, String location, String orderType) async {
    try {
      final ordersCollection = FirebaseFirestore.instance.collection('Orders');
      final currentDate = DateTime.now();
      final year = currentDate.year;
      final month = currentDate.month;
      final day = currentDate.day;
      final currentDateStart = DateTime(year, month, day);
      final currentDateEnd = currentDateStart.add(const Duration(days: 1));

      final querySnapshot = await ordersCollection
          // .where('deliveryDate', isGreaterThanOrEqualTo: currentDateStart)
          .where('deliveryDate', isLessThan: currentDateStart)
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
          'deliveryDate': data['deliveryDate']
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

  Future<Map<String, dynamic>> fetchOrderByOrderStatus(
      String orderStatus, String location, String orderType) async {
    try {
      final ordersCollection = FirebaseFirestore.instance.collection('Orders');
      final currentDate = DateTime.now();
      final year = currentDate.year;
      final month = currentDate.month;
      final day = currentDate.day;
      final currentDateStart = DateTime(year, month, day);
      final currentDateEnd = currentDateStart.add(const Duration(days: 1));

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
          'deliveryDate': data['deliveryDate']
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

  Future<List?> getDeliveryPartnerId(
      String userEmail, BuildContext context) async {
    final getPartnerDetails = [];
    try {
      QuerySnapshot querySnapshot = await userPartners
          .where('email', isEqualTo: userEmail)
          .where('userType', isEqualTo: "Delivery Partner")
          .get();

      if (querySnapshot.docs.isNotEmpty) {
        DocumentSnapshot documentSnapshot = querySnapshot.docs.first;
        if (documentSnapshot['adminApproved'] == "Approved") {
          final partnerType = documentSnapshot['userType'];
          getPartnerDetails.add([partnerType, documentSnapshot.id]);
          return getPartnerDetails; // Return the document id
        } else {
          showDialog(
            context: context,
            builder: (BuildContext context) {
              return AlertDialog(
                title: const Text('Awaiting Approval'),
                content: const Text(
                    'Your account is still awaiting approval. Please contact the admin for further assistance.'),
                actions: <Widget>[
                  TextButton(
                    child: const Text('OK'),
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
        // ignore: avoid_print
        print('No matching deliveryId found');
        return null;
      }
    } catch (e) {
      print('Error: $e');
      return null;
    }
  }

  Future<List?> getRepresentativeId(
      String userEmail, BuildContext context) async {
    final getPartnerDetails = [];
    try {
      QuerySnapshot querySnapshot = await userPartners
          .where('email', isEqualTo: userEmail)
          .where('userType', isEqualTo: "Representative")
          .get();

      if (querySnapshot.docs.isNotEmpty) {
        // Assuming that userEmail is unique and only one document will match
        DocumentSnapshot documentSnapshot = querySnapshot.docs.first;
        if (documentSnapshot['adminApproved'] == "Approved") {
          final partnerType = documentSnapshot['userType'];
          getPartnerDetails.add([partnerType, documentSnapshot.id]);
          return getPartnerDetails; // Return the document id
        } else {
          // Show a dialog since the user is not approved
          // ignore: use_build_context_synchronously
          showDialog(
            context: context,
            builder: (BuildContext context) {
              return AlertDialog(
                title: const Text('Awaiting Approval'),
                content: const Text(
                    'Your account is still awaiting approval. Please contact the admin for further assistance.'),
                actions: <Widget>[
                  TextButton(
                    child: const Text('OK'),
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

  Future<Map<String, dynamic>> getPartnerDetails(String partnerId) async {
    try {
      DocumentReference docRef = userPartners.doc(partnerId);
      DocumentSnapshot docSnapshot = await docRef.get();

      if (docSnapshot.exists) {
        final data = docSnapshot.data() as Map<String, dynamic>;
        return {
          'name': docSnapshot.reference.id,
          'display_name': data['display_name'],
          'email': data['email'],
          'locations': data['locations'],
          'phone_number': data['phone_number'],
          'photo_url': data['photo_url'],
          'userType': data['userType'],
        };
      } else {
        // Handle the case where the document doesn't exist.
        return {};
      }
    } catch (e) {
      print('Error: $e');
      return {}; // Handle the error gracefully.
    }
  }

  Future<List<dynamic>?> getLocationsForPartnerId(String partnerId) async {
    try {
      DocumentReference docRef = userPartners.doc(partnerId);
      DocumentSnapshot docSnapshot = await docRef.get();
      print("partnerId ${docSnapshot.data}");
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

    try {
      if (locations != null) {
        for (String locationRef in locations) {
          // Check if the location is in the officeLocation collection
          DocumentReference officeDoc = officeLocation.doc(locationRef);
          DocumentSnapshot officeSnapshot = await officeDoc.get();
          print("locationRef $locationRef");
          if (officeSnapshot.exists) {
            final dynamic officeData = officeSnapshot.data(); // Cast to dynamic
            locationNames.add("${officeData["name"]}");
          } else {
            // Check if the location is in the schoolLocation collection
            DocumentReference schoolDoc = schoolLocation.doc(locationRef);
            DocumentSnapshot schoolSnapshot = await schoolDoc.get();
            if (schoolSnapshot.exists) {
              final dynamic schoolData =
                  schoolSnapshot.data(); // Cast to dynamic
              locationNames.add("${schoolData["name"]}");
            } else {
              // Print a message when neither officeDoc nor schoolDoc exists
              print("Neither officeDoc nor schoolDoc exists for $locationRef");
            }
          }
          print("locationNames: $locationNames");
        }
      }
    } catch (e) {
      print('Error: $e');
    }

    return locationNames;
  }

  void startLocationUpdate(String partnerId) {
    // Clear any existing timers to ensure only one timer runs
    stopLocationUpdate();

    // Start a timer that runs every 10 seconds
     locationUpdateTimer = Timer.periodic(Duration(seconds: 10), (timer) {
    // Get the partner's current location using Geolocator
    Geolocator.getCurrentPosition().then((Position position) {
        if (position != null) {
          // Update the partner's location in the "locationUpdate" collection
          DocumentReference locationUpdateRef = deliveryPartner.doc(partnerId);

          // Set the new location data
          locationUpdateRef.set({
            'latitude': position.latitude,
            'longitude': position.longitude,
          });
        }
      }).catchError((error) {
        print('Error getting location: $error');
      });
    });
  }

  void stopLocationUpdate() {
    if (locationUpdateTimer != null) {
      locationUpdateTimer!.cancel();
    }
  }
}
  