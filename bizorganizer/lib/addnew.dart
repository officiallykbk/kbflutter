import 'package:bizorganizer/main.dart';
import 'package:bizorganizer/models/reusables.dart';
import 'package:bizorganizer/models/trips.dart';
import 'package:bizorganizer/providers/orders_providers.dart';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'dart:io';

import 'package:provider/provider.dart';

final _formKey = GlobalKey<FormState>();
DateTime selectedDate = DateTime.now();
String selectedStatus = 'Pending';
// Define controllers for each text field
final TextEditingController clientController = TextEditingController();
final TextEditingController clientNumberController = TextEditingController();
final TextEditingController clientEmailController = TextEditingController();
final TextEditingController originController = TextEditingController();
final TextEditingController destinationController = TextEditingController();
final TextEditingController amountController = TextEditingController();
final TextEditingController descriptionController = TextEditingController();
final TextEditingController pictureName = TextEditingController();
String imageUrl = '';

class AddTrip extends StatefulWidget {
  const AddTrip({Key? key}) : super(key: key);

  @override
  State<AddTrip> createState() => _AddTripState();
}

class _AddTripState extends State<AddTrip> {
  // @override
  // void dispose() {
  //   // Dispose of the controllers when the widget is disposed
  //   clientController.dispose();
  //   clientNumberController.dispose();
  //   clientEmailController.dispose();
  //   destinationController.dispose();
  //   amountController.dispose();
  //   descriptionController.dispose();
  //   pictureName.dispose();
  //   super.dispose();
  // }

  final picker = ImagePicker();

  Future<void> getImageGallery(ImageSource imgSource, String imgName) async {
    try {
      final pickedFile = await picker.pickImage(source: imgSource);

      if (pickedFile != null) {
        await uploadImageToSupabase(File(pickedFile.path), imgName);
      }
    } catch (e) {
      print('Failed to pick image: $e');
    }
  }

