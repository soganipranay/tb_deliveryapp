import 'dart:io';
import 'dart:developer';
import 'package:flutter/material.dart';
import '../../services/auth_manager.dart';
import 'package:qr_code_scanner/qr_code_scanner.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:tb_deliveryapp/services/firebase_service.dart';

class DeliveredQRView extends StatefulWidget {
  final List<Map<String, dynamic>> packedOrdersList;
  const DeliveredQRView({Key? key, required this.packedOrdersList}) : super(key: key);

  @override
  State<StatefulWidget> createState() => _DeliveredQRViewState();
}

class _DeliveredQRViewState extends State<DeliveredQRView> {
  final FirebaseService firebaseService = FirebaseService();
  Barcode? result;
  QRViewController? controller;
  final GlobalKey qrKey = GlobalKey(debugLabel: 'QR');
  late List<Map<String, dynamic>> scannedOrderDetails = [];

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
        title: const Text('Delivered'),
        leading: Padding(
          padding: const EdgeInsets.all(6.0),
          child: Image.asset(
            'assets/TummyBox_Logo_wbg.png', // Replace with the actual path to your logo image
            width: 40, // Adjust the width as needed
            height: 40, // Adjust the height as needed
          ),
        ),
      ),
      body: Column(
        children: <Widget>[
          SizedBox(
            height: MediaQuery.of(context).size.height * 0.4,
            child: _buildQrView(context),
          ),
          const SizedBox(
              height: 16), // Add spacing between QR and order details
          Expanded(
            child: result != null // Check if result is not null
                ? FutureBuilder<List<Map<String, dynamic>>>(
                    future: fetchOrderReferencesByPid(result!.code.toString()),
                    builder: (context, snapshot) {
                      if (snapshot.connectionState == ConnectionState.waiting) {
                        return const CircularProgressIndicator(
                            color: Colors.orange);
                      } else if (snapshot.hasError) {
                        print('Snapshot Error: ${snapshot.error}');
                        return Text('Error: ${snapshot.error}');
                      } else if (!snapshot.hasData || snapshot.data!.isEmpty) {
                        print(
                            '-----------------No Orders Found!------------------');
                        return const Text('No orders found.');
                      } else {
                        print("Orders found: ${snapshot.data}");
                        scannedOrderDetails = snapshot.data!;
                        List<Map<String, dynamic>> orderDetails =
                            snapshot.data!;
                        return ListView.builder(
                          itemCount: orderDetails.length,
                          itemBuilder: (context, index) {
                            return ListTile(
                              title: Text(
                                  "Order Name: ${orderDetails[index]['orderName']}"),
                              subtitle: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                      "Quantity: ${orderDetails[index]['quantity']}"),
                                  Text(
                                      "Order Type: ${orderDetails[index]['orderType']}"),
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
              onPressed: result != null &&
                      scannedOrderDetails
                          .isNotEmpty // Use the stored orderDetails variable
                  ? () async {
                      await controller?.pauseCamera();
                      result = null;
                      for (var orderItem in scannedOrderDetails) {
                        if (orderItem['orderStatus'] == 'Packed') {
                          await firebaseService.updateOrderStatus(
                              orderItem['orderRef'], 'Delivered');
                          print("Delivered: ${orderItem['orderRef']}");
                        } else if (orderItem['orderStatus'] ==
                            'Delivered') {
                          // Dissable the ElevatedButton
                          print('Order already Delivered');
                        } else {
                          // ignore: use_build_context_synchronously
                          showDialog(
                              context: context,
                              builder: (BuildContext context) {
                                return AlertDialog(
                                    title:
                                        const Text('Order already Delivered'),
                                    content: Text(orderItem['orderRef']),
                                    actions: <Widget>[
                                      ElevatedButton(
                                        onPressed: () => Navigator.of(context)
                                            .pop(), // Close the dialog,
                                        style: ElevatedButton.styleFrom(
                                          backgroundColor: Colors
                                              .orange, // Use the accent color
                                        ),
                                        child: const Text('Ok'),
                                      )
                                    ]);
                              });
                        }
                      }
                      await controller?.resumeCamera();
                    }
                  : () => {
                        print(
                            'Button is disabled and barcodeResult = result = $result and {$scannedOrderDetails}'),
                        print(scannedOrderDetails.isNotEmpty),
                        result = null,
                      },
              style: ElevatedButton.styleFrom(
                padding:
                    const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                minimumSize: const Size(100, 40),
                textStyle: const TextStyle(fontSize: 14),
              ),
              child: const Text('Delivered', style: TextStyle(fontSize: 10)),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildQrView(BuildContext context) {
    // For this example we check how width or tall the device is and change the scanArea and overlay accordingly.
    var scanArea = (MediaQuery.of(context).size.width < 400 ||
            MediaQuery.of(context).size.height < 400)
        ? 200.0
        : 200.0;
    // To ensure the Scanner view is properly sizes after rotation
    // we need to listen for Flutter SizeChanged notification and update controller
    return QRView(
      key: qrKey,
      onQRViewCreated: _onQRViewCreated,
      overlay: QrScannerOverlayShape(
          borderColor: Colors.red,
          borderRadius: 10,
          borderLength: 30,
          borderWidth: 10,
          cutOutSize: scanArea),
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
        const SnackBar(content: Text('no Permission')),
      );
    }
  }

  Future<String> fetchDocumentData(DocumentReference documentRef) async {
    try {
      DocumentSnapshot snapshot = await documentRef.get();

      if (snapshot.exists) {
        // Access data using snapshot.data() or snapshot.get('fieldName')
        Map<String, dynamic> data = snapshot.data() as Map<String, dynamic>;

        // Now you can use the 'data' map to access values
        String fieldValue =
            data['name']; // Replace 'fieldName' with your actual field name

        // Do something with the fetched data
        print("Fetched value: $fieldValue");
        return fieldValue;
      } else {
        print("Document does not exist");
        return '';
      }
    } catch (e) {
      print("Error fetching document data: $e");
      throw UnimplementedError('');
    }
  }

  @override
  void dispose() {
    controller?.dispose();
    super.dispose();
  }

  Future<List<Map<String, dynamic>>> fetchOrderReferencesByPid(pid) async {
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
          .where('pid', isEqualTo: pid)
          .where('deliveryDate', isGreaterThanOrEqualTo: currentDate)
          .where('deliveryDate', isLessThan: nextDate)
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
