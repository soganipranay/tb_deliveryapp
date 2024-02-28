import 'dart:developer';
import 'package:tb_deliveryapp/all.dart';



class HandlingQRView extends StatefulWidget {
  final List<Map<String, dynamic>> deliveredOrdersList; // Add this field

  HandlingQRView({Key? key, required this.deliveredOrdersList}) : super(key: key);

  @override
  State<StatefulWidget> createState() => _HandlingQRViewState();
}

class _HandlingQRViewState extends State<HandlingQRView> {
  FirebaseService firebaseService = FirebaseService();
  Barcode? result;
  QRViewController? controller;
  final GlobalKey qrKey = GlobalKey(debugLabel: 'QR');
  late List<Map<String, dynamic>> scannedOrderDetails = [];
  late String profileType;
  bool allOrdersHanded = false;

  void _onQRViewCreated(QRViewController controller) {
    setState(() {
      this.controller = controller;
    });
    controller.scannedDataStream.listen((scanData) async {
      setState(() {
        result = scanData;
      });

      // Check if the scanned QR code exists in the deliveredOrdersList
      bool found = false;
      Map<String, dynamic>? orderDetails;
      print(widget.deliveredOrdersList);
      for (var orderItem in widget.deliveredOrdersList) {
        if (orderItem['pid'] == result!.code.toString()) {
          found = true;
          orderDetails = orderItem;
          break;
        }
      }

      if (found) {
        // Handle the case when the QR code is found in deliveredOrdersList
        print("QR Code found in deliveredOrdersList: ${result!.code.toString()}");
        setState(() {
          scannedOrderDetails.clear();
          scannedOrderDetails.add(orderDetails!);
        });

        // Check if all orders are packed and the delivered order list is empty
        bool allHanded = true;
        for (var orderItem in scannedOrderDetails) {
          if (orderItem['orderStatus'] != 'Handed') {
            allHanded = false;
            break;
          }
        }
        if (allHanded && widget.deliveredOrdersList.isEmpty) {
          // Prepare a list of orders to update in Firestore
          List<Map<String, dynamic>> ordersToUpdate = [];
          for (var orderItem in scannedOrderDetails) {
            if (orderItem['orderStatus'] == 'Handed') {
              ordersToUpdate.add({
                'orderRef': orderItem['orderRef'],
                'orderStatus': 'Handed',
              });
            }
          }
          // Update the Firestore collection with packed orders
          await firebaseService.updateOrdersInFirestore(ordersToUpdate);
          print("Orders updated in Firestore");
        }
      } else {
        // Handle the case when the QR code is not found in deliveredOrdersList
        print(
            "QR Code not found in deliveredOrdersList: ${result!.code.toString()}");
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
            height: 16,
          ),
          Expanded(
            child: scannedOrderDetails.isNotEmpty
                ? ListView.builder(
                    itemCount: scannedOrderDetails.length,
                    itemBuilder: (context, index) {
                      final orderItem = scannedOrderDetails[index];
                      bool isHanded = orderItem['orderStatus'] == 'Handed';

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
                        trailing: isHanded
                            ? Icon(
                                Icons.circle,
                                color: Colors.green,
                              )
                            : null, // Display green dot if packed, null otherwise
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
                        if (orderItem['orderStatus'] == 'Handed') {
                          await firebaseService.updateOrderStatus(
                              orderItem['orderRef'], 'Delivered');
                          // Update the order status in the local list
                          orderItem['orderStatus'] = 'Delivered';
                          print("Delivered: ${orderItem['orderRef']}");
                        } else {
                          showDialog(
                            context: context,
                            builder: (BuildContext context) {
                              return AlertDialog(
                                title: const Text('Order already packed'),
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
              child: const Text('Handed', style: TextStyle(fontSize: 10)),
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
}
