import 'package:tb_deliveryapp/all.dart';

class ProcessView extends StatefulWidget {
  const ProcessView(
      {Key? key,
      required this.meal,
      required this.locations,
      required this.partnerType})
      : super(key: key);
  final String meal;
  final String partnerType;
  final List<dynamic>? locations;
  @override
  State<ProcessView> createState() => _ProcessViewState();
}

class _ProcessViewState extends State<ProcessView> {
  List<String>? deliveryPartnerLocationName;
  @override
  void initState() {
    super.initState();
    initializeData();
  }

  Future<void> initializeData() async {
    FirebaseService firebaseService = FirebaseService();
    print("process view ${widget.locations}");
    List<String>? locationName =
        await firebaseService.fetchLocationNamesByLocationIds(widget.locations);
    print("Process View locationNames: $locationName");
    if (locationName != null) {
      // List<String> filteredLocationNames =
      //     locationName.map((name) => name.replaceAll('Office: ', '')).toList();
      setState(() {
        deliveryPartnerLocationName = locationName;
        print("deliveryPartnerLocationsNames $deliveryPartnerLocationName");
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
        appBar: AppBar(
          title: const Text('Tummy Box Partner App'),
          leading: IconButton(
            icon: Icon(Icons.arrow_back),
            onPressed: () {
              Navigator.of(context).popUntil((route) => route.isFirst);
              // Navigate back when back button is pressed
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
        // add buttons to redirect to packed and delivered pages

        body: Container(
            child: Column(
          children: [
            ElevatedButton(
              onPressed: widget.partnerType == 'Delivery Partner'
                  ? () {
                      print(widget.meal);
                      Navigator.push(
                          context,
                          MaterialPageRoute(
                              builder: (context) => CountPackedOrders(
                                  meal: widget.meal,
                                  locationNames: deliveryPartnerLocationName)));
                    }
                  : null,
              child: const Text('Packaging'),
            ),
            ElevatedButton(
              onPressed: widget.partnerType == 'Delivery Partner'
                  ? () {
                      Navigator.push(
                          context,
                          MaterialPageRoute(
                              builder: (context) => CountDeliveredOrders(
                                  meal: widget.meal,
                                  locationNames: deliveryPartnerLocationName)));
                    }
                  : null,
              child: const Text('Delivery'),
            ),
            ElevatedButton(
              onPressed: widget.partnerType == 'Representative'
                  ? () {
                      Navigator.push(
                          context,
                          MaterialPageRoute(
                              builder: (context) => RepresentativeOrders(
                                  meal: widget.meal,
                                  locationNames: deliveryPartnerLocationName)));
                    }
                  : null,
              child: const Text('Representative'),
            ),
            ElevatedButton(
              onPressed: widget.partnerType == 'Delivery Partner'
                  ? () {
                      Navigator.push(
                          context,
                          MaterialPageRoute(
                              builder: (context) => CountPickedOrders(
                                  meal: widget.meal,
                                  locationNames: deliveryPartnerLocationName)));
                    }
                  : null,
              child: const Text('Picking'),
            ),
          ],
        )));
  }
}
