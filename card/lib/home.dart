import 'dart:math';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:pattern_formatter/numeric_formatter.dart';

ThemeMode themeChanger = ThemeMode.light;
final formKey = GlobalKey<FormState>();
final name = TextEditingController();
final number = TextEditingController();
final date = TextEditingController();
final cardType = TextEditingController();

class CardFill extends StatefulWidget {
  const CardFill({super.key});

  @override
  State<CardFill> createState() => _CardFillState();
}

List<Color> colorOptions = [Colors.red, Colors.yellow, Colors.blue];
Color selectedColor = colorOptions[0];
int selectedIndex = 0;

late AnimationController _controller;
late Animation<double> _animation;

class _CardFillState extends State<CardFill>
    with SingleTickerProviderStateMixin {
  @override
  void initState() {
    _controller =
        AnimationController(vsync: this, duration: const Duration(seconds: 3));
    _animation = Tween<double>(begin: 0, end: 2 * pi).animate(_controller);
    _controller.repeat();
    super.initState();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        leading: Container(
          margin: const EdgeInsets.all(8),
          decoration: BoxDecoration(
              color: Colors.grey.shade300,
              borderRadius: BorderRadius.circular(10)),
          child: const Icon(Icons.arrow_back_outlined),
        ),
        title: const Text(
          'Add Card',
          style: TextStyle(fontWeight: FontWeight.bold),
        ),
        centerTitle: true,
      ),
      body: Form(
        key: formKey,
        child: CustomScrollView(
          slivers: [
            // CARD
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.all(8.0),
                child: AnimatedBuilder(
                  animation: _animation,
                  builder: (context, child) => Transform(
                    alignment: Alignment.center,
                    transform: Matrix4.identity()..rotateY(_animation.value),
                    child: Stack(
                      children: [
                        Card(
                          color: Colors.green,
                          elevation: 10,
                          child: Padding(
                            padding: const EdgeInsets.all(10.0),
                            child: TextFormField(
                              readOnly: true,
                              controller: name,
                              decoration: const InputDecoration(
                                  hintText: 'Full Name',
                                  border: InputBorder.none),
                              style: const TextStyle(
                                fontSize: 25,
                              ),
                              textCapitalization: TextCapitalization.characters,
                              validator: (value) {
                                if (value == null || value == '') {
                                  return 'Field can not be left empty';
                                }
                                return null;
                              },
                            ),
                          ),
                        ),
                        Card(
                          color: selectedColor,
                          elevation: 10,
                          child: Padding(
                            padding: const EdgeInsets.all(10.0),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                TextFormField(
                                  readOnly: true,
                                  controller: name,
                                  decoration: const InputDecoration(
                                      hintText: 'Full Name',
                                      border: InputBorder.none),
                                  style: const TextStyle(
                                    fontSize: 25,
                                  ),
                                  textCapitalization:
                                      TextCapitalization.characters,
                                  validator: (value) {
                                    if (value == null || value == '') {
                                      return 'Field can not be left empty';
                                    }
                                    return null;
                                  },
                                ),
                                TextFormField(
                                  readOnly: true,
                                  controller: number,
                                  textAlign: TextAlign.center,
                                  decoration: const InputDecoration(
                                      hintText: 'Card Number',
                                      border: InputBorder.none),
                                  style: const TextStyle(
                                      fontSize: 30,
                                      fontWeight: FontWeight.bold),
                                  validator: (value) {
                                    if (value == null || value == '') {
                                      return 'Field can not be left empty';
                                    }
                                    return null;
                                  },
                                ),
                                const Text(
                                  'Valid thru',
                                  style: TextStyle(
                                      fontWeight: FontWeight.bold,
                                      fontSize: 17,
                                      height: 0),
                                ),
                                TextFormField(
                                  readOnly: true,
                                  controller: date,
                                  decoration: const InputDecoration(
                                      hintText: '-- / --',
                                      border: InputBorder.none),
                                  style:
                                      const TextStyle(fontSize: 20, height: 0),
                                  validator: (value) {
                                    if (value == null || value == '') {
                                      return 'Field can not be left empty';
                                    }
                                    return null;
                                  },
                                ),
                                TextFormField(
                                  controller: cardType,
                                  decoration: const InputDecoration(
                                      hintText: 'Card Type',
                                      border: InputBorder.none),
                                  textCapitalization:
                                      TextCapitalization.characters,
                                  style: const TextStyle(
                                      fontWeight: FontWeight.bold,
                                      fontSize: 17,
                                      height: 0),
                                  validator: (value) {
                                    if (value == null || value == '') {
                                      return 'Field can not be left empty';
                                    }
                                    return null;
                                  },
                                ),
                              ],
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
            // CUSTOM COLORS
            SliverToBoxAdapter(
              child: Container(
                height: 100,
                width: double.infinity,
                alignment: Alignment.center,
                child: ListView.builder(
                    scrollDirection: Axis.horizontal,
                    itemCount: colorOptions.length,
                    itemBuilder: (context, index) {
                      return InkWell(
                        overlayColor: WidgetStateColor.transparent,
                        onTap: () {
                          setState(() => selectedColor = colorOptions[index]);
                          if (selectedColor == colorOptions[index]) {
                            selectedColor = colorOptions[index];
                            selectedIndex = index;
                          }
                        },
                        child: Stack(
                          alignment: Alignment.center,
                          children: [
                            Padding(
                              padding: const EdgeInsets.all(10.0),
                              child: Container(
                                decoration: BoxDecoration(
                                    color: colorOptions[index],
                                    borderRadius: BorderRadius.circular(30)),
                                height: 100,
                                width: 100,
                              ),
                            ),
                            Visibility(
                              visible: selectedIndex == index,
                              child: Container(
                                height: 30,
                                width: 30,
                                decoration: const BoxDecoration(
                                  color: Colors.white,
                                  shape: BoxShape.circle,
                                ),
                                child: Container(
                                  margin: const EdgeInsets.all(2),
                                  decoration: BoxDecoration(
                                      color: colorOptions[(index + 1) % 3],
                                      shape: BoxShape.circle),
                                ),
                              ),
                            )
                          ],
                        ),
                      );
                    }),
              ),
            ),
            // FORM FILL AREA
            SliverToBoxAdapter(
              child: Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: TextFormField(
                    textCapitalization: TextCapitalization.characters,
                    controller: name,
                    decoration: InputDecoration(
                      labelText: 'Full Name',
                      fillColor: Colors.grey.shade200,
                      filled: true,
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(16),
                        borderSide: BorderSide.none,
                      ),
                    ),
                    style: const TextStyle(
                        fontSize: 20, fontWeight: FontWeight.bold),
                    validator: (value) {
                      if (value == null || value == '') {
                        return 'Field can not be left empty';
                      }
                      return null;
                    },
                  )),
            ),
            SliverToBoxAdapter(
              child: Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: TextFormField(
                    controller: number,
                    keyboardType: TextInputType.number,
                    inputFormatters: [
                      LengthLimitingTextInputFormatter(19),
                      CreditCardFormatter()
                    ],
                    decoration: InputDecoration(
                      fillColor: Colors.grey.shade200,
                      filled: true,
                      labelText: 'Card Number',
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(16),
                        borderSide: BorderSide.none,
                      ),
                    ),
                    style: const TextStyle(
                        fontSize: 20, fontWeight: FontWeight.bold),
                    validator: (value) {
                      if (value == null || value == '') {
                        return 'Field can not be left empty';
                      }
                      return null;
                    },
                  )),
            ),

            SliverToBoxAdapter(
              child: Wrap(
                children: [
                  SizedBox(
                    width: MediaQuery.of(context).size.width * 0.5,
                    child: Padding(
                      padding: const EdgeInsets.all(16.0),
                      child: TextFormField(
                        controller: date,
                        inputFormatters: [
                          LengthLimitingTextInputFormatter(5),
                          ExpiryDateInputFormatter()
                        ],
                        decoration: InputDecoration(
                          fillColor: Colors.grey.shade200,
                          filled: true,
                          labelText: 'Expiry Date',
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(16),
                            borderSide: BorderSide.none,
                          ),
                        ),
                        style: const TextStyle(
                            fontSize: 20, fontWeight: FontWeight.bold),
                        validator: (value) {
                          if (value == null || value == '') {
                            return 'Field can not be left empty';
                          }
                          return null;
                        },
                      ),
                    ),
                  ),
                  SizedBox(
                    width: MediaQuery.of(context).size.width * 0.5,
                    child: Padding(
                      padding: const EdgeInsets.all(16.0),
                      child: TextFormField(
                        controller: cardType,
                        inputFormatters: [
                          FilteringTextInputFormatter.digitsOnly,
                          LengthLimitingTextInputFormatter(3)
                        ],
                        keyboardType: TextInputType.number,
                        decoration: InputDecoration(
                          fillColor: Colors.grey.shade200,
                          filled: true,
                          labelText: 'CVV',
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(16),
                            borderSide: BorderSide.none,
                          ),
                        ),
                        style: const TextStyle(
                            fontSize: 20, fontWeight: FontWeight.bold),
                        validator: (value) {
                          if (value == null || value == '') {
                            return 'Field can not be left empty';
                          }
                          return null;
                        },
                      ),
                    ),
                  ),
                ],
              ),
            ),
            SliverToBoxAdapter(
              child: Container(
                margin:
                    const EdgeInsets.symmetric(horizontal: 10, vertical: 20),
                width: double.infinity,
                height: 70,
                decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(15),
                    gradient: LinearGradient(colors: colorOptions)),
                child: const Center(
                  child: Text(
                    'Next',
                    style: TextStyle(
                      fontSize: 30,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ),
            )
          ],
        ),
      ),
    );
  }
}

class ExpiryDateInputFormatter extends TextInputFormatter {
  @override
  TextEditingValue formatEditUpdate(
      TextEditingValue oldValue, TextEditingValue newValue) {
    String text = newValue.text;

    // Remove any non-digit characters
    text = text.replaceAll(RegExp(r'[^0-9]'), '');

    // Ensure the text is at most 4 digits
    if (text.length > 4) {
      text = text.substring(0, 4);
    }

    // Format as MM/YY
    if (text.length >= 3) {
      text = '${text.substring(0, 2)}/${text.substring(2)}';
    }

    return TextEditingValue(
      text: text,
      selection: TextSelection.collapsed(offset: text.length),
    );
  }
}
