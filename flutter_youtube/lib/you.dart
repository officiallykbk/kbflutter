import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';

class YouPage extends StatefulWidget {
  const YouPage({super.key});

  @override
  State<YouPage> createState() => _YouPageState();
}

List<String> tabNames = [
  "Switch account",
  "Google Account",
  "Turn on incognito"
];

class _YouPageState extends State<YouPage> {
  bool visiblestate = false;
  @override
  Widget build(BuildContext context) {
    final width = MediaQuery.of(context).size.width;

    return Scaffold(
        appBar: AppBar(
          automaticallyImplyLeading: false,
          backgroundColor: Colors.black,
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
              // flex: 1,
              child: Row(
            children: [
              CircleAvatar(
                child: Text("B"),
              ),
              SizedBox(
                width: 50,
              ),
              Column(
                children: [
                  Text("Bunsen Burner"),
                  Row(
                    children: [
                      Text("@bunsenburner8750 •"),
                      TextButton(
                          onPressed: () {}, child: Text("View channel >"))
                    ],
                  )
                ],
              )
            ],
          )),
          Expanded(
            // flex: 8,
            child: SizedBox(
                height: 40,
                child: ListView(scrollDirection: Axis.horizontal, children: [
                  Expanded(
                    child: ListView.builder(
                      shrinkWrap: true,
                      scrollDirection: Axis.horizontal,
                      itemCount: 3,
                      itemBuilder: (BuildContext context, int index) {
                        return Container(
                          margin: const EdgeInsets.symmetric(horizontal: 10),
                          child: Column(
                            children: [
                              TextButton(
                                  onPressed: () {},
                                  child: Text(tabNames[index]))
                            ],
                          ),
                        );
                      },
                    ),
                  ),
                ])),
          ),
          Expanded(
            child: ListView.builder(
              itemCount: 10,
              scrollDirection: Axis.horizontal,
              itemBuilder: (BuildContext context, int index) {
                return Row(
                  children: [
                    const SizedBox(
                      width: 20,
                    ),
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Container(
                          height: 100,
                          width: width * 0.5,
                          color: Colors.white,
                        ),
                        Text(
                          "Title of Video",
                          style: const TextStyle(
                              color: Colors.white, fontSize: 25),
                        ),
                        Text(
                          "Channel Name",
                          style: const TextStyle(color: Colors.white),
                        )
                      ],
                    ),
                  ],
                );
              },
            ),
          ),
        ]));
  }
}
