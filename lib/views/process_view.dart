import 'delivered_qr_view.dart';
import 'package:flutter/material.dart';
import 'package:tb_deliveryapp/views/packaging/count_packed.dart';

class ProcessView extends StatefulWidget {
  const ProcessView({Key? key, required this.meal}) : super(key: key);
  final String meal;
  @override
  State<ProcessView> createState() => _ProcessViewState();
}

class _ProcessViewState extends State<ProcessView> {
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
        // add buttons to redirect to packed and delivered pages

        body: Container(
            child: Column(
          children: [
            ElevatedButton(
              onPressed: () {
                Navigator.push(
                    context,
                    MaterialPageRoute(
                        builder: (context) =>
                            CountPackedOrders(meal: widget.meal)));
              },
              child: const Text('Packaging'),
            ),
            ElevatedButton(
              onPressed: () {
                Navigator.push(
                    context,
                    MaterialPageRoute(
                        builder: (context) =>
                            DeliveredQRView(meal: widget.meal)));
              },
              child: const Text('Delivery'),
            ),
            ElevatedButton(
              onPressed: () {
                Navigator.push(
                    context,
                    MaterialPageRoute(
                        builder: (context) =>
                            DeliveredQRView(meal: widget.meal)));
              },
              child: const Text('Representative'),
            ),
            ElevatedButton(
              onPressed: () {
                Navigator.push(
                    context,
                    MaterialPageRoute(
                        builder: (context) =>
                            DeliveredQRView(meal: widget.meal)));
              },
              child: const Text('Picked'),
            ),
          ],
        )));
  }
}
