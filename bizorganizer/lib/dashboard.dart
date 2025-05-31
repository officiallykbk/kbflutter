import 'package:bizorganizer/main.dart';
import 'package:bizorganizer/stats.dart';
import 'package:flutter/rendering.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:bizorganizer/addjob.dart';
import 'package:bizorganizer/jobdetails.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart'; // Task 1.d: Import provider
import 'package:bizorganizer/providers/orders_providers.dart'; // Task 1.d: Import CargoJobProvider
import 'package:bizorganizer/models/cargo_job.dart'; // Task 1.d: Import CargoJob model
import 'package:bizorganizer/widgets/revenue_trend_chart_widget.dart'; // Task 1.d: Import RevenueTrendChartWidget
import 'package:bizorganizer/models/status_constants.dart'; // For payment status options

class Dashboard extends StatefulWidget {
  const Dashboard({super.key});

  @override
  State<Dashboard> createState() => _DashboardState();
}

class _DashboardState extends State<Dashboard> {
  final ScrollController _scrollController = ScrollController();
  bool _isFabVisible = true;

  int _totalJobsCount = 0;
  int _pendingJobsCount = 0;
  int _completedJobsCount = 0;
  int _cancelledJobsCount = 0;
  int _overdueJobsCount = 0;

  late final Stream<List<Map<String, dynamic>>> _jobsStream;

  // Task 1.a: Add State Variables for Dashboard Filters
  DateTime _dashboardStartDate = DateTime.now().subtract(const Duration(days: 29)); // Default: Last 30 days (29+today)
  DateTime _dashboardEndDate = DateTime.now();
  // String _dashboardDateRangeDisplay = "Last 30 Days";

  String _dashboardPaymentStatusFilter = "Paid + Pending";
  // final List<String> _paymentStatusOptions = ["Paid + Pending", "Paid Only", "Pending Only"];


  @override
  void initState() {
    super.initState();
    _scrollController.addListener(_scrollListener);
    _jobsStream = _getJobsStream(supabase);

    // Ensure data is fetched when the dashboard is initialized
    // The provider will handle fallback to cache if Supabase fetch fails.
    WidgetsBinding.instance.addPostFrameCallback((_) {
      Provider.of<CargoJobProvider>(context, listen: false).fetchJobsData();
    });

    // Initialize _dashboardDateRangeDisplay based on default dates
    // _updateDashboardDateRangeDisplay(_dashboardStartDate, _dashboardEndDate, isInitial: true);
  }

//   void _updateDashboardDateRangeDisplay(DateTime start, DateTime end, {bool isInitial = false}) {
//     // Check if it's a predefined range or custom
//     if (!isInitial || selectedRangeIsPredefined()) { // If it's a predefined range, use the friendly name
//         // This part might need adjustment if selectedRange is not directly managed here.
//         // For now, if it's not a custom range via _selectDashboardDateRange, keep or set predefined text.
//         if (isInitial && _dashboardDateRangeDisplay == "Last 30 Days") {
//              // Keep default if it's the initial setup for "Last 30 days"
//         } else if (!isInitial) { // Only update if it's a custom selection that changed it
//              _dashboardDateRangeDisplay = "${DateFormat.yMd().format(start)} - ${DateFormat.yMd().format(end)}";
//         }
//     } else { // Custom range
//          _dashboardDateRangeDisplay = "${DateFormat.yMd().format(start)} - ${DateFormat.yMd().format(end)}";
//     }
// }


  bool selectedRangeIsPredefined() {
    // Helper to check if the current _dashboardStartDate and _dashboardEndDate match a predefined range
    // This is a simplified check. A more robust one would compare against all predefined ranges.
    final now = DateTime.now();
    if (_dashboardStartDate.year == now.subtract(const Duration(days: 29)).year &&
        _dashboardStartDate.month == now.subtract(const Duration(days: 29)).month &&
        _dashboardStartDate.day == now.subtract(const Duration(days: 29)).day &&
        _dashboardEndDate.year == now.year &&
        _dashboardEndDate.month == now.month &&
        _dashboardEndDate.day == now.day) {
        return true; // Matches "Last 30 Days"
    }
    // Add more checks for other predefined ranges if you have them
    return false;
  }


