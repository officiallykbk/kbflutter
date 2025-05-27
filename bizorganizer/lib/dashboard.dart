import 'package:bizorganizer/main.dart';
import 'package:bizorganizer/stats.dart'; 
import 'package:flutter/rendering.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:bizorganizer/addjob.dart'; 
import 'package:bizorganizer/jobdetails.dart'; 
import 'package:flutter/material.dart';
import 'package:intl/intl.dart'; 

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

  // Task 2.1: Declare _jobsStream
  late final Stream<List<Map<String, dynamic>>> _jobsStream;

  @override
  void initState() {
    super.initState();
    _scrollController.addListener(_scrollListener);
    // Task 2.1: Initialize _jobsStream in initState
    // 'supabase' is already a global final variable from main.dart, so we can use it directly.
    _jobsStream = _getJobsStream(supabase); 
  }

  void _scrollListener() {
    if (_scrollController.position.userScrollDirection == ScrollDirection.reverse) {
      if (_isFabVisible) {
        // Task 3: Ensure setState is minimal
        setState(() { _isFabVisible = false; }); 
      }
    } else if (_scrollController.position.userScrollDirection == ScrollDirection.forward) {
      if (!_isFabVisible) {
        // Task 3: Ensure setState is minimal
        setState(() { _isFabVisible = true; }); 
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
        title: const Text('Dashboard', style: TextStyle(color: Colors.white)), // Added const
        centerTitle: true,
        backgroundColor: Theme.of(context).colorScheme.primary,
        iconTheme: const IconThemeData(color: Colors.white), // Added const and themed color
      ),
      body: SafeArea(
        child: StreamBuilder<List<Map<String, dynamic>>>(
          stream: _jobsStream, // Task 2.2: Use the instance variable
          builder: (context, snapshot) {
            if (snapshot.connectionState == ConnectionState.waiting) {
              return const Center(child: CircularProgressIndicator());
            }

            if (snapshot.hasError) {
              print('Dashboard Stream Error: ${snapshot.error}'); 
              return const Center(child: Text('Error loading jobs. Please check connection.'));
            }

            if (!snapshot.hasData || snapshot.data!.isEmpty) {
              return const Center(child: Text('No jobs available.'));
            }

            final jobs = snapshot.data!; 

            _totalJobsCount = jobs.length;
            _pendingJobsCount = jobs.where((job) => job['delivery_status']?.toString().toLowerCase() == 'pending' || job['delivery_status']?.toString().toLowerCase() == 'in progress').length;
            _completedJobsCount = jobs.where((job) => job['delivery_status']?.toString().toLowerCase() == 'completed').length;
            _cancelledJobsCount = jobs.where((job) => job['delivery_status']?.toString().toLowerCase() == 'cancelled' || job['delivery_status']?.toString().toLowerCase() == 'refunded').length;
            _overdueJobsCount = jobs.where((job) => job['delivery_status']?.toString().toLowerCase() == 'overdue' || job['delivery_status']?.toString().toLowerCase() == 'onhold').length;

            return CustomScrollView(
              controller: _scrollController,
              slivers: [
                SliverToBoxAdapter(
                  child: Stack(children: [
                    Container(
                      margin: const EdgeInsets.all(16.0),
                      height: MediaQuery.of(context).size.height * 0.3,
                      decoration: BoxDecoration( // Added decoration for placeholder
                        color: Colors.grey.shade300,
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Center(child: Icon(Icons.bar_chart, size: 100, color: Colors.grey.shade500)), // Placeholder content
                    ),
                    Positioned(
                      top: 20,
                      right: 10,
                      child: IconButton(
                          iconSize: 40,
                          color: Theme.of(context).colorScheme.primary, // Themed icon
                          onPressed: () => Navigator.of(context).push(
                              MaterialPageRoute(
                                  builder: (_) => JobStatsPage())), 
                          icon: const Icon(Icons.insights_rounded)), // Changed icon and added const
                    )
                  ]),
                ),
                SliverPadding(
                  padding: const EdgeInsets.all(16.0),
                  sliver: SliverList(
                    delegate: SliverChildListDelegate([
                      SingleChildScrollView(
                        scrollDirection: Axis.horizontal,
                        child: Row(
                          children: [
                            _buildSummaryCard(context, 'Total Jobs', _totalJobsCount, Colors.blue.shade700), 
                            const SizedBox(width: 8),
                            _buildSummaryCard(context, 'Pending', _pendingJobsCount, Colors.orange.shade700),
                            const SizedBox(width: 8),
                            _buildSummaryCard(context, 'Completed', _completedJobsCount, Colors.green.shade700),
                            const SizedBox(width: 8),
                            _buildSummaryCard(context, 'Cancelled', _cancelledJobsCount, Colors.red.shade700),
                            const SizedBox(width: 8),
                            _buildSummaryCard(context, 'Overdue', _overdueJobsCount, Colors.purple.shade700),
                          ],
                        ),
                      ),
                    ]),
                  ),
                ),
                SliverPadding(
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  sliver: SliverList(
                    delegate: SliverChildBuilderDelegate(
                      (BuildContext context, int index) {
                        final job = jobs[index]; 
                        return _buildJobCard(context, job); 
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
        offset: _isFabVisible ? Offset.zero : const Offset(0, 2), // Slide down
        duration: const Duration(milliseconds: 300),
        child: AnimatedOpacity(
          opacity: _isFabVisible ? 1.0 : 0.0,
          duration: const Duration(milliseconds: 300),
          child: FloatingActionButton.extended(
            onPressed: () {
              Navigator.of(context)
                  .push(MaterialPageRoute(builder: (_) => const AddJob())); // Added const
            },
            label: const Text('Add New Job'), 
            icon: const Icon(Icons.add),
            backgroundColor: Theme.of(context).colorScheme.secondary, // Themed FAB
            foregroundColor: Theme.of(context).colorScheme.onSecondary,
          ),
        ),
      ),
    );
  }

  Stream<List<Map<String, dynamic>>> _getJobsStream(SupabaseClient supabaseInstance) { // Ensure supabaseInstance is used
    final stream = supabaseInstance // Use passed instance
        .from('cargo_jobs')  
        .stream(primaryKey: ['id'])
        .order('id', ascending: false) 
        .map((rows) => rows.map((row) => row as Map<String, dynamic>).toList());
    return stream;
  }

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

  Widget _buildJobCard(BuildContext context, Map<String, dynamic> job) { 
    return Card(
      margin: const EdgeInsets.only(bottom: 10),
      elevation: 2, // Added some elevation
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
      child: ListTile(
        onTap: () {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (_) => JobDetails(job: job), 
            ),
          );
        },
        leading: Icon(
          Icons.local_shipping, 
          color: Theme.of(context).colorScheme.primary, 
          size: 28, 
        ),
        title: Text(
          job['shipper_name'] ?? 'N/A Shipper', 
          style: const TextStyle(fontWeight: FontWeight.bold), 
        ),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const SizedBox(height: 4),
            Text("Date: ${_formatJobDate(job['pickup_date'] ?? job['created_at'])}"), 
            const SizedBox(height: 2),
            Text("Status: ${job['delivery_status'] ?? 'N/A'}", 
                style: TextStyle(
                  color: _getStatusColor(job['delivery_status']?.toString()), 
                  fontWeight: FontWeight.bold,
                )),
            const SizedBox(height: 2),
            Text("Payment: ${job['payment_status'] ?? 'N/A'}"), 
          ],
        ),
        trailing: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          crossAxisAlignment: CrossAxisAlignment.end, 
          children: [
            Text(
              "\$${(job['agreed_price'] as num?)?.toStringAsFixed(2) ?? '0.00'}", 
              style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16, color: Colors.green),
            ),
          ],
        ),
      ),
    );
  }

  String _formatJobDate(String? dateString) {
    if (dateString == null || dateString.isEmpty) return 'N/A';
    try {
      final dateTime = DateTime.parse(dateString);
      return DateFormat('MMM d, yyyy').format(dateTime); 
    } catch (e) {
      return dateString; 
    }
  }

  Color _getStatusColor(String? status) {
    switch (status?.toLowerCase()) {
      case 'delivered': 
      case 'completed':
        return Colors.green.shade700; // Darker green
      case 'pending':
      case 'in progress': 
        return Colors.orange.shade700; // Darker orange
      case 'cancelled':
      case 'refunded': 
        return Colors.red.shade700; // Darker red
      case 'onhold': 
        return Colors.yellow.shade800; // Darker yellow
      case 'rejected': 
        return Colors.grey.shade600; // Darker grey
      default:
        return Theme.of(context).textTheme.bodySmall?.color ?? Colors.black; // Default text color
    }
  }
}
