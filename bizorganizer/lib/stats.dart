import 'package:bizorganizer/main.dart';
import 'package:bizorganizer/providers/orders_providers.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import 'package:syncfusion_flutter_charts/charts.dart';

// Helper class for generic chart data
class ChartData {
  final String x;
  final double y;
  ChartData(this.x, this.y);
}

class RevenueData {
  final DateTime date;
  final double revenue;
  final String paymentStatus; // Added to help with sub-KPI filtering

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


class TripStatsPage extends StatefulWidget {
  @override
  _TripStatsPageState createState() => _TripStatsPageState();
}

class _TripStatsPageState extends State<TripStatsPage> {
  DateTimeRange? selectedDateRange;
  String dateRangeText = 'Select Date Range';
  late TooltipBehavior _tooltipBehavior;
  
  List<RevenueData> filteredRevenueData = []; // For Revenue Trend Chart (after all filters)
  List<Map<String,dynamic>> paymentFilteredTripsFullDetails = []; // Trips after payment filter, before date filter (used for chart aggregations)

  String selectedRange = 'Last 7 Days'; // For predefined date ranges
  String selectedPaymentStatusFilter = 'Paid + Pending';

  final NumberFormat currencyFormatter = NumberFormat.currency(locale: 'en_US', symbol: '\$');

