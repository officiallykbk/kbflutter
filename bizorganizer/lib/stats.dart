import 'package:bizorganizer/main.dart';
import 'package:bizorganizer/providers/orders_providers.dart'; 
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import 'package:syncfusion_flutter_charts/charts.dart';
import 'package:bizorganizer/models/status_constants.dart'; 
import 'package:bizorganizer/models/cargo_job.dart'; 
import 'package:bizorganizer/widgets/revenue_trend_chart_widget.dart'; 

// Helper class for generic chart data
class ChartData {
  final String x;
  final double y;
  ChartData(this.x, this.y);
}

class RevenueData { 
  final DateTime date;
  final double revenue;
  final String paymentStatus; 

  RevenueData(this.date, this.revenue, {required this.paymentStatus});

  Map<String, dynamic> toJson() {
    return {'date': date, 'revenue': revenue, 'paymentStatus': paymentStatus};
  }
}

class StatusData {
  final String status;
  final int count;
  StatusData(this.status, this.count);
}


class JobStatsPage extends StatefulWidget { 
  final DateTime? initialStartDate;
  final DateTime? initialEndDate;
  final String? initialPaymentStatusFilter;

  const JobStatsPage({
    Key? key,
    this.initialStartDate,
    this.initialEndDate,
    this.initialPaymentStatusFilter,
  }) : super(key: key);

  @override
  _JobStatsPageState createState() => _JobStatsPageState(); 
}

class _JobStatsPageState extends State<JobStatsPage> { 
  DateTimeRange? _selectedDateRange; 
  String dateRangeText = 'Select Date Range';
  late TooltipBehavior _tooltipBehaviorOtherCharts; 
  
  List<Map<String,dynamic>> paymentFilteredJobsFullDetails = []; 

  String selectedRange = 'Last 7 Days'; 
  String selectedPaymentStatusFilter = 'Paid + Pending';

  DateTime? _axisMinDate;
  DateTime? _axisMaxDate;

  final NumberFormat currencyFormatter = NumberFormat.currency(locale: 'en_US', symbol: '\$');

