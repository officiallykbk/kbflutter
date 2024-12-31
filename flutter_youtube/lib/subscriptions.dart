import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:flutter_youtube/ytdatahandling.dart';

class SubscriptionsPage extends StatefulWidget {
  const SubscriptionsPage({super.key});

  @override
  State<SubscriptionsPage> createState() => _SubscriptionsPageState();
}

class _SubscriptionsPageState extends State<SubscriptionsPage> {
  bool visiblestate = false;
  @override
  Widget build(BuildContext context) {
    return Scaffold(
        appBar: AppBar(
          automaticallyImplyLeading: false,
          backgroundColor: Colors.black,
          title: SvgPicture.asset(
            "assets/youtubegh3.svg",
          ),
          actions: [
            SvgPicture.asset("assets/cast.svg"),
            const SizedBox(width: 20),
            const Icon(
              Icons.notifications_outlined,
              color: Colors.white,
            ),
            const SizedBox(width: 20),
            SvgPicture.asset(
              "assets/search.svg",
              height: 18,
            ),
            const SizedBox(width: 10),
          ],
        ),
        body: Column(children: [
          Expanded(
            flex: 2,
            child: SizedBox(
                height: 40,
                child: ListView(scrollDirection: Axis.horizontal, children: [
                  Expanded(
                    child: GestureDetector(
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
                        shrinkWrap: true,
                        scrollDirection: Axis.horizontal,
                        itemCount: 50,
                        itemBuilder: (BuildContext context, int index) {
                          return Container(
                            margin: const EdgeInsets.symmetric(horizontal: 10),
                            child: Column(
                              children: [
                                const CircleAvatar(
                                  backgroundColor: Colors.grey,
                                ),
                                Visibility(
                                    visible: visiblestate,
                                    child: const Text(
                                      "Hello",
                                      style: TextStyle(
                                          color: Color.fromARGB(
                                              255, 196, 196, 197)),
                                    ))
                              ],
                            ),
                          );
                        },
                      ),
                    ),
                  ),
                ])),
          ),
          Expanded(flex: 22, child: YtContent())
        ]));
  }
}
