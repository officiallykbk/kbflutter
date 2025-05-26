import 'package:bizorganizer/main.dart';
import 'package:bizorganizer/stats.dart';
import 'package:flutter/rendering.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:bizorganizer/addnew.dart';
import 'package:bizorganizer/tripdetails.dart';
import 'package:flutter/material.dart';

class Dashboard extends StatefulWidget {
  const Dashboard({super.key});

  @override
  State<Dashboard> createState() => _DashboardState();
}

class _DashboardState extends State<Dashboard> {
  final ScrollController _scrollController = ScrollController();
  bool _isFabVisible = true;

  // State variables for trip counts
  int _totalTripsCount = 0;
  int _pendingTripsCount = 0;
  int _completedTripsCount = 0;
  int _cancelledTripsCount = 0; 
  int _overdueTripsCount = 0;   

  @override
  void initState() {
    super.initState();
    _scrollController.addListener(_scrollListener);
  }

  void _scrollListener() {
    if (_scrollController.position.userScrollDirection ==
        ScrollDirection.reverse) {
      if (_isFabVisible) {
        setState(() => _isFabVisible = false); // Hide FAB when scrolling down
      }
    } else if (_scrollController.position.userScrollDirection ==
        ScrollDirection.forward) {
      if (!_isFabVisible) {
        setState(() => _isFabVisible = true); // Show FAB when scrolling up
      }
    }
  }

