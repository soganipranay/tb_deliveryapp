import 'package:tb_deliveryapp/utils/utils.dart';
import 'package:cloud_firestore/cloud_firestore.dart';


class FirebaseService {
  final CollectionReference ordersCollection = FirebaseFirestore.instance.collection('Orders');
  final CollectionReference timeCollection = FirebaseFirestore.instance.collection('Time');
  final CollectionReference deliveryPartners = FirebaseFirestore.instance.collection('DeliveryPartners');



Future<int> fetchTotalOrders(int totalOrders, String profileType) async {
    

    try {
    
      DateTime currentDate = DateTime.now();
      int year = currentDate.year; // Year component
      int month = currentDate.month; // Month component (1 to 12)
      int day = currentDate.day; // Day component

      currentDate = DateTime(year, month, day);

      DateTime nextDate = currentDate.add(const Duration(days: 1));

      print('Current Date: $currentDate');
      print('Next Date: $nextDate');

    Map<String, dynamic> timeSlots = await fetchTimeForScanning();
      String currentTime = Utils.getCurrentTime();

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
      print("Error fetching order count references: $e");
      return [];
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

   Future<List<Map<String, dynamic>>> fetchOrderReferencesByPid(pid, String profileType) async {
    try {
      List<Map<String, dynamic>> ordersList = [];
      CollectionReference ordersCollection =
          FirebaseFirestore.instance.collection('Orders');

      DateTime currentDate = DateTime.now();
      DateTime nextDate = currentDate.add(const Duration(days: 1));
      print('Current Date: $currentDate');
      print('Next Date: $nextDate');

      Map<String, dynamic> timeSlots = await fetchTimeForScanning();
      String currentTime = Utils.getCurrentTime();

      if (DateTime.now().hour >=
              int.parse(timeSlots['breakfast']['startTime'].split(':')[0]) &&
          DateTime.now().minute >=
              int.parse(timeSlots['breakfast']['startTime'].split(':')[1]) &&
          DateTime.now().hour <
              int.parse(timeSlots['breakfast']['endTime'].split(':')[0]) &&
          DateTime.now().minute <
              int.parse(timeSlots['breakfast']['endTime'].split(':')[1])) {
        if (profileType == "Child") {
          ordersList.addAll(await fetchOrders(ordersCollection, pid,
              currentDate, nextDate, ['breakfast', 'lunch'], profileType));
        }
      } else if (profileType == "Adult") {
        ordersList.addAll(await fetchOrders(ordersCollection, pid, currentDate,
            nextDate, ['breakfast'], profileType));
      } else if (DateTime.now().hour >=
              int.parse(timeSlots['lunch']['startTime'].split(':')[0]) &&
          DateTime.now().minute >=
              int.parse(timeSlots['lunch']['startTime'].split(':')[1]) &&
          DateTime.now().hour <
              int.parse(timeSlots['lunch']['endTime'].split(':')[0]) &&
          DateTime.now().minute <
              int.parse(timeSlots['lunch']['endTime'].split(':')[1])) {
        ordersList.addAll(await fetchOrders(
            ordersCollection, pid, currentDate, nextDate, ['lunch'], 'Adult'));
      } else if (DateTime.now().hour >=
              int.parse(timeSlots['dinner']['startTime'].split(':')[0]) &&
          DateTime.now().minute >=
              int.parse(timeSlots['dinner']['startTime'].split(':')[1]) &&
          DateTime.now().hour <
              int.parse(timeSlots['dinner']['endTime'].split(':')[0]) &&
          DateTime.now().minute <
              int.parse(timeSlots['dinner']['endTime'].split(':')[1])) {
        ordersList.addAll(await fetchOrders(
            ordersCollection, pid, currentDate, nextDate, ['dinner'], 'Adult'));
      } else {
        print('No orders found');
      }

      return ordersList;
    } catch (e) {
      print("Error fetching order references: $e");
      return [];
    }
  }

   Future<List<Map<String, dynamic>>> fetchOrders(
      CollectionReference ordersCollection,
      String pid,
      DateTime currentDate,
      DateTime nextDate,
      List<String> orderTypes,
      String profileType) async {
    List<Map<String, dynamic>> ordersList = [];
    QuerySnapshot ordersQuerySnapshot = await ordersCollection
        .where('pid', isEqualTo: pid)
        .where('deliveryDate', isGreaterThanOrEqualTo: currentDate)
        .where('deliveryDate', isLessThan: nextDate)
        .where('orderType', whereIn: orderTypes)
        .where('profileType', isEqualTo: profileType)
        .get();

    ordersQuerySnapshot.docs.forEach((documentSnapshot) {
      DocumentReference documentReference = documentSnapshot.reference;
      print('Document Path: ${documentReference.path}');
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
  }

Future<String?> getDeliveryPartnerId(String userEmail) async {
    try {
      QuerySnapshot querySnapshot = await deliveryPartners
          .where('partner_email', isEqualTo: userEmail).get();

      if (querySnapshot.docs.isNotEmpty) {
        // Assuming that userEmail is unique and only one document will match
        DocumentSnapshot documentSnapshot = querySnapshot.docs.first;
        return documentSnapshot.id;  // Return the document id
      } else {
        print('No matching deliveryId found');
        return null;
      }
    } catch (e) {
      print('Error: $e');
      return null;
    }
  }

  Future<List<dynamic>?> getDeliveryLocationsForPartnerId(String deliveryPartnerId) async {
    try {
      DocumentReference docRef = deliveryPartners.doc(deliveryPartnerId);
       DocumentSnapshot docSnapshot = await docRef.get();
       List<dynamic> locationsForDeliveryPartner = List<dynamic>.from(docSnapshot['partner_locationID'] ?? []);
    return locationsForDeliveryPartner;
    } catch (e) {
      print('Error: $e');
      return null;
    }
  }

  

}