import 'package:bizorganizer/main.dart';
import 'package:bizorganizer/models/reusables.dart';
import 'package:bizorganizer/models/cargo_job.dart'; 
import 'package:bizorganizer/providers/orders_providers.dart'; 
import 'package:flutter/material.dart';
import 'package:intl/intl.dart'; 
import 'package:image_picker/image_picker.dart';
import 'dart:io';
import 'package:provider/provider.dart';
import 'package:bizorganizer/models/status_constants.dart';
import 'package:bizorganizer/utils/us_states_data.dart';



class AddJob extends StatefulWidget { 
  final CargoJob? job; 
  final bool isEditing;

  const AddJob({Key? key, this.job, this.isEditing = false}) : super(key: key); 

  @override
  State<AddJob> createState() => _AddJobState(); 
}

class _AddJobState extends State<AddJob> { 
  final _formKey = GlobalKey<FormState>();
  
  DateTime? _pickupDate;
  DateTime? _estimatedDeliveryDate;
  DateTime? _actualDeliveryDate;

  late String _selectedPaymentStatus; 
  late String _selectedDeliveryStatus; 
  String? _imageUrl;
  bool _isPickingImage = false;

  late TextEditingController _shipperNameController;
  late TextEditingController _agreedPriceController;
  late TextEditingController _notesController;
  late TextEditingController _pictureNameController;

  String? _selectedPickupLocationState;
  String? _selectedDropoffLocationState;

  List<String> _customerSuggestions = [];
  bool _isLoadingCustomerNames = false;

  final picker = ImagePicker();

  @override
  void initState() {
    super.initState();
    _shipperNameController = TextEditingController();
    _agreedPriceController = TextEditingController();
    _notesController = TextEditingController();
    _pictureNameController = TextEditingController();

    _loadCustomerNames(); // Call to load customer names

    if (widget.isEditing && widget.job != null) {
      final job = widget.job!;
      _shipperNameController.text = job.shipperName ?? '';
      _agreedPriceController.text = job.agreedPrice?.toString() ?? '';
      _notesController.text = job.notes ?? '';
      _imageUrl = job.receiptUrl;
      
      _pickupDate = job.pickupDate; 
      _estimatedDeliveryDate = job.estimatedDeliveryDate; 
      _actualDeliveryDate = job.actualDeliveryDate; 

      // Assuming job.pickupLocation and job.dropoffLocation store abbreviations
      if (job.pickupLocation != null && usStatesAndAbbreviations.any((s) => s.abbr == job.pickupLocation)) {
        _selectedPickupLocationState = job.pickupLocation;
      } else {
         _selectedPickupLocationState = null; 
      }

      if (job.dropoffLocation != null && usStatesAndAbbreviations.any((s) => s.abbr == job.dropoffLocation)) {
        _selectedDropoffLocationState = job.dropoffLocation;
      } else {
        _selectedDropoffLocationState = null;
      }
      
      _selectedPaymentStatus = job.paymentStatus ?? paymentStatusToString(PaymentStatus.Pending);
      
      DeliveryStatus? initialDeliveryStatusEnum = deliveryStatusFromString(job.deliveryStatus);
      _selectedDeliveryStatus = initialDeliveryStatusEnum != null 
                               ? deliveryStatusToString(initialDeliveryStatusEnum) 
                               : deliveryStatusToString(DeliveryStatus.Scheduled);

    } else {
      _pickupDate = DateTime.now();
      _selectedDeliveryStatus = deliveryStatusToString(DeliveryStatus.Scheduled);
      _selectedPaymentStatus = paymentStatusToString(PaymentStatus.Pending);
    }
  }

