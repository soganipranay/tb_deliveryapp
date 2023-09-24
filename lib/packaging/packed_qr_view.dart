import 'dart:io';
import 'dart:developer';
import 'package:flutter/material.dart';
import 'package:qr_code_scanner/qr_code_scanner.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class PackedQRView extends StatefulWidget {
  @override
  State<StatefulWidget> createState() => _PackedQRViewState();
}

class _PackedQRViewState extends State<PackedQRView> {
  Barcode? result;
  QRViewController? controller;
  final GlobalKey qrKey = GlobalKey(debugLabel: 'QR');
  late List<Map<String, dynamic>> scannedOrderDetails = [];
  late String profileType;

  // In order to get hot reload to work we need to pause the camera if the platform
  // is android, or resume the camera if the platform is iOS.
  @override
  void reassemble() {
    super.reassemble();
    if (Platform.isAndroid) {
      controller!.pauseCamera();
    }
    controller!.resumeCamera();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Packaging'),
        leading: Padding(
          padding: const EdgeInsets.all(6.0),
          child: Image.asset(
            'assets/TummyBox_Logo_wbg.png', // Replace with the actual path to your logo image
            width: 40, // Adjust the width as needed
            height: 40, // Adjust the height as needed
          ),
        ),
      ),
      body:  Column(
        children: <Widget>[
          SizedBox(
            height: MediaQuery.of(context).size.height * 0.4,
            child: _buildQrView(context),
          ),
          const SizedBox(
            height: 16,
          ),
          Expanded(
            child: result != null
                ? FutureBuilder<List<Map<String, dynamic>>>(
                    future: fetchOrderReferencesByPid(result!.code.toString()),
                    builder: (context, snapshot) {
                      if (snapshot.connectionState == ConnectionState.waiting) {
                        return const CircularProgressIndicator(
                          color: Colors.orange,
                        );
                      } else if (snapshot.hasError) {
                        return Text('Error: ${snapshot.error}');
                      } else if (!snapshot.hasData || snapshot.data!.isEmpty) {
                        return const Text('No orders found.');
                      } else {
                        scannedOrderDetails = snapshot.data!;
                        return ListView.builder(
                          itemCount: scannedOrderDetails.length,
                          itemBuilder: (context, index) {
                            final orderItem = scannedOrderDetails[index];
                            return ListTile(
                              title: Text("Order Name: ${orderItem['orderName']}"),
                              subtitle: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text("Quantity: ${orderItem['quantity']}"),
                                  Text("Order Type: ${orderItem['orderType']}"),
                                  const Divider(),
                                ],
                              ),
                            );
                          },
                        );
                      }
                    },
                  )
                : const Text('Scan a code'),
          ),
          Container(
            margin: const EdgeInsets.all(8),
            child: ElevatedButton(
              onPressed: result != null && scannedOrderDetails.isNotEmpty
                  ? () async {
                      await controller?.pauseCamera();
                      result = null;
                      for (var orderItem in scannedOrderDetails) {
                        if (orderItem['orderStatus'] == 'Pending') {
                          await updateOrderStatus(orderItem['orderRef'], 'Order Packed');
                          print("Order Packed: ${orderItem['orderRef']}");
                        } else {
                          showDialog(
                            context: context,
                            builder: (BuildContext context) {
                              return AlertDialog(
                                title: const Text('Order already packed'),
                                content: Text(orderItem['orderRef']),
                                actions: <Widget>[
                                  ElevatedButton(
                                    onPressed: () => Navigator.of(context).pop(),
                                    style: ElevatedButton.styleFrom(
                                      backgroundColor: Colors.orange,
                                    ),
                                    child: const Text('Ok'),
                                  )
                                ],
                              );
                            },
                          );
                        }
                      }
                      await controller?.resumeCamera();
                    }
                  : () {},
              style: ElevatedButton.styleFrom(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                minimumSize: const Size(100, 40),
                textStyle: const TextStyle(fontSize: 14),
              ),
              child: const Text('Packed', style: TextStyle(fontSize: 10)),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildQrView(BuildContext context) {
    var scanArea = (MediaQuery.of(context).size.width < 400 ||
            MediaQuery.of(context).size.height < 400)
        ? 200.0
        : 200.0;

    return QRView(
      key: qrKey,
      onQRViewCreated: _onQRViewCreated,
      overlay: QrScannerOverlayShape(
        borderColor: Colors.red,
        borderRadius: 10,
        borderLength: 30,
        borderWidth: 10,
        cutOutSize: scanArea,
      ),
      onPermissionSet: (ctrl, p) => _onPermissionSet(context, ctrl, p),
    );
  }

  void _onQRViewCreated(QRViewController controller) {
    setState(() {
      this.controller = controller;
    });
    controller.scannedDataStream.listen((scanData) async {
      setState(() {
        result = scanData;
      });
      print(result!.code.toString());
    });
  }

  void _onPermissionSet(BuildContext context, QRViewController ctrl, bool p) {
    log('${DateTime.now().toIso8601String()}_onPermissionSet $p');
    if (!p) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('No Permission')),
      );
    }
  }

  Future<void> updateOrderStatus(String orderId, String newStatus) async {
    try {
      final ordersCollection = FirebaseFirestore.instance.collection('Orders');
      final orderDocRef = ordersCollection.doc(orderId);

      await orderDocRef.update({'Status': newStatus});
      print('Order status updated to: $newStatus');
    } catch (e) {
      print('Error updating order status: $e');
    }
  }

  String getCurrentTime() {
    final now = DateTime.now();
    return "${now.hour}:${now.minute}:${now.second}";
  }


  Future<Map<String, dynamic>> fetchTimeForScanning() async {
    final timeCollection = FirebaseFirestore.instance.collection('Time');

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

  Future<List<Map<String, dynamic>>> fetchOrderReferencesByPid(pid) async {
    try {
      List<Map<String, dynamic>> ordersList = [];
      CollectionReference ordersCollection =
          FirebaseFirestore.instance.collection('Orders');

      DateTime currentDate = DateTime.now();
      DateTime nextDate = currentDate.add(const Duration(days: 1));
      print('Current Date: $currentDate');
      print('Next Date: $nextDate');

      Map<String, dynamic> timeSlots = await fetchTimeForScanning();
      String currentTime = getCurrentTime();

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

  @override
  void dispose() {
    controller?.dispose();
    super.dispose();
  }
}
