import 'package:tb_deliveryapp/all.dart';

class CountPickedOrders extends StatefulWidget {
  final String meal;
  final List<String>? locationNames;

  CountPickedOrders({Key? key, required this.meal, required this.locationNames})
      : super(key: key);

  @override
  State<CountPickedOrders> createState() => _CountPickedOrdersState();
}

class _CountPickedOrdersState extends State<CountPickedOrders> {
  final FirebaseService firebaseService = FirebaseService();
  int totalPickedOrders = 0;
  late String profileType = "";
  Map<String, int> locationPickedOrders = {};
  Map<String, int> locationDeliveredOrders = {};

  late int totalOrders = 0;
  List<Map<String, dynamic>> pickedOrdersList = [];
  List<Map<String, dynamic>> deliveredOrdersList = [];

  List<String>? locationNames; // Declare the variable
  bool isLoading = true;
  @override
  void initState() {
    super.initState();
    locationNames =
        widget.locationNames; // Initialize it with widget.locationNames
    countPickedOrders(); // Call the function to fetch the data
    print("pickedOrdersList $pickedOrdersList");
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Picking for ${widget.meal}'),
        leading: Padding(
          padding: const EdgeInsets.all(6.0),
          child: Image.asset(
            'assets/TummyBox_Logo_wbg.png', // Replace with the actual path to your logo image
            width: 40, // Adjust the width as needed
            height: 40, // Adjust the height as needed
          ),
        ),
      ),
      body: isLoading // Check if data is still loading
          ? Center(
              child: CircularProgressIndicator(),
            )
          : SingleChildScrollView(
              child: Column(
                children: locationNames?.map((locationName) {
                      final int deliveredOrders =
                          locationDeliveredOrders[locationName] ?? 0;
                      final int pickedOrders =
                          locationPickedOrders[locationName] ?? 0;

                      return ListTile(
                        title: Text(locationName),
                        subtitle: Text(
                          "Delivered: $deliveredOrders, Picked: $pickedOrders",
                          style: TextStyle(
                            fontWeight: FontWeight.bold,
                            color: Colors.green,
                          ),
                        ),
                        tileColor: Colors.blue.withOpacity(0.1),
                        onTap: () {
                          Navigator.of(context)
                              .pushReplacement(MaterialPageRoute(
                                  builder: (context) => PickedQRView(
                                        deliveredOrdersList:
                                            deliveredOrdersList,
                                      ))); // Pass locationNames
                          // Handle tap event if needed
                        },
                      );
                    }).toList() ??
                    [],
              ),
            ),
    );
  }

  Future<void> countPickedOrders() async {
    final currentDate = DateTime.now();
    for (String location in widget.locationNames ?? []) {
      // Fetch the total picked orders for the current location
      final Map<String, dynamic> pickedOrders = await firebaseService
          .fetchOrderByOrderStatus('Picked', location, widget.meal);
      final int totalPickedOrders = pickedOrders['totalOrders'];
      final List<Map<String, dynamic>> pickedOrdersData = pickedOrders[
          'ordersList']; // Use a different variable name to avoid conflict

      final List<Map<String, dynamic>> pickedOrdersDataFiltered =
          pickedOrdersData.where((order) {
        DateTime deliveryDate = order['deliveryDate'].toDate();
        return deliveryDate.isBefore(currentDate);
      }).toList();

      // Fetch the total delivered orders for the current location
      final Map<String, dynamic> deliveredOrders = await firebaseService
          .fetchOrderforPickingStatus('Delivered', location, widget.meal);
      final int totalDeliveredOrders = deliveredOrders['totalOrders'];
      final List<Map<String, dynamic>> deliveredOrdersData = deliveredOrders[
          'ordersList']; // Use a different variable name to avoid conflict
      print("deliveredOrdersData $deliveredOrdersData");
      final List<Map<String, dynamic>> deliveredOrdersDataFiltered =
          deliveredOrdersData.where((order) {
        DateTime deliveryDate = order['deliveryDate'].toDate();
        print("deliveryDate ${deliveryDate.isBefore(currentDate)}");
        return deliveryDate.isBefore(currentDate);
      }).toList();
      print("deliveredOrdersDataFiltered $deliveredOrdersDataFiltered");

      // Update the locationpickedOrders and locationDeliveredOrders maps
      setState(() {
        locationPickedOrders[location] = totalPickedOrders;
        locationDeliveredOrders[location] = totalDeliveredOrders;

        // Update the lists
        pickedOrdersList.addAll(pickedOrdersDataFiltered);
        deliveredOrdersList.addAll(deliveredOrdersDataFiltered);

        print("pickedOrdersList $pickedOrdersList");
        print("deliveredOrdersList $deliveredOrdersList");

        print("locationPickedOrders ${locationPickedOrders[location]}");
        print("locationDeliveredOrders ${locationDeliveredOrders[location]}");
      });
    }
    setState(() {
      isLoading = false;
    });
  }
}
