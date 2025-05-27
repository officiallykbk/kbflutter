import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:syncfusion_flutter_charts/charts.dart';
import 'package:bizorganizer/models/cargo_job.dart'; // Assuming CargoJob model is here
import 'package:bizorganizer/models/status_constants.dart'; // For paymentStatusToString

class RevenueTrendChartWidget extends StatefulWidget {
  const RevenueTrendChartWidget({
    Key? key,
    required this.jobs, 
    required this.startDate,
    required this.endDate,
    required this.paymentStatusFilter, 
  }) : super(key: key);

  final List<CargoJob> jobs; // Changed to List<CargoJob>
  final DateTime startDate;
  final DateTime endDate;
  final String paymentStatusFilter;

  @override
  State<RevenueTrendChartWidget> createState() => _RevenueTrendChartWidgetState();
}

class _RevenueTrendChartWidgetState extends State<RevenueTrendChartWidget> {
  List<_ChartData> _processedChartData = [];
  late TooltipBehavior _tooltipBehavior;

  // Private helper class for chart data points
  class _ChartData {
    _ChartData(this.date, this.revenue);
    final DateTime date;
    final double revenue;
  }

  @override
  void initState() {
    super.initState();
    _tooltipBehavior = TooltipBehavior(
      enable: true, 
      header: '', 
      format: 'point.x : point.y',
      // Customize further if needed, e.g., using DateFormat for point.x
      // builder: (dynamic data, dynamic point, dynamic series, int pointIndex, int seriesIndex) {
      //   final _ChartData chartData = data as _ChartData;
      //   return Container(
      //     padding: EdgeInsets.all(10),
      //     decoration: BoxDecoration(
      //       color: Colors.grey.shade800,
      //       borderRadius: BorderRadius.circular(5)
      //     ),
      //     child: Text(
      //       '${DateFormat.MMMd().format(chartData.date)}: \$${chartData.revenue.toStringAsFixed(2)}',
      //        style: TextStyle(color: Colors.white)
      //     )
      //   );
      // }
    );
    _processData();
  }

  @override
  void didUpdateWidget(RevenueTrendChartWidget oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.jobs != oldWidget.jobs ||
        widget.startDate != oldWidget.startDate ||
        widget.endDate != oldWidget.endDate ||
        widget.paymentStatusFilter != oldWidget.paymentStatusFilter) {
      _processData();
    }
  }

  void _processData() {
    // Step 2.a: Filter by Payment Status
    List<CargoJob> paymentFilteredJobs;
    final paidStatusStr = paymentStatusToString(PaymentStatus.Paid).toLowerCase();
    final pendingStatusStr = paymentStatusToString(PaymentStatus.Pending).toLowerCase();

    if (widget.paymentStatusFilter == 'Paid Only') {
      paymentFilteredJobs = widget.jobs.where((job) => job.paymentStatus?.toLowerCase() == paidStatusStr).toList();
    } else if (widget.paymentStatusFilter == 'Pending Only') {
      paymentFilteredJobs = widget.jobs.where((job) => job.paymentStatus?.toLowerCase() == pendingStatusStr).toList();
    } else { // 'Paid + Pending' or any other case, treat as all relevant (paid or pending)
      paymentFilteredJobs = widget.jobs.where((job) {
        final status = job.paymentStatus?.toLowerCase();
        return status == paidStatusStr || status == pendingStatusStr;
      }).toList();
    }

    // Step 2.b: Aggregate Revenue by Date (using createdAt as the date field)
    Map<DateTime, double> dailyRevenue = {};
    for (var job in paymentFilteredJobs) {
      if (job.createdAt != null && job.agreedPrice != null) {
        // Normalize createdAt to the start of the day to aggregate daily
        DateTime day = DateTime(job.createdAt!.year, job.createdAt!.month, job.createdAt!.day);
        dailyRevenue[day] = (dailyRevenue[day] ?? 0) + job.agreedPrice!;
      }
    }

    List<_ChartData> aggregatedData = dailyRevenue.entries.map((entry) {
      return _ChartData(entry.key, entry.value);
    }).toList();

    // Sort by date (important for line/spline charts)
    aggregatedData.sort((a, b) => a.date.compareTo(b.date));
    
    // Step 2.c: Filter by Date Range (for chart series data)
    // The chart itself will use widget.startDate and widget.endDate for axis min/max.
    // Here, we filter the dataSource for the series to only include points within this range.
    // Normalizing widget.startDate and widget.endDate to compare dates correctly.
    final DateTime rangeStartDate = DateTime(widget.startDate.year, widget.startDate.month, widget.startDate.day);
    final DateTime rangeEndDate = DateTime(widget.endDate.year, widget.endDate.month, widget.endDate.day, 23, 59, 59, 999);


    List<_ChartData> dateRangeFilteredData = aggregatedData.where((dataPoint) {
      return !dataPoint.date.isBefore(rangeStartDate) && !dataPoint.date.isAfter(rangeEndDate);
    }).toList();

    if (mounted) {
      setState(() {
        _processedChartData = dateRangeFilteredData;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 300, // Default height, can be adjusted
      child: SfCartesianChart(
        legend: Legend(isVisible: true, position: LegendPosition.bottom, textStyle: TextStyle(color: Colors.white70)),
        primaryXAxis: DateTimeAxis(
          minimum: widget.startDate,
          maximum: widget.endDate,
          dateFormat: DateFormat.MMMd(), 
          intervalType: DateTimeIntervalType.auto,
          majorGridLines: MajorGridLines(width: 0.2, color: Colors.grey.shade700),
          labelStyle: TextStyle(color: Colors.white70, fontSize: 10),
          axisLine: AxisLine(color: Colors.grey.shade700),
        ),
        primaryYAxis: NumericAxis(
          labelFormat: '\${value}', // Currency format
          majorTickLines: MajorTickLines(size: 0),
          labelStyle: TextStyle(color: Colors.white70, fontSize: 10),
          axisLine: AxisLine(width: 0, color: Colors.grey.shade700),
          numberFormat: NumberFormat.compactSimpleCurrency(locale: 'en_US'), // Compact format for large numbers
        ),
        tooltipBehavior: _tooltipBehavior,
        series: <ChartSeries<_ChartData, DateTime>>[
          SplineSeries<_ChartData, DateTime>( // Changed to SplineSeries for a smoother curve
            dataSource: _processedChartData,
            xValueMapper: (_ChartData data, _) => data.date,
            yValueMapper: (_ChartData data, _) => data.revenue,
            name: 'Revenue', 
            color: Theme.of(context).colorScheme.primary,
            markerSettings: MarkerSettings(isVisible: true, height: 3, width: 3),
            enableTooltip: true,
          )
        ],
      ),
    );
  }
}
