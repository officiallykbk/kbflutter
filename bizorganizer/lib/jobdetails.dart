import 'package:bizorganizer/models/imageCaching.dart';
import 'package:bizorganizer/providers/orders_providers.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:photo_view/photo_view.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import 'package:bizorganizer/models/job_history_entry.dart';
import 'package:bizorganizer/models/cargo_job.dart';
import 'package:bizorganizer/models/status_constants.dart';
import 'package:bizorganizer/utils/us_states_data.dart'; // Added import

class JobDetails extends StatefulWidget {
  final Map<String, dynamic> job;

  const JobDetails({super.key, required this.job});

  @override
  State<JobDetails> createState() => _JobDetailsState();
}

class _JobDetailsState extends State<JobDetails> {
  late String currentActualDeliveryStatus;
  late String currentActualPaymentStatus;
  late String prevDelivStatus;
  late String prevPayStatus;

  List<JobHistoryEntry> _historyEntries = [];
  bool _isLoadingHistory = true;

  final NumberFormat currencyFormatter =
      NumberFormat.currency(locale: 'en_US', symbol: '\$');

  // Task 2.2: Update userSelectableDeliveryStatuses
  final List<DeliveryStatus> userSelectableDeliveryStatuses = [
    DeliveryStatus.Scheduled,
    DeliveryStatus.Delivered,
    DeliveryStatus.Cancelled,
    DeliveryStatus.Delayed
  ];

  // Payment status options remain broader as per previous implementation, not changed by this task
  final List<PaymentStatus> userSelectablePaymentStatuses = [
    PaymentStatus.Pending,
    PaymentStatus.Paid,
    PaymentStatus.Refunded,
  ];

  @override
  void initState() {
    super.initState();
    DeliveryStatus? initialDeliveryEnum =
        deliveryStatusFromString(widget.job['delivery_status']?.toString());
    currentActualDeliveryStatus = (initialDeliveryEnum != null
            ? deliveryStatusToString(initialDeliveryEnum)
            : deliveryStatusToString(DeliveryStatus.Scheduled))
        .toLowerCase();

    PaymentStatus? initialPaymentEnum =
        paymentStatusFromString(widget.job['payment_status']?.toString());

    currentActualPaymentStatus = (initialPaymentEnum != null
            ? paymentStatusToString(initialPaymentEnum)
            : paymentStatusToString(PaymentStatus.Pending))
        .toLowerCase();
    prevDelivStatus = currentActualDeliveryStatus;
    prevPayStatus = currentActualPaymentStatus;
    _fetchHistory();
  }

