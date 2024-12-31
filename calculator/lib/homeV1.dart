import 'package:calculator/calculator_provider.dart';
import 'package:flutter/material.dart';

import 'package:provider/provider.dart';

List<String> keys = [
  'AC',
  '+/-',
  '%',
  '÷',
  '7',
  '8',
  '9',
  '×',
  '4',
  '5',
  '6',
  '-',
  '1',
  '2',
  '3',
  '+',
  '0',
  '.',
  '='
];

class HomePage extends StatefulWidget {
  const HomePage({super.key});

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
          child: Column(
        mainAxisAlignment: MainAxisAlignment.end,
        children: [
          Align(
            alignment: Alignment.topRight,
            child: SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: Text(
                context.watch<Calc_provider>().displayText,
                style: const TextStyle(fontSize: 80),
              ),
            ),
          ),
          const Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              NormalKeys(
                keys: 'AC',
                keyColor: Color.fromARGB(255, 234, 231, 231),
                textColor: Colors.black87,
              ),
              NormalKeys(
                keys: '+/-',
                keyColor: Color.fromARGB(255, 234, 231, 231),
                textColor: Colors.black87,
              ),
              NormalKeys(
                keys: '%',
                keyColor: Color.fromARGB(255, 234, 231, 231),
                textColor: Colors.black87,
              ),
              NormalKeys(keys: '÷', keyColor: Colors.amber),
            ],
          ),
          const Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              NormalKeys(keys: '7'),
              NormalKeys(keys: '8'),
              NormalKeys(keys: '9'),
              NormalKeys(keys: '×', keyColor: Colors.amber),
            ],
          ),
          const Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              NormalKeys(keys: '4'),
              NormalKeys(keys: '5'),
              NormalKeys(keys: '6'),
              NormalKeys(keys: '-', keyColor: Colors.amber),
            ],
          ),
          const Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              NormalKeys(keys: '1'),
              NormalKeys(keys: '2'),
              NormalKeys(keys: '3'),
              NormalKeys(keys: '+', keyColor: Colors.amber),
            ],
          ),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Padding(
                padding: const EdgeInsets.all(10),
                child: ElevatedButton(
                  onPressed: () {
                    context.read<Calc_provider>().receiver('0');
                  },
                  style: ElevatedButton.styleFrom(
                      backgroundColor: const Color.fromARGB(255, 64, 53, 53),
                      shape: const StadiumBorder(),
                      padding: const EdgeInsets.fromLTRB(35, 12, 120, 12)),
                  child: const Padding(
                    padding: EdgeInsets.all(5),
                    child: Center(
                      child: Text(
                        '0',
                        style: TextStyle(color: Colors.white, fontSize: 35),
                      ),
                    ),
                  ),
                ),
              ),
              const NormalKeys(keys: '.'),
              const NormalKeys(keys: '=', keyColor: Colors.amber),
            ],
          )
        ],
      )),
    );
  }
}

class NormalKeys extends StatelessWidget {
  const NormalKeys(
      {super.key,
      required this.keys,
      this.keyColor = const Color.fromARGB(255, 64, 53, 53),
      this.textColor = Colors.white});
  final String keys;
  final Color keyColor;
  final Color textColor;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () => context.read<Calc_provider>().receiver(keys),
      child: Padding(
        padding: const EdgeInsets.all(10),
        child: Container(
          width: 80,
          height: 80,
          decoration: BoxDecoration(shape: BoxShape.circle, color: keyColor),
          child: Padding(
            padding: const EdgeInsets.all(5),
            child: Center(
              child: Text(
                keys,
                style: TextStyle(color: textColor),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