  // // Task 1.c: Implement UI for Filters on Dashboard - Date Range Picker Trigger
  // Future<void> _selectDashboardDateRange(BuildContext context) async {
  //   final picked = await showDateRangePicker(
  //     context: context,
  //     initialDateRange: DateTimeRange(start: _dashboardStartDate, end: _dashboardEndDate),
  //     firstDate: DateTime(2000),
  //     lastDate: DateTime.now().add(const Duration(days: 365)),
  //   );
  //   if (picked != null && (picked.start != _dashboardStartDate || picked.end != _dashboardEndDate)) {
  //     setState(() {
  //       _dashboardStartDate = picked.start;
  //       _dashboardEndDate = picked.end;
  //       _dashboardDateRangeDisplay = "${DateFormat.yMd().format(picked.start)} - ${DateFormat.yMd().format(picked.end)}";
  //     });
  //   }
  // }

  void _scrollListener() {
    if (_scrollController.position.userScrollDirection == ScrollDirection.reverse) {
      if (_isFabVisible) {
        setState(() { _isFabVisible = false; });
      }
    } else if (_scrollController.position.userScrollDirection == ScrollDirection.forward) {
      if (!_isFabVisible) {
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
    // Task 1.d: Fetch jobs from provider
    final jobProvider = context.watch<CargoJobProvider>();
    final allJobs = jobProvider.jobs; // This is List<Map<String, dynamic>>

    return Scaffold(
      appBar: AppBar(
        title: const Text('Dashboard', style: TextStyle(color: Colors.white)),
        centerTitle: true,
        backgroundColor: Theme.of(context).colorScheme.primary,
        iconTheme: const IconThemeData(color: Colors.white),
        actions: [
          Consumer<CargoJobProvider>(
            builder: (context, jobProvider, child) {
              // Use the new isNetworkOffline flag
              bool isOffline = jobProvider.isNetworkOffline;
              // Secondary information: is data from cache?
              bool dataIsFromCache = jobProvider.isDataFromCache;

              if (isOffline) {
                return IconButton(
                  icon: Icon(Icons.radio_button_checked, color: Colors.redAccent),
                  tooltip: dataIsFromCache
                             ? 'Network Offline - Displaying Cached Data'
                             : 'Network Offline - Could not load fresh data',
                  onPressed: () {
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(content: Text(dataIsFromCache
                                              ? 'Network is offline. Showing data from cache.'
                                              : 'Network is offline. Failed to load fresh data and no cache available.'))
                    );
                  },
                );
              } else {
                // Online
                return IconButton(
                  icon: Icon(Icons.radio_button_checked, color: Colors.greenAccent),
                  tooltip: 'Online Mode - Data is Live',
                  onPressed: () {
                     ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text('Network is online. Data is live.'))
                    );
                  },
                );
              }
            },
          ),
        ],
      ),
      body: SafeArea(
        child: StreamBuilder<List<Map<String, dynamic>>>(
          stream: _jobsStream,
          builder: (context, snapshot) {
            List<Map<String, dynamic>> displayJobs;
            bool fromCache = jobProvider.isDataFromCache;
            bool streamHasUsableData = snapshot.hasData && snapshot.data!.isNotEmpty;

            if (snapshot.connectionState == ConnectionState.waiting && allJobs.isEmpty && !fromCache) {
              return const Center(child: CircularProgressIndicator());
            }

            if (snapshot.hasError) {
              print('Dashboard Stream Error: ${snapshot.error}');
              // When stream has error, rely solely on provider's data (which might be cached)
              displayJobs = allJobs;
              fromCache = jobProvider.isDataFromCache; // Re-check, as provider might have updated
              if (displayJobs.isEmpty && !fromCache) {
                 // If stream errored and provider has no fresh data (and not from cache attempt)
                return Center(child: Text('Error loading jobs. Offline? Cached data: ${fromCache ? 'Available' : 'Not available'}'));
              }
            } else if (streamHasUsableData) {
              displayJobs = snapshot.data!;
              // If stream has data, assume it's fresh, so not "from cache" in terms of current display priority
              // However, provider.isDataFromCache tells us about the provider's last successful load source.
              // For the "Offline mode" banner, jobProvider.isDataFromCache is more relevant.
            } else {
              // Stream has no data or is not active, use provider's data
              displayJobs = allJobs;
            }

            if (displayJobs.isEmpty) {
              String emptyStateMessage = 'No jobs found.'; // Default if online and no jobs
              if (jobProvider.isNetworkOffline) {
                if (jobProvider.isDataFromCache) { // Tried cache, but it was empty or failed
                  emptyStateMessage = 'Network Offline - No cached data found.';
                } else { // Network offline, and didn't even rely on cache (e.g. cache disabled or first attempt failed)
                  emptyStateMessage = 'Network Offline - Could not fetch data.';
                }
                // Special empty state UI for offline
                return Center(
                  child: SingleChildScrollView(
                    padding: const EdgeInsets.all(16.0),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const Icon(Icons.wifi_off_rounded, size: 48, color: Colors.grey),
                        const SizedBox(height: 16),
                        Text(emptyStateMessage, textAlign: TextAlign.center, style: const TextStyle(color: Colors.grey)),
                      ],
                    ),
                  ),
                );
              }
              // Online but no jobs
              return Center(child: Text(emptyStateMessage));
            }

            // Update counts based on the determined displayJobs
            _totalJobsCount = displayJobs.length;
            _pendingJobsCount = displayJobs.where((job) =>  deliveryStatusFromString(job['delivery_status']?.toString()) == DeliveryStatus.Scheduled).length;
            _completedJobsCount = displayJobs.where((job) => deliveryStatusFromString(job['delivery_status']?.toString()) == DeliveryStatus.Delivered).length;
            _cancelledJobsCount = displayJobs.where((job) => deliveryStatusFromString(job['delivery_status']?.toString()) == DeliveryStatus.Cancelled).length;
            _overdueJobsCount = displayJobs.where((job) => deliveryStatusFromString(job['delivery_status']?.toString()) == DeliveryStatus.Delayed).length;

            return CustomScrollView(
              controller: _scrollController,
              slivers: [
                // Updated Banner Logic
                if (jobProvider.isNetworkOffline)
                  SliverToBoxAdapter(
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                      color: Colors.amber.withOpacity(0.3), // Amber for more warning
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(Icons.wifi_off_sharp, color: Colors.amber.shade800, size: 18),
                          const SizedBox(width: 10),
                          Text(
                            jobProvider.isDataFromCache && allJobs.isNotEmpty
                                ? "Network Offline - Showing Cached Data"
                                : "Network Offline - Attempting to Reconnect...",
                            style: TextStyle(color: Colors.amber.shade900, fontWeight: FontWeight.w500),
                          ),
                        ],
                      ),
                    ),
                  ),
                SliverToBoxAdapter(
                  child: Padding(
                    padding: const EdgeInsets.all(16.0),
                    child: Card(
                      elevation: 4,
                      child: Padding(
                        padding: const EdgeInsets.all(12.0),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Text("Revenue Overview", style: Theme.of(context).textTheme.headlineSmall?.copyWith(color: Colors.white70)),
                                   Align(
                                      alignment: Alignment.centerRight,
                                      child: TextButton(
                                        onPressed: () => Navigator.of(context).push(
                                          MaterialPageRoute(builder: (_) => JobStatsPage(
                                                initialStartDate: _dashboardStartDate,
                                                initialEndDate: _dashboardEndDate,
                                                initialPaymentStatusFilter: _dashboardPaymentStatusFilter,
                                          ))),
                                        child: const Text("View More Stats ->", style: TextStyle(fontSize: 12)),
                                      ),
                                    )
                              ],
                            ),
                            const SizedBox(height: 12),
                            GestureDetector(
                              onTap: () {
                                Navigator.push(
                                  context,
                                  MaterialPageRoute(
                                    builder: (context) => JobStatsPage(
                                      initialStartDate: _dashboardStartDate,
                                      initialEndDate: _dashboardEndDate,
                                      initialPaymentStatusFilter: _dashboardPaymentStatusFilter,
                                    ),
                                  ),
                                );
                              },
                              child: Hero(
                                tag: 'revenueTrendChartHero',
                                child: RevenueTrendChartWidget(
                                  // Use allJobs from provider for consistency in chart, as it's also cache-aware
                                  jobs: allJobs.map((jobMap) => CargoJob.fromJson(jobMap)).toList(),
                                  startDate: _dashboardStartDate,
                                  endDate: _dashboardEndDate,
                                  paymentStatusFilter: _dashboardPaymentStatusFilter,
                                ),
                              ),
                            ),
                            const SizedBox(height: 8),
                          ],
                        ),
                      ),
                    ),
                  ),
                ),
                SliverPadding(
                  padding: const EdgeInsets.fromLTRB(16,0,16,16), // Adjusted padding
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
                            _buildSummaryCard(context, 'Delivered', _completedJobsCount, Colors.green.shade700),
                            const SizedBox(width: 8),
                            _buildSummaryCard(context, 'Cancelled', _cancelledJobsCount, Colors.red.shade700),
                            const SizedBox(width: 8),
                            _buildSummaryCard(context, 'Delayed', _overdueJobsCount, Colors.purple.shade700),
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
                        final job = displayJobs[index];
                        return _buildJobCard(context, job);
                      },
                      childCount: displayJobs.length, // Use displayJobs.length here
                    ),
                  ),
                ),
              ],
            );
          },
        ),
      ),
      floatingActionButton: AnimatedSlide(
        offset: _isFabVisible ? Offset.zero : const Offset(0, 2),
        duration: const Duration(milliseconds: 300),
        child: AnimatedOpacity(
          opacity: _isFabVisible ? 1.0 : 0.0,
          duration: const Duration(milliseconds: 300),
          child: FloatingActionButton.extended(
            onPressed: () async {
              // Before navigating, try to refresh data to ensure "Add Job" screen
              // might have freshest customer list, etc.
              // This is optional, but can improve UX if coming back online.
              await Provider.of<CargoJobProvider>(context, listen: false).fetchJobsData();
              Navigator.of(context)
                  .push(MaterialPageRoute(builder: (_) => const AddJob()));
            },
            label: const Text('Add New Job'),
            icon: const Icon(Icons.add),
            backgroundColor: Theme.of(context).colorScheme.secondary,
            foregroundColor: Theme.of(context).colorScheme.onSecondary,
          ),
        ),
      ),
    );
  }

  Stream<List<Map<String, dynamic>>> _getJobsStream(SupabaseClient supabaseInstance) {
    final stream = supabaseInstance
        .from('cargo_jobs')
        .stream(primaryKey: ['id'])
        .order('created_at', ascending: false) // Order by created_at for consistency
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
      elevation: 2,
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
      case 'completed': // Kept for backward compatibility if data contains "completed"
        return Colors.green.shade700;
      case 'pending':
      case 'scheduled': // Group Scheduled with Pending/InProgress for color
        return Colors.orange.shade700;
      case 'cancelled':
      case 'refunded':
        return Colors.red.shade700;
      case 'delayed': // Added new status color
      default:
        return Theme.of(context).textTheme.bodySmall?.color ?? Colors.black;
    }
  }
}
