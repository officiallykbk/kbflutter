import 'package:bizorganizer/main.dart';
import 'package:bizorganizer/models/reusables.dart';
import 'package:bizorganizer/models/trips.dart';
import 'package:bizorganizer/providers/orders_providers.dart';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'dart:io';
import 'package:provider/provider.dart';

// US States List (as per fallback plan)
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

class AddTrip extends StatefulWidget {
  const AddTrip({Key? key}) : super(key: key);

  @override
  State<AddTrip> createState() => _AddTripState();
}

class _AddTripState extends State<AddTrip> {
  final _formKey = GlobalKey<FormState>();
  DateTime _selectedDate = DateTime.now();
  String _selectedPaymentStatus = 'Pending'; // Default payment status
  String? _imageUrl;
  bool _isPickingImage = false;

  // TextEditingControllers moved into state
  late TextEditingController _clientController;
  late TextEditingController _clientNumberController;
  late TextEditingController _clientEmailController;
  late TextEditingController _amountController;
  late TextEditingController _descriptionController;
  late TextEditingController _pictureNameController; // For naming the receipt image

  // State variables for dropdowns
  String? _selectedOriginState;
  String? _selectedDestinationState;

  final picker = ImagePicker();

  @override
  void initState() {
    super.initState();
    _clientController = TextEditingController();
    _clientNumberController = TextEditingController();
    _clientEmailController = TextEditingController();
    _amountController = TextEditingController();
    _descriptionController = TextEditingController();
    _pictureNameController = TextEditingController();
  }

  @override
  void dispose() {
    // Dispose of the controllers when the widget is disposed
    _clientController.dispose();
    _clientNumberController.dispose();
    _clientEmailController.dispose();
    _amountController.dispose();
    _descriptionController.dispose();
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
    _clientController.clear();
    _clientNumberController.clear();
    _clientEmailController.clear();
    _amountController.clear();
    _descriptionController.clear();
    _pictureNameController.clear(); // Clear the picture name as well
    if (mounted) {
      setState(() {
        _imageUrl = null; // Changed from '' to null
        _selectedDate = DateTime.now();
        _selectedPaymentStatus = 'Pending';
        _selectedOriginState = null;
        _selectedDestinationState = null;
      });
    }
  }

