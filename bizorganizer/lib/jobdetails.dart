import 'package:bizorganizer/models/imageCaching.dart'; 
import 'package:bizorganizer/providers/orders_providers.dart'; 
import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:photo_view/photo_view.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart'; 
import 'package:bizorganizer/models/job_history_entry.dart'; 
import 'package:bizorganizer/addjob.dart'; 
import 'package:bizorganizer/models/cargo_job.dart'; 
import 'package:bizorganizer/models/status_constants.dart'; // Task 1: Already imported, confirmed.

class JobDetails extends StatefulWidget {
  final Map<String, dynamic> job; 

  const JobDetails({super.key, required this.job});

  @override
  State<JobDetails> createState() => _JobDetailsState();
}

class _JobDetailsState extends State<JobDetails> {
  late String currentActualDeliveryStatus; // Stores the actual DB value for delivery_status
  late String currentActualPaymentStatus;  // Stores the actual DB value for payment_status

  List<JobHistoryEntry> _historyEntries = [];
  bool _isLoadingHistory = true;

  final NumberFormat currencyFormatter = NumberFormat.currency(locale: 'en_US', symbol: '\$');

  // Task 3 & 4: Define user-selectable statuses
  final List<DeliveryStatus> userSelectableDeliveryStatuses = [
    DeliveryStatus.Completed,
    DeliveryStatus.Cancelled,
    // Add other statuses users can *manually set from details page* if needed, e.g., back to Scheduled or InProgress
    // For now, sticking to task: Completed, Cancelled
  ];

  final List<PaymentStatus> userSelectablePaymentStatuses = [
    PaymentStatus.Pending,
    PaymentStatus.Paid,
    PaymentStatus.Cancelled,
    // Consider PaymentStatus.Refunded if it's a common manual operation here
  ];


  @override
  void initState() {
    super.initState();
    // Initialize with actual statuses from the job data
    currentActualDeliveryStatus = widget.job['delivery_status']?.toString().toLowerCase() ?? deliveryStatusToString(DeliveryStatus.Pending);
    currentActualPaymentStatus = widget.job['payment_status']?.toString().toLowerCase() ?? paymentStatusToString(PaymentStatus.Pending);
    _fetchHistory();
  }

