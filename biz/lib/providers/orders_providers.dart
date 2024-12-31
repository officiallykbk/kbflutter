import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';

class OrdersProviders extends ChangeNotifier {
  //variables
  String? _image;
  List _allOrders = [];
  List _allOrderspaid = [];
  List _allOrdersPending = [];
  List _allOrdersCancelled = [];
  List _allOrdersRejected = [];
  List _allOrdersOnHold = [];

//getters
  String? get image => _image;
  List get allOrders => _allOrders;
  List get allOrderspaid => _allOrderspaid;
  List get allOrdersPending => _allOrdersPending;
  List get allOrdersCancelled => _allOrdersCancelled;
  List get allOrdersRejected => _allOrdersRejected;
  List get allOrdersOnHold => _allOrdersOnHold;

  // get all orders
  Future<void> allOrdersData() async {
    try {
      QuerySnapshot querySnapshot = await FirebaseFirestore.instance
          .collection('Orders')
          .orderBy('Date')
          .get();

      List<Map<String, dynamic>> orders = querySnapshot.docs.map((doc) {
        return {'id': doc.id, ...doc.data() as Map<String, dynamic>};
      }).toList();
      _allOrders = orders;

      List<Map<String, dynamic>> paidOrders = orders.where((order) {
        return order['paymentStatus'] == 'Paid';
      }).toList();
      _allOrderspaid = paidOrders;
      print('paidzzz ${_allOrderspaid}');
    } catch (e) {
      print('We hit an error in pulling the orderzz: ${e}');
    }
    notifyListeners();
  }
}
