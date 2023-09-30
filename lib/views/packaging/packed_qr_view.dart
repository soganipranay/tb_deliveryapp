import 'dart:io';
import 'dart:developer';
import 'package:flutter/material.dart';
import 'package:qr_code_scanner/qr_code_scanner.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:tb_deliveryapp/services/firebase_service.dart';

class PackedQRView extends StatefulWidget {
  @override
  State<StatefulWidget> createState() => _PackedQRViewState();
}

class _PackedQRViewState extends State<PackedQRView> {
  FirebaseService firebaseService = FirebaseService();
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
                    future: firebaseService.fetchOrderReferencesByPid(result!.code.toString(), profileType),
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
                          await firebaseService.updateOrderStatus(orderItem['orderRef'], 'Packed');
                          print("Packed: ${orderItem['orderRef']}");
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



  @override
  void dispose() {
    controller?.dispose();
    super.dispose();
  }
}
