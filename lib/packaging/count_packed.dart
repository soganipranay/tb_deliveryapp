import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:tb_deliveryapp/packaging/location_view.dart';
import 'package:tb_deliveryapp/packaging/packed_qr_view.dart';

class CountPackedOrders extends StatefulWidget {
  CountPackedOrders({Key? key}) : super(key: key);

  @override
  State<CountPackedOrders> createState() => _CountPackedOrdersState();
}

class _CountPackedOrdersState extends State<CountPackedOrders> {
  String profileType = "";
  int totalPackedOrders = 0;
  int totalOrders = 0;

  @override
  void initState() {
    super.initState();
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
      body: SingleChildScrollView(
        child: Container(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('Welcome to Tummy Box Partner App'),
              Text('You have a total of $totalOrders orders to pack today'),
              ElevatedButton(
                onPressed: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(builder: (context) => PackedQRView()),
                  );
                },
                child: Text('You have packed $totalPackedOrders orders today'),
              ),
              Text(
                "You have packed $totalPackedOrders orders today and ${(totalOrders - totalPackedOrders).clamp(0, totalOrders)} orders are remaining",
              ),
              const SizedBox(height: 16.0),
              LocationView(),
            ],
          ),
        ),
      ),
    );
  }

  // Count the total number of orders packed today
  Future<void> countPackedOrders() async {
    final orders = await fetchOrderByOrderStatus('Order Packed');
    setState(() {
      totalPackedOrders = orders.length;
    });
  }

  Future<int> fetchTotalOrders() async {
    try {
      final ordersCollection = FirebaseFirestore.instance.collection('Orders');
      final currentDate = DateTime.now();
      final year = currentDate.year;
      final month = currentDate.month;
      final day = currentDate.day;
      final currentTime = getCurrentTime();

      final currentDateStart = DateTime(year, month, day);
      final currentDateEnd = currentDateStart.add(Duration(days: 1));

      final timeSlots = await fetchTimeForScanning();

      if (isTimeInRange(currentTime, timeSlots['breakfast'] as Map<String, String>)) {
        final orderType =
            profileType == "Child" ? ['breakfast', 'lunch'] : ['breakfast'];
        final querySnapshot = await ordersCollection
            .where('deliveryDate', isGreaterThanOrEqualTo: currentDateStart)
            .where('deliveryDate', isLessThan: currentDateEnd)
            .where('orderType', whereIn: orderType)
            .where('profileType', isEqualTo: profileType)
            .get();
        totalOrders = querySnapshot.size;
      } else if (isTimeInRange(currentTime, timeSlots['lunch'] as Map<String, String>)) {
        final querySnapshot = await ordersCollection
            .where('deliveryDate', isGreaterThanOrEqualTo: currentDateStart)
            .where('deliveryDate', isLessThan: currentDateEnd)
            .where('orderType', isEqualTo: 'lunch')
            .where('profileType', isEqualTo: 'Adult')
            .get();
        totalOrders = querySnapshot.size;
      } else if (isTimeInRange(currentTime, timeSlots['dinner'] as Map<String, String>)) {
        final querySnapshot = await ordersCollection
            .where('deliveryDate', isGreaterThanOrEqualTo: currentDateStart)
            .where('deliveryDate', isLessThan: currentDateEnd)
            .where('orderType', isEqualTo: 'dinner')
            .where('profileType', isEqualTo: 'Adult')
            .get();
        totalOrders = querySnapshot.size;
      }

      return totalOrders;
    } catch (e) {
      print("Error fetching total order references: $e");
      return totalOrders;
    }
  }

  Future<List<Map<String, dynamic>>> fetchOrderByOrderStatus(
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
          .get();

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

      return ordersList;
    } catch (e) {
      print("Error fetching order count references: $e");
      return [];
    }
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