  @override
  void initState() {
    super.initState();
    _tooltipBehaviorOtherCharts = TooltipBehavior(enable: true, header: '', format: 'point.x : point.y');

    if (widget.initialStartDate != null && widget.initialEndDate != null) {
      _selectedDateRange = DateTimeRange(start: widget.initialStartDate!, end: widget.initialEndDate!);
      selectedRange = 'Custom'; 
      dateRangeText = '${DateFormat('dd/MM/yyyy').format(widget.initialStartDate!)} - ${DateFormat('dd/MM/yyyy').format(widget.initialEndDate!)}';
    } else {
      // Default date range initialization logic
      final now = DateTime.now();
      _selectedDateRange = null; // Explicitly null for predefined ranges initially
      selectedRange = 'Last 7 Days'; // Default predefined range
      dateRangeText = 'Last 7 Days'; // Default display text
    }

    if (widget.initialPaymentStatusFilter != null) {
      selectedPaymentStatusFilter = widget.initialPaymentStatusFilter!;
    }
    
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) {
        _processAndFilterDataForPage(); 
      }
    });
  }

  List<Map<String, dynamic>> _getRawJobsBasedOnPaymentFilter() { 
    if (!mounted) return [];
    final jobProvider = Provider.of<CargoJobProvider>(context, listen: false); 
    final allProviderJobs = jobProvider.jobs; 

    switch (selectedPaymentStatusFilter) {
      case 'Paid Only':
        return allProviderJobs.where((job) => job['payment_status']?.toString().toLowerCase() == paymentStatusToString(PaymentStatus.Paid).toLowerCase()).toList(); 
      case 'Pending Only':
        return allProviderJobs.where((job) => job['payment_status']?.toString().toLowerCase() == paymentStatusToString(PaymentStatus.Pending).toLowerCase()).toList(); 
      case 'Paid + Pending':
        return allProviderJobs.where((job) {
          final status = job['payment_status']?.toString().toLowerCase(); 
          return status == paymentStatusToString(PaymentStatus.Paid).toLowerCase() || status == paymentStatusToString(PaymentStatus.Pending).toLowerCase();
        }).toList();
      default:
        return [];
    }
  }

  void _processAndFilterDataForPage() {
    if (!mounted) return;
    paymentFilteredJobsFullDetails = _getRawJobsBasedOnPaymentFilter(); 
    _updateAxisDates(); 
    setState(() {
    });
  }

  void _updateAxisDates() {
    DateTime now = DateTime.now();
    DateTime calculatedStartDate;
    DateTime calculatedEndDate = now;

    if (_selectedDateRange != null) { 
      calculatedStartDate = _selectedDateRange!.start;
      calculatedEndDate = _selectedDateRange!.end;
    } else { 
      switch (selectedRange) {
        case 'Last 7 Days':
          calculatedStartDate = now.subtract(const Duration(days: 6));
          break;
        case 'Last Month':
          calculatedStartDate = DateTime(now.year, now.month - 1, 1);
          calculatedEndDate = DateTime(now.year, now.month, 0); 
          break;
        case 'Last 6 Months':
          calculatedStartDate = DateTime(now.year, now.month - 6, 1);
          break;
        // 'Custom' is handled by _selectedDateRange being non-null
        default: // Default to Last 7 Days
          calculatedStartDate = now.subtract(const Duration(days: 6));
      }
    }
    
    _axisMinDate = DateTime(calculatedStartDate.year, calculatedStartDate.month, calculatedStartDate.day);
    _axisMaxDate = DateTime(calculatedEndDate.year, calculatedEndDate.month, calculatedEndDate.day, 23, 59, 59, 999);
  }


  void _handleCustomDateRangeSelected(DateTime startDate, DateTime endDate) {
    if (!mounted) return;
    setState(() {
      _selectedDateRange = DateTimeRange(start: startDate, end: endDate);
      dateRangeText = '${DateFormat('dd/MM/yyyy').format(startDate)} - ${DateFormat('dd/MM/yyyy').format(endDate)}';
      selectedRange = 'Custom'; 
      _processAndFilterDataForPage(); 
    });
  }

  List<Map<String,dynamic>> _getJobsInCurrentDateRange() {
      if (_axisMinDate == null || _axisMaxDate == null) return [];
      return paymentFilteredJobsFullDetails.where((job){
        final createdAtString = job['created_at'] as String?;
        if (createdAtString == null) return false;
        try {
            final jobDate = DateTime.parse(createdAtString);
            return !jobDate.isBefore(_axisMinDate!) && !jobDate.isAfter(_axisMaxDate!);
        } catch (e) { return false; }
    }).toList();
  }

  double _calculateTotalRevenueForCurrentRange() {
    final jobsInDateRange = _getJobsInCurrentDateRange();
    return jobsInDateRange.fold(0.0, (sum, job) => sum + ((job['agreed_price'] as num?)?.toDouble() ?? 0.0));
  }

  double _calculateAverageRevenuePerJobForCurrentRange() { 
    final jobsInDateRange = _getJobsInCurrentDateRange();
    if (jobsInDateRange.isEmpty) return 0.0;
    return _calculateTotalRevenueForCurrentRange() / jobsInDateRange.length;
  }

  Map<String, double> _calculatePaidVsPendingRevenueForCurrentRange() {
    double paid = 0;
    double pending = 0;
    final jobsInDateRange = _getJobsInCurrentDateRange();

    for (var job in jobsInDateRange) { 
        final paymentStatus = job['payment_status']?.toString().toLowerCase() ?? 'unknown'; 
        final amount = (job['agreed_price'] as num? ?? 0.0).toDouble(); 
        if (paymentStatus == paymentStatusToString(PaymentStatus.Paid).toLowerCase()) {
            paid += amount;
        } else if (paymentStatus == paymentStatusToString(PaymentStatus.Pending).toLowerCase()) {
            pending += amount;
        }
    }
    return {'paid': paid, 'pending': pending};
}


  List<ChartData> _getRevenueByDeliveryStatusData() { 
    if (!mounted) return [];
    Map<String, double> revenueByStatus = {};
    final dateFilteredJobsForChart = _getJobsInCurrentDateRange();

    for (var job in dateFilteredJobsForChart) { 
      String statusStr = job['delivery_status']?.toString().toLowerCase() ?? deliveryStatusToString(DeliveryStatus.Scheduled).toLowerCase();
      DeliveryStatus? statusEnum = deliveryStatusFromString(statusStr);

      String chartCategory = statusStr; 
      if (statusEnum != null) { 
          chartCategory = deliveryStatusToString(statusEnum);
      }
      
      double amount = (job['agreed_price'] as num? ?? 0.0).toDouble(); 
      revenueByStatus[chartCategory] = (revenueByStatus[chartCategory] ?? 0) + amount;
    }
    
    return revenueByStatus.entries.map((entry) => ChartData(entry.key.toUpperCase(), entry.value)).toList();
  }

  List<ChartData> _getRevenueByTop5DropoffLocationData() { 
    if (!mounted) return [];
    Map<String, double> revenueByDestination = {};
    final dateFilteredJobsForChart = _getJobsInCurrentDateRange();

    for (var job in dateFilteredJobsForChart) { 
      String destination = job['dropoff_location']?.toString() ?? 'Unknown'; 
      if (destination.isEmpty) destination = 'N/A';
      double amount = (job['agreed_price'] as num? ?? 0.0).toDouble(); 
      revenueByDestination[destination] = (revenueByDestination[destination] ?? 0) + amount;
    }

    List<ChartData> chartData = revenueByDestination.entries
        .map((entry) => ChartData(entry.key, entry.value))
        .toList();
    chartData.sort((a, b) => b.y.compareTo(a.y));
    return chartData.take(5).toList();
  }

  List<StatusData> _getJobStatusDistributionData() { 
    if (!mounted) return [];
    final jobProvider = context.watch<CargoJobProvider>(); 
    
    int deliveredCount = 0;
    int scheduledAndInProgressCount = 0;
    int cancelledCount = 0;
    int delayedCount = 0;

    for (var jobMap in jobProvider.jobs) { 
      final cargoJob = CargoJob.fromJson(jobMap); 
      String? effectiveStatus = cargoJob.effectiveDeliveryStatus;

      if (effectiveStatus == deliveryStatusToString(DeliveryStatus.Delivered)) {
        deliveredCount++;
      } else if (effectiveStatus == deliveryStatusToString(DeliveryStatus.Cancelled)) {
        cancelledCount++;
      } else if (effectiveStatus == deliveryStatusToString(DeliveryStatus.Delayed)) {
        delayedCount++;
      } else if (effectiveStatus == deliveryStatusToString(DeliveryStatus.Scheduled) ||
                 effectiveStatus == deliveryStatusToString(DeliveryStatus.InProgress)) {
        scheduledAndInProgressCount++;
      }
    }

    return [
      StatusData(deliveryStatusToString(DeliveryStatus.Delivered).toUpperCase(), deliveredCount),
      StatusData("${deliveryStatusToString(DeliveryStatus.Scheduled)}/\n${deliveryStatusToString(DeliveryStatus.InProgress)}", scheduledAndInProgressCount), 
      StatusData(deliveryStatusToString(DeliveryStatus.Cancelled).toUpperCase(), cancelledCount),
      StatusData(deliveryStatusToString(DeliveryStatus.Delayed).toUpperCase(), delayedCount),
    ];
  }

  @override
  Widget build(BuildContext context) {
    double totalRevenue = _calculateTotalRevenueForCurrentRange();
    double avgRevenuePerJob = _calculateAverageRevenuePerJobForCurrentRange(); 
    Map<String, double> paidVsPending = selectedPaymentStatusFilter == 'Paid + Pending' 
                                      ? _calculatePaidVsPendingRevenueForCurrentRange() 
                                      : {};
    
    final jobProvider = Provider.of<CargoJobProvider>(context, listen: false); 

    return Scaffold(
      appBar: AppBar(
        title: Text('Job Statistics', style: TextStyle(color: Theme.of(context).colorScheme.onPrimary)), 
        backgroundColor: Theme.of(context).colorScheme.primary,
        iconTheme: IconThemeData(color: Theme.of(context).colorScheme.onPrimary), 
      ),
      body: Padding(
        padding: const EdgeInsets.all(8.0),
        child: Column(
          children: [
            Card(
              elevation: 4,
              child: Padding(
                padding: const EdgeInsets.all(12.0),
                child: Column(
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceAround,
                      children: [
                        _buildKpi("Total Revenue", currencyFormatter.format(totalRevenue)),
                        _buildKpi("Avg. Revenue/Job", currencyFormatter.format(avgRevenuePerJob)), 
                      ],
                    ),
                    if (selectedPaymentStatusFilter == 'Paid + Pending' && paidVsPending.isNotEmpty) ...[
                      SizedBox(height: 10),
                      _buildPaidVsPendingSubKpi(paidVsPending['paid']!, paidVsPending['pending']!),
                    ]
                  ],
                ),
              ),
            ),
            SizedBox(height: 10),

            Card(
              elevation: 4,
              child: Padding(
                padding: const EdgeInsets.all(8.0),
                child: Column(
                  children: [
                    Row(
                      children: [
                        Expanded(
                          child: GestureDetector(
                            onTap: _pickDateRange,
                            child: Container(
                              padding: EdgeInsets.symmetric(horizontal: 12, vertical: 15),
                              decoration: BoxDecoration(
                                color: Colors.grey[200],
                                borderRadius: BorderRadius.circular(8),
                              ),
                              child: Row(
                                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                children: [
                                  Flexible(child: Text(dateRangeText, style: TextStyle(fontSize: 14, color: Colors.black))),
                                  Icon(Icons.calendar_today, size: 20),
                                ],
                              ),
                            ),
                          ),
                        ),
                        SizedBox(width: 8),
                        Expanded(
                          child: DropdownButtonFormField<String>(
                            decoration: InputDecoration(
                              border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
                              contentPadding: EdgeInsets.symmetric(horizontal: 10, vertical: 0),
                              fillColor: Colors.grey[200],
                              filled: true,
                            ),
                            value: selectedRange,
                            items: ['Last 7 Days', 'Last Month', 'Last 6 Months', 'Custom']
                                .map((range) => DropdownMenuItem(
                                      value: range,
                                      child: Text(range, style: TextStyle(fontSize: 14)),
                                    ))
                                .toList(),
                            onChanged: (value) {
                              if (!mounted) return;
                              setState(() {
                                selectedRange = value!;
                                if (value != 'Custom') {
                                  _selectedDateRange = null; 
                                  dateRangeText = 'Select Date Range'; 
                                }
                                if (value != 'Custom') _processAndFilterDataForPage();
                              });
                            },
                          ),
                        ),
                      ],
                    ),
                    SizedBox(height: 8),
                    DropdownButtonFormField<String>(
                      decoration: InputDecoration(
                        labelText: "Filter by Payment Status",
                        border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
                        contentPadding: EdgeInsets.symmetric(horizontal: 10, vertical: 10),
                        fillColor: Colors.grey[200],
                        filled: true,
                      ),
                      value: selectedPaymentStatusFilter,
                      items: ['Paid Only', 'Pending Only', 'Paid + Pending']
                          .map((status) => DropdownMenuItem(
                                value: status,
                                child: Text(status),
                              ))
                          .toList(),
                      onChanged: (value) {
                        if (!mounted) return;
                        setState(() {
                          selectedPaymentStatusFilter = value!;
                          _processAndFilterDataForPage();
                        });
                      },
                    ),
                  ],
                ),
              ),
            ),
            SizedBox(height: 10),

            _buildJobProgressOverview(), 
            SizedBox(height: 10),

            Expanded(
              child: ListView(
                children: [
                  _buildSectionTitle('Revenue Trend'),
                  // Task 1: Wrap RevenueTrendChartWidget with Hero
                  Hero(
                    tag: 'revenueTrendChartHero',
                    child: (_axisMinDate != null && _axisMaxDate != null) 
                      ? RevenueTrendChartWidget(
                          // Task 2: Pass all jobs from provider, widget filters payment status internally
                          jobs: jobProvider.jobs.map((jobMap) => CargoJob.fromJson(jobMap)).toList(),
                          startDate: _axisMinDate!,
                          endDate: _axisMaxDate!,
                          paymentStatusFilter: selectedPaymentStatusFilter, 
                        )
                      : Container(height: 300, child: Center(child: Text('Select date range to view trend.'))),
                  ),
                  
                  SizedBox(height: 16),
                  _buildSectionTitle('Job Status Distribution (Overall Counts)'), 
                  SizedBox(
                    height: 250,
                    child: SfCircularChart(
                      legend: Legend(isVisible: true, position: LegendPosition.bottom),
                      series: <CircularSeries>[
                        PieSeries<StatusData, String>(
                          dataSource: _getJobStatusDistributionData(), 
                          xValueMapper: (StatusData data, _) => data.status,
                          yValueMapper: (StatusData data, _) => data.count,
                          dataLabelSettings: DataLabelSettings(isVisible: true, labelPosition: ChartDataLabelPosition.outside),
                          enableTooltip: true,
                        )
                      ],
                    ),
                  ),
                  SizedBox(height: 16),
                  _buildSectionTitle('Revenue by Delivery Status (Filtered)'), 
                  _buildRevenueByDeliveryStatusChart(), 
                  SizedBox(height: 16),
                  _buildSectionTitle('Top 5 Revenue by Dropoff Location (Filtered)'), 
                  _buildRevenueByTop5DropoffLocationChart(), 
                  SizedBox(height: 16),
                ],
              ),
            ),
            ElevatedButton.icon(
              onPressed: _exportData,
              icon: Icon(Icons.download),
              label: Text('Export Data'),
              style: ElevatedButton.styleFrom(
                backgroundColor: Theme.of(context).colorScheme.secondary,
                foregroundColor: Theme.of(context).colorScheme.onSecondary,
                padding: EdgeInsets.symmetric(horizontal: 30, vertical: 15),
                textStyle: TextStyle(fontSize: 16),
              ),
            ),
            SizedBox(height: 10),
          ],
        ),
      ),
    );
  }

  Widget _buildKpi(String title, String value) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Text(title, style: TextStyle(fontSize: 14, color: Colors.grey[700]), textAlign: TextAlign.center),
        SizedBox(height: 4),
        Text(value, style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Theme.of(context).colorScheme.primary), textAlign: TextAlign.center),
      ],
    );
  }

  Widget _buildPaidVsPendingSubKpi(double paidRevenue, double pendingRevenue) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceAround,
      children: [
        Text("Paid: ${currencyFormatter.format(paidRevenue)}", style: TextStyle(color: Colors.green, fontSize: 14, fontWeight: FontWeight.bold)),
        Text("Pending: ${currencyFormatter.format(pendingRevenue)}", style: TextStyle(color: Colors.orange, fontSize: 14, fontWeight: FontWeight.bold)),
      ],
    );
  }

  Widget _buildSectionTitle(String title) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8.0),
      child: Text(title, style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Theme.of(context).colorScheme.secondary)),
    );
  }

  Widget _statusCard(String title, Color color, int count) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Text(title, style: TextStyle(color: color, fontSize: 12, fontWeight: FontWeight.bold)),
        SizedBox(height: 4),
        Text('$count jobs', style: TextStyle(fontSize: 16, fontWeight:FontWeight.bold, color: Theme.of(context).textTheme.bodyLarge?.color ?? Colors.black)), 
      ],
    );
  }
  
  Widget _buildJobProgressOverview() { 
    if (!mounted) return SizedBox.shrink();
    final jobProvider = context.watch<CargoJobProvider>(); 
    return Card(
      elevation: 2,
      child: Padding(
        padding: const EdgeInsets.all(12.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text("Job Status Overview (Overall)", style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Theme.of(context).colorScheme.tertiary)), 
            SizedBox(height: 12),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              children: [
                _statusCard(deliveryStatusToString(DeliveryStatus.Delivered).toUpperCase(), Colors.green, jobProvider.completedJobs.length), 
                _statusCard(deliveryStatusToString(DeliveryStatus.Scheduled).toUpperCase(), Colors.blue.shade300, jobProvider.jobs.where((j) => deliveryStatusFromString(j['delivery_status']?.toString()) == DeliveryStatus.Scheduled).length),
                _statusCard(deliveryStatusToString(DeliveryStatus.InProgress).toUpperCase(), Colors.orange.shade700, jobProvider.jobs.where((j) => deliveryStatusFromString(j['delivery_status']?.toString()) == DeliveryStatus.InProgress).length),
                _statusCard(deliveryStatusToString(DeliveryStatus.Cancelled).toUpperCase(), Colors.red.shade700, jobProvider.cancelledJobs.length),
                _statusCard(deliveryStatusToString(DeliveryStatus.Delayed).toUpperCase(), Colors.purple.shade700, jobProvider.delayedJobs.length), 
              ],
            ),
          ],
        ),
      ),
    );
  }
  
  Widget _buildRevenueByDeliveryStatusChart() { 
    if (!mounted) return SizedBox.shrink();
    List<ChartData> chartData = _getRevenueByDeliveryStatusData(); 
    if (chartData.isEmpty) return Center(child: Padding(padding: const EdgeInsets.all(8.0), child: Text("No revenue data for current filter.")));

    return SizedBox(
      height: 300,
      child: SfCartesianChart(
        primaryXAxis: CategoryAxis(majorGridLines: MajorGridLines(width: 0), labelStyle: TextStyle(fontSize: 10)),
        primaryYAxis: NumericAxis(labelFormat: '\${value}', majorTickLines: MajorTickLines(size:0)),
        series: <CartesianSeries>[
          ColumnSeries<ChartData, String>(
            dataSource: chartData,
            xValueMapper: (ChartData data, _) => data.x,
            yValueMapper: (ChartData data, _) => data.y,
            name: 'Revenue',
            dataLabelSettings: DataLabelSettings(isVisible: true, labelAlignment: ChartDataLabelAlignment.top),
            color: Theme.of(context).colorScheme.tertiary,
          )
        ],
         tooltipBehavior: _tooltipBehaviorOtherCharts, 
      ),
    );
  }

  Widget _buildRevenueByTop5DropoffLocationChart() { 
     if (!mounted) return SizedBox.shrink();
    List<ChartData> top5Data = _getRevenueByTop5DropoffLocationData(); 
     if (top5Data.isEmpty) return Center(child: Padding(padding: const EdgeInsets.all(8.0), child: Text("No revenue data for current filter.")));

    return SizedBox(
      height: 300,
      child: SfCartesianChart(
        primaryXAxis: CategoryAxis(labelRotation: -45, majorGridLines: MajorGridLines(width: 0), labelStyle: TextStyle(fontSize: 10)),
        primaryYAxis: NumericAxis(labelFormat: '\${value}', majorTickLines: MajorTickLines(size:0)),
        series: <CartesianSeries>[
          BarSeries<ChartData, String>( 
            dataSource: top5Data,
            xValueMapper: (ChartData data, _) => data.x,
            yValueMapper: (ChartData data, _) => data.y,
            name: 'Revenue',
            dataLabelSettings: DataLabelSettings(isVisible: true),
            color: Theme.of(context).colorScheme.secondary,
          )
        ],
        tooltipBehavior: _tooltipBehaviorOtherCharts, 
      ),
    );
  }

  void _pickDateRange() async {
    if (!mounted) return;
    final DateTimeRange? picked = await showDateRangePicker( 
      context: context,
      initialDateRange: _selectedDateRange, 
      firstDate: DateTime(2020),
      lastDate: DateTime.now().add(Duration(days: 365)),
    );
    if (picked != null) {
      _handleCustomDateRangeSelected(picked.start, picked.end);
    }
  }

  void _exportData() {
    if (!mounted) return;
    print("Exporting data for date range: $dateRangeText, payment status: $selectedPaymentStatusFilter");
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('Export functionality not yet implemented.')),
    );
  }
}
