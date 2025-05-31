import 'package:bizorganizer/main.dart';
import 'package:bizorganizer/providers/loading_provider.dart';
import 'package:bizorganizer/stats.dart';
import 'package:flutter/rendering.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:bizorganizer/addjob.dart';
import 'package:bizorganizer/jobdetails.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import 'package:bizorganizer/providers/orders_providers.dart';
import 'package:bizorganizer/models/cargo_job.dart';
import 'package:bizorganizer/widgets/revenue_trend_chart_widget.dart';
import 'package:bizorganizer/models/status_constants.dart';
import 'package:hive/hive.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:bizorganizer/models/offline_change.dart';
import 'package:flutter/foundation.dart';

class Dashboard extends StatefulWidget {
  const Dashboard({super.key});

  @override
  State<Dashboard> createState() => _DashboardState();
}

class _DashboardState extends State<Dashboard> {
  final ScrollController _scrollController = ScrollController();
  bool _isFabVisible = true;
  late ValueListenable<Box<OfflineChange>> _offlineChangesListenable;

  int _totalJobsCount = 0;
  int _pendingJobsCount = 0;
  int _completedJobsCount = 0;
  int _cancelledJobsCount = 0;
  int _overdueJobsCount = 0;

  late final Stream<List<Map<String, dynamic>>> _jobsStream;

  DateTime _dashboardStartDate =
      DateTime.now().subtract(const Duration(days: 29));
  DateTime _dashboardEndDate = DateTime.now();
  String _dashboardPaymentStatusFilter = "Paid + Pending";

  @override
  void initState() {
    super.initState();
    _scrollController.addListener(_scrollListener);
    _jobsStream = _getJobsStream(supabase);

    // Initialize the offline changes box and make it listenable
    final box = Hive.box<OfflineChange>('offlineChangesBox');
    _offlineChangesListenable = box.listenable();

    // Ensure data is fetched when the dashboard is initialized
    WidgetsBinding.instance.addPostFrameCallback((_) {
      Provider.of<CargoJobProvider>(context, listen: false).fetchJobsData();
    });
  }

