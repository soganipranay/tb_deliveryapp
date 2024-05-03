import 'package:intl/intl.dart';
import 'package:tb_deliveryapp/all.dart';

class CountDeliveredOrders extends StatefulWidget {
  final String meal;
  final List<String>? locationNames;

  CountDeliveredOrders(
      {Key? key, required this.meal, required this.locationNames})
      : super(key: key);

  @override
  State<CountDeliveredOrders> createState() => _CountDeliveredOrdersState();
}

class _CountDeliveredOrdersState extends State<CountDeliveredOrders> {
  final FirebaseService firebaseService = FirebaseService();
  int totalDeliveredOrders = 0;
  late String profileType = "";
  Map<String, int> locationDeliveredOrders = {};
  Map<String, int> locationPackedOrders = {};

  late int totalOrders = 0;
  List<Map<String, dynamic>> deliveredOrdersList = [];
  List<Map<String, dynamic>> packedOrdersList = [];

  List<String>? locationNames; // Declare the variable
  bool isLoading = true;
  @override
  void initState() {
    super.initState();
    locationNames =
        widget.locationNames; // Initialize it with widget.locationNames
    countDeliveredOrders(); // Call the function to fetch the data
    print("deliveredOrdersList $deliveredOrdersList");
  }
  Future<void> _launchUrl(String mapLink)  async {
    Uri _url = Uri.parse(mapLink);
    if (await canLaunchUrl(_url)) {
      await launchUrl(_url);
      print("url launched");
    } else {
      throw Exception('Could not launch $_url');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Delivering for ${widget.meal}'),
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
          : locationNames != null &&
                  locationNames!
                      .isNotEmpty // Check if locationNames is not empty
              ? SingleChildScrollView(
              child: Column(
                children: locationNames?.map((locationName) {
                      final int packedOrders =
                          locationPackedOrders[locationName] ?? 0;
                      final int deliveredOrders =
                          locationDeliveredOrders[locationName] ?? 0;

                      return ListTile(
                        title: Text(locationName),
                        subtitle: Text(
                          "Packed: $packedOrders, Delivered: $deliveredOrders",
                          style: TextStyle(
                            fontWeight: FontWeight.bold,
                            color: Colors.green,
                          ),
                        ),
                        tileColor: Colors.blue.withOpacity(0.1),
                        onTap: () {
                          Navigator.of(context).pushReplacement(
                              MaterialPageRoute(
                                  builder: (context) => DeliveredQRView(
                                      packedOrdersList: packedOrdersList,
                                      locationName:
                                          locationName))); // Pass locationNames
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

  
  Future<void> countDeliveredOrders() async {
    for (String location in widget.locationNames ?? []) {
      // Fetch the total delivered orders for the current location
      final Map<String, dynamic> deliveredOrders = await firebaseService
          .fetchOrderByOrderStatus('Delivered', location, widget.meal);
      final int totalDeliveredOrders = deliveredOrders['totalOrders'];
      final List<Map<String, dynamic>> deliveredOrdersData = deliveredOrders[
          'ordersList']; // Use a different variable name to avoid conflict

      // Fetch the total packed orders for the current location
      final Map<String, dynamic> packedOrders = await firebaseService
          .fetchOrderByOrderStatus('Packed', location, widget.meal);
      final int totalPackedOrders = packedOrders['totalOrders'];
      final List<Map<String, dynamic>> packedOrdersData = packedOrders[
          'ordersList']; // Use a different variable name to avoid conflict

      // Update the locationdeliveredOrders and locationPackedOrders maps
      setState(() {
        locationDeliveredOrders[location] = totalDeliveredOrders;
        locationPackedOrders[location] = totalPackedOrders;

        // Update the lists
        deliveredOrdersList.addAll(deliveredOrdersData);
        packedOrdersList.addAll(packedOrdersData);

        print(" deliveredOrdersList $deliveredOrdersList");
        print(" packedOrdersList $packedOrdersList");

        print("locationDeliveredOrders ${locationDeliveredOrders[location]}");
        print("locationPackedOrders ${locationPackedOrders[location]}");
      });
    }
    setState(() {
      isLoading = false;
    });
  }
}