  Future<void> _loadCustomerNames() async {
    if (!mounted) return;
    setState(() {
      _isLoadingCustomerNames = true;
    });
    try {
      final provider = context.read<CargoJobProvider>();
      final names = await provider.fetchUniqueCustomerNames();
      if (!mounted) return;
      setState(() {
        _customerSuggestions = names;
      });
    } catch (e) {
      print('Error loading customer names: $e');
      if (mounted) {
        CustomSnackBar.show(context, 'Error loading customer names: $e', Icons.error, backgroundColor: Colors.red);
      }
    } finally {
      if (mounted) {
        setState(() {
          _isLoadingCustomerNames = false;
        });
      }
    }
  }

  @override
  void dispose() {
    _shipperNameController.dispose();
    _agreedPriceController.dispose();
    _notesController.dispose();
    _pictureNameController.dispose();
    super.dispose();
  }

  Future<void> _getImageGallery(ImageSource imgSource, String imgName) async {
    if (!mounted) return;
    setState(() {
      _isPickingImage = true;
    });
    try {
      final pickedFile = await picker.pickImage(source: imgSource);
      if (pickedFile != null) {
        await _uploadImageToSupabase(File(pickedFile.path), imgName);
      }
    } catch (e) {
      print('Failed to pick image: $e');
      if (mounted) {
        CustomSnackBar.show(context, 'Failed to pick image: $e', Icons.error, backgroundColor: Colors.red);
      }
    } finally {
      if (mounted) {
        setState(() {
          _isPickingImage = false;
        });
      }
    }
  }

  Future<void> _uploadImageToSupabase(File image, String imgName) async {
    try {
      final String path = 'images/$imgName--${DateTime.now().toIso8601String()}.png';
      await supabase.storage.from('receipts').upload(path, image);

      if (!mounted) return;
      CustomSnackBar.show(context, 'Image Uploaded', Icons.check);
      setState(() {
        _imageUrl = supabase.storage.from('receipts').getPublicUrl(path);
      });
    } catch (e) {
      print('Failed to upload image: $e');
      if (mounted) {
         CustomSnackBar.show(context, 'Failed to Upload Image', Icons.error, backgroundColor: Colors.red);
      }
    }
  }

  void _clearFields() {
    _shipperNameController.clear();
    _agreedPriceController.clear();
    _notesController.clear();
    _pictureNameController.clear(); 
    if (mounted) {
      setState(() {
        _imageUrl = null; 
        _pickupDate = DateTime.now(); 
        _estimatedDeliveryDate = null;
        _actualDeliveryDate = null;
        _selectedPaymentStatus = paymentStatusToString(PaymentStatus.Pending);
        _selectedDeliveryStatus = deliveryStatusToString(DeliveryStatus.Scheduled);
        _selectedPickupLocationState = null;
        _selectedDropoffLocationState = null;
      });
    }
  }

  Future<void> _proceedWithSavingJob() async {
    if (!_formKey.currentState!.validate()) {
      CustomSnackBar.show(context, 'Please fix errors in the form.', Icons.error, backgroundColor: Colors.orange);
      return;
    }

    String capitalizeFirst(String input) {
      if (input.isEmpty) return input;
      return input[0].toUpperCase() + input.substring(1).toLowerCase();
    }

    String capitalizeEachWord(String input) {
      if (input.isEmpty) return input;
      return input
          .split(' ')
          .map((word) => word.isNotEmpty ? capitalizeFirst(word) : word)
          .join(' ');
    }

    final jobData = CargoJob(
      id: widget.isEditing ? widget.job!.id : null,
      shipperName: capitalizeEachWord(_shipperNameController.text),
      receiptUrl: _imageUrl,
      pickupDate: _pickupDate,
      estimatedDeliveryDate: _estimatedDeliveryDate,
      actualDeliveryDate: _actualDeliveryDate,
      pickupLocation: _selectedPickupLocationState,
      dropoffLocation: _selectedDropoffLocationState,
      agreedPrice: double.tryParse(_agreedPriceController.text) ?? 0.0,
      paymentStatus: _selectedPaymentStatus,
      deliveryStatus: _selectedDeliveryStatus,
      notes: _notesController.text,
      // Attempt to set createdBy if user is available.
      // Supabase policies should ideally handle setting this based on auth.uid() if this is null.
      createdBy: supabase.auth.currentUser?.id,
    );

    try {
      final provider = context.read<CargoJobProvider>();
      if (widget.isEditing) {
        // await provider.editJob(jobData.id!, jobData);
        if (mounted) CustomSnackBar.show(context, 'Job updated successfully', Icons.check);
      } else {
        await provider.addJob(jobData);
        if (mounted) CustomSnackBar.show(context, 'Job added successfully', Icons.check);
      }
      if (mounted) Navigator.of(context).pop(true); // Pop AddJob screen
    } catch (e) {
      print('Error saving/updating job: $e');
      if (mounted) CustomSnackBar.show(context, 'Failed to save job: $e', Icons.error, backgroundColor: Colors.red);
    }
  }