  @override
  void dispose() {
    _scrollController.removeListener(_scrollListener);
    _scrollController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Dashboard', style: TextStyle(color: Colors.white)),
        centerTitle: true,
        backgroundColor: Theme.of(context).colorScheme.primary,
      ),
      body: SafeArea(
        child: StreamBuilder<List<Map<String, dynamic>>>(
          stream: _getTripsStream(supabase),
          builder: (context, snapshot) {
            if (snapshot.connectionState == ConnectionState.waiting) {
              return Center(child: CircularProgressIndicator());
            }

            if (snapshot.hasError) {
              return Center(child: Text('Check internet / restart app'));
            }

            if (!snapshot.hasData || snapshot.data!.isEmpty) {
              return Center(child: Text('No trips available.'));
            }

            final trips = snapshot.data!; // No longer reversing here

            // Calculate counts once
            _totalTripsCount = trips.length;
            _pendingTripsCount = trips.where((trip) => trip['orderStatus']?.toString().toLowerCase() == 'pending' || trip['orderStatus']?.toString().toLowerCase() == 'in progress').length;
            _completedTripsCount = trips.where((trip) => trip['orderStatus']?.toString().toLowerCase() == 'completed').length;
            _cancelledTripsCount = trips.where((trip) => trip['orderStatus']?.toString().toLowerCase() == 'cancelled' || trip['orderStatus']?.toString().toLowerCase() == 'refunded').length;
            _overdueTripsCount = trips.where((trip) => trip['orderStatus']?.toString().toLowerCase() == 'overdue' || trip['orderStatus']?.toString().toLowerCase() == 'onhold').length;

            return CustomScrollView(
              controller: _scrollController,
              slivers: [
                SliverToBoxAdapter(
                  child: Stack(children: [
                    Container(
                      margin: const EdgeInsets.all(16.0),
                      height: MediaQuery.of(context).size.height * 0.3,
                      color: Colors.grey, // Placeholder color
                    ),
                    Positioned(
                      top: 20,
                      right: 10,
                      child: IconButton(
                          iconSize: 40,
                          onPressed: () => Navigator.of(context).push(
                              MaterialPageRoute(
                                  builder: (_) => TripStatsPage())),
                          icon: const Icon(Icons.output_rounded)), // Added const
                    )
                  ]),
                ),
                // Summary Cards Section (Scrollable horizontally)
                SliverPadding(
                  padding: const EdgeInsets.all(16.0),
                  sliver: SliverList(
                    delegate: SliverChildListDelegate([
                      SingleChildScrollView(
                        scrollDirection: Axis.horizontal,
                        child: Row(
                          children: [
                            _buildSummaryCard(context, 'Total Trips', _totalTripsCount, Colors.blue),
                            const SizedBox(width: 8), // Added for spacing
                            _buildSummaryCard(context, 'Pending', _pendingTripsCount, Colors.orange),
                            const SizedBox(width: 8),
                            _buildSummaryCard(context, 'Completed', _completedTripsCount, Colors.green),
                            const SizedBox(width: 8),
                            _buildSummaryCard(context, 'Cancelled', _cancelledTripsCount, Colors.red),
                             const SizedBox(width: 8),
                            _buildSummaryCard(context, 'Overdue', _overdueTripsCount, Colors.purple),
                          ],
                        ),
                      ),
                    ]),
                  ),
                ),
                // Trip List Section
                SliverPadding(
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  sliver: SliverList(
                    delegate: SliverChildBuilderDelegate(
                      (BuildContext context, int index) { // Added BuildContext type
                        final trip = trips[index];
                        return _buildTripCard(context, trip);
                      },
                      childCount: _totalTripsCount, // Use pre-calculated count
                    ),
                  ),
                ),
              ],
            );
          },
        ),
      ),
      floatingActionButton: AnimatedSlide(
        offset: _isFabVisible ? Offset(0, 0) : Offset(1, 0),
        duration: Duration(milliseconds: 300),
        child: AnimatedOpacity(
          opacity: _isFabVisible ? 1.0 : 0.0,
          duration: Duration(milliseconds: 300),
          child: FloatingActionButton.extended(
            onPressed: () {
              Navigator.of(context)
                  .push(MaterialPageRoute(builder: (_) => AddTrip()));
            },
            label: const Text('Add New Trip'),
            icon: const Icon(Icons.add),
          ),
        ),
      ),
    );
  }

  // Get stream of trips from Supabase
  Stream<List<Map<String, dynamic>>> _getTripsStream(SupabaseClient supabase) {
    final stream = supabase
        .from('trip') 
        .stream(primaryKey: ['id'])
        .order('id', ascending: false) // Server-side ordering
        .map((rows) => rows.map((row) => row as Map<String, dynamic>).toList());

    return stream;
  }

  // Summary card widget
  Widget _buildSummaryCard(BuildContext context, String title, int count, Color color) {
    return Card(
      elevation: 2, // Added slight elevation
      color: color.withOpacity(0.15), // Use passed color with opacity
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)), // Slightly larger radius
      child: Container( // Added container for fixed width and padding
        width: 120, // Fixed width for summary cards
        padding: const EdgeInsets.all(12.0), // Adjusted padding
        child: Column(
          mainAxisSize: MainAxisSize.min,
          mainAxisAlignment: MainAxisAlignment.center, // Center content
          children: [
            Text(title, style: Theme.of(context).textTheme.titleMedium?.copyWith(color: color, fontWeight: FontWeight.bold), textAlign: TextAlign.center,), // Use titleMedium
            const SizedBox(height: 8),
            Text(
              count.toString(),
              style: TextStyle( // Keep specific style for count
                fontSize: 22, // Slightly larger count
                fontWeight: FontWeight.bold,
                color: color, // Use passed color
              ),
            ),
          ],
        ),
      ),
    );
  }

  // Trip card widget
  Widget _buildTripCard(BuildContext context, Map<String, dynamic> trip) {
    return Card(
      margin: const EdgeInsets.only(bottom: 10),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
      child: ListTile(
        onTap: () {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (_) => TripDetails(trip: trip),
            ),
          );
        },
        leading: Icon(
          Icons.local_shipping, // Changed icon
          color: Theme.of(context).colorScheme.primary, // Use theme color
          size: 28, // Adjusted size
        ),
        title: Text(
          trip['clientName'],
          style: const TextStyle(fontWeight: FontWeight.bold), // Added const
        ),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text("Date: ${trip['date'] ?? 'N/A'}"), // Added null check
            Text("Status: ${trip['orderStatus'] ?? 'N/A'}", // Added null check
                style: TextStyle(
                  color: _getStatusColor(trip['orderStatus']?.toString()), // Added toString
                  fontWeight: FontWeight.bold,
                )),
            Text("Payment: ${trip['paymentStatus'] ?? 'N/A'}"), // Added null check and changed label
          ],
        ),
        trailing: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          crossAxisAlignment: CrossAxisAlignment.end, // Align text to end
          children: [
            Text(
              "\$${trip['amount']?.toStringAsFixed(2) ?? '0.00'}", // Added null check and formatting
              style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16, color: Colors.green), // Added const and color
            ),
            // Removed icon for cleaner look, amount is prominent enough
          ],
        ),
      ),
    );
  }

  // Helper to get color based on status
  Color _getStatusColor(String? status) {
    switch (status?.toLowerCase()) {
      case 'completed':
        return Colors.green;
      case 'pending':
        return Colors.orange;
      case 'cancelled':
        return Colors.red;
      case 'onhold':
        return Colors.yellow;
      case 'rejected':
        return Colors.grey;
      default:
        return Colors.black;
    }
  }
}