  Future<void> _fetchHistory() async {
    if (!mounted) return;
    setState(() {
      _isLoadingHistory = true;
    });
    final jobId = widget.job['id'] as int?;
    if (jobId == null) {
      setState(() {
        _isLoadingHistory = false;
        print("Job ID is null, cannot fetch history.");
      });
      return;
    }
    try {
      final entries = await context.read<CargoJobProvider>().fetchJobHistory(jobId);
      if (mounted) {
        setState(() {
          _historyEntries = entries;
          _isLoadingHistory = false;
        });
      }
    } catch (e) {
      print("Error fetching job history in JobDetails: $e");
      if (mounted) {
        setState(() {
          _isLoadingHistory = false;
        });
         ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Error fetching job history: $e')),
          );
      }
    }
  }

  String _formatDate(String? dateString, {bool includeTime = true}) {
    if (dateString == null || dateString.isEmpty) return 'N/A';
    try {
      final dateTime = DateTime.parse(dateString);
      if (includeTime) {
        return DateFormat('MMMM d, yyyy, hh:mm a').format(dateTime); 
      } else {
        return DateFormat('MMMM d, yyyy').format(dateTime);
      }
    } catch (e) {
      return dateString; 
    }
  }

  TableRow _buildTableRow(String label, String value, {bool isMultiline = false}) {
    return TableRow(
      children: [
        TableCell(
          verticalAlignment: TableCellVerticalAlignment.top,
          child: Padding(
            padding: const EdgeInsets.all(8.0),
            child: Text(label, style: const TextStyle(fontWeight: FontWeight.bold, color: Colors.white70)),
          ),
        ),
        TableCell(
          verticalAlignment: TableCellVerticalAlignment.top,
          child: Padding(
            padding: const EdgeInsets.all(8.0),
            child: Text(value, style: TextStyle(color: Colors.white, height: isMultiline ? 1.5 : null)),
          ),
        ),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    final jobProvider = Provider.of<CargoJobProvider>(context);
    final CargoJob cargoJobInstance = CargoJob.fromJson(widget.job); // Convert map to CargoJob instance

    // Use local state for chip selection, which reflects the actual DB status
    // The effective status is for display purposes in the table.
    String displayDeliveryStatus = cargoJobInstance.effectiveDeliveryStatus ?? deliveryStatusToString(DeliveryStatus.Pending);
    
    return Scaffold(
      appBar: AppBar(
        title: Text('Job Details', style: TextStyle(color: Theme.of(context).colorScheme.onPrimary)), 
        centerTitle: true,
        backgroundColor: Theme.of(context).colorScheme.primary,
        iconTheme: IconThemeData(color: Theme.of(context).colorScheme.onPrimary),
        actions: [
          IconButton(
            icon: const Icon(Icons.edit),
            onPressed: () {
              Navigator.of(context).push(
                MaterialPageRoute(
                  builder: (_) => AddJob(job: cargoJobInstance, isEditing: true), 
                ),
              ).then((value) async { 
                if (value == true) { 
                  await jobProvider.fetchJobsData();
                  final updatedJobData = jobProvider.jobs.firstWhere((j) => j['id'] == widget.job['id'], orElse: () => widget.job);
                  if (mounted) {
                    setState(() {
                      // Update the local map that widget.job refers to, so UI rebuilds with new data
                      widget.job.clear();
                      widget.job.addAll(updatedJobData);
                      
                      // Re-initialize currentActual statuses from the (potentially) updated widget.job
                      currentActualDeliveryStatus = widget.job['delivery_status']?.toString().toLowerCase() ?? deliveryStatusToString(DeliveryStatus.Pending);
                      currentActualPaymentStatus = widget.job['payment_status']?.toString().toLowerCase() ?? paymentStatusToString(PaymentStatus.Pending);
                      _fetchHistory(); 
                    });
                  }
                }
              });
            },
          ),
        ],
      ),
      body: SafeArea(
        child: CustomScrollView(
          slivers: [
            if (cargoJobInstance.receiptUrl != null && cargoJobInstance.receiptUrl!.isNotEmpty) 
              SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('Receipt:', style: Theme.of(context).textTheme.titleLarge?.copyWith(color: Colors.white70)),
                      const SizedBox(height: 10),
                      InkWell(
                          onTap: () => Navigator.of(context).push(
                              MaterialPageRoute(
                                  builder: (_) => FullScreenImage(
                                      imageUrl: cargoJobInstance.receiptUrl!))), 
                          child: Hero(
                              tag: cargoJobInstance.receiptUrl!, 
                              child: CacheImage(imageUrl: cargoJobInstance.receiptUrl!))) 
                    ],
                  ),
                ),
              ),
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Table(
                  border: TableBorder.all(color: Colors.grey.shade700, borderRadius: BorderRadius.circular(8)), 
                  columnWidths: const {
                    0: FixedColumnWidth(140), 
                    1: FlexColumnWidth(), 
                  },
                  children: [
                    _buildTableRow('Shipper Name:', cargoJobInstance.shipperName ?? 'N/A'),
                    _buildTableRow('Pickup Date:', _formatDate(cargoJobInstance.pickupDate?.toIso8601String(), includeTime: false)),
                    _buildTableRow('Pickup Location:', cargoJobInstance.pickupLocation ?? 'N/A'),
                    _buildTableRow('Dropoff Location:', cargoJobInstance.dropoffLocation ?? 'N/A'),
                    _buildTableRow('Est. Delivery Date:', _formatDate(cargoJobInstance.estimatedDeliveryDate?.toIso8601String(), includeTime: false)),
                    _buildTableRow('Actual Delivery Date:', _formatDate(cargoJobInstance.actualDeliveryDate?.toIso8601String(), includeTime: false)),
                    _buildTableRow('Agreed Price:', currencyFormatter.format(cargoJobInstance.agreedPrice ?? 0.00)),
                    _buildTableRow('Payment Status:', currentActualPaymentStatus.toUpperCase()), // Display actual stored payment status
                    _buildTableRow('Effective Delivery Status:', displayDeliveryStatus.toUpperCase()), // Task 2.2: Display effective status
                    _buildTableRow('Actual Delivery Status:', currentActualDeliveryStatus.toUpperCase()), // Display actual stored delivery status
                    _buildTableRow('Notes:', cargoJobInstance.notes ?? 'N/A', isMultiline: true),
                    _buildTableRow('Created At:', _formatDate(cargoJobInstance.createdAt?.toIso8601String())),
                    _buildTableRow('Updated At:', _formatDate(cargoJobInstance.updatedAt?.toIso8601String())),
                    _buildTableRow('Created By (User ID):', cargoJobInstance.createdBy ?? 'N/A', isMultiline: true),
                  ],
                ),
              ),
            ),

            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(16.0, 16.0, 16.0, 8.0), 
                child: Text('Update Delivery Status:', style: Theme.of(context).textTheme.titleMedium?.copyWith(color: Colors.white70)),
              ),
            ),
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 12.0), 
                child: Wrap(
                  spacing: 8.0, 
                  runSpacing: 4.0,
                  children: userSelectableDeliveryStatuses.map((statusEnum) { // Task 3.1 & 3.2
                    final statusStr = deliveryStatusToString(statusEnum);
                    return ChoiceChip(
                      label: Text(statusStr.toUpperCase(), style: TextStyle(color: currentActualDeliveryStatus == statusStr.toLowerCase() ? Colors.black : Colors.white)),
                      selected: currentActualDeliveryStatus == statusStr.toLowerCase(), // Task 3.3: Reflect actual status
                      onSelected: (selected) {
                        if (selected) {
                           // Provider method already handles history logging correctly with old status fetching
                          jobProvider.updateJobDeliveryStatus(cargoJobInstance.id!, statusStr); // Task 3.4
                          setState(() {
                            currentActualDeliveryStatus = statusStr.toLowerCase(); // Update local state for immediate UI feedback
                          });
                        }
                      },
                      selectedColor: Theme.of(context).colorScheme.secondary,
                      backgroundColor: Colors.grey.shade700,
                    );
                  }).toList(),
                ),
              ),
            ),
            const SliverToBoxAdapter(child: SizedBox(height: 20)),

            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(16.0, 8.0, 16.0, 8.0), 
                child: Text('Update Payment Status:', style: Theme.of(context).textTheme.titleMedium?.copyWith(color: Colors.white70)),
              ),
            ),
            SliverToBoxAdapter(
              child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 12.0), 
                  child: Wrap( 
                    spacing: 8.0, 
                    runSpacing: 4.0,
                    children: userSelectablePaymentStatuses.map((statusEnum) { // Task 4.1 & 4.2
                      final statusStr = paymentStatusToString(statusEnum);
                      return ChoiceChip(
                        label: Text(statusStr.toUpperCase(), style: TextStyle(color: currentActualPaymentStatus == statusStr.toLowerCase() ? Colors.black : Colors.white)),
                        selected: currentActualPaymentStatus == statusStr.toLowerCase(), // Task 4.3: Reflect actual status
                        onSelected: (selected) {
                           if (selected) {
                            // Provider method already handles history logging correctly with old status fetching
                            jobProvider.updateJobPaymentStatus(cargoJobInstance.id!, statusStr); // Task 4.4
                            setState(() {
                               currentActualPaymentStatus = statusStr.toLowerCase(); // Update local state
                            });
                          }
                        },
                        selectedColor: Theme.of(context).colorScheme.secondary,
                        backgroundColor: Colors.grey.shade700,
                      );
                    }).toList(),
                  )
              ),
            ),
            const SliverToBoxAdapter(child: SizedBox(height: 20)),

            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(16.0, 16.0, 16.0, 8.0),
                child: Text('Job History', style: Theme.of(context).textTheme.titleLarge?.copyWith(color: Colors.white)),
              ),
            ),
            _isLoadingHistory
                ? const SliverToBoxAdapter(child: Center(child: Padding(padding: EdgeInsets.all(16.0), child: CircularProgressIndicator())))
                : _historyEntries.isEmpty
                    ? const SliverToBoxAdapter(
                        child: Padding(
                          padding: EdgeInsets.all(16.0),
                          child: Center(child: Text('No history found for this job.', style: TextStyle(color: Colors.white70))),
                        ),
                      )
                    : SliverList(
                        delegate: SliverChildBuilderDelegate(
                          (context, index) {
                            final entry = _historyEntries[index];
                            return Card(
                              color: Colors.grey.shade800,
                              margin: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 4.0),
                              child: ListTile(
                                title: Text(
                                  'Field: ${entry.fieldChanged?.replaceAll('_', ' ').toUpperCase() ?? 'N/A'}',
                                  style: const TextStyle(fontWeight: FontWeight.bold, color: Colors.white),
                                ),
                                subtitle: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text('Old Value: ${entry.oldValue ?? 'N/A'}', style: const TextStyle(color: Colors.white70, fontSize: 12)),
                                    Text('New Value: ${entry.newValue ?? 'N/A'}', style: const TextStyle(color: Colors.white70, fontSize: 12)),
                                    const SizedBox(height: 4),
                                    Text('Changed At: ${_formatDate(entry.changedAt)}', style: const TextStyle(color: Colors.grey, fontSize: 10)),
                                    Text('Changed By: ${entry.changedBy ?? 'N/A'}', style: const TextStyle(color: Colors.grey, fontSize: 10)),
                                  ],
                                ),
                                dense: true,
                              ),
                            );
                          },
                          childCount: _historyEntries.length,
                        ),
                      ),
            const SliverToBoxAdapter(child: SizedBox(height: 30)),
          ],
        ),
      ),
    );
  }
}