  Future<void> _fetchHistory() async {
    if (!mounted) return;
    setState(() {
      _isLoadingHistory = true;
    });
    final jobId = widget.job['id'] as String?;
    if (jobId == null) {
      setState(() {
        _isLoadingHistory = false;
        print("Job ID is null, cannot fetch history.");
      });
      return;
    }
    try {
      final entries =
          await context.read<CargoJobProvider>().fetchJobHistory(jobId);
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

  String _getFullStateName(String? abbr) {
    if (abbr == null || abbr.isEmpty) return 'N/A';
    try {
      final state = usStatesAndAbbreviations.firstWhere(
        (s) => s.abbr.toLowerCase() == abbr.toLowerCase(),
      );
      return state.name;
    } catch (e) {
      // Catches if not found by firstWhere or other errors
      return abbr; // Return the original abbreviation if not found or on error
    }
  }

  TableRow _buildTableRow(String label, String value,
      {bool isMultiline = false}) {
    return TableRow(
      children: [
        TableCell(
          verticalAlignment: TableCellVerticalAlignment.top,
          child: Padding(
            padding: const EdgeInsets.all(8.0),
            child: Text(label,
                style: const TextStyle(
                    fontWeight: FontWeight.bold, color: Colors.white70)),
          ),
        ),
        TableCell(
          verticalAlignment: TableCellVerticalAlignment.top,
          child: Padding(
            padding: const EdgeInsets.all(8.0),
            child: Text(value,
                style: TextStyle(
                    color: Colors.white, height: isMultiline ? 1.5 : null)),
          ),
        ),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    final jobProvider = Provider.of<CargoJobProvider>(context);
    final CargoJob cargoJobInstance = CargoJob.fromJson(widget.job);

    String displayEffectiveDeliveryStatus =
        cargoJobInstance.effectiveDeliveryStatus ??
            deliveryStatusToString(DeliveryStatus.Scheduled);

    return Scaffold(
      appBar: AppBar(
        title: Text('Job Details',
            style: TextStyle(color: Theme.of(context).colorScheme.onPrimary)),
        centerTitle: true,
        backgroundColor: Theme.of(context).colorScheme.primary,
        iconTheme:
            IconThemeData(color: Theme.of(context).colorScheme.onPrimary),
        actions: [
          IconButton(
            icon: const Icon(Icons.delete, color: Colors.redAccent),
            onPressed:
                _confirmDeleteJob, // Call the new delete confirmation method
          ),
        ],
      ),
      body: SafeArea(
        child: CustomScrollView(
          slivers: [
            if (cargoJobInstance.receiptUrl != null &&
                cargoJobInstance.receiptUrl!.isNotEmpty)
              SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('Receipt:',
                          style: Theme.of(context)
                              .textTheme
                              .titleLarge
                              ?.copyWith(color: Colors.white70)),
                      const SizedBox(height: 10),
                      InkWell(
                          onTap: () => Navigator.of(context).push(
                              MaterialPageRoute(
                                  builder: (_) => FullScreenImage(
                                      imageUrl: cargoJobInstance.receiptUrl!))),
                          child: Hero(
                              tag: cargoJobInstance.receiptUrl!,
                              child: CacheImage(
                                  imageUrl: cargoJobInstance.receiptUrl!)))
                    ],
                  ),
                ),
              ),
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Table(
                  border: TableBorder.all(
                      color: Colors.grey.shade700,
                      borderRadius: BorderRadius.circular(8)),
                  columnWidths: const {
                    0: FixedColumnWidth(140),
                    1: FlexColumnWidth(),
                  },
                  children: [
                    _buildTableRow(
                        'Shipper Name:', cargoJobInstance.shipperName ?? 'N/A'),
                    _buildTableRow(
                        'Pickup Date:',
                        _formatDate(
                            cargoJobInstance.pickupDate?.toIso8601String(),
                            includeTime: false)),
                    _buildTableRow('Pickup Location:',
                        _getFullStateName(cargoJobInstance.pickupLocation)),
                    _buildTableRow('Dropoff Location:',
                        _getFullStateName(cargoJobInstance.dropoffLocation)),
                    _buildTableRow(
                        'Est. Delivery Date:',
                        _formatDate(
                            cargoJobInstance.estimatedDeliveryDate
                                ?.toIso8601String(),
                            includeTime: false)),
                    _buildTableRow(
                        'Actual Delivery Date:',
                        _formatDate(
                            cargoJobInstance.actualDeliveryDate
                                ?.toIso8601String(),
                            includeTime: false)),
                    _buildTableRow(
                        'Agreed Price:',
                        currencyFormatter
                            .format(cargoJobInstance.agreedPrice ?? 0.00)),
                    _buildTableRow('Payment Status:',
                        currentActualPaymentStatus.toUpperCase()),
                    _buildTableRow('Effective Delivery Status:',
                        displayEffectiveDeliveryStatus.toUpperCase()),
                    _buildTableRow('Actual Delivery Status:',
                        currentActualDeliveryStatus.toUpperCase()),
                    _buildTableRow('Notes:', cargoJobInstance.notes ?? 'N/A',
                        isMultiline: true),
                    _buildTableRow(
                        'Updated At:',
                        _formatDate(
                            cargoJobInstance.updatedAt?.toIso8601String())),
                  ],
                ),
              ),
            ),
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(16.0, 16.0, 16.0, 8.0),
                child: Text('Update Delivery Status:',
                    style: Theme.of(context)
                        .textTheme
                        .titleMedium
                        ?.copyWith(color: Colors.white70)),
              ),
            ),
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 12.0),
                child: Wrap(
                  spacing: 8.0,
                  runSpacing: 4.0,
                  children: userSelectableDeliveryStatuses.map((statusEnum) {
                    final statusStr = deliveryStatusToString(statusEnum);
                    return ChoiceChip(
                      label: Text(statusStr.toUpperCase(),
                          style: TextStyle(
                              color: currentActualDeliveryStatus ==
                                      statusStr.toLowerCase()
                                  ? Colors.black
                                  : Colors.white)),
                      selected: currentActualDeliveryStatus ==
                          statusStr.toLowerCase(),
                      onSelected: (selected) async {
                        // Made async
                        if (selected) {
                          try {
                            await jobProvider.updateJobDeliveryStatus(
                                cargoJobInstance.id!.toString(), statusStr);
                            if (mounted) {
                              prevDelivStatus = currentActualDeliveryStatus;
                              setState(() {
                                currentActualDeliveryStatus =
                                    statusStr.toLowerCase();
                              });
                              _fetchHistory(); // Added history refresh
                              ScaffoldMessenger.of(context).showSnackBar(
                                SnackBar(
                                    content: Text(
                                        'Delivery status updated to ${statusStr.toUpperCase()}'),
                                    backgroundColor: Colors.green),
                              );
                            }
                          } catch (e) {
                            if (mounted) {
                              ScaffoldMessenger.of(context).showSnackBar(
                                SnackBar(
                                  content: Text(
                                      'Error updating delivery status: $e'),
                                  backgroundColor: Colors.red,
                                ),
                              );
                              setState(() {
                                currentActualDeliveryStatus =
                                    prevDelivStatus.toLowerCase();
                              });
                            }
                          }
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
                child: Text('Update Payment Status:',
                    style: Theme.of(context)
                        .textTheme
                        .titleMedium
                        ?.copyWith(color: Colors.white70)),
              ),
            ),
            SliverToBoxAdapter(
              child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 12.0),
                  child: Wrap(
                    spacing: 8.0,
                    runSpacing: 4.0,
                    children: userSelectablePaymentStatuses.map((statusEnum) {
                      final statusStr = paymentStatusToString(statusEnum);
                      return ChoiceChip(
                        label: Text(statusStr.toUpperCase(),
                            style: TextStyle(
                                color: currentActualPaymentStatus ==
                                        statusStr.toLowerCase()
                                    ? Colors.black
                                    : Colors.white)),
                        selected: currentActualPaymentStatus ==
                            statusStr.toLowerCase(),
                        onSelected: (selected) async {
                          if (selected) {
                            try {
                              if (mounted) {
                                prevPayStatus = currentActualPaymentStatus;
                                setState(() {
                                  currentActualPaymentStatus =
                                      statusStr.toLowerCase();
                                });
                              }
                              await jobProvider.updateJobPaymentStatus(
                                  cargoJobInstance.id!.toString(),
                                  statusStr); // Fixed ID type
                              _fetchHistory(); // Added history refresh
                              ScaffoldMessenger.of(context).showSnackBar(
                                SnackBar(
                                    content: Text(
                                        'Payment status updated to ${statusStr.toUpperCase()}'),
                                    backgroundColor: Colors.green),
                              );
                            } catch (e) {
                              if (mounted) {
                                ScaffoldMessenger.of(context).showSnackBar(
                                  SnackBar(
                                    content: Text(
                                        'Error updating payment status: $e'),
                                    backgroundColor: Colors.red,
                                  ),
                                );
                                currentActualPaymentStatus = prevPayStatus;
                              }
                            }
                          }
                        },
                        selectedColor: Theme.of(context).colorScheme.secondary,
                        backgroundColor: Colors.grey.shade700,
                      );
                    }).toList(),
                  )),
            ),
            const SliverToBoxAdapter(child: SizedBox(height: 20)),
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(16.0, 16.0, 16.0, 8.0),
                child: Text('Job History',
                    style: Theme.of(context)
                        .textTheme
                        .titleLarge
                        ?.copyWith(color: Colors.white)),
              ),
            ),
            _isLoadingHistory
                ? const SliverToBoxAdapter(
                    child: Center(
                        child: Padding(
                            padding: EdgeInsets.all(16.0),
                            child: CircularProgressIndicator())))
                : _historyEntries.isEmpty
                    ? const SliverToBoxAdapter(
                        child: Padding(
                          padding: EdgeInsets.all(16.0),
                          child: Center(
                              child: Text('No history found for this job.',
                                  style: TextStyle(color: Colors.white70))),
                        ),
                      )
                    : SliverList(
                        delegate: SliverChildBuilderDelegate(
                          (context, index) {
                            final entry = _historyEntries[index];
                            return Card(
                              color: Colors.grey.shade800,
                              margin: const EdgeInsets.symmetric(
                                  horizontal: 16.0, vertical: 4.0),
                              child: ListTile(
                                title: Text(
                                  'Field: ${entry.fieldChanged?.replaceAll('_', ' ').toUpperCase() ?? 'N/A'}',
                                  style: const TextStyle(
                                      fontWeight: FontWeight.bold,
                                      color: Colors.white),
                                ),
                                subtitle: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                        'Old Value: ${entry.oldValue ?? 'N/A'}',
                                        style: const TextStyle(
                                            color: Colors.white70,
                                            fontSize: 12)),
                                    Text(
                                        'New Value: ${entry.newValue ?? 'N/A'}',
                                        style: const TextStyle(
                                            color: Colors.white70,
                                            fontSize: 12)),
                                    const SizedBox(height: 4),
                                    Text(
                                        'Changed At: ${_formatDate(entry.changedAt)}',
                                        style: const TextStyle(
                                            color: Colors.grey, fontSize: 10)),
                                    Text(
                                        'Changed By: ${entry.changedBy ?? 'N/A'}',
                                        style: const TextStyle(
                                            color: Colors.grey, fontSize: 10)),
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

  Future<void> _confirmDeleteJob() async {
    final TextEditingController deleteConfirmController = TextEditingController();
    final GlobalKey<FormFieldState<String>> confirmKey = GlobalKey<FormFieldState<String>>();

    return showDialog<void>(
      context: context,
      barrierDismissible: false, // User must tap button!
      builder: (BuildContext dialogContext) {
        // Use a single StatefulBuilder for the dialog's interactive parts
        return StatefulBuilder(
          builder: (BuildContext context, StateSetter setState) {
            final bool isButtonEnabled = deleteConfirmController.text.trim().toLowerCase() == 'delete this';

            return AlertDialog(
              title: const Text('Confirm Deletion'),
              content: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: <Widget>[
                  const Text("To delete this job, please type 'delete this' in the box below."),
                  const SizedBox(height: 16),
                  TextFormField(
                    key: confirmKey,
                    controller: deleteConfirmController,
                    decoration: const InputDecoration(
                      labelText: "Type 'delete this'",
                      border: OutlineInputBorder(),
                    ),
                    autofocus: true,
                    onChanged: (text) {
                      // This setState will rebuild the AlertDialog via the common StatefulBuilder
                      setState(() {});
                      // Optionally, trigger validation if you want live error messages
                      confirmKey.currentState?.validate();
                    },
                    validator: (value) {
                      if (value?.trim().toLowerCase() != 'delete this') {
                        return "Text does not match 'delete this'.";
                      }
                      return null;
                    },
                    // autovalidateMode: AutovalidateMode.onUserInteraction, // Alternative to manual validate
                  ),
                ],
              ),
              actions: <Widget>[
                TextButton(
                  child: const Text('Cancel'),
                  onPressed: () {
                    Navigator.of(dialogContext).pop();
                  },
                ),
                TextButton(
                  child: Text('Confirm Delete',
                      style: TextStyle(
                          color: isButtonEnabled
                              ? const Color.fromARGB(255, 255, 82, 82) // More prominent red for enabled
                              : Theme.of(context).disabledColor)), // Use theme's disabled color
                  onPressed: isButtonEnabled
                      ? () async {
                          final String? jobId = widget.job['id'] as String?;
                          if (jobId != null) {
                            try {
                              final provider = Provider.of<CargoJobProvider>(
                                  this.context, // Refers to _JobDetailsState's context
                                  listen: false);
                              await provider.removeJob(jobId);

                              Navigator.of(dialogContext).pop(); // Close the dialog
                              if (mounted) { // Check mount status of _JobDetailsState
                                Navigator.of(this.context).pop(true); // Pop JobDetails screen
                                ScaffoldMessenger.of(this.context).showSnackBar(
                                  const SnackBar(
                                      content: Text('Job deleted successfully'),
                                      backgroundColor: Colors.green),
                                );
                              }
                            } catch (e) {
                              Navigator.of(dialogContext).pop(); // Close the dialog
                               if (mounted) { // Check mount status of _JobDetailsState
                                ScaffoldMessenger.of(this.context).showSnackBar(
                                  SnackBar(
                                      content: Text('Error deleting job: $e'),
                                      backgroundColor: Colors.red),
                                );
                              }
                            }
                          } else {
                            Navigator.of(dialogContext).pop(); // Close the dialog
                            if (mounted) { // Check mount status of _JobDetailsState
                              ScaffoldMessenger.of(this.context).showSnackBar(
                                const SnackBar(
                                    content: Text('Error: Job ID not found.'),
                                    backgroundColor: Colors.red),
                              );
                            }
                          }
                        }
                      : null, // Button is disabled if condition is not met
                ),
              ],
            );
          }
        );
      },
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
            if (details.primaryVelocity != null &&
                details.primaryVelocity!.abs() > 200) {
              Navigator.pop(context);
            }
          },
          child: PhotoView(
            backgroundDecoration:
                const BoxDecoration(color: Colors.transparent),
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