  Future<void> _addTrip() async {
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

    final trip = Trip(
      clientName: capitalizeEachWord(_clientController.text),
      contactNumber: _clientNumberController.text,
      receipt: _imageUrl ?? '', // Use null-aware operator
      date: "${_selectedDate.day}-${_selectedDate.month}-${_selectedDate.year}",
      origin: _selectedOriginState ?? '', // Use selected state
      destination: _selectedDestinationState ?? '', // Use selected state
      amount: double.tryParse(_amountController.text) ?? 0.0,
      paymentStatus: _selectedPaymentStatus.toLowerCase(),
      description: _descriptionController.text,
      // orderStatus is defaulted in the Trip model if not provided
    );

    if (mounted) {
      await context.read<TripsProvider>().addTrip(trip);
      CustomSnackBar.show(context, 'Trip Recorded', Icons.check); // Corrected typo
    }

    print('clearing fields');
    // Delay slightly to allow snackbar to show before form reset potentially rebuilds widget
    Future.delayed(const Duration(milliseconds: 100), () {
      if (mounted) {
        _formKey.currentState?.reset(); // Reset form fields visually
        _clearFields(); // Clear controllers and state variables
      }
    });
  }


  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF121212), // Dark background
      body: CustomScrollView(
        slivers: [
          const SliverAppBar(
            title: Text("Create New Trip"),
            centerTitle: true,
            backgroundColor: Color(0xFF1F1F1F), // Darker app bar
            elevation: 0,
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
                        leading: _isPickingImage ? CircularProgressIndicator() : const Icon(Icons.add_a_photo_sharp),
                        title: Text(
                          _imageUrl == null || _imageUrl!.isEmpty ? 'Pick receipt image' : _imageUrl!,
                          style: const TextStyle(color: Colors.white70),
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                      const SizedBox(height: 16),
                      TextInputField( // Reusable custom widget
                        controller: _clientController,
                        label: 'Client/CompanyName',
                        icon: Icons.person,
                        inputType: TextInputType.name,
                        validator: (value) {
                          if (value == null || value.isEmpty) {
                            return 'Please enter the client or company name';
                          } else if (value.length < 3) {
                            return 'Name must be at least 3 characters';
                          }
                          return null;
                        },
                      ),
                      const SizedBox(height: 16),
                      TextInputField(
                        controller: _clientNumberController,
                        label: 'Client phone number',
                        icon: Icons.phone_android_outlined,
                        inputType: TextInputType.phone,
                        validator: (value) {
                          if (value == null || value.isEmpty) {
                            return 'Please enter a phone number';
                          }
                          return null;
                        },
                      ),
                      const SizedBox(height: 16),
                      TextInputField(
                        controller: _clientEmailController,
                        label: 'Client email address',
                        icon: Icons.email,
                        inputType: TextInputType.emailAddress,
                        validator: (value) {
                          if (value == null || value.isEmpty) {
                            return 'Field can not be empty';
                          }
                          final emailRegex = RegExp(r'^[a-zA-Z0-9._%+-]+@[a-zA-Z0-9.-]+\.[a-zA-Z]{2,}$');
                          if (!emailRegex.hasMatch(value)) {
                            return 'Invalid Email';
                          }
                          return null;
                        },
                      ),
                      const SizedBox(height: 16),
                      CalendarSelectWidget(
                        selectedDate: _selectedDate,
                        onDateSelected: (date) {
                          setState(() {
                            _selectedDate = date;
                          });
                        },
                      ),
                      const SizedBox(height: 16),
                      // Origin Dropdown
                      DropdownButtonFormField<String>(
                        decoration: InputDecoration(
                          labelText: 'Origin State',
                          prefixIcon: Icon(Icons.place_rounded, color: Colors.white),
                          border: OutlineInputBorder(),
                          filled: true,
                          fillColor: Colors.grey.shade800,
                          labelStyle: TextStyle(color: Colors.white70),
                        ),
                        dropdownColor: Colors.grey.shade800,
                        style: TextStyle(color: Colors.white),
                        value: _selectedOriginState,
                        items: usStates.map((String value) {
                          return DropdownMenuItem<String>(
                            value: value,
                            child: Text(value),
                          );
                        }).toList(),
                        onChanged: (String? newValue) {
                          setState(() {
                            _selectedOriginState = newValue;
                          });
                        },
                        validator: (value) => value == null ? 'Please select an origin state' : null,
                      ),
                      const SizedBox(height: 16),
                      // Destination Dropdown
                      DropdownButtonFormField<String>(
                        decoration: InputDecoration(
                          labelText: 'Destination State',
                           prefixIcon: Icon(Icons.place_rounded, color: Colors.white),
                          border: OutlineInputBorder(),
                          filled: true,
                          fillColor: Colors.grey.shade800,
                          labelStyle: TextStyle(color: Colors.white70),
                        ),
                        dropdownColor: Colors.grey.shade800,
                        style: TextStyle(color: Colors.white),
                        value: _selectedDestinationState,
                        items: usStates.map((String value) {
                          return DropdownMenuItem<String>(
                            value: value,
                            child: Text(value),
                          );
                        }).toList(),
                        onChanged: (String? newValue) {
                          setState(() {
                            _selectedDestinationState = newValue;
                          });
                        },
                        validator: (value) => value == null ? 'Please select a destination state' : null,
                      ),
                      const SizedBox(height: 16),
                      TextInputField(
                        controller: _amountController,
                        label: 'Amount',
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
                      PaymentStatusWidget(
                        selectedStatus: _selectedPaymentStatus,
                        onStatusSelected: (status) {
                           setState(() {
                             _selectedPaymentStatus = status;
                           });
                        },
                      ),
                      const SizedBox(height: 16),
                      TextInputField(
                        controller: _descriptionController,
                        label: 'Description (Optional)',
                        icon: Icons.description,
                        maxlines: 5,
                        inputType: TextInputType.multiline,
                        // Validator is optional for description
                      ),
                      const SizedBox(height: 32),
                      ElevatedButton(
                        onPressed: () async {
                          if (_formKey.currentState!.validate()) {
                            await _addTrip();
                          }
                        },
                        style: ElevatedButton.styleFrom(
                            minimumSize: const Size(double.infinity, 50),
                            backgroundColor: Colors.amber,
                            foregroundColor: Colors.black, // Text color for amber button
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                        ),
                        child: const Text("Save Trip", style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                      ),
                       const SizedBox(height: 20), // Padding at the bottom
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
}

// Text Input Field Widget (remains mostly the same, adapted for dark theme)
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
      style: const TextStyle(color: Colors.white), // Text input color
      decoration: InputDecoration(
        labelText: label,
        labelStyle: const TextStyle(color: Colors.white70),
        prefixIcon: Icon(icon, color: Colors.white70),
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(10), borderSide: BorderSide(color: Colors.grey.shade700)),
        enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(10), borderSide: BorderSide(color: Colors.grey.shade700)),
        focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(10), borderSide: BorderSide(color: Colors.amber)),
        filled: true,
        fillColor: Colors.grey.shade800, // Darker field background
      ),
      validator: validator,
    );
  }
}

// Calendar Selection Widget (adapted for state management from parent)
class CalendarSelectWidget extends StatelessWidget {
  final DateTime selectedDate;
  final ValueChanged<DateTime> onDateSelected;

  const CalendarSelectWidget({
    Key? key,
    required this.selectedDate,
    required this.onDateSelected,
  }) : super(key: key);

  Future<void> _selectDate(BuildContext context) async {
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: selectedDate,
      firstDate: DateTime(2015, 8),
      lastDate: DateTime(2101),
    );
    if (picked != null && picked != selectedDate) {
      onDateSelected(picked);
    }
  }

  @override
  Widget build(BuildContext context) {
    return ListTile(
      leading: const Icon(Icons.calendar_today, color: Colors.purpleAccent),
      title: Text(
        "Date: ${selectedDate.day}-${selectedDate.month}-${selectedDate.year}",
        style: const TextStyle(fontSize: 16, color: Colors.white70),
      ),
      onTap: () => _selectDate(context),
      tileColor: Colors.grey.shade800,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(10),
        side: BorderSide(color: Colors.grey.shade700),
      ),
    );
  }
}

// Payment Status Selection Widget (adapted for state management from parent)
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
      contentPadding: EdgeInsets.symmetric(vertical: 5, horizontal: 10),
      tileColor: Colors.grey.shade800,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(10),
        side: BorderSide(color: Colors.grey.shade700),
      ),
      subtitle: Row(
        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
        children: ['Paid', 'Pending', 'Overdue'].map((status) {
          bool isSelected = selectedStatus == status;
          return ChoiceChip(
            label: Text(status, style: TextStyle(color: isSelected ? Colors.black : Colors.white70)),
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