  Future<void> _saveOrUpdateJob() async {
    if (widget.isEditing == false) {
      // Show confirmation dialog only when creating a new job
      showDialog(
        context: context,
        builder: (BuildContext dialogContext) { // Use a different context name for the dialog
          return AlertDialog(
            title: const Text('Confirm Save'),
            content: const Text('Note: Once a job is created, only the delivery and payment statuses can be edited. Proceed with saving?'),
            actions: <Widget>[
              TextButton(
                child: const Text('Cancel'),
                onPressed: () {
                  Navigator.of(dialogContext).pop(); // Dismiss the dialog
                },
              ),
              TextButton(
                child: const Text('Save'),
                onPressed: () {
                  Navigator.of(dialogContext).pop(); // Dismiss the dialog
                  _proceedWithSavingJob(); // Proceed with saving
                },
              ),
            ],
          );
        },
      );
    } else {
      // If editing, proceed directly
      _proceedWithSavingJob();
    }
  }

  @override
  Widget build(BuildContext context) {
    List<DeliveryStatus> deliveryDropdownItemsEnums;
    if (widget.isEditing) {
      deliveryDropdownItemsEnums = [ 
        DeliveryStatus.Scheduled,
        DeliveryStatus.Delivered,
        DeliveryStatus.Cancelled,
      ];
    } else {
      deliveryDropdownItemsEnums = [DeliveryStatus.Scheduled]; 
    }

    List<PaymentStatus> paymentDropdownItemsEnums = widget.isEditing
        ? [PaymentStatus.Pending, PaymentStatus.Paid, PaymentStatus.Refunded] 
        : [PaymentStatus.Pending, PaymentStatus.Paid]; 

    return Scaffold(
      backgroundColor: const Color(0xFF121212), 
      body: CustomScrollView(
        slivers: [
          SliverAppBar(
            title: Text(widget.isEditing ? 'Edit Job' : 'Create New Job'), 
            centerTitle: true,
            backgroundColor: const Color(0xFF1F1F1F), 
            elevation: 0,
            pinned: true,
          ),
          SliverPadding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            sliver: SliverList(
              delegate: SliverChildListDelegate([
                Form(
                  key: _formKey,
                  child: Column(
                    children: [
                      ListTile(
                        shape: RoundedRectangleBorder(side: BorderSide(color: Colors.grey.shade700), borderRadius: BorderRadius.circular(8)),
                        iconColor: Colors.white,
                        onTap: () {
                          showDialog(
                              context: context,
                              barrierDismissible: true,
                              builder: (context) => AlertDialog(
                                      title: TextFormField(
                                        controller: _pictureNameController,
                                        decoration: InputDecoration(
                                          labelText: 'Enter receipt Name',
                                          border: OutlineInputBorder(
                                            borderRadius: BorderRadius.circular(10),
                                          ),
                                        ),
                                        onFieldSubmitted: (value) async {
                                          Navigator.pop(context);
                                          if (value.isNotEmpty) {
                                            await _getImageGallery(ImageSource.gallery, value);
                                          }
                                        },
                                        style: const TextStyle(fontSize: 18),
                                      ),
                                      content: const Text(
                                        'Give it a name that can be easily referenced.',
                                        style: TextStyle(color: Colors.grey),
                                      ),
                                      actions: [
                                        ElevatedButton(
                                          onPressed: () async {
                                            Navigator.pop(context);
                                            final String enteredName = _pictureNameController.text;
                                            if (enteredName.isNotEmpty) {
                                              await _getImageGallery(ImageSource.gallery, enteredName);
                                            }
                                          },
                                          child: const Text("Get Image"),
                                        ),
                                      ]));
                        },
                        leading: _isPickingImage ? const CircularProgressIndicator() : const Icon(Icons.add_a_photo_sharp),
                        title: Text(
                          _imageUrl == null || _imageUrl!.isEmpty ? 'Pick receipt image' : (_imageUrl!.length > 30 ? '...${_imageUrl!.substring(_imageUrl!.length - 27)}' : _imageUrl!),
                          style: const TextStyle(color: Colors.white70),
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                      const SizedBox(height: 16),
                      // Shipper Name Autocomplete
                      if (_isLoadingCustomerNames)
                        const Padding(
                          padding: EdgeInsets.symmetric(vertical: 16.0),
                          child: Center(child: CircularProgressIndicator()),
                        )
                      else
                        Autocomplete<String>(
                          optionsBuilder: (TextEditingValue textEditingValue) {
                            if (textEditingValue.text.isEmpty) {
                              // Show all suggestions if the text field is empty and has focus, or a subset.
                              // For now, let's show all loaded suggestions.
                              return _customerSuggestions;
                            }
                            return _customerSuggestions.where((String option) {
                              return option.toLowerCase().contains(textEditingValue.text.toLowerCase());
                            });
                          },
                          onSelected: (String selection) {
                            _shipperNameController.text = selection;
                            // Update the Autocomplete's internal controller's text as well,
                            // and move cursor to the end. This is important if the fieldViewBuilder's
                            // controller is different or if you want to ensure UI consistency immediately.
                            // However, with the current fieldViewBuilder, this should be handled.
                            FocusScope.of(context).unfocus(); // Hide keyboard
                          },
                          displayStringForOption: (String option) => option,
                          fieldViewBuilder: (BuildContext context,
                              TextEditingController fieldTextEditingController,
                              FocusNode fieldFocusNode,
                              VoidCallback onFieldSubmitted) {

                            // Sync Autocomplete's internal controller with _shipperNameController when the widget builds/rebuilds
                            // This is important for initial values (e.g., in edit mode)
                            if (_shipperNameController.text != fieldTextEditingController.text) {
                                fieldTextEditingController.text = _shipperNameController.text;
                                // Place cursor at the end
                                fieldTextEditingController.selection = TextSelection.fromPosition(TextPosition(offset: fieldTextEditingController.text.length));
                            }
                            
                            return TextFormField(
                              controller: fieldTextEditingController, // USE Autocomplete's own controller
                              focusNode: fieldFocusNode,
                              decoration: _inputDecoration('Shipper Name (Type or Select)', Icons.person),
                              validator: (value) {
                                // It's better to validate against _shipperNameController.text
                                // as it's the one being updated by `onChanged` and `onSelected`.
                                final textToValidate = _shipperNameController.text;
                                if (textToValidate.isEmpty) {
                                  return 'Please enter shipper name';
                                } else if (textToValidate.length < 3) {
                                  return 'Name must be at least 3 characters';
                                }
                                return null;
                              },
                              onChanged: (text) {
                                // CRUCIAL: Update _shipperNameController whenever the user types
                                // This ensures that if the user types and doesn't select an option,
                                // _shipperNameController (used for saving) still gets the value.
                                _shipperNameController.text = text;
                              },
                              onFieldSubmitted: (_) {
                                onFieldSubmitted(); // Standard Autocomplete behavior
                              },
                            );
                          },
                          optionsViewBuilder: (BuildContext context,
                              AutocompleteOnSelected<String> onSelected,
                              Iterable<String> options) {
                            return Align(
                              alignment: Alignment.topLeft,
                              child: Material(
                                elevation: 4.0,
                                color: Colors.grey.shade800, // Theming for options
                                child: ConstrainedBox(
                                  constraints: const BoxConstraints(maxHeight: 250, maxWidth: 300), // Max height and width for options
                                  child: ListView.builder(
                                    padding: EdgeInsets.zero,
                                    shrinkWrap: true, // Important for ConstrainedBox to work correctly with ListView
                                    itemCount: options.length,
                                    itemBuilder: (BuildContext context, int index) {
                                      final String option = options.elementAt(index);
                                      return InkWell(
                                        onTap: () {
                                          onSelected(option);
                                        },
                                        child: Padding(
                                          padding: const EdgeInsets.all(16.0),
                                          child: Text(option, style: const TextStyle(color: Colors.white)), // Theming for option text
                                        ),
                                      );
                                    },
                                  ),
                                ),
                              ),
                            );
                          },
                        ),
                      const SizedBox(height: 16),
                      DateSelectWidget(
                        label: "Pickup Date",
                        selectedDate: _pickupDate,
                        onDateSelected: (date) {
                          setState(() {
                            _pickupDate = date;
                          });
                        },
                      ),
                      const SizedBox(height: 16),
                      DateSelectWidget(
                        label: "Est. Delivery Date",
                        selectedDate: _estimatedDeliveryDate,
                        onDateSelected: (date) {
                          setState(() {
                            _estimatedDeliveryDate = date;
                          });
                        },
                        isOptional: false,
                      ),
                      const SizedBox(height: 16),
                      DateSelectWidget(
                        label: "Actual Delivery Date (Optional)",
                        selectedDate: _actualDeliveryDate,
                        onDateSelected: (date) {
                          setState(() {
                            _actualDeliveryDate = date;
                          });
                        },
                         isOptional: true,
                      ),
                      const SizedBox(height: 16),
                      // Task 4: Update Pickup Location Dropdown
                      DropdownButtonFormField<String>(
                        decoration: _inputDecoration('Pickup Location (State)', Icons.place_rounded),
                        dropdownColor: Colors.grey.shade800,
                        style: const TextStyle(color: Colors.white),
                        value: _selectedPickupLocationState,
                        items: usStatesAndAbbreviations.map((USState state) {
                          return DropdownMenuItem<String>(
                            value: state.abbr, // Value is the abbreviation
                            child: Text(state.name), // Display is the full name
                          );
                        }).toList(),
                        onChanged: (String? newValue) {
                          setState(() { _selectedPickupLocationState = newValue; });
                        },
                        validator: (value) => value == null ? 'Please select a pickup state' : null,
                      ),
                      const SizedBox(height: 16),
                      // Task 4: Update Dropoff Location Dropdown
                      DropdownButtonFormField<String>(
                        decoration: _inputDecoration('Dropoff Location (State)', Icons.place_rounded),
                        dropdownColor: Colors.grey.shade800,
                        style: const TextStyle(color: Colors.white),
                        value: _selectedDropoffLocationState,
                        items: usStatesAndAbbreviations.map((USState state) {
                          return DropdownMenuItem<String>(
                            value: state.abbr, // Value is the abbreviation
                            child: Text(state.name), // Display is the full name
                          );
                        }).toList(),
                        onChanged: (String? newValue) {
                          setState(() { _selectedDropoffLocationState = newValue; });
                        },
                        validator: (value) => value == null ? 'Please select a dropoff state' : null,
                      ),
                      const SizedBox(height: 16),
                      TextInputField(
                        controller: _agreedPriceController,
                        label: 'Agreed Price', 
                        icon: Icons.attach_money_outlined,
                        inputType: TextInputType.number,
                        validator: (value) {
                          if (value == null || value.isEmpty) {
                            return 'Please enter an amount';
                          }
                          if (double.tryParse(value) == null) {
                            return 'Amount can only be number';
                          }
                          return null;
                        },
                      ),
                      const SizedBox(height: 16),
                      // Delivery Status ChoiceChips
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text('Delivery Status:', style: TextStyle(color: Colors.white70, fontSize: 16)),
                          const SizedBox(height: 8),
                          Wrap(
                            spacing: 8.0,
                            runSpacing: 4.0,
                            children: deliveryDropdownItemsEnums.map((DeliveryStatus statusEnum) {
                              final statusStr = deliveryStatusToString(statusEnum);
                              return ChoiceChip(
                                label: Text(statusStr.toUpperCase()),
                                selected: _selectedDeliveryStatus == statusStr,
                                onSelected: (bool selected) {
                                  if (selected) {
                                    setState(() {
                                      _selectedDeliveryStatus = statusStr;
                                    });
                                  }
                                },
                                selectedColor: Theme.of(context).colorScheme.secondary,
                                backgroundColor: Colors.grey.shade700,
                                labelStyle: TextStyle(color: _selectedDeliveryStatus == statusStr ? Colors.black : Colors.white),
                              );
                            }).toList(),
                          ),
                        ],
                      ),
                      const SizedBox(height: 16),
                      // Payment Status ChoiceChips
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text('Payment Status:', style: TextStyle(color: Colors.white70, fontSize: 16)),
                          const SizedBox(height: 8),
                          Wrap(
                            spacing: 8.0,
                            runSpacing: 4.0,
                            children: paymentDropdownItemsEnums.map((PaymentStatus statusEnum) {
                              final statusStr = paymentStatusToString(statusEnum);
                              return ChoiceChip(
                                label: Text(statusStr.toUpperCase()),
                                selected: _selectedPaymentStatus == statusStr,
                                onSelected: (bool selected) {
                                  if (selected) {
                                    setState(() {
                                      _selectedPaymentStatus = statusStr;
                                    });
                                  }
                                },
                                selectedColor: Theme.of(context).colorScheme.secondary,
                                backgroundColor: Colors.grey.shade700,
                                labelStyle: TextStyle(color: _selectedPaymentStatus == statusStr ? Colors.black : Colors.white),
                              );
                            }).toList(),
                          ),
                        ],
                      ),
                      const SizedBox(height: 16),
                      TextInputField(
                        controller: _notesController,
                        label: 'Notes (Optional)', 
                        icon: Icons.description,
                        maxlines: 5,
                        inputType: TextInputType.multiline,
                      ),
                      const SizedBox(height: 32),
                      ElevatedButton(
                        onPressed: _saveOrUpdateJob, 
                        style: ElevatedButton.styleFrom(
                            minimumSize: const Size(double.infinity, 50),
                            backgroundColor: Colors.amber,
                            foregroundColor: Colors.black, 
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                        ),
                        child: Text(widget.isEditing ? 'Update Job' : 'Save Job', style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold)), 
                      ),
                       const SizedBox(height: 20), 
                    ],
                  ),
                )
              ]),
            ),
          ),
        ],
      ),
    );
  }

  InputDecoration _inputDecoration(String label, IconData icon) {
    return InputDecoration(
      labelText: label,
      prefixIcon: Icon(icon, color: Colors.white70),
      border: OutlineInputBorder(borderRadius: BorderRadius.circular(10), borderSide: BorderSide(color: Colors.grey.shade700)),
      enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(10), borderSide: BorderSide(color: Colors.grey.shade700)),
      focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(10), borderSide: BorderSide(color: Colors.amber)),
      filled: true,
      fillColor: Colors.grey.shade800,
      labelStyle: const TextStyle(color: Colors.white70),
    );
  }
}

