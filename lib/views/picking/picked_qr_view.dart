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

  @override
  void initState() {
    super.initState();
    deliveredOrders = List.from(widget.deliveredOrdersList);
  }

  void updateOrderToPicked(Map<String, dynamic> order) {
    setState(() {
      order['orderStatus'] = 'Picked';
    });
  }

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
        }
      } else {
        print(
            "QR Code not found in deliveredOrdersList: ${result!.code.toString()}");
        setState(() {
          scannedOrderDetails.clear();
        });
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
                          updateOrderToPicked(orderItem);
                          // You can also update Firebase here if needed
                          print("Picked: ${orderItem['orderRef']}");
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
}