  void _scrollListener() {
    if (_scrollController.position.userScrollDirection ==
        ScrollDirection.reverse) {
      if (_isFabVisible) {
        setState(() {
          _isFabVisible = false;
        });
      }
    } else if (_scrollController.position.userScrollDirection ==
        ScrollDirection.forward) {
      if (!_isFabVisible) {
        setState(() {
          _isFabVisible = true;
        });
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
    final jobProvider = context.watch<CargoJobProvider>();
    final allJobs = jobProvider.jobs;
    final bool fromCache = jobProvider
        .isDataFromCache; // Though fromCache itself isn't directly used in this version of build logic, it's good to be aware of
    final bool isLoading = jobProvider.isLoadingJobs;
    final String? fetchError = jobProvider.fetchError;
    final bool isSyncing = jobProvider.isSyncing;
    final bool isNetworkOffline = jobProvider.isNetworkOffline;

    print(
        'Dashboard build: isLoadingJobs: $isLoading, isSyncing: $isSyncing, isNetworkOffline: $isNetworkOffline, fetchError: $fetchError, displayJobs count: ${allJobs.length}, fromCache: $fromCache');

    return Scaffold(
      appBar: AppBar(
        title: const Text('Dashboard', style: TextStyle(color: Colors.white)),
        centerTitle: true,
        backgroundColor: Theme.of(context).colorScheme.primary,
        iconTheme: const IconThemeData(color: Colors.white),
        actions: [
          // Pending Changes Indicator
          ValueListenableBuilder<Box<OfflineChange>>(
            valueListenable: _offlineChangesListenable,
            builder: (context, box, _) {
              if (box.isNotEmpty) {
                return Padding(
                    padding: const EdgeInsets.only(right: 8.0),
                    child: Tooltip(
                      message: '${box.length} pending changes to sync',
                      child: Badge(
                        label: Text(box.length.toString()),
                        child: const Icon(Icons.sync_problem_outlined,
                            color: Colors.orangeAccent),
                      ),
                    ));
              }
              return const SizedBox.shrink();
            },
          ),
          // Online/Offline Indicator
          Consumer<CargoJobProvider>(
            builder: (context, jobProvider, child) {
              if (jobProvider.isNetworkOffline) {
                return Tooltip(
                  message: 'Network Offline',
                  child: Padding(
                    padding:
                        const EdgeInsets.only(right: 12.0), // Adjusted padding
                    child: Icon(Icons.cloud_off, color: Colors.red[300]),
                  ),
                );
              }
              return Tooltip(
                message: 'Network Online',
                child: Padding(
                  padding:
                      const EdgeInsets.only(right: 12.0), // Adjusted padding
                  child: Icon(Icons.cloud_queue, color: Colors.green[300]),
                ),
              );
            },
          ),
        ],
      ),
      body: SafeArea(
        child: Builder(
          // Use Builder or Consumer to ensure context is correct for provider
          builder: (context) {
            // Handle Loading State
            if (isLoading && allJobs.isEmpty && !fromCache) {
              return const Center(
                  child: GlobalLoadingIndicator(loadState: true));
            }

            // Handle Error State
            if (fetchError != null && allJobs.isEmpty && !fromCache) {
              // Only show full error if no data at all
              return Center(
                child: Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(Icons.error_outline, color: Colors.red, size: 48),
                      SizedBox(height: 16),
                      Text(
                        'Error loading jobs: $fetchError',
                        textAlign: TextAlign.center,
                        style: TextStyle(color: Colors.red),
                      ),
                      SizedBox(height: 16),
                      ElevatedButton(
                        onPressed: () => jobProvider.fetchJobsData(),
                        child: Text('Retry'),
                      )
                    ],
                  ),
                ),
              );
            }

            // Handle Empty State (after loading and error checks)
            if (!isLoading && allJobs.isEmpty) {
              String emptyStateMessage =
                  'No jobs found. Add a new job to get started!';
              if (jobProvider.isNetworkOffline) {
                emptyStateMessage = fromCache
                    ? 'Network Offline - No cached jobs found.'
                    : 'Network Offline - Could not fetch data.';
                return Center(
                  child: SingleChildScrollView(
                    padding: const EdgeInsets.all(16.0),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const Icon(Icons.wifi_off_rounded,
                            size: 48, color: Colors.grey),
                        const SizedBox(height: 16),
                        Text(emptyStateMessage,
                            textAlign: TextAlign.center,
                            style: const TextStyle(color: Colors.grey)),
                      ],
                    ),
                  ),
                );
              }
              return Center(
                  child: Text(
                emptyStateMessage,
                textAlign: TextAlign.center,
              ));
            }

            // Data available, update counts (already using displayJobs from provider)
            _totalJobsCount = allJobs.length;
            _pendingJobsCount = allJobs
                .where((job) =>
                    deliveryStatusFromString(
                        job['delivery_status']?.toString()) ==
                    DeliveryStatus.Scheduled)
                .length;
            _completedJobsCount = allJobs
                .where((job) =>
                    deliveryStatusFromString(
                        job['delivery_status']?.toString()) ==
                    DeliveryStatus.Delivered)
                .length;
            _cancelledJobsCount = allJobs
                .where((job) =>
                    deliveryStatusFromString(
                        job['delivery_status']?.toString()) ==
                    DeliveryStatus.Cancelled)
                .length;
            _overdueJobsCount = allJobs
                .where((job) =>
                    deliveryStatusFromString(
                        job['delivery_status']?.toString()) ==
                    DeliveryStatus.Delayed)
                .length;

            return CustomScrollView(
              controller: _scrollController,
              slivers: [
                // Sync Progress Indicator
                Consumer<CargoJobProvider>(
                    builder: (context, jobProvider, child) {
                  if (jobProvider.isSyncing) {
                    return SliverToBoxAdapter(
                      child: LinearProgressIndicator(
                        backgroundColor: Colors.amber.withOpacity(0.3),
                        valueColor: AlwaysStoppedAnimation<Color>(Colors.amber),
                        minHeight: 5, // Make it a bit more prominent
                      ),
                    );
                  }
                  return SliverToBoxAdapter(child: SizedBox.shrink());
                }),
                // Enhanced Offline Banner Logic
                Consumer<CargoJobProvider>(
                    builder: (context, jobProvider, child) {
                  if (jobProvider.isNetworkOffline) {
                    return SliverToBoxAdapter(
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 16, vertical: 8),
                        color: Colors.amber.withOpacity(0.9),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(Icons.wifi_off,
                                color: Colors.black87, size: 18),
                            SizedBox(width: 10),
                            Text(
                              "Offline: Displaying cached data. Changes will sync when online.",
                              style: TextStyle(
                                  color: Colors.black87,
                                  fontWeight: FontWeight.w500),
                              textAlign: TextAlign.center,
                            ),
                          ],
                        ),
                      ),
                    );
                  }
                  return SliverToBoxAdapter(child: SizedBox.shrink());
                }),
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
                                Text("Revenue Overview",
                                    style: Theme.of(context)
                                        .textTheme
                                        .headlineSmall
                                        ?.copyWith(color: Colors.white70)),
                                Align(
                                  alignment: Alignment.centerRight,
                                  child: TextButton(
                                    onPressed: () => Navigator.of(context)
                                        .push(MaterialPageRoute(
                                            builder: (_) => JobStatsPage(
                                                  initialStartDate:
                                                      _dashboardStartDate,
                                                  initialEndDate:
                                                      _dashboardEndDate,
                                                  initialPaymentStatusFilter:
                                                      _dashboardPaymentStatusFilter,
                                                ))),
                                    child: const Text("View More Stats ->",
                                        style: TextStyle(fontSize: 12)),
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
                                      initialPaymentStatusFilter:
                                          _dashboardPaymentStatusFilter,
                                    ),
                                  ),
                                );
                              },
                              child: Hero(
                                tag: 'revenueTrendChartHero',
                                child: RevenueTrendChartWidget(
                                  // Use displayJobs (which is jobProvider.jobs) for the chart
                                  jobs: allJobs
                                      .map(
                                          (jobMap) => CargoJob.fromJson(jobMap))
                                      .toList(),
                                  startDate: _dashboardStartDate,
                                  endDate: _dashboardEndDate,
                                  paymentStatusFilter:
                                      _dashboardPaymentStatusFilter,
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
                  padding: const EdgeInsets.fromLTRB(
                      16, 0, 16, 16), // Adjusted padding
                  sliver: SliverList(
                    delegate: SliverChildListDelegate([
                      SingleChildScrollView(
                        scrollDirection: Axis.horizontal,
                        child: Row(
                          children: [
                            _buildSummaryCard(context, 'Total Jobs',
                                _totalJobsCount, Colors.blue.shade700),
                            const SizedBox(width: 8),
                            _buildSummaryCard(context, 'Pending',
                                _pendingJobsCount, Colors.orange.shade700),
                            const SizedBox(width: 8),
                            _buildSummaryCard(context, 'Delivered',
                                _completedJobsCount, Colors.green.shade700),
                            const SizedBox(width: 8),
                            _buildSummaryCard(context, 'Cancelled',
                                _cancelledJobsCount, Colors.red.shade700),
                            const SizedBox(width: 8),
                            _buildSummaryCard(context, 'Delayed',
                                _overdueJobsCount, Colors.purple.shade700),
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
                        final job = allJobs[index];
                        return _buildJobCard(context, job);
                      },
                      childCount: allJobs.length, // Use displayJobs.length here
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
              await Provider.of<CargoJobProvider>(context, listen: false)
                  .fetchJobsData();
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

  Stream<List<Map<String, dynamic>>> _getJobsStream(
      SupabaseClient supabaseInstance) {
    final stream = supabaseInstance
        .from('cargo_jobs')
        .stream(primaryKey: ['id'])
        .order('created_at', ascending: false)
        .map((rows) => rows.map((row) => row as Map<String, dynamic>).toList());
    return stream;
  }

  Widget _buildSummaryCard(
      BuildContext context, String title, int count, Color color) {
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
            Text(
              title,
              style: Theme.of(context)
                  .textTheme
                  .titleMedium
                  ?.copyWith(color: color, fontWeight: FontWeight.bold),
              textAlign: TextAlign.center,
            ),
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
            Text(
                "Date: ${_formatJobDate(job['pickup_date'] ?? job['created_at'])}"),
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
              style: const TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 16,
                  color: Colors.green),
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