  @override
  void initState() {
    super.initState();
    _tooltipBehavior = TooltipBehavior(enable: true, header: '', format: 'point.x : point.y');
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) {
        _processAndFilterData();
      }
    });
  }

  List<Map<String, dynamic>> _getRawTripsBasedOnPaymentFilter() {
    if (!mounted) return [];
    final tripsProvider = Provider.of<TripsProvider>(context, listen: false);
    final allProviderTrips = tripsProvider.trips;

    switch (selectedPaymentStatusFilter) {
      case 'Paid Only':
        return allProviderTrips.where((trip) => trip['paymentStatus']?.toString().toLowerCase() == 'paid').toList();
      case 'Pending Only':
        return allProviderTrips.where((trip) => trip['paymentStatus']?.toString().toLowerCase() == 'pending').toList();
      case 'Paid + Pending':
        return allProviderTrips.where((trip) {
          final status = trip['paymentStatus']?.toString().toLowerCase();
          return status == 'paid' || status == 'pending';
        }).toList();
      default:
        return [];
    }
  }

  void _processAndFilterData() {
    if (!mounted) return;

    paymentFilteredTripsFullDetails = _getRawTripsBasedOnPaymentFilter();
    
    List<RevenueData> revenueDataFromPaymentFilteredTrips = paymentFilteredTripsFullDetails.map((trip) {
      final createdAtString = trip['created_at'];
      final amount = trip['amount'];
      final paymentStatus = trip['paymentStatus']?.toString().toLowerCase() ?? 'unknown';
      if (createdAtString is String && amount is num) {
        try {
          return RevenueData(DateTime.parse(createdAtString), amount.toDouble(), paymentStatus: paymentStatus);
        } catch (e) {
          print("Error parsing date for trip ${trip['id']}: $e");
          return null;
        }
      }
      return null;
    }).whereType<RevenueData>().toList();

    _applyDateFilterToRevenueData(revenueDataFromPaymentFilteredTrips);
  }

  void _applyDateFilterToRevenueData(List<RevenueData> sourceRevenueData) {
    if (!mounted) return;

    DateTime now = DateTime.now();
    DateTime startDate;
    DateTime endDate = now;

    if (selectedDateRange != null) {
      startDate = selectedDateRange!.start;
      endDate = selectedDateRange!.end;
    } else {
      switch (selectedRange) {
        case 'Last 7 Days':
          startDate = now.subtract(const Duration(days: 6));
          break;
        case 'Last Month':
          startDate = DateTime(now.year, now.month - 1, 1);
          endDate = DateTime(now.year, now.month, 0);
          break;
        case 'Last 6 Months':
          startDate = DateTime(now.year, now.month - 6, 1);
          endDate = now;
          break;
        case 'Custom': 
          if (selectedDateRange == null) { // Should not happen if UI logic is correct
            startDate = now.subtract(const Duration(days: 6)); 
            print("Warning: Custom date range selected but no date range picked. Defaulting to Last 7 Days.");
          } else {
             startDate = selectedDateRange!.start;
             endDate = selectedDateRange!.end;
          }
          break;
        default:
          startDate = now.subtract(const Duration(days: 6));
      }
    }

    setState(() {
      filteredRevenueData = sourceRevenueData
          .where((data) =>
              !data.date.isBefore(startDate.subtract(Duration(microseconds: 1))) &&
              !data.date.isAfter(endDate.add(Duration(days: 1, microseconds: -1))))
          .toList();
    });
  }

  void _handleCustomDateRangeSelected(DateTime startDate, DateTime endDate) {
    if (!mounted) return;
    setState(() {
      selectedDateRange = DateTimeRange(start: startDate, end: endDate);
      dateRangeText = '${DateFormat('dd/MM/yyyy').format(startDate)} - ${DateFormat('dd/MM/yyyy').format(endDate)}';
      selectedRange = 'Custom';
      _processAndFilterData(); 
    });
  }

  double _calculateTotalRevenue(List<RevenueData> data) {
    return data.fold(0.0, (sum, item) => sum + item.revenue);
  }

  double _calculateAverageRevenuePerTrip(List<RevenueData> data) {
    if (data.isEmpty) return 0.0;
    return _calculateTotalRevenue(data) / data.length;
  }

  Map<String, double> _calculatePaidVsPendingRevenue() {
    double paid = 0;
    double pending = 0;
    
    // This should use the trips that contributed to filteredRevenueData
    // To do this accurately, we need to know which trips in `paymentFilteredTripsFullDetails`
    // correspond to the `RevenueData` objects in `filteredRevenueData`.
    // A simpler way is to filter paymentFilteredTripsFullDetails by the current date range again.

    DateTime now = DateTime.now();
    DateTime filterStartDate;
    DateTime filterEndDate = now;

    if (selectedDateRange != null) {
        filterStartDate = selectedDateRange!.start;
        filterEndDate = selectedDateRange!.end;
    } else {
        switch (selectedRange) {
            case 'Last 7 Days': filterStartDate = now.subtract(const Duration(days: 6)); break;
            case 'Last Month':
                filterStartDate = DateTime(now.year, now.month - 1, 1);
                filterEndDate = DateTime(now.year, now.month, 0);
                break;
            case 'Last 6 Months': filterStartDate = DateTime(now.year, now.month - 6, 1); break;
            default: filterStartDate = now.subtract(const Duration(days: 6));
        }
    }
    
    List<Map<String,dynamic>> dateAndPaymentFilteredTrips = paymentFilteredTripsFullDetails.where((trip){
        try {
            final tripDate = DateTime.parse(trip['created_at'] as String);
            return !tripDate.isBefore(filterStartDate.subtract(Duration(microseconds:1))) && 
                   !tripDate.isAfter(filterEndDate.add(Duration(days: 1, microseconds: -1)));
        } catch (e) { return false; }
    }).toList();

    for (var trip in dateAndPaymentFilteredTrips) {
        final paymentStatus = trip['paymentStatus']?.toString().toLowerCase() ?? 'unknown';
        final amount = (trip['amount'] as num? ?? 0.0).toDouble();
        if (paymentStatus == 'paid') {
            paid += amount;
        } else if (paymentStatus == 'pending') {
            pending += amount;
        }
    }
    return {'paid': paid, 'pending': pending};
}


  List<ChartData> _getRevenueByOrderStatusData() {
    if (!mounted) return [];
    Map<String, double> revenueByStatus = {};
    
    DateTime now = DateTime.now();
    DateTime filterStartDate;
    DateTime filterEndDate = now;

    if (selectedDateRange != null) {
      filterStartDate = selectedDateRange!.start;
      filterEndDate = selectedDateRange!.end;
    } else {
      switch (selectedRange) {
        case 'Last 7 Days': filterStartDate = now.subtract(const Duration(days: 6)); break;
        case 'Last Month':
          filterStartDate = DateTime(now.year, now.month - 1, 1);
          filterEndDate = DateTime(now.year, now.month, 0);
          break;
        case 'Last 6 Months': filterStartDate = DateTime(now.year, now.month - 6, 1); break;
        default: filterStartDate = now.subtract(const Duration(days: 6));
      }
    }

    List<Map<String,dynamic>> dateFilteredTrips = paymentFilteredTripsFullDetails.where((trip){
        try {
            final tripDate = DateTime.parse(trip['created_at'] as String);
            return !tripDate.isBefore(filterStartDate.subtract(Duration(microseconds:1))) && 
                   !tripDate.isAfter(filterEndDate.add(Duration(days: 1, microseconds: -1)));
        } catch (e) { return false; }
    }).toList();


    for (var trip in dateFilteredTrips) {
      String status = trip['orderStatus']?.toString().toLowerCase() ?? 'unknown';
      if (status == 'in progress') status = 'pending'; // Assuming 'in progress' maps to 'pending'
      if (status == 'refunded') status = 'cancelled'; // Assuming 'refunded' maps to 'cancelled'
      if (status == 'onhold') status = 'overdue'; // Assuming 'onhold' maps to 'overdue'

      double amount = (trip['amount'] as num? ?? 0.0).toDouble();
      revenueByStatus[status] = (revenueByStatus[status] ?? 0) + amount;
    }
    
    return revenueByStatus.entries.map((entry) => ChartData(entry.key.toUpperCase(), entry.value)).toList();
  }

  List<ChartData> _getRevenueByTop5DestinationData() {
    if (!mounted) return [];
    Map<String, double> revenueByDestination = {};

    DateTime now = DateTime.now();
    DateTime filterStartDate;
    DateTime filterEndDate = now;

    if (selectedDateRange != null) {
      filterStartDate = selectedDateRange!.start;
      filterEndDate = selectedDateRange!.end;
    } else {
      switch (selectedRange) {
        case 'Last 7 Days': filterStartDate = now.subtract(const Duration(days: 6)); break;
        case 'Last Month':
          filterStartDate = DateTime(now.year, now.month - 1, 1);
          filterEndDate = DateTime(now.year, now.month, 0);
          break;
        case 'Last 6 Months': filterStartDate = DateTime(now.year, now.month - 6, 1); break;
        default: filterStartDate = now.subtract(const Duration(days: 6));
      }
    }

    List<Map<String,dynamic>> dateFilteredTrips = paymentFilteredTripsFullDetails.where((trip){
        try {
            final tripDate = DateTime.parse(trip['created_at'] as String);
            return !tripDate.isBefore(filterStartDate.subtract(Duration(microseconds:1))) && 
                   !tripDate.isAfter(filterEndDate.add(Duration(days: 1, microseconds: -1)));
        } catch (e) { return false; }
    }).toList();

    for (var trip in dateFilteredTrips) {
      String destination = trip['destination']?.toString() ?? 'Unknown';
      if (destination.isEmpty) destination = 'N/A';
      double amount = (trip['amount'] as num? ?? 0.0).toDouble();
      revenueByDestination[destination] = (revenueByDestination[destination] ?? 0) + amount;
    }

    List<ChartData> chartData = revenueByDestination.entries
        .map((entry) => ChartData(entry.key, entry.value))
        .toList();
    chartData.sort((a, b) => b.y.compareTo(a.y));
    return chartData.take(5).toList();
  }

  List<StatusData> _getTripStatusDistributionData() {
    if (!mounted) return [];
    final tripsProvider = context.watch<TripsProvider>(); 
    // These counts are overall and not affected by payment/date filters on this page by design
    // Mapping provider's lists to the required statuses for the chart
    int pendingCount = tripsProvider.pendingTrips.length; // Assuming this includes "In Progress"
    int completedCount = tripsProvider.completedTrips.length;
    int cancelledCount = tripsProvider.cancelledTrips.length; // Assuming this includes "Refunded"
    int overdueCount = tripsProvider.onHoldTrips.length; // Assuming onHoldTrips are considered 'Overdue' orders

    return [
      StatusData('Completed', completedCount),
      StatusData('Pending', pendingCount),
      StatusData('Cancelled', cancelledCount),
      StatusData('Overdue', overdueCount),
    ];
  }

  @override
  Widget build(BuildContext context) {
    double totalRevenue = _calculateTotalRevenue(filteredRevenueData);
    double avgRevenuePerTrip = _calculateAverageRevenuePerTrip(filteredRevenueData);
    Map<String, double> paidVsPending = selectedPaymentStatusFilter == 'Paid + Pending' ? _calculatePaidVsPendingRevenue() : {};

    return Scaffold(
      appBar: AppBar(
        title: Text('Trip Statistics', style: TextStyle(color: Theme.of(context).colorScheme.onPrimary)),
        backgroundColor: Theme.of(context).colorScheme.primary,
        iconTheme: IconThemeData(color: Theme.of(context).colorScheme.onPrimary),
      ),
      body: Padding(
        padding: const EdgeInsets.all(8.0),
        child: Column(
          children: [
            // KPIs Section
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
                        _buildKpi("Avg. Revenue/Trip", currencyFormatter.format(avgRevenuePerTrip)),
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

            // Filters Section
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
                                  selectedDateRange = null;
                                  dateRangeText = 'Select Date Range';
                                }
                                if (value != 'Custom') _processAndFilterData();
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
                          _processAndFilterData();
                        });
                      },
                    ),
                  ],
                ),
              ),
            ),
            SizedBox(height: 10),

            _buildTripProgressOverview(), 
            SizedBox(height: 10),

            Expanded(
              child: ListView(
                children: [
                  _buildSectionTitle('Revenue Trend'),
                  SizedBox(
                    height: 300,
                    child: SfCartesianChart(
                      legend: Legend(isVisible: true, position: LegendPosition.bottom),
                      primaryXAxis: DateTimeAxis(majorGridLines: MajorGridLines(width: 0)),
                      primaryYAxis: NumericAxis(labelFormat: '\${value}', majorTickLines: MajorTickLines(size: 0)),
                      tooltipBehavior: _tooltipBehavior,
                      series: [
                        LineSeries<RevenueData, DateTime>(
                          name: 'Revenue',
                          dataSource: filteredRevenueData,
                          xValueMapper: (RevenueData data, _) => data.date,
                          yValueMapper: (RevenueData data, _) => data.revenue,
                          enableTooltip: true,
                          markerSettings: MarkerSettings(isVisible: true),
                          color: Theme.of(context).colorScheme.primary,
                        )
                      ],
                    ),
                  ),
                  SizedBox(height: 16),
                  _buildSectionTitle('Trip Status Distribution (Overall Counts)'),
                  SizedBox(
                    height: 250,
                    child: SfCircularChart(
                      legend: Legend(isVisible: true, position: LegendPosition.bottom),
                      series: <CircularSeries>[
                        PieSeries<StatusData, String>(
                          dataSource: _getTripStatusDistributionData(),
                          xValueMapper: (StatusData data, _) => data.status,
                          yValueMapper: (StatusData data, _) => data.count,
                          dataLabelSettings: DataLabelSettings(isVisible: true, labelPosition: ChartDataLabelPosition.outside),
                          enableTooltip: true,
                        )
                      ],
                    ),
                  ),
                  SizedBox(height: 16),
                  _buildSectionTitle('Revenue by Order Status (Filtered)'),
                  _buildRevenueByOrderStatusChart(),
                  SizedBox(height: 16),
                  _buildSectionTitle('Top 5 Revenue by Destination (Filtered)'),
                  _buildRevenueByDestinationChart(),
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
        Text('$count trips', style: TextStyle(fontSize: 16, fontWeight:FontWeight.bold, color: Theme.of(context).textTheme.bodyLarge?.color ?? Colors.black)),
      ],
    );
  }
  
  Widget _buildTripProgressOverview() {
    if (!mounted) return SizedBox.shrink();
    final tripsProvider = context.watch<TripsProvider>(); // Watching for live updates on overall counts
    return Card(
      elevation: 2,
      child: Padding(
        padding: const EdgeInsets.all(12.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text("Trip Status Overview (Overall)", style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Theme.of(context).colorScheme.tertiary)),
            SizedBox(height: 12),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              children: [
                _statusCard('Completed', Colors.green, tripsProvider.completedTrips.length),
                _statusCard('Pending', Colors.orange, tripsProvider.pendingTrips.length), // Assumes provider handles mapping "In Progress"
                _statusCard('Cancelled', Colors.red, tripsProvider.cancelledTrips.length), // Assumes provider handles mapping "Refunded"
                _statusCard('Overdue', Colors.purple, tripsProvider.onHoldTrips.length), // Assumes onHoldTrips are 'Overdue' orders
              ],
            ),
          ],
        ),
      ),
    );
  }
  
  Widget _buildRevenueByOrderStatusChart() {
    if (!mounted) return SizedBox.shrink();
    List<ChartData> chartData = _getRevenueByOrderStatusData();
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
         tooltipBehavior: _tooltipBehavior,
      ),
    );
  }

  Widget _buildRevenueByDestinationChart() {
     if (!mounted) return SizedBox.shrink();
    List<ChartData> top5Data = _getRevenueByTop5DestinationData();
     if (top5Data.isEmpty) return Center(child: Padding(padding: const EdgeInsets.all(8.0), child: Text("No revenue data for current filter.")));

    return SizedBox(
      height: 300,
      child: SfCartesianChart(
        primaryXAxis: CategoryAxis(labelRotation: -45, majorGridLines: MajorGridLines(width: 0), labelStyle: TextStyle(fontSize: 10)),
        primaryYAxis: NumericAxis(labelFormat: '\${value}', majorTickLines: MajorTickLines(size:0)),
        series: <CartesianSeries>[
          BarSeries<ChartData, String>( // Changed to BarSeries for horizontal bars
            dataSource: top5Data,
            xValueMapper: (ChartData data, _) => data.x,
            yValueMapper: (ChartData data, _) => data.y,
            name: 'Revenue',
            dataLabelSettings: DataLabelSettings(isVisible: true),
            color: Theme.of(context).colorScheme.secondary,
          )
        ],
        tooltipBehavior: _tooltipBehavior,
      ),
    );
  }

  void _pickDateRange() async {
    if (!mounted) return;
    DateTimeRange? picked = await showDateRangePicker(
      context: context,
      initialDateRange: selectedDateRange,
      firstDate: DateTime(2020),
      lastDate: DateTime.now().add(Duration(days: 365)),
    );
    if (picked != null) {
      _handleCustomDateRangeSelected(picked.start, picked.end);
    }
  }

  void _exportData() {
    if (!mounted) return;
    // This is a placeholder. Actual export logic would involve converting
    // the filtered data (e.g., paymentFilteredTripsFullDetails further filtered by date)
    // to CSV or another format and using a plugin to save/share the file.
    print("Exporting data for date range: $dateRangeText, payment status: $selectedPaymentStatusFilter");
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('Export functionality not yet implemented.')),
    );
  }
}