class FullScreenImage extends StatelessWidget { 
  const FullScreenImage({super.key, required this.imageUrl});
  final String imageUrl; 

  @override
  Widget build(BuildContext context) {
    return Hero(
      tag: imageUrl, 
      child: Scaffold( 
        backgroundColor: Colors.black.withOpacity(0.8),
        appBar: AppBar(
          backgroundColor: Colors.transparent,
          elevation: 0,
          leading: IconButton(
            icon: const Icon(Icons.close, color: Colors.white, size: 30),
            onPressed: () => Navigator.pop(context),
          ),
        ),
        body: GestureDetector(
          onVerticalDragEnd: (details) {
            if (details.primaryVelocity != null && details.primaryVelocity!.abs() > 200) { 
              Navigator.pop(context);
            }
          },
          child: PhotoView(
            backgroundDecoration: const BoxDecoration(color: Colors.transparent),
            imageProvider: CachedNetworkImageProvider(imageUrl), 
            loadingBuilder: (context, event) => Center(
              child: CircularProgressIndicator(
                value: event == null || event.expectedTotalBytes == null 
                    ? null
                    : event.cumulativeBytesLoaded / event.expectedTotalBytes!,
              ),
            ),
            minScale: PhotoViewComputedScale.contained * 0.8,
            maxScale: PhotoViewComputedScale.covered * 2,
          ),
        ),
      ),
    );
  }
}
