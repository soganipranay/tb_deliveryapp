import 'package:tb_deliveryapp/all.dart';

class CountPackedOrders extends StatefulWidget {
  final String meal;
  final List<String>? locationNames;

  CountPackedOrders({Key? key, required this.meal, required this.locationNames})
      : super(key: key);

  @override
  State<CountPackedOrders> createState() => _CountPackedOrdersState();
}

class _CountPackedOrdersState extends State<CountPackedOrders> {
  final FirebaseService firebaseService = FirebaseService();
  int totalPackedOrders = 0;
  late String profileType = "";
  Map<String, int> locationPackedOrders = {};
  Map<String, int> locationPendingOrders = {};

  late int totalOrders = 0;
  List<Map<String, dynamic>> packedOrdersList = [];
  List<Map<String, dynamic>> pendingOrdersList = [];

  List<String>? locationNames; // Declare the variable
  bool isLoading = true;
  
  @override
  void initState() {
    super.initState();
    locationNames =
        widget.locationNames; // Initialize it with widget.locationNames
    countPackedOrders(); // Call the function to fetch the data
    print("packedOrdersList $packedOrdersList");
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Packaging for ${widget.meal}'),
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
                      final int pendingOrders =
                          locationPendingOrders[locationName] ?? 0;
                      final int packedOrders =
                          locationPackedOrders[locationName] ?? 0;

                      return ListTile(
                        title: Text(locationName),
                        subtitle: Text(
                          "Pending: $pendingOrders, Packed: $packedOrders",
                          style: TextStyle(
                            fontWeight: FontWeight.bold,
                            color: Colors.green,
                          ),
                        ),
                        tileColor: Colors.blue.withOpacity(0.1),
                        onTap: () {
                          Navigator.of(context)
                              .pushReplacement(MaterialPageRoute(
                                  builder: (context) => PackedQRView(
                                        pendingOrdersList: pendingOrdersList,
                                      ))); // Pass locationNames
                          // Handle tap event if needed
                        },
                        trailing: PopupMenuButton<String>(
                          icon: Icon(Icons.more_vert),
                          itemBuilder: (BuildContext context) => [
                            PopupMenuItem<String>(
                              value: locationName,
                              child: GestureDetector(
                                onTap: () {
                                  // Handle link opening here
                                  String? mapLink = globalLocationMap[locationName];
                                  if (mapLink != null) {
                                    _launchUrl(mapLink); // Launch the URL
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
            ),
    );
  }

  // final Uri _url = Uri.parse(
  //     'https://www.google.com/search?q=wtp+location+jaipur&oq=wtp+locaation+&gs_lcrp=EgZjaHJvbWUqCQgBEAAYDRiABDIGCAAQRRg5MgkIARAAGA0YgAQyCAgCEAAYFhgeMggIAxAAGBYYHjIICAQQABgWGB4yDQgFEAAYhgMYgAQYigUyDQgGEAAYhgMYgAQYigXSAQg2OTYyajBqN6gCALACAA&sourceid=chrome&ie=UTF-8&lqi=ChN3dHAgbG9jYXRpb24gamFpcHVySPSvxMztqoCACFoZEAAYACITd3RwIGxvY2F0aW9uIGphaXB1cpIBD3Nob3BwaW5nX2NlbnRlcpoBJENoZERTVWhOTUc5blMwVkpRMEZuU1VSemNVbDFSRGxuUlJBQqoBRBABKgciA3d0cCgAMh4QASIahS40xo7-cDhN57Qu7Gcv_Soh6_gw4Gb4uAEyFxACIhN3dHAgbG9jYXRpb24gamFpcHVy#rlimm=4847010798830747055');
  Future<void> _launchUrl(String mapLink) async {
    Uri _url = Uri.parse(mapLink);
    if (await canLaunchUrl(_url)) {
      await launchUrl(_url);
      print("url launched");
    } else {
      throw Exception('Could not launch $_url');
    }
  }

  Future<void> countPackedOrders() async {
    print(widget.locationNames);
    for (String location in widget.locationNames ?? []) {
      // Fetch the total packed orders for the current location
      final Map<String, dynamic> packedOrders = await firebaseService
          .fetchOrderByOrderStatus('Packed', location, widget.meal);
      final int totalPackedOrders = packedOrders['totalOrders'];
      final List<Map<String, dynamic>> packedOrdersData = packedOrders[
          'ordersList']; // Use a different variable name to avoid conflict

      // Fetch the total pending orders for the current location
      final Map<String, dynamic> pendingOrders = await firebaseService
          .fetchOrderByOrderStatus('Pending', location, widget.meal);

      final int totalPendingOrders = pendingOrders['totalOrders'];
      final List<Map<String, dynamic>> pendingOrdersData = pendingOrders[
          'ordersList']; // Use a different variable name to avoid conflict

      // Update the locationPackedOrders and locationPendingOrders maps
      setState(() {
        locationPackedOrders[location] = totalPackedOrders;
        locationPendingOrders[location] = totalPendingOrders;

        // Update the lists
        packedOrdersList.addAll(packedOrdersData);
        pendingOrdersList.addAll(pendingOrdersData);

        print(" packedOrdersList $packedOrdersList");
        print(" pendingOrdersList $pendingOrdersList");

        print("locationPackedOrders ${locationPackedOrders[location]}");
        print("locationPendingOrders ${locationPendingOrders[location]}");
      });
    }
    // A // Set loading state to false once data is fetched
    setState(() {
      isLoading = false;
    });
  }
}