class TextInputField extends StatelessWidget {
  final String label;
  final IconData icon;
  final TextInputType inputType;
  final TextEditingController controller;
  final int maxlines;
  final String? Function(String?)? validator;

  const TextInputField({
    Key? key,
    required this.label,
    required this.icon,
    required this.inputType,
    required this.controller,
    this.maxlines = 1,
    this.validator,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return TextFormField(
      maxLines: maxlines,
      controller: controller,
      keyboardType: inputType,
      style: const TextStyle(color: Colors.white), 
      decoration: InputDecoration(
        labelText: label,
        labelStyle: const TextStyle(color: Colors.white70),
        prefixIcon: Icon(icon, color: Colors.white70),
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(10), borderSide: BorderSide(color: Colors.grey.shade700)),
        enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(10), borderSide: BorderSide(color: Colors.grey.shade700)),
        focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(10), borderSide: BorderSide(color: Colors.amber)),
        filled: true,
        fillColor: Colors.grey.shade800, 
      ),
      validator: validator,
    );
  }
}

class DateSelectWidget extends StatelessWidget {
  final String label;
  final DateTime? selectedDate;
  final ValueChanged<DateTime> onDateSelected;
  final bool isOptional;

  const DateSelectWidget({
    Key? key,
    required this.label,
    required this.selectedDate,
    required this.onDateSelected,
    this.isOptional = false,
  }) : super(key: key);

