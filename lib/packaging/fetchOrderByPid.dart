import 'package:tb_deliveryapp/utils/utils.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class FirebaseService {
  final CollectionReference ordersCollection =
      FirebaseFirestore.instance.collection('Orders');
  final CollectionReference timeCollection =
      FirebaseFirestore.instance.collection('Time');

  Future<Map<String, dynamic>> fetchOrderReferencesByPid(
      pid, String profileType, String orderType, String orderStatus) async {
    try {
      final ordersCollection = FirebaseFirestore.instance.collection('Orders');
      final currentDate = DateTime.now();
      final year = currentDate.year;
      final month = currentDate.month;
      final day = currentDate.day;
      final currentDateStart = DateTime(year, month, day);
      final currentDateEnd = currentDateStart.add(Duration(days: 1));

      final querySnapshot = await ordersCollection
          .where('pid', isEqualTo: pid)
          .where('deliveryDate', isGreaterThanOrEqualTo: currentDateStart)
          .where('deliveryDate', isLessThan: currentDateEnd)
          .where('profileType', isEqualTo: profileType)
          .where('Status', isEqualTo: orderStatus)
          .where('orderType', isEqualTo: orderType)
          .get();
      final totalOrders = querySnapshot.size;

      final ordersList = querySnapshot.docs.map((documentSnapshot) {
        final data = documentSnapshot.data() as Map<String, dynamic>;
        return {
          'orderRef': documentSnapshot.reference.id,
          'orderName': data['orderName'],
          'quantity': data['numberOfItems'],
          'orderType': data['orderType'],
          'orderStatus': data['Status'],
        };
      }).toList();

      return {
        'totalOrders': totalOrders,
        'ordersList': ordersList,
      };
    } catch (e) {
      print("Error fetching order references: $e");
      return {
        'totalOrders': 0,
        'ordersList': [],
      };
    }
  }
}
