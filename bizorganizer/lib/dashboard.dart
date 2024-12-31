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

            final trips = snapshot.data!.reversed.toList();

            return CustomScrollView(
              controller: _scrollController,
              slivers: [
                SliverToBoxAdapter(
                  child: Stack(children: [
                    Container(
                      margin: const EdgeInsets.all(16.0),
                      height: MediaQuery.of(context).size.height * 0.3,
                      color: Colors.grey,
                    ),
                    Positioned(
                      top: 20,
                      right: 10,
                      child: IconButton(
                          iconSize: 40,
                          onPressed: () => Navigator.of(context).push(
                              MaterialPageRoute(
                                  builder: (_) => TripStatsPage())),
                          icon: Icon(Icons.output_rounded)),
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
                            _buildSummaryCard(
                                context, 'Total Trips', trips.length),
                            _buildSummaryCard(
                                context,
                                'Pending Trips',
                                trips
                                    .where((trip) =>
                                        trip['orderStatus']
                                            .toString()
                                            .toLowerCase() ==
                                        'pending')
                                    .length),
                            _buildSummaryCard(
                                context,
                                'Completed Trips',
                                trips
                                    .where((trip) =>
                                        trip['orderStatus']
                                            .toString()
                                            .toLowerCase() ==
                                        'completed')
                                    .length),
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
                      (context, index) {
                        final trip = trips[index];
                        return _buildTripCard(context, trip);
                      },
                      childCount: trips.length,
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
        .from('trip') // Replace with your Supabase table name
        .stream(primaryKey: ['id']) // Assuming `id` is the primary key
        .map((rows) => rows.map((row) => row as Map<String, dynamic>).toList());

    return stream;
  }

  // Summary card widget
  Widget _buildSummaryCard(BuildContext context, String title, int count) {
    return Card(
      color: Theme.of(context).colorScheme.primary.withOpacity(0.1),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(title, style: Theme.of(context).textTheme.bodyMedium),
            const SizedBox(height: 8),
            Text(
              count.toString(),
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
                color: Theme.of(context).colorScheme.primary,
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
          Icons.fire_truck,
          color: Colors.blueAccent,
          size: 30,
        ),
        title: Text(
          trip['clientName'],
          style: TextStyle(fontWeight: FontWeight.bold),
        ),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text("Date: ${trip['date']}"),
            Text("Status: ${trip['orderStatus']}",
                style: TextStyle(
                  color: _getStatusColor(trip['orderStatus']),
                  fontWeight: FontWeight.bold,
                )),
            Text("Payment Status: ${trip['paymentStatus']}"),
          ],
        ),
        trailing: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.attach_money, color: Colors.green),
            Text("\$${trip['amount'].toString()}",
                style: TextStyle(fontWeight: FontWeight.bold, fontSize: 17)),
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
