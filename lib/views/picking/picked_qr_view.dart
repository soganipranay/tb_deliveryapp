import 'dart:developer';
import 'package:tb_deliveryapp/all.dart';

class PickedQRView extends StatefulWidget {
  final List<Map<String, dynamic>> deliveredOrdersList;

  PickedQRView({Key? key, required this.deliveredOrdersList}) : super(key: key);

  @override
  State<StatefulWidget> createState() => _PickedQRViewState();
}

class _PickedQRViewState extends State<PickedQRView> {
  FirebaseService firebaseService = FirebaseService();
  Barcode? result;
  QRViewController? controller;
  final GlobalKey qrKey = GlobalKey(debugLabel: 'QR');
  late List<Map<String, dynamic>> scannedOrderDetails = [];
  late String profileType;

  // Initialize the list of picked orders
  List<Map<String, dynamic>> pickedOrders = [];
  List<Map<String, dynamic>> deliveredOrders = [];
  int userTiffinCount = 0;
  @override
  void initState() {
    super.initState();
    deliveredOrders = List.from(widget.deliveredOrdersList);
  }

  // void updateOrderToPicked(Map<String, dynamic> order) {
  //   setState(() {
  //     order['orderStatus'] = 'Picked';
  //   });
  // }

  void _onQRViewCreated(QRViewController controller) {
    setState(() {
      this.controller = controller;
    });
    controller.scannedDataStream.listen((scanData) async {
      setState(() {
        result = scanData;
      });

      if (result != null && result!.code != null) {
        // Check if the scanned QR code exists in the deliveredOrdersList
        bool found = false;
        Map<String, dynamic>? orderDetails;
        // final currentDate = DateTime.now();
        for (var orderItem in deliveredOrders) {
          if (orderItem['pid'] == result!.code.toString()) {
            found = true;
            orderDetails = orderItem;
            break;
          }
        }

        if (found) {
          print(
              "QR Code found in deliveredOrdersList: ${result!.code.toString()}");
          setState(() {
            scannedOrderDetails.clear();
            scannedOrderDetails.add(orderDetails!);
          });

          bool isAlreadyPicked = false;

          for (var orderItem in pickedOrders) {
            if (orderItem['pid'] == orderDetails!['pid']) {
              isAlreadyPicked = true;
              break;
            }
          }

          if (!isAlreadyPicked) {
            pickedOrders.add(orderDetails!);
            // Now that you've determined an order needs to be marked as "Picked," call the function to update its status.
            await markTiffinAsPicked(
                orderDetails['orderRef'],
                orderDetails['pid'],
                orderDetails['userTiffinCount'],
                orderDetails['tiffinCount']);
          }
        } else {
          print(
              "QR Code not found in deliveredOrdersList: ${result!.code.toString()}");
          setState(() {
            scannedOrderDetails.clear();
          });
        }
      }
    });
  }