  Future<void> _selectDate(BuildContext context) async {
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: selectedDate ?? DateTime.now(),
      firstDate: DateTime(2000), 
      lastDate: DateTime(2101),
    );
    if (picked != null) {
      onDateSelected(picked);
    }
  }

  @override
  Widget build(BuildContext context) {
    return ListTile(
      leading: const Icon(Icons.calendar_today, color: Colors.purpleAccent),
      title: Text(
        "$label: ${selectedDate != null ? DateFormat('MMMM d, yyyy').format(selectedDate!) : 'Not Set'}",
        style: const TextStyle(fontSize: 16, color: Colors.white70),
      ),
      trailing: isOptional && selectedDate != null 
        ? IconButton(icon: const Icon(Icons.clear, color: Colors.redAccent), onPressed: () => onDateSelected(DateTime(0))) 
        : null,
      onTap: () => _selectDate(context),
      tileColor: Colors.grey.shade800, 
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(10),
        side: BorderSide(color: Colors.grey.shade700),
      ),
    );
  }
}


class PaymentStatusWidget extends StatelessWidget { 
  final String selectedStatus;
  final ValueChanged<String> onStatusSelected;
  final bool isEditing; 

  const PaymentStatusWidget({
    Key? key,
    required this.selectedStatus,
    required this.onStatusSelected,
    required this.isEditing, 
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    List<PaymentStatus> items = isEditing
      ? [PaymentStatus.Pending, PaymentStatus.Paid, PaymentStatus.Refunded] 
      : [PaymentStatus.Pending, PaymentStatus.Paid];

    return DropdownButtonFormField<String>(
        decoration: InputDecoration( 
          labelText: "Payment Status",
          prefixIcon: Icon(Icons.payment, color: Colors.white70),
          border: OutlineInputBorder(borderRadius: BorderRadius.circular(10), borderSide: BorderSide(color: Colors.grey.shade700)),
          enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(10), borderSide: BorderSide(color: Colors.grey.shade700)),
          focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(10), borderSide: BorderSide(color: Colors.amber)),
          filled: true,
          fillColor: Colors.grey.shade800,
          labelStyle: const TextStyle(color: Colors.white70),
        ),
        dropdownColor: Colors.grey.shade800,
        style: const TextStyle(color: Colors.white),
        value: selectedStatus,
        items: items.map((PaymentStatus status) { 
          final statusStr = paymentStatusToString(status);
          return DropdownMenuItem<String>(
            value: statusStr,
            child: Text(statusStr.toUpperCase()),
          );
        }).toList(),
        onChanged: (String? newValue) {
           onStatusSelected(newValue ?? paymentStatusToString(PaymentStatus.Pending));
        },
        validator: (value) => value == null || value.isEmpty ? 'Please select a payment status' : null,
      );
  }
}
