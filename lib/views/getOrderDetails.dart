// import 'package:cloud_firestore/cloud_firestore.dart';

// Future<List<Map<String, dynamic>>> fetchOrders(String profileRef) async {
//   try {
//     CollectionReference ordersCollection = FirebaseFirestore.instance.collection('Orders');
//     DateTime currentDate = DateTime.now();
//     String formattedDate = currentDate.toLocal().toString().split(' ')[0];

//     QuerySnapshot querySnapshot = await ordersCollection
//         .where('pid', isEqualTo: profileRef)
//         .where('deliveryDate', isEqualTo: formattedDate)
//         .get();

//     List<Map<String, dynamic>> ordersList = [];
//     querySnapshot.docs.forEach((documentSnapshot) {
//       Map<String, dynamic> data = documentSnapshot.data() as Map<String, dynamic>;
//       String orderName = data['orderName'];
//       int quantity = data['quantity'];
//       String orderType = data['orderType'];

//       Map<String, dynamic> orderMap = {
//         'orderName': orderName,
//         'quantity': quantity,
//         'orderType': orderType,
//       };
//       ordersList.add(orderMap);
//     });

//     return ordersList;
//   } catch (e) {
//     print("Error fetching orders: $e");
//     return [];
//   }
// }

// void orderDetails() async {
//   String profileRef = 'your_provided_value';
//   List<Map<String, dynamic>> orders = await fetchOrders(profileRef);

//   if (orders.isNotEmpty) {
//     for (Map<String, dynamic> order in orders) {
//       print("Order Name: ${order['orderName']}");
//       print("Quantity: ${order['quantity']}");
//       print("Order Type: ${order['orderType']}");
//       print(""); // Print an empty line between orders
//     }
//   } else {
//     print("No matching orders found.");
//   }
// }