  Future uploadImageToSupabase(File image, String imgName) async {
    try {
      final String path =
          'images/$imgName--${DateTime.now().toString().substring(0, 10)}.png';

      // Upload the image to Supabase storage bucket
      await supabase.storage.from('BizBucket').upload(path, image);
      CustomSnackBar.show(context, 'Image Uploaded', Icons.check);

      // Retrieve the public URL of the uploaded image
      setState(() {
        imageUrl = supabase.storage.from('BizBucket').getPublicUrl(path);
      });
    } catch (e) {
      print('Failed to upload image: $e');
      CustomSnackBar.show(context, 'Failed to Upload Image', Icons.error,
          backgroundColor: Colors.red);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF121212),
      body: CustomScrollView(
        slivers: [
          const SliverAppBar(
            title: Text("Create New Trip"),
            centerTitle: true,
            // pinned: true,
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
                        shape: Border.all(color: Colors.grey),
                        iconColor: Colors.white,
                        onTap: () {
                          showDialog(
                              context: context,
                              barrierDismissible: true,
                              builder: (context) => AlertDialog(
                                      title: TextFormField(
                                        controller: pictureName,
                                        decoration: InputDecoration(
                                          labelText: 'Enter receipt Name',
                                          border: OutlineInputBorder(
                                            borderRadius:
                                                BorderRadius.circular(10),
                                          ),
                                        ),
                                        onFieldSubmitted: (value) async {
                                          Navigator.pop(context);
                                          if (value != '' && value.isNotEmpty) {
                                            await getImageGallery(
                                                ImageSource.gallery, value);
                                          }
                                        },
                                        style: const TextStyle(fontSize: 18),
                                      ),
                                      content: const Text(
                                        'Give it a name that can be easily referenced',
                                        style: TextStyle(color: Colors.red),
                                      ),
                                      actions: [
                                        ElevatedButton(
                                          onPressed: () async {
                                            Navigator.pop(context);
                                            final String enteredName =
                                                pictureName.text;

                                            if (enteredName != '' &&
                                                enteredName.isNotEmpty) {
                                              await getImageGallery(
                                                  ImageSource.gallery,
                                                  enteredName);
                                            }
                                          },
                                          style: ElevatedButton.styleFrom(
                                            backgroundColor: Colors.blue,
                                            foregroundColor: Colors.white,
                                            shape: RoundedRectangleBorder(
                                              borderRadius:
                                                  BorderRadius.circular(10),
                                            ),
                                            padding: const EdgeInsets.symmetric(
                                                horizontal: 20, vertical: 10),
                                          ),
                                          child: const Text(
                                            "Get Image",
                                            style: TextStyle(fontSize: 16),
                                          ),
                                        ),
                                      ]));
                        },
                        leading: const Icon(Icons.add_a_photo_sharp),
                        title: Text(
                          imageUrl == '' ? 'Pick receipt image' : imageUrl,
                          style: const TextStyle(color: Colors.white),
                        ),
                      ),
                      const SizedBox(height: 16),
                      TextInputField(
                        controller: clientController,
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
                        controller: clientNumberController,
                        label: 'Client phone number',
                        icon: Icons.phone_android_outlined,
                        inputType: TextInputType.phone,
                        validator: (value) {
                          if (value == null || value.isEmpty) {
                            return 'Please enter a phone number';
                          }
                          // else if (!(RegExp(
                          //         r"^(?:\+1\s?)?(\d{3}|\(\d{3}\))[-.\s]?\d{3}[-.\s]?\d{4}$")
                          //     .hasMatch(value))) {
                          //   return 'This is not a valid US phone number';
                          // }
                          return null;
                        },
                      ),
                      const SizedBox(height: 16),
                      TextInputField(
                        controller: clientEmailController,
                        label: 'Client email address',
                        icon: Icons.email,
                        inputType: TextInputType.emailAddress,
                        validator: (value) {
                          if (value!.isEmpty) {
                            return 'Field can not be empty';
                          } else {
                            bool isValidEmail(String email) {
                              final emailRegex = RegExp(
                                r'^[a-zA-Z0-9._%+-]+@[a-zA-Z0-9.-]+\.[a-zA-Z]{2,}$',
                              );
                              return emailRegex.hasMatch(email);
                            }

                            if (isValidEmail(clientEmailController.text)) {
                              return null;
                            } else {
                              return 'Invalid Email';
                            }
                          }
                        },
                      ),
                      const SizedBox(height: 16),
                      const CalendarSelect(),
                      const SizedBox(height: 16),
                      TextInputField(
                        controller: originController,
                        label: 'Origin',
                        icon: Icons.place_rounded,
                        inputType: TextInputType.name,
                        validator: (value) {
                          if (value == null || value.isEmpty) {
                            return 'Field can not be empty';
                          } else {
                            return null;
                          }
                        },
                      ),
                      const SizedBox(height: 16),
                      TextInputField(
                        controller: destinationController,
                        label: 'Destination',
                        icon: Icons.place_rounded,
                        inputType: TextInputType.name,
                        validator: (value) {
                          if (value == null || value.isEmpty) {
                            return 'Field can not be empty';
                          } else {
                            return null;
                          }
                        },
                      ),
                      const SizedBox(height: 16),
                      TextInputField(
                        controller: amountController,
                        label: 'Amount',
                        icon: Icons.attach_money_outlined,
                        inputType: TextInputType.number,
                        validator: (value) {
                          if (value!.isEmpty) {
                            return 'Please enter an amount';
                          } else if (!(RegExp(r'^\d+(\.\d+)?$')
                              .hasMatch(value))) {
                            return 'Amount can only be number';
                          } else {
                            return null;
                          }
                        },
                      ),
                      const SizedBox(height: 16),
                      const PaymentStatus(),
                      const SizedBox(height: 16),
                      TextInputField(
                        controller: descriptionController,
                        label: 'Description',
                        icon: Icons.description,
                        maxlines: 5,
                        inputType: TextInputType.name,
                        // validator: (value) {
                        //   if (value == null || value.isEmpty) {
                        //     return 'Field can not be empty';
                        //   } else {
                        //     return null;
                        //   }
                        // },
                      ),
                      const SizedBox(height: 32),
                      const SaveButton(),
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

// Text Input Field Widget with personalized validation
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
      decoration: InputDecoration(
        labelText: label,
        labelStyle: const TextStyle(color: Colors.white),
        prefixIcon: Icon(icon, color: Colors.white),
        border: const OutlineInputBorder(),
      ),
      validator: validator,
    );
  }
}

// Calendar Selection Widget
class CalendarSelect extends StatefulWidget {
  const CalendarSelect({Key? key}) : super(key: key);

