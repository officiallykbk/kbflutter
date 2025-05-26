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

class JobDetails extends StatefulWidget {
  final Map<String, dynamic> job; 

  const JobDetails({super.key, required this.job});

  @override
  State<JobDetails> createState() => _JobDetailsState();
}

class _JobDetailsState extends State<JobDetails> {
  late String currentDeliveryStatus;
  late String currentPaymentStatus;

  List<JobHistoryEntry> _historyEntries = [];
  bool _isLoadingHistory = true;

  final NumberFormat currencyFormatter = NumberFormat.currency(locale: 'en_US', symbol: '\$');

  @override
  void initState() {
    super.initState();
    currentDeliveryStatus = widget.job['delivery_status']?.toString().toLowerCase() ?? 'pending';
    currentPaymentStatus = widget.job['payment_status']?.toString().toLowerCase() ?? 'pending';
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
                  builder: (_) => AddJob(job: CargoJob.fromJson(widget.job), isEditing: true), 
                ),
              ).then((value) async { 
                if (value == true) { 
                  await jobProvider.fetchJobsData();
                  final updatedJobData = jobProvider.jobs.firstWhere((j) => j['id'] == widget.job['id'], orElse: () => widget.job);
                  if (mounted) {
                    setState(() {
                      currentDeliveryStatus = updatedJobData['delivery_status']?.toString().toLowerCase() ?? 'pending';
                      currentPaymentStatus = updatedJobData['payment_status']?.toString().toLowerCase() ?? 'pending';
                      // Refresh widget.job with new data if possible, or rely on parent to pass updated map
                      // This is a simplification; a more robust solution might involve a direct way to update widget.job
                      // or making JobDetails listen to a specific job ID from the provider.
                      (widget as JobDetails).job.clear();
                      (widget as JobDetails).job.addAll(updatedJobData);

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
            if (widget.job['receipt_url'] != null && widget.job['receipt_url'].isNotEmpty) 
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
                                      imageUrl: widget.job['receipt_url']))), 
                          child: Hero(
                              tag: widget.job['receipt_url'], 
                              child: CacheImage(imageUrl: widget.job['receipt_url']))) 
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
                    _buildTableRow('Shipper Name:', widget.job['shipper_name'] ?? 'N/A'),
                    _buildTableRow('Pickup Date:', _formatDate(widget.job['pickup_date'], includeTime: false)),
                    _buildTableRow('Pickup Location:', widget.job['pickup_location'] ?? 'N/A'),
                    _buildTableRow('Dropoff Location:', widget.job['dropoff_location'] ?? 'N/A'),
                    _buildTableRow('Est. Delivery Date:', _formatDate(widget.job['estimated_delivery_date'], includeTime: false)),
                    _buildTableRow('Actual Delivery Date:', _formatDate(widget.job['actual_delivery_date'], includeTime: false)),
                    _buildTableRow('Agreed Price:', currencyFormatter.format((widget.job['agreed_price'] as num?)?.toDouble() ?? 0.00)),
                    _buildTableRow('Payment Status:', currentPaymentStatus.toUpperCase()),
                    _buildTableRow('Delivery Status:', currentDeliveryStatus.toUpperCase()),
                    _buildTableRow('Notes:', widget.job['notes'] ?? 'N/A', isMultiline: true),
                    _buildTableRow('Created At:', _formatDate(widget.job['created_at'])),
                    _buildTableRow('Updated At:', _formatDate(widget.job['updated_at'])),
                    _buildTableRow('Created By (User ID):', widget.job['created_by'] ?? 'N/A', isMultiline: true),
                  ],
                ),
              ),
            ),

            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(16.0, 16.0, 16.0, 8.0), 
                child: Text('Change Delivery Status:', style: Theme.of(context).textTheme.titleMedium?.copyWith(color: Colors.white70)),
              ),
            ),
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 12.0), 
                child: Wrap(
                  spacing: 8.0, 
                  runSpacing: 4.0,
                  children: [ 
                    'pending', 'in progress', 'completed', 'cancelled', 'onhold', 'rejected' 
                  ].map((status) {
                    return ChoiceChip(
                      label: Text(status.toUpperCase(), style: TextStyle(color: currentDeliveryStatus == status ? Colors.black : Colors.white)),
                      selected: currentDeliveryStatus == status,
                      onSelected: (selected) {
                        if (selected) {
                          jobProvider.updateJobDeliveryStatus(widget.job['id'] as int, status);
                          setState(() {
                            currentDeliveryStatus = status;
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
                child: Text('Change Payment Status:', style: Theme.of(context).textTheme.titleMedium?.copyWith(color: Colors.white70)),
              ),
            ),
            SliverToBoxAdapter(
              child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 12.0), 
                  child: Wrap( 
                    spacing: 8.0, 
                    runSpacing: 4.0,
                    children: ['pending', 'paid', 'overdue', 'refunded'] 
                        .map((status) {
                      return ChoiceChip(
                        label: Text(status.toUpperCase(), style: TextStyle(color: currentPaymentStatus == status ? Colors.black : Colors.white)),
                        selected: currentPaymentStatus == status,
                        onSelected: (selected) {
                           if (selected) {
                            jobProvider.updateJobPaymentStatus(widget.job['id'] as int, status);
                            setState(() {
                               currentPaymentStatus = status;
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

            // Job History Section
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
