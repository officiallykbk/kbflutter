import 'package:bizorganizer/main.dart';
import 'package:bizorganizer/main.dart'; // Assuming supabase client is here
import 'package:bizorganizer/stats.dart';
import 'package:bizorganizer/main.dart'; // Assuming supabase client is here
import 'package:bizorganizer/stats.dart'; // Will be JobStatsPage
import 'package:flutter/rendering.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:bizorganizer/addjob.dart'; // Updated to AddJob
import 'package:bizorganizer/jobdetails.dart'; 
import 'package:flutter/material.dart';
import 'package:intl/intl.dart'; // For date formatting
// No direct import for CargoJob model needed here as we are working with Map<String, dynamic> from stream

class Dashboard extends StatefulWidget {
  const Dashboard({super.key});

  @override
  State<Dashboard> createState() => _DashboardState();
}

class _DashboardState extends State<Dashboard> {
  final ScrollController _scrollController = ScrollController();
  bool _isFabVisible = true;

  // State variables for job counts
  int _totalJobsCount = 0;
  int _pendingJobsCount = 0;
  int _completedJobsCount = 0;
  int _cancelledJobsCount = 0; 
  int _overdueJobsCount = 0;   

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
          stream: _getJobsStream(supabase), // Updated stream method name
          builder: (context, snapshot) {
            if (snapshot.connectionState == ConnectionState.waiting) {
              return const Center(child: CircularProgressIndicator());
            }

            if (snapshot.hasError) {
              print('Dashboard Stream Error: ${snapshot.error}'); // Log error
              return const Center(child: Text('Error loading jobs. Please check connection.'));
            }

            if (!snapshot.hasData || snapshot.data!.isEmpty) {
              return const Center(child: Text('No jobs available.'));
            }

            final jobs = snapshot.data!; // Renamed for clarity

            // Calculate counts once using new field names
            _totalJobsCount = jobs.length;
            // Assuming 'pending' and 'in progress' are valid delivery_status values
            _pendingJobsCount = jobs.where((job) => job['delivery_status']?.toString().toLowerCase() == 'pending' || job['delivery_status']?.toString().toLowerCase() == 'in progress').length;
            _completedJobsCount = jobs.where((job) => job['delivery_status']?.toString().toLowerCase() == 'completed').length;
            // Assuming 'cancelled' and 'refunded' are valid delivery_status values
            _cancelledJobsCount = jobs.where((job) => job['delivery_status']?.toString().toLowerCase() == 'cancelled' || job['delivery_status']?.toString().toLowerCase() == 'refunded').length;
            // Assuming 'overdue' and 'onhold' are valid delivery_status values
            _overdueJobsCount = jobs.where((job) => job['delivery_status']?.toString().toLowerCase() == 'overdue' || job['delivery_status']?.toString().toLowerCase() == 'onhold').length;

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
                                  builder: (_) => JobStatsPage())), // Updated to JobStatsPage
                          icon: const Icon(Icons.output_rounded)), 
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
                            _buildSummaryCard(context, 'Total Jobs', _totalJobsCount, Colors.blue), // Updated label
                            const SizedBox(width: 8),
                            _buildSummaryCard(context, 'Pending', _pendingJobsCount, Colors.orange),
                            const SizedBox(width: 8),
                            _buildSummaryCard(context, 'Completed', _completedJobsCount, Colors.green),
                            const SizedBox(width: 8),
                            _buildSummaryCard(context, 'Cancelled', _cancelledJobsCount, Colors.red),
                            const SizedBox(width: 8),
                            _buildSummaryCard(context, 'Overdue', _overdueJobsCount, Colors.purple),
                          ],
                        ),
                      ),
                    ]),
                  ),
                ),
                // Job List Section
                SliverPadding(
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  sliver: SliverList(
                    delegate: SliverChildBuilderDelegate(
                      (BuildContext context, int index) {
                        final job = jobs[index]; // Use 'job'
                        return _buildJobCard(context, job); // Updated card builder name
                      },
                      childCount: _totalJobsCount, 
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
                  .push(MaterialPageRoute(builder: (_) => AddJob())); // Updated to AddJob
            },
            label: const Text('Add New Job'), 
            icon: const Icon(Icons.add),
          ),
        ),
      ),
    );
  }

  // Get stream of jobs from Supabase
  Stream<List<Map<String, dynamic>>> _getJobsStream(SupabaseClient supabase) { // Renamed method
    final stream = supabase
        .from('cargo_jobs')  // Updated table name
        .stream(primaryKey: ['id'])
        .order('id', ascending: false) 
        .map((rows) => rows.map((row) => row as Map<String, dynamic>).toList());

    return stream;
  }

  // Summary card widget - remains largely the same, titles are generic
  Widget _buildSummaryCard(BuildContext context, String title, int count, Color color) {
    return Card(
      elevation: 2,
      color: color.withOpacity(0.15),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
      child: Container(
        width: 120, 
        padding: const EdgeInsets.all(12.0),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(title, style: Theme.of(context).textTheme.titleMedium?.copyWith(color: color, fontWeight: FontWeight.bold), textAlign: TextAlign.center,),
            const SizedBox(height: 8),
            Text(
              count.toString(),
              style: TextStyle(
                fontSize: 22,
                fontWeight: FontWeight.bold,
                color: color,
              ),
            ),
          ],
        ),
      ),
    );
  }

  // Job card widget (formerly _buildTripCard)
  Widget _buildJobCard(BuildContext context, Map<String, dynamic> job) { // Renamed parameter
    return Card(
      margin: const EdgeInsets.only(bottom: 10),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
      child: ListTile(
        onTap: () {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (_) => JobDetails(job: job), // Updated to JobDetails
            ),
          );
        },
        leading: Icon(
          Icons.local_shipping, 
          color: Theme.of(context).colorScheme.primary, 
          size: 28, 
        ),
        title: Text(
          job['shipper_name'] ?? 'N/A Shipper', // Updated field name
          style: const TextStyle(fontWeight: FontWeight.bold), 
        ),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text("Date: ${_formatJobDate(job['pickup_date'] ?? job['created_at'])}"), // Added formatting
            Text("Status: ${job['delivery_status'] ?? 'N/A'}", 
                style: TextStyle(
                  color: _getStatusColor(job['delivery_status']?.toString()), 
                  fontWeight: FontWeight.bold,
                )),
            Text("Payment: ${job['payment_status'] ?? 'N/A'}"), 
          ],
        ),
        trailing: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          crossAxisAlignment: CrossAxisAlignment.end, 
          children: [
            Text(
              "\$${(job['agreed_price'] as num?)?.toStringAsFixed(2) ?? '0.00'}", // Updated field name and type handling
              style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16, color: Colors.green),
            ),
          ],
        ),
      ),
    );
  }

  // Helper to get color based on status
  // Helper to format date strings for display
  String _formatJobDate(String? dateString) {
    if (dateString == null || dateString.isEmpty) return 'N/A';
    try {
      final dateTime = DateTime.parse(dateString);
      return DateFormat('MMM d, yyyy').format(dateTime); // e.g., Jan 1, 2023
    } catch (e) {
      return dateString; // Return original if parsing fails
    }
  }

  Color _getStatusColor(String? status) {
    switch (status?.toLowerCase()) {
      // delivery_status values
      case 'delivered': // Assuming 'delivered' might be used for completed
      case 'completed':
        return Colors.green;
      case 'pending':
      case 'in progress': // Map 'in progress' to orange as well
        return Colors.orange;
      case 'cancelled':
      case 'refunded': // Map 'refunded' to red
        return Colors.red;
      case 'onhold': // Keep yellow for onhold
        return Colors.yellow;
      case 'rejected': // Keep grey for rejected
        return Colors.grey;
      default:
        return Colors.black;
    }
  }
}
