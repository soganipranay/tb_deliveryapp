import 'dart:developer';
import 'package:intl/intl.dart';
import 'package:tb_deliveryapp/all.dart';
import 'package:tb_deliveryapp/main.dart';

class DeliveredQRView extends StatefulWidget {
  final List<Map<String, dynamic>> packedOrdersList; // Add this field
  final String locationName;

  DeliveredQRView(
      {Key? key, required this.packedOrdersList, required this.locationName})
      : super(key: key);

  @override
  State<StatefulWidget> createState() => _DeliveredQRViewState();
}

class _DeliveredQRViewState extends State<DeliveredQRView> {
  FirebaseService firebaseService = FirebaseService();
  Barcode? result;
  QRViewController? controller;
  final GlobalKey qrKey = GlobalKey(debugLabel: 'QR');
  late List<Map<String, dynamic>> scannedOrderDetails = [];
  late String profileType;
  bool allOrdersDelivered = false;

  void _onQRViewCreated(QRViewController controller) {
    setState(() {
      this.controller = controller;
    });
    controller.scannedDataStream.listen((scanData) async {
      setState(() {
        result = scanData;
      });

      // Check if the scanned QR code exists in the packedOrdersList
      bool found = false;
      Map<String, dynamic>? orderDetails;
      print(widget.packedOrdersList);
      for (var orderItem in widget.packedOrdersList) {
        if (orderItem['pid'] == result!.code.toString()) {
          found = true;
          orderDetails = orderItem;
          break;
        }
      }

      if (found) {
        // Handle the case when the QR code is found in packedOrdersList
        print("QR Code found in packedOrdersList: ${result!.code.toString()}");
        setState(() {
          scannedOrderDetails.clear();
          scannedOrderDetails.add(orderDetails!);
        });

        // Check if all orders are delivered and the packed order list is empty
        bool allDelivered = true;
        for (var orderItem in scannedOrderDetails) {
          if (orderItem['orderStatus'] != 'Delivered') {
            allDelivered = false;
            break;
          }
        }
        if (allDelivered && widget.packedOrdersList.isEmpty) {
          // Prepare a list of orders to update in Firestore
          List<Map<String, dynamic>> ordersToUpdate = [];
          for (var orderItem in scannedOrderDetails) {
            if (orderItem['orderStatus'] == 'Delivered') {
              ordersToUpdate.add({
                'orderRef': orderItem['orderRef'],
                'orderStatus': 'Delivered',
              });
            }
          }
          // Update the Firestore collection with delivered orders
          await firebaseService.updateOrdersInFirestore(ordersToUpdate);
          print("Orders updated in Firestore");
        }
      } else {
        // Handle the case when the QR code is not found in packedOrdersList
        print(
            "QR Code not found in packedOrdersList: ${result!.code.toString()}");
        setState(() {
          scannedOrderDetails.clear();
        });
        // You can show an error message or perform other actions as needed.
      }
    });
  }

  // In order to get hot reload to work we need to pause the camera if the platform
  // is android, or resume the camera if the platform is iOS.
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
        title: const Text('Packaging'),
        leading: IconButton(
          icon: Icon(Icons.arrow_back),
          onPressed: () {
            Navigator.of(context).pushReplacement(MaterialPageRoute(
              builder: (context) => LoginPage(),
            )); // Navigate back when back button is pressed
          },
        ),
        actions: [
          Padding(
            padding: const EdgeInsets.all(6.0),
            child: Image.asset(
              'assets/TummyBox_Logo_wbg.png', // Replace with the actual path to your logo image
              width: 40, // Adjust the width as needed
              height: 40, // Adjust the height as needed
            ),
          ),
        ],
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
            child: scannedOrderDetails.isNotEmpty
                ? ListView.builder(
                    itemCount: scannedOrderDetails.length,
                    itemBuilder: (context, index) {
                      final orderItem = scannedOrderDetails[index];
                      bool isDelivered =
                          orderItem['orderStatus'] == 'Delivered';

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
                        trailing: isDelivered
                            ? Icon(
                                Icons.circle,
                                color: Colors.green,
                              )
                            : null, // Display green dot if delivered, null otherwise
                      );
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
                        print("orderItem: $orderItem");
                        if (orderItem['orderStatus'] == 'Packed') {
                          await firebaseService.updateOrderStatus(
                              orderItem['orderRef'], 'Delivered');
                          // Update the order status in the local list
                          orderItem['orderStatus'] = 'Delivered';
                          markTiffinAsDelivered(
                              orderItem['orderRef'],
                              orderItem['pid'],
                              orderItem['quantity'],
                              orderItem['deliveryDate']);
                          print(
                              "Delivered: ${orderItem['orderRef']}, ${DateTime.now()}");
                          print(
                              "Delivered: ${orderItem['userID']}, ${DateTime.now()}");

                          try {
                            await firebaseService.uploadNotificationDocument(
                                orderItem['userID'], orderItem['userID']);
                            print("message sent");
                          } catch (e) {
                            print("Error marking order as delivered: $e");
                          }
                        } else {
                          showDialog(
                            context: context,
                            builder: (BuildContext context) {
                              return AlertDialog(
                                title: const Text('Order already delivered'),
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
                      setState(
                          () {}); // Refresh the UI to reflect the updated status
                    }
                  : () {},
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

  Future<void> markTiffinAsDelivered(String orderId, String pid,
      int numberOfItems, Timestamp deliveryDate) async {
    try {
      int userTiffinCount = 0;
      // Update the status of the order to "Delivered" in the Orders collection
      final ordersCollection = FirebaseFirestore.instance.collection('Orders');
      await ordersCollection.doc(orderId).update({'Status': 'Delivered'});
      print('deliveryDate $deliveryDate');
      final tiffinsCollection =
          FirebaseFirestore.instance.collection('Tiffins');
      final tiffinData = {
        'locationRef':
            widget.locationName, // Update with your location reference
        'orderID': orderId,
        'pid': pid, // Update with the appropriate value
        'status': 'Delivered',
        'tiffinCondition': ' ', // Update with the condition
        'tiffinCount':
            numberOfItems, // You can set this to the number of items in the list
        'deliveryDate': deliveryDate,
        'userTiffinCount': userTiffinCount
      };

      print(tiffinData);
      await tiffinsCollection.add(tiffinData);
    } catch (e) {
      print("Error marking order as delivered: $e");
    }
  }
}
