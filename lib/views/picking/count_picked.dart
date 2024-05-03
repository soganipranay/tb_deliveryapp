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
          : locationNames != null ||
                  locationNames!
                      .isNotEmpty // Check if locationNames is not empty
              ? SingleChildScrollView(
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
                            trailing:
                            PopupMenuButton<String>(
                              icon: Icon(Icons.more_vert),
                              itemBuilder: (BuildContext context) => [
                                PopupMenuItem<String>(
                                  value: locationName,
                                  child: GestureDetector(
                                    onTap: () {
                                      // Handle link opening here
                                      String? mapLink =
                                          globalLocationMap[locationName];
                                      if (mapLink != null) {
                                        _launchUrl(
                                            mapLink); // Launch the URL
                                        print('Open Location Link Clicked');
                                      } else {
                                        print(
                                            'Map link not found for $locationName');
                                      }
                                    },
                                    child: Text('Open Location'),
                                  ),
                                ),
                                // Add more options as needed
                              ],
                              onSelected: (String value) {
                                // Handle the selected option
                                print('Selected: $value');
                             },
                          ),
                      );
                    }).toList() ??
                    [],
              ),
            ): Center(
                  // Display a message if locationNames is empty
                  child: Text(
                    'No locations assigned yet',
                    style: TextStyle(
                      fontSize: 18,
                      
                    ),
                  ),
                ),
    );
  }

  Future<void> _launchUrl(String mapLink) async {
    Uri _url = Uri.parse(mapLink);
    if (await canLaunchUrl(_url)) {
      await launchUrl(_url);
      print("url launched");
    } else {
      throw Exception('Could not launch $_url');
    }
  }

  Future<void> countPickedOrders() async {
    final currentDate = DateTime.now();
    for (String location in widget.locationNames ?? []) {
      // Fetch the total picked orders for the current location
      final Map<String, dynamic> pickedOrders = await firebaseService
          .fetchOrderforPickingStatus('Picked', location, widget.meal);
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
