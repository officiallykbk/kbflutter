import 'package:bizorganizer/main.dart';
import 'package:bizorganizer/models/reusables.dart';
import 'package:bizorganizer/models/cargo_job.dart'; // Updated import
import 'package:bizorganizer/providers/orders_providers.dart'; 
import 'package:flutter/material.dart';
import 'package:intl/intl.dart'; 
import 'package:image_picker/image_picker.dart';
import 'dart:io';
import 'package:provider/provider.dart';

const List<String> usStates = [
  "Alabama", "Alaska", "Arizona", "Arkansas", "California", "Colorado",
  "Connecticut", "Delaware", "Florida", "Georgia", "Hawaii", "Idaho",
  "Illinois", "Indiana", "Iowa", "Kansas", "Kentucky", "Louisiana",
  "Maine", "Maryland", "Massachusetts", "Michigan", "Minnesota",
  "Mississippi", "Missouri", "Montana", "Nebraska", "Nevada",
  "New Hampshire", "New Jersey", "New Mexico", "New York",
  "North Carolina", "North Dakota", "Ohio", "Oklahoma", "Oregon",
  "Pennsylvania", "Rhode Island", "South Carolina", "South Dakota",
  "Tennessee", "Texas", "Utah", "Vermont", "Virginia", "Washington",
  "West Virginia", "Wisconsin", "Wyoming"
];

// Delivery Status Options
const List<String> deliveryStatusOptions = [
  'pending', 'in progress', 'completed', 'cancelled', 'onhold', 'rejected'
];


class AddJob extends StatefulWidget { // Renamed class
  final CargoJob? job; // To pass for editing
  final bool isEditing;

  const AddJob({Key? key, this.job, this.isEditing = false}) : super(key: key); // Updated constructor

  @override
  State<AddJob> createState() => _AddJobState(); 
}

class _AddJobState extends State<AddJob> { 
  final _formKey = GlobalKey<FormState>();
  
  // Dates
  DateTime? _pickupDate;
  DateTime? _estimatedDeliveryDate;
  DateTime? _actualDeliveryDate;

  String _selectedPaymentStatus = 'pending'; 
  String _selectedDeliveryStatus = 'pending'; // Default delivery status
  String? _imageUrl;
  bool _isPickingImage = false;

  late TextEditingController _shipperNameController; // Renamed from _clientController
  // _clientNumberController and _clientEmailController removed as per CargoJob model
  late TextEditingController _agreedPriceController; // Renamed from _amountController
  late TextEditingController _notesController; // Renamed from _descriptionController
  late TextEditingController _pictureNameController; 

  String? _selectedPickupLocationState; // Renamed from _selectedOriginState
  String? _selectedDropoffLocationState; // Renamed from _selectedDestinationState

  final picker = ImagePicker();

  @override
  void initState() {
    super.initState();
    _shipperNameController = TextEditingController();
    _agreedPriceController = TextEditingController();
    _notesController = TextEditingController();
    _pictureNameController = TextEditingController();

    if (widget.isEditing && widget.job != null) {
      final job = widget.job!;
      _shipperNameController.text = job.shipperName ?? '';
      _agreedPriceController.text = job.agreedPrice?.toString() ?? '';
      _notesController.text = job.notes ?? '';
      _imageUrl = job.receiptUrl;
      
      if (job.pickupDate != null && job.pickupDate!.isNotEmpty) {
        _pickupDate = DateTime.tryParse(job.pickupDate!);
      }
      if (job.estimatedDeliveryDate != null && job.estimatedDeliveryDate!.isNotEmpty) {
        _estimatedDeliveryDate = DateTime.tryParse(job.estimatedDeliveryDate!);
      }
      if (job.actualDeliveryDate != null && job.actualDeliveryDate!.isNotEmpty) {
        _actualDeliveryDate = DateTime.tryParse(job.actualDeliveryDate!);
      }

      _selectedPickupLocationState = usStates.contains(job.pickupLocation) ? job.pickupLocation : null;
      _selectedDropoffLocationState = usStates.contains(job.dropoffLocation) ? job.dropoffLocation : null;
      
      _selectedPaymentStatus = job.paymentStatus?.toLowerCase() ?? 'pending';
      _selectedDeliveryStatus = job.deliveryStatus?.toLowerCase() ?? 'pending';
    } else {
      // Set default for pickupDate if not editing
      _pickupDate = DateTime.now();
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
      await supabase.storage.from('BizBucket').upload(path, image);
      
      if (!mounted) return;
      CustomSnackBar.show(context, 'Image Uploaded', Icons.check);
      setState(() {
        _imageUrl = supabase.storage.from('BizBucket').getPublicUrl(path);
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
        _pickupDate = DateTime.now(); // Reset to now for new entries
        _estimatedDeliveryDate = null;
        _actualDeliveryDate = null;
        _selectedPaymentStatus = 'pending';
        _selectedDeliveryStatus = 'pending';
        _selectedPickupLocationState = null;
        _selectedDropoffLocationState = null;
      });
    }
  }

  Future<void> _saveOrUpdateJob() async { 
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
      id: widget.isEditing ? widget.job!.id : null, // Set ID if editing
      shipperName: capitalizeEachWord(_shipperNameController.text),
      receiptUrl: _imageUrl, 
      pickupDate: _pickupDate != null ? DateFormat('yyyy-MM-ddTHH:mm:ss').format(_pickupDate!) : null,
      estimatedDeliveryDate: _estimatedDeliveryDate != null ? DateFormat('yyyy-MM-ddTHH:mm:ss').format(_estimatedDeliveryDate!) : null,
      actualDeliveryDate: _actualDeliveryDate != null ? DateFormat('yyyy-MM-ddTHH:mm:ss').format(_actualDeliveryDate!) : null,
      pickupLocation: _selectedPickupLocationState, 
      dropoffLocation: _selectedDropoffLocationState, 
      agreedPrice: double.tryParse(_agreedPriceController.text) ?? 0.0, 
      paymentStatus: _selectedPaymentStatus.toLowerCase(), 
      deliveryStatus: _selectedDeliveryStatus.toLowerCase(),
      notes: _notesController.text,
      // created_by and updated_at will be handled by Supabase or provider logic
    );

