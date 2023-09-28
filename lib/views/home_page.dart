import 'package:flutter/material.dart';
import 'package:tb_deliveryapp/views/process_view.dart';



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
            'assets/TummyBox_Logo_wbg.png',
            width: 40,
            height: 40,
          ),
        ),
       
      ),
      body: Container(
        child: Column(
          children: [
            ElevatedButton(
              onPressed: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => ProcessView(meal: "breakfast"),
                  ),
                );
              },
              child: const Text('Breakfast'),
            ),
            ElevatedButton(
              onPressed: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => ProcessView(meal: "lunch"),
                  ),
                );
              },
              child: const Text('Lunch'),
            ),
            ElevatedButton(
              onPressed: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => ProcessView(meal: "dinner"),
                  ),
                );
              },
              child: const Text('Dinner'),
            ),
          ],
        ),
      ),
    );
  }
}
