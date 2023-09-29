import 'package:flutter/material.dart';
import 'package:tb_deliveryapp/services/firebase_service.dart';

class LocationView extends StatefulWidget {
  LocationView({
    Key? key,
    required this.locationNames,
    required this.mealType,
    required this.locationPackedOrders,
    required this.locationPendingOrders,
  }) : super(key: key);

  final List<String>? locationNames;
  final String mealType;
  final Map<String, int> locationPackedOrders;
  final Map<String, int> locationPendingOrders;

  @override
  State<LocationView> createState() => _LocationViewState();
}

class _LocationViewState extends State<LocationView> {
  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      child: Column(
        children: widget.locationNames?.map((locationName) {
              final int pendingOrders =
                  widget.locationPendingOrders[locationName] ?? 0;
              final int packedOrders =
                  widget.locationPackedOrders[locationName] ?? 0;

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
                  // Handle tap event if needed
                },
              );
            }).toList() ??
            [],
      ),
    );
  }
}