    try {
      final provider = context.read<CargoJobProvider>();
      if (widget.isEditing) {
        await provider.editJob(jobData.id!, jobData); // Pass jobData directly
        if(mounted) CustomSnackBar.show(context, 'Job updated successfully', Icons.check);
      } else {
        await provider.addJob(jobData);
        if(mounted) CustomSnackBar.show(context, 'Job added successfully', Icons.check);
      }
      if(mounted) Navigator.of(context).pop(true); // Pop screen on success, pass true
    } catch (e) {
      print('Error saving/updating job: $e');
      if(mounted) CustomSnackBar.show(context, 'Failed to save job: $e', Icons.error, backgroundColor: Colors.red);
    }
  }


  @override
  Widget build(BuildContext context) {
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
                      TextInputField( 
                        controller: _shipperNameController,
                        label: 'Shipper Name', 
                        icon: Icons.person,
                        inputType: TextInputType.name,
                        validator: (value) {
                          if (value == null || value.isEmpty) {
                            return 'Please enter shipper name';
                          } else if (value.length < 3) {
                            return 'Name must be at least 3 characters';
                          }
                          return null;
                        },
                      ),
                      const SizedBox(height: 16),
                      // Client Number and Email fields are removed as they are not in CargoJob
                      
                      // Pickup Date
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
                      // Estimated Delivery Date
                      DateSelectWidget(
                        label: "Est. Delivery Date (Optional)",
                        selectedDate: _estimatedDeliveryDate,
                        onDateSelected: (date) {
                          setState(() {
                            _estimatedDeliveryDate = date;
                          });
                        },
                        isOptional: true,
                      ),
                      const SizedBox(height: 16),
                      // Actual Delivery Date
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
                      DropdownButtonFormField<String>(
                        decoration: _inputDecoration('Pickup Location (State)', Icons.place_rounded),
                        dropdownColor: Colors.grey.shade800,
                        style: const TextStyle(color: Colors.white),
                        value: _selectedPickupLocationState,
                        items: usStates.map((String value) {
                          return DropdownMenuItem<String>(value: value, child: Text(value));
                        }).toList(),
                        onChanged: (String? newValue) {
                          setState(() { _selectedPickupLocationState = newValue; });
                        },
                        validator: (value) => value == null ? 'Please select a pickup state' : null,
                      ),
                      const SizedBox(height: 16),
                      DropdownButtonFormField<String>(
                        decoration: _inputDecoration('Dropoff Location (State)', Icons.place_rounded),
                        dropdownColor: Colors.grey.shade800,
                        style: const TextStyle(color: Colors.white),
                        value: _selectedDropoffLocationState,
                        items: usStates.map((String value) {
                          return DropdownMenuItem<String>(value: value, child: Text(value));
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
                      // Delivery Status Dropdown
                      DropdownButtonFormField<String>(
                        decoration: _inputDecoration('Delivery Status', Icons.local_shipping),
                        dropdownColor: Colors.grey.shade800,
                        style: const TextStyle(color: Colors.white),
                        value: _selectedDeliveryStatus,
                        items: deliveryStatusOptions.map((String value) {
                          return DropdownMenuItem<String>(value: value, child: Text(value.toUpperCase()));
                        }).toList(),
                        onChanged: (String? newValue) {
                          setState(() { _selectedDeliveryStatus = newValue ?? 'pending'; });
                        },
                        validator: (value) => value == null ? 'Please select a delivery status' : null,
                      ),
                      const SizedBox(height: 16),
                      PaymentStatusWidget( // This is already a custom widget
                        selectedStatus: _selectedPaymentStatus,
                        onStatusSelected: (status) {
                           setState(() { _selectedPaymentStatus = status; });
                        },
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
                        onPressed: _saveOrUpdateJob, // Updated method call
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

// Generic Date Selection Widget
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
      firstDate: DateTime(2000), // Adjust as needed
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
        ? IconButton(icon: Icon(Icons.clear, color: Colors.redAccent), onPressed: () => onDateSelected(DateTime(0))) // Special value to clear
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

  const PaymentStatusWidget({
    Key? key,
    required this.selectedStatus,
    required this.onStatusSelected,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return ListTile(
      title: const Text("Payment Status", style: TextStyle(fontSize: 16, color: Colors.white70)),
      contentPadding: const EdgeInsets.symmetric(vertical: 5, horizontal: 10), 
      tileColor: Colors.grey.shade800,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(10),
        side: BorderSide(color: Colors.grey.shade700),
      ),
      subtitle: Row(
        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
        children: ['pending', 'paid', 'overdue', 'refunded'].map((status) { // Added 'refunded'
          bool isSelected = selectedStatus.toLowerCase() == status; // Ensure case-insensitive comparison
          return ChoiceChip(
            label: Text(status.toUpperCase(), style: TextStyle(color: isSelected ? Colors.black : Colors.white70)),
            selected: isSelected,
            onSelected: (selected) {
              if (selected) onStatusSelected(status);
            },
            selectedColor: Colors.amber,
            backgroundColor: Colors.grey.shade700,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20), side: BorderSide(color: isSelected ? Colors.amber : Colors.grey.shade600)),
          );
        }).toList(),
      ),
    );
  }
}
