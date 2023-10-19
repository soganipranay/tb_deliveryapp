import 'package:tb_deliveryapp/all.dart';

class HomeView extends StatefulWidget {
  final bool isLoggedIn;
  final String partnerId;
  final String partnerType;
  const HomeView(
      {Key? key,
      required this.isLoggedIn,
      required this.partnerId,
      required this.partnerType})
      : super(key: key);

  @override
  State<HomeView> createState() => _HomeViewState();
}

class _HomeViewState extends State<HomeView> {
  late Future<Map<String, dynamic>> dataFuture;
  List<dynamic>? deliveryPartnerLocations = []; // Change the data type here
  Map<String, dynamic> partnerDetails = {};
  late String name = "";
  late String email = "";
  late String phone = "";
  late String photoUrl = ''; // Initialize photoUrl with an empty string
  late String retainedPartnerId;
  late String retainedPartnertype;

  @override
  void initState() {
    super.initState();
    retainedPartnerId = widget.partnerId;
    retainedPartnertype = widget.partnerType;
    initializeData();
    print("partner type ${retainedPartnertype}");
    dataFuture = initializeData();
  }



  Future<Map<String, dynamic>> initializeData() async {
    FirebaseService firebaseService = FirebaseService();
    try {
      List<dynamic>? locations =
          await firebaseService.getLocationsForPartnerId(retainedPartnerId);
      Map<String, dynamic> details =
          await firebaseService.getPartnerDetails(retainedPartnerId);

      if (locations != null) {
        setState(() {
          deliveryPartnerLocations = locations;
          partnerDetails = details; // Store the details in the state
          name = partnerDetails['display_name'];
          email = partnerDetails['email'];
          phone = partnerDetails['phone_number'];
          photoUrl = partnerDetails['photo_url'];
          print("Partner Details: $partnerDetails");
          print("Home deliveryPartnerLocations $deliveryPartnerLocations");
        });
      }
      print(partnerDetails);
      return partnerDetails;
    } catch (e) {
      print("Error fetching data: $e");
      // Handle the error gracefully, e.g., show an error message to the user.
      return Map<String,
          dynamic>(); // Return an empty map or handle it as needed.
    }
  }

  void _handleLogout() {
    AuthManager authManager = AuthManager();
    authManager.logoutUser(context);
  }

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
        actions: [
          IconButton(
            icon: Icon(Icons.logout),
            onPressed: _handleLogout, // Call the logout function here
          ),
        ],
      ),
      body: FutureBuilder(
        future: dataFuture,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return CircularProgressIndicator(); // Display a loading indicator while fetching data.
          } else if (snapshot.hasError) {
            return Text('Error: ${snapshot.error}');
          } else if (!snapshot.hasData) {
            return Text('No Data');
          } else {
            if (retainedPartnertype == "Delivery Partner") {
              return Container(
                child: Center(
                  child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        // Add more details as needed
                        Container(
                          width: 120,
                          height: 120,
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            border: Border.all(
                              color: Colors.blue, // Border color
                              width: 2.0, // Border width
                            ),
                          ),
                          child: ClipOval(
                            child: Image.network(
                              photoUrl, // Use the photo URL from partnerDetails
                              width: 120,
                              height: 120,
                              fit: BoxFit.cover,
                            ),
                          ),
                        ),
                        SizedBox(
                          height: 8,
                        ),
                        Container(
                            child: Column(
                                crossAxisAlignment: CrossAxisAlignment.stretch,
                                children: [
                              // Add more details as needed
                              Container(
                                decoration: BoxDecoration(
                                  border: Border.all(
                                    color: Colors.blue,
                                    width: 0.5,
                                  ),
                                ),
                                child: Text('Name: $name',
                                    textAlign: TextAlign.center),
                                padding: EdgeInsets.all(8.0),
                              ),
                              Container(
                                decoration: BoxDecoration(
                                  border: Border.all(
                                    color: Colors.blue,
                                    width: 0.5,
                                  ),
                                ),
                                child: Text('Email: $email',
                                    textAlign: TextAlign.center),
                                padding: EdgeInsets.all(8.0),
                              ),
                              Container(
                                decoration: BoxDecoration(
                                  border: Border.all(
                                    color: Colors
                                        .blue, // Border color for the text container
                                    width:
                                        0.5, // Border width for the text container
                                  ),
                                ),
                                child: Text('Phone Number: $phone',
                                    textAlign: TextAlign.center),
                                padding: EdgeInsets.all(
                                    8.0), // Add padding to the text container
                              ),
                            ])),
                        ElevatedButton(
                          onPressed: () {
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (context) => ProcessView(
                                  meal: "Breakfast",
                                  locations: deliveryPartnerLocations,
                                ),
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
                                builder: (context) => ProcessView(
                                  meal: "Lunch",
                                  locations: deliveryPartnerLocations,
                                ),
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
                                builder: (context) => ProcessView(
                                  meal: "Dinner",
                                  locations: deliveryPartnerLocations,
                                ),
                              ),
                            );
                          },
                          child: const Text('Dinner'),
                        ),
                      ]),
                ),
              );
            } else if (retainedPartnertype == "Representative") {
              return Container(
                child: Center(
                  child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        // Add more details as needed
                        Container(
                          width: 120,
                          height: 120,
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            border: Border.all(
                              color: Colors.blue, // Border color
                              width: 2.0, // Border width
                            ),
                          ),
                          child: ClipOval(
                            child: Image.network(
                              photoUrl, // Use the photo URL from partnerDetails
                              width: 120,
                              height: 120,
                              fit: BoxFit.cover,
                            ),
                          ),
                        ),
                        SizedBox(
                          height: 8,
                        ),
                        Container(
                            child: Column(
                                crossAxisAlignment: CrossAxisAlignment.stretch,
                                children: [
                              // Add more details as needed
                              Container(
                                decoration: BoxDecoration(
                                  border: Border.all(
                                    color: Colors.blue,
                                    width: 0.5,
                                  ),
                                ),
                                child: Text('Name: $name',
                                    textAlign: TextAlign.center),
                                padding: EdgeInsets.all(8.0),
                              ),
                              Container(
                                decoration: BoxDecoration(
                                  border: Border.all(
                                    color: Colors.blue,
                                    width: 0.5,
                                  ),
                                ),
                                child: Text('Email: $email',
                                    textAlign: TextAlign.center),
                                padding: EdgeInsets.all(8.0),
                              ),
                              Container(
                                decoration: BoxDecoration(
                                  border: Border.all(
                                    color: Colors
                                        .blue, // Border color for the text container
                                    width:
                                        0.5, // Border width for the text container
                                  ),
                                ),
                                child: Text('Phone Number: $phone',
                                    textAlign: TextAlign.center),
                                padding: EdgeInsets.all(
                                    8.0), // Add padding to the text container
                              ),
                            ])),
                        ElevatedButton(
                          onPressed: () {
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (context) => RepresentativeOrders(
                                  meal: "Breakfast",
                                  locationNames: deliveryPartnerLocations,
                                ),
                              ),
                            );
                          },
                          child: const Text('Orders handed'),
                        ),
                      ]),
                ),
              );
            } else {
              return const Text('No User found');
            }
          }
        },
      ),
    );
  }
}
