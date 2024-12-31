import 'package:flutter/material.dart';
import 'package:random_string/random_string.dart';

class ytRequest {
  String title;
  String channelName;
  String? releaseDate;
  String? description;

  ytRequest(
      {required this.title,
      required this.channelName,
      required this.releaseDate,
      required this.description});
}

class YtContent extends StatefulWidget {
  const YtContent({super.key});

  @override
  State<YtContent> createState() => _YtContentState();
}

class _YtContentState extends State<YtContent> {
  bool visiblestate = false;
  @override
  Widget build(BuildContext context) {
    final width = MediaQuery.of(context).size.width;
    return GestureDetector(
      onVerticalDragUpdate: (details) {
        if (details.primaryDelta! > 0) {
          setState(() {
            visiblestate = true;
          });
        } else {
          setState(() {
            visiblestate = false;
          });
        }
      },
      child: ListView.builder(
          itemCount: 100,
          itemBuilder: (context, index) {
            return Container(
              margin: const EdgeInsets.symmetric(vertical: 10),
              child: Column(
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: [
                    Container(
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(15),
                        color: const Color.fromARGB(255, 66, 66, 68),
                      ),
                      width: width - 20,
                      height: 220,
                    ),
                    const SizedBox(
                      height: 10,
                    ),
                    SizedBox(
                      width: width - 50,
                      child: Row(
                        children: [
                          const CircleAvatar(
                            backgroundColor: Color.fromARGB(255, 66, 66, 68),
                          ),
                          const SizedBox(
                            width: 10,
                          ),
                          Column(
                            children: [
                              SizedBox(
                                width: width - 100,
                                child: const Text(
                                  "Title of Video",
                                  softWrap: true,
                                  style: TextStyle(
                                    color: Colors.white,
                                  ),
                                ),
                              ),
                              SizedBox(
                                width: width - 100,
                                child: Text(
                                  "Channel Name • ${randomBetween(0, 100)}k views • release",
                                  softWrap: true,
                                  style: const TextStyle(
                                    color: Colors.white,
                                  ),
                                ),
                              ),
                              // SizedBox(
                              //   width: width - 100,
                              //   child: const Text(
                              //     "views • release",
                              //     softWrap: true,
                              //     style: TextStyle(
                              //       color: Colors.white,
                              //     ),
                              //   ),
                              // ),
                            ],
                          )
                        ],
                      ),
                    )
                  ]),
            );
          }),
    );
  }
}
