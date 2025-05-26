import 'package:bizorganizer/main.dart';
import 'package:bizorganizer/models/trips.dart';
import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class TripsProvider extends ChangeNotifier {
  final SupabaseClient _supabase = Supabase.instance.client;

  // Fields for trips and statuses
  String? _image;
  List<Map<String, dynamic>> _trips = [];
  List<Map<String, dynamic>> _completedTrips = [];
  List<Map<String, dynamic>> _pendingTrips = [];
  List<Map<String, dynamic>> _cancelledTrips = [];
  List<Map<String, dynamic>> _onHoldTrips = [];
  List<Map<String, dynamic>> _rejectedTrips = [];
  List<Map<String, dynamic>> _paidTrips = [];
  List<Map<String, dynamic>> _pendingPayments = [];
  List<Map<String, dynamic>> _overduePayments = [];

  // Getters for trips and image
  String? get image => _image;
  List<Map<String, dynamic>> get trips => _trips;
  List<Map<String, dynamic>> get completedTrips => _completedTrips;
  List<Map<String, dynamic>> get pendingTrips => _pendingTrips;
  List<Map<String, dynamic>> get cancelledTrips => _cancelledTrips;
  List<Map<String, dynamic>> get onHoldTrips => _onHoldTrips;
  List<Map<String, dynamic>> get rejectedTrips => _rejectedTrips;
  List<Map<String, dynamic>> get paidTrips => _paidTrips;
  List<Map<String, dynamic>> get pendingPayments => _pendingPayments;
  List<Map<String, dynamic>> get overduePayments => _overduePayments;

  // Fetch all trip data and categorize based on status
  Future<void> fetchTripsData() async {
    try {
      // Fetch all trip data from Supabase
      // DateFormat format = DateFormat('d-mm-yyyy');
      final response = await _supabase
          .from('trip')
          .select()
          .order('created_at', ascending: true);

      List<Map<String, dynamic>> tripsData =
          (response as List).cast<Map<String, dynamic>>();

      // for (var data in tripsData) {
      //   format.parse(data['date']);
      // }
      // tripsData.sort((a, b) => a['date'].compareTo(b['date']));

      // tripsData.sort((a, b) {
      //   DateTime dateA = format.parse(a['date']);
      //   DateTime dateB = format.parse(b['date']);
      //   return dateA.compareTo(dateB); // Ascending order
      // });

      _trips = tripsData;
      print(_trips);

      // Filter based on Order Status
      _completedTrips = tripsData
          .where((trip) => trip['orderStatus'] == 'completed')
          .toList();
      _pendingTrips =
          tripsData.where((trip) => trip['orderStatus'] == 'pending').toList();
      _cancelledTrips = tripsData
          .where((trip) => trip['orderStatus'] == 'cancelled')
          .toList();
      _onHoldTrips =
          tripsData.where((trip) => trip['orderStatus'] == 'onhold').toList();
      _rejectedTrips =
          tripsData.where((trip) => trip['orderStatus'] == 'rejected').toList();

      // Filter based on Payment Status
      _paidTrips =
          tripsData.where((trip) => trip['paymentStatus'] == 'paid').toList();
      _pendingPayments = tripsData
          .where((trip) => trip['paymentStatus'] == 'pending')
          .toList();
      _overduePayments = tripsData
          .where((trip) => trip['paymentStatus'] == 'overdue')
          .toList();

      notifyListeners();
    } catch (e) {
      print('Error fetching trips data: $e');
    }
  }

  Future<void> addTrip(Trip trip) async {
    try {
      // Save the customer data first
      await _supabase.from('customer').upsert({
        'clientName': trip.clientName,
        'contactNumber': trip.contactNumber,
      });

      // Save the trip data
      await _supabase.from('trip').insert(trip.toJson());
      fetchTripsData();
    } catch (e) {
      print('Error adding trip: $e');
    }
  }

  // Remove a trip by id
  Future<void> removeTrip(String id) async {
    try {
      await _supabase.from('trip').delete().eq('id', id);
      _trips.removeWhere((trip) => trip['id'] == id);
      notifyListeners();
      print('Trip removed successfully');
    } catch (e) {
      print('Error removing trip: $e');
    }
  }

  // Edit a trip by id
  Future<void> editTrip(String id, Map<String, dynamic> updatedTrip) async {
    try {
      await _supabase.from('trip').update(updatedTrip).eq('id', id);
      await fetchTripsData();
      print('Trip updated successfully');
    } catch (e) {
      print('Error updating trip: $e');
    }
  }

  void updateOrderStatus(int tripId, String newStatus) async {
    try {
      final tripIndex = _trips.indexWhere((trip) => trip['id'] == tripId);
      if (tripIndex != -1) {
        _trips[tripIndex]['orderStatus'] = newStatus;

        // Update on Supabase
        final response = await supabase
            .from('trip')
            .update({'orderStatus': newStatus})
            .eq('id', tripId)
            .select();
        print('responsezz $response');

        notifyListeners();
      }
    } catch (e) {
      print('Errorzzz in changing orderStatus $e');
    }
  }

  void updatePaymentStatus(int tripId, String newStatus) async {
    try {
      final tripIndex = _trips.indexWhere((trip) => trip['id'] == tripId);
      if (tripIndex != -1) {
        _trips[tripIndex]['paymentStatus'] = newStatus;

        // Update on Supabase
        final response = await supabase
            .from('trip')
            .update({'paymentStatus': newStatus})
            .eq('id', tripId)
            .select();

        print('responsezz $response');

        notifyListeners();
      }
    } catch (e) {
      print('Errorzzz in changing paymentStatus $e');
    }
  }

  // Set image reference and notify listeners
  void addImage(String imageRef) {
    _image = imageRef;
    notifyListeners();
  }

  // // Sort trip by criteria
  // void sortTrips(String criteria) {
  //   _trips.sort((a, b) => a[criteria].compareTo(b[criteria]));
  //   notifyListeners();
  // }

  // // Filter trip by order status
  // List<Map<String, dynamic>> filterTripsByStatus(String status) {
  //   return _allTrips.where((trip) => trip['orderStatus'] == status).toList();
  // }

  // // Filter trip by payment status
  // List<Map<String, dynamic>> filterTripsByPaymentStatus(String status) {
  //   return _allTrips.where((trip) => trip['paymentStatus'] == status).toList();
  // }
}
