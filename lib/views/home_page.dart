import 'package:tb_deliveryapp/services/firebase_service.dart';

import '../services/auth_manager.dart';
import 'delivered_qr_view.dart';
import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart';
import 'package:tb_deliveryapp/views/packaging/count_packed.dart';
import 'package:tb_deliveryapp/views/packaging/packed_qr_view.dart';






class HomeView extends StatefulWidget {
  final bool isLoggedIn;
  const HomeView({Key? key, required this.isLoggedIn}) : super(key: key);

  @override
  State<HomeView> createState() => _HomeViewState();
}
class _HomeViewState extends State<HomeView> {
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
            const Text('Welcome to Tummy Box Partner App'),
            const Text('Please select an option below'),
            ElevatedButton(
              onPressed: () {
                Navigator.push(context, MaterialPageRoute(builder: (context) =>  CountPackedOrders()));
              },
              child: const Text('Packed'),
            ),
            ElevatedButton(
              onPressed: () {
                Navigator.push(context, MaterialPageRoute(builder: (context) => const DeliveredQRView()));
              },
              child: const Text('Delivered'),
            ),
          ],
        )
      )
      
    );
  }
}