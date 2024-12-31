import 'package:bizorganizer/main.dart';
import 'package:bizorganizer/providers/orders_providers.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import 'package:syncfusion_flutter_charts/charts.dart';

class TripStatsPage extends StatefulWidget {
  @override
  _TripStatsPageState createState() => _TripStatsPageState();
}

class _TripStatsPageState extends State<TripStatsPage> {
  DateTimeRange? selectedDateRange;
  String dateRangeText = 'Select Date Range';
  late TooltipBehavior _tooltipBehavior;
  List<RevenueData> filteredData = [];
  List<RevenueData> getRevenueData = [];
  String selectedRange = 'Last 7 Days';

  @override
  void initState() {
    // enabling tooltip for chart
    _tooltipBehavior = TooltipBehavior(
      enable: true,
    );
    // getting all trips
    final tripProvider =
        Provider.of<TripsProvider>(context, listen: false).trips;
    getRevenueData = tripProvider.map((trip) {
      return RevenueData(
          DateTime.parse(trip['created_at']), trip['amount'].toDouble() ?? 0);
    }).toList();

    super.initState();
  }

  getcustomRange(startDate, endDate) {
    setState(() {
      filteredData = getRevenueData
          .where((data) =>
              data.date.isAfter(startDate) && data.date.isBefore(endDate))
          .toList();
    });
  }

  @override
  Widget build(BuildContext context) {
    // final trips = Provider.of<TripsProvider>(context);
    // // Mock Data for Charts
    // List<RevenueData> _getRevenueData() {
    //   DateFormat format = DateFormat('yyyy-MM-dd');
    //   return trips.trips.map((trip) {
    //     return RevenueData(
    //       format.parse(trip['created_at']),
    //       trip['amount'].toDouble(), // Ensuring amount is a double
    //     );
    //   }).toList();
    // }

    // // DateFormat format = DateFormat('d-MM-yyyy');
    // List<RevenueData> getRevenueData = trips.trips.map((trip) {
    //   return RevenueData(
    //       DateTime.parse(trip['created_at']), trip['amount'].toDouble() ?? 0);
    // }).toList();

    // for (var data in getRevenueData) {
    //   print(
    //       'Date: ${DateFormat('yyyy-MM-dd').format(data.date)}, Amount: ${data.revenue}');
    // }

    void filterData() {
      DateTime now = DateTime.now();
      DateTime startDate;

      switch (selectedRange) {
        case 'Last 7 Days':
          startDate = now.subtract(const Duration(days: 7));
          break;
        case 'Last Month':
          startDate = DateTime(now.day, now.month - 1, now.year);
          break;
        case 'Last 6 Months':
          startDate = DateTime(now.day, now.month - 6, now.year);
          break;
        default:
          startDate = now.subtract(const Duration(days: 7));
      }

      setState(() {
        filteredData = getRevenueData
            .where((data) =>
                data.date.isAfter(startDate) && data.date.isBefore(now))
            .toList();
      });
    }

    return Scaffold(
      appBar: AppBar(title: Text('Trip Statistics')),
      body: Padding(
        padding: const EdgeInsets.all(8.0),
        child: Column(
          children: [
            // Date Range Picker Section
            GestureDetector(
              onTap: _pickDateRange,
              child: Container(
                padding: EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.grey[300],
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(dateRangeText,
                        style: TextStyle(fontSize: 16, color: Colors.black)),
                    Icon(Icons.calendar_today),
                  ],
                ),
              ),
            ),
            SizedBox(height: 16),

            // Trip Progress Overview
            Card(
              elevation: 3,
              child: ListTile(
                title: Text("Trip Progress Overview"),
                subtitle: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                  children: [
                    _statusCard('Completed', Colors.green,
                        context.watch<TripsProvider>().completedTrips.length),
                    _statusCard('Pending', Colors.orange,
                        context.watch<TripsProvider>().pendingTrips.length),
                    _statusCard('Cancelled', Colors.red,
                        context.watch<TripsProvider>().cancelledTrips.length),
                  ],
                ),
              ),
            ),
            SizedBox(height: 16),

            // Date Range Selector
            Padding(
              padding: const EdgeInsets.all(16.0),
              child: DropdownButton<String>(
                value: selectedRange,
                items: ['Last 7 Days', 'Last Month', 'Last 6 Months']
                    .map((range) => DropdownMenuItem(
                          value: range,
                          child: Text(range),
                        ))
                    .toList(),
                onChanged: (value) {
                  setState(() {
                    selectedRange = value!;
                    filterData();
                  });
                },
              ),
            ),

            // Statistics Visualization (using charts)
            Expanded(
              child: ListView(
                children: [
                  Text('Revenue Trend'),
                  SizedBox(
                    height: 400,
                    child: SfCartesianChart(
                      legend: Legend(isVisible: true),
                      primaryXAxis: DateTimeAxis(),
                      primaryYAxis: NumericAxis(labelFormat: '{value}'),
                      tooltipBehavior: _tooltipBehavior,
                      series: [
                        LineSeries<RevenueData, DateTime>(
                          name: businessName,
                          dataSource: filteredData,
                          xValueMapper: (RevenueData data, _) => data.date,
                          yValueMapper: (RevenueData data, _) => data.revenue,
                          enableTooltip: true,
                        )
                      ],
                    ),
                  ),
                  SizedBox(height: 16),
                  Text('Trip Status Distribution'),
                  SizedBox(
                    height: 200,
                    child: SfCircularChart(
                      series: <CircularSeries>[
                        PieSeries<StatusData, String>(
                          dataSource: _getStatusData(),
                          xValueMapper: (StatusData data, _) => data.status,
                          yValueMapper: (StatusData data, _) => data.count,
                        )
                      ],
                    ),
                  ),
                  SizedBox(height: 16),
                ],
              ),
            ),

            // Export Button
            ElevatedButton.icon(
              onPressed: _exportData,
              icon: Icon(Icons.download),
              label: Text('Export Data'),
            ),
          ],
        ),
      ),
    );
  }

  // Status Card Widget
  Widget _statusCard(String title, Color color, int count) {
    return Column(
      children: [
        Text(title, style: TextStyle(color: color)),
        SizedBox(height: 4),
        Text('$count trips', style: TextStyle(fontSize: 18)),
      ],
    );
  }

  List<StatusData> _getStatusData() {
    return [
      StatusData(
          'Completed', context.watch<TripsProvider>().completedTrips.length),
      StatusData('Pending', context.watch<TripsProvider>().pendingTrips.length),
      StatusData(
          'Cancelled', context.watch<TripsProvider>().cancelledTrips.length),
    ];
  }

  // Pick Date Range
  void _pickDateRange() async {
    DateTimeRange? picked = await showDateRangePicker(
      context: context,
      firstDate: DateTime(2020),
      lastDate: DateTime.now(),
    );
    if (picked != null) {
      setState(() {
        selectedDateRange = picked;
        dateRangeText =
            '${DateFormat('dd/MM/yyyy').format(picked.start)} - ${DateFormat('dd/MM/yyyy').format(picked.end)}';
        getcustomRange(picked.start, picked.end);
      });
    }
  }

  // Placeholder for Export Data Function
  void _exportData() {
    // Export function can be implemented here.
    print("Exporting data for range $dateRangeText");
  }
}

// Mock Data Classes for Chart
class RevenueData {
  final DateTime date;
  final double revenue;
  RevenueData(this.date, this.revenue);

  Map<String, dynamic> toJson() {
    return {'date': date, 'revenue': revenue};
  }
}

class StatusData {
  final String status;
  final int count;
  StatusData(this.status, this.count);
}