  @override
  void reassemble() {
    super.reassemble();
    if (Platform.isAndroid) {}
    controller!.resumeCamera();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Picking'),
        leading: Padding(
          padding: const EdgeInsets.all(6.0),
          child: Image.asset(
            'assets/TummyBox_Logo_wbg.png',
            width: 40,
            height: 40,
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
            height: 16,
          ),
          Expanded(
            child: ListView.builder(
              itemCount: deliveredOrders.length,
              itemBuilder: (context, index) {
                final orderItem = deliveredOrders[index];
                bool isPicked = orderItem['orderStatus'] == 'Picked';

                return ListTile(
                  title: Text("Order Name: ${orderItem['orderName']}"),
                  subtitle: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text("Quantity: ${orderItem['quantity']}"),
                      Text("Order Type: ${orderItem['orderType']}"),
                      Text("Packaging Type: ${orderItem['packaging']}"),
                      Text("Profile Name: ${orderItem['profileName']}"),
                      const Divider(),
                    ],
                  ),
                  trailing: isPicked
                      ? const Icon(
                          Icons.circle,
                          color: Colors.green,
                        )
                      : null,
                );
              },
            ),
          ),
          Container(
            margin: const EdgeInsets.all(8),
            child: ElevatedButton(
              onPressed: result != null && scannedOrderDetails.isNotEmpty
                  ? () async {
                      await controller?.pauseCamera();
                      result = null;
                      for (var orderItem in scannedOrderDetails) {
                        if (orderItem['orderStatus'] == 'Delivered') {
                          print("orderItem $orderItem");
                          if (orderItem['quantity'] > 1) {
                            // Show the quantity input dialog
                            await _showQuantityDialog(context, orderItem);
                          } else {
                            // If there's only one item, just update userTiffinCount
                            userTiffinCount = 1;
                          }
                          await firebaseService.updateOrderStatus(
                              orderItem['orderRef'], 'Picked');
                          orderItem['orderStatus'] = 'Picked';
                          markTiffinAsPicked(
                              orderItem['orderRef'],
                              orderItem['pid'],
                              userTiffinCount,
                              orderItem['quantity']);
                          print("Delivered: ${orderItem['orderRef']}");
                        } else {
                          // ignore: use_build_context_synchronously
                          showDialog(
                            context: context,
                            builder: (BuildContext context) {
                              return AlertDialog(
                                title: const Text('Order already Picked'),
                                content: Text(orderItem['orderRef']),
                                actions: <Widget>[
                                  ElevatedButton(
                                    onPressed: () =>
                                        Navigator.of(context).pop(),
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
                      setState(() {});
                    }
                  : () {},
              style: ElevatedButton.styleFrom(
                padding:
                    const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                minimumSize: const Size(100, 40),
                textStyle: const TextStyle(fontSize: 14),
              ),
              child: const Text('Picked', style: TextStyle(fontSize: 10)),
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

  Future<void> _showQuantityDialog(
      BuildContext context, Map<String, dynamic> orderDetails) async {
    int receivedQuantity = 0;

    return showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: Text('Enter Received Quantity'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: <Widget>[
              TextField(
                decoration: InputDecoration(labelText: 'Received Quantity'),
                keyboardType: TextInputType.number,
                onChanged: (value) {
                  receivedQuantity = int.tryParse(value) ?? 0;
                },
              ),
            ],
          ),
          actions: <Widget>[
            ElevatedButton(
              onPressed: () async {
                if (receivedQuantity <= orderDetails['quantity']) {
                  userTiffinCount = orderDetails['quantity'] - receivedQuantity;
                  Navigator.of(context).pop();
                }
              },
              child: Text('Save'),
            ),
          ],
        );
      },
    );
  }

  Future<void> markTiffinAsPicked(String orderRef, String pid,
      int? userTiffinCount, int tiffinCount) async {
    try {
      if (userTiffinCount != null) {
        final tiffinsCollection =
            FirebaseFirestore.instance.collection('Tiffins');
        final currentDate = DateTime.now();
        final year = currentDate.year;
        final month = currentDate.month;
        final day = currentDate.day;
        final currentDateStart = DateTime(year, month, day);

        // Query the Tiffins collection for the specific tiffin entry to update
        final querySnapshot = await tiffinsCollection
            .where('orderID', isEqualTo: orderRef)
            .where('status', isEqualTo: 'Delivered')
            .where('deliveryDate',
                isLessThan: currentDateStart) // Check for status "Delivered"
            .get();

        // If you have a unique entry, you can directly update it; otherwise, you may need to loop through the results if there are multiple entries.
        print(userTiffinCount);
        if (querySnapshot.docs.isNotEmpty) {
          for (var doc in querySnapshot.docs) {
            await tiffinsCollection.doc(doc.reference.id).update({
              'status': 'Picked', // Update the status to "Picked"
              'userTiffinCount': userTiffinCount
            });
          }
        }
      } else {
        print("userTiffinCount is null. Skipping the update.");
      }
    } catch (e) {
      print("Error marking tiffin as picked: $e");
    }
  }
}