  @override
  State<CalendarSelect> createState() => _CalendarSelectState();
}

class _CalendarSelectState extends State<CalendarSelect> {
  Future<void> _selectDate(BuildContext context) async {
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: selectedDate,
      firstDate: DateTime(2015, 8),
      lastDate: DateTime(2101),
    );
    if (picked != null && picked != selectedDate) {
      setState(() {
        selectedDate = picked;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return ListTile(
      leading: const Icon(
        Icons.calendar_today,
        color: Colors.purple,
      ),
      title: Text(
        "Date: ${selectedDate.day}-${selectedDate.month}-${selectedDate.year}",
        style: const TextStyle(fontSize: 16, color: Colors.black),
      ),
      onTap: () => _selectDate(context),
      tileColor: Colors.grey[200],
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(8),
        side: const BorderSide(color: Colors.grey),
      ),
    );
  }
}

// Payment Status Selection Widget
class PaymentStatus extends StatefulWidget {
  const PaymentStatus({Key? key}) : super(key: key);

  @override
  State<PaymentStatus> createState() => _PaymentStatusState();
}

class _PaymentStatusState extends State<PaymentStatus> {
  @override
  Widget build(BuildContext context) {
    return ListTile(
      title: const Text("Payment Status",
          style: TextStyle(fontSize: 16, color: Colors.black)),
      subtitle: Row(
        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
        children: ['Paid', 'Pending', 'Overdue'].map((status) {
          return ChoiceChip(
            label: Text(status),
            selected: selectedStatus == status,
            onSelected: (selected) {
              setState(() {
                if (selected) selectedStatus = status;
              });
            },
          );
        }).toList(),
      ),
      tileColor: Colors.grey[200],
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(8),
        side: const BorderSide(color: Colors.grey),
      ),
    );
  }
}

// Save Button Widget
class SaveButton extends StatefulWidget {
  const SaveButton({Key? key}) : super(key: key);

  @override
  State<SaveButton> createState() => _SaveButtonState();
}

class _SaveButtonState extends State<SaveButton> {
  // final tripModel = Provider.of<TripsProvider>(context);
  void clearFields() {
    clientController.clear();
    clientNumberController.clear();
    clientEmailController.clear();
    destinationController.clear();
    amountController.clear();
    descriptionController.clear();
    pictureName.clear();
    setState(() {
      imageUrl = '';
    });
  }

  addTrip() {
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
      clientName: capitalizeEachWord(clientController.text),
      contactNumber: clientNumberController.text,
      receipt: imageUrl,
      date: "${selectedDate.day}-${selectedDate.month}-${selectedDate.year}",
      origin: capitalizeEachWord(originController.text),
      destination: capitalizeEachWord(destinationController.text),
      amount: double.parse(amountController.text),
      paymentStatus: selectedStatus.toLowerCase(),
      description: descriptionController.text,
    );
    context.read<TripsProvider>().addTrip(trip);

    CustomSnackBar.show(context, 'Trip Recoded', Icons.check);

    print('clearing fields');

    Future.delayed(const Duration(milliseconds: 100), () {
      setState(() {
        _formKey.currentState?.reset();
        clearFields();
      });
    });
  }

  @override
  Widget build(BuildContext context) {
    return ElevatedButton(
      onPressed: () async {
        if (_formKey.currentState!.validate()) {
          await addTrip();
        }
      },
      style: ElevatedButton.styleFrom(
          minimumSize: const Size(double.infinity, 50),
          backgroundColor: Colors.amber),
      child: const Text("Save",
          style: TextStyle(fontSize: 18, color: Colors.white)),
    );
  }
}
