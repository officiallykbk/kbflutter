import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:flutter_youtube/ytdatahandling.dart';
import 'package:youtube_api/youtube_api.dart';
import 'package:random_string/random_string.dart';

class MyHomePage extends StatefulWidget {
  const MyHomePage({super.key});

  @override
  State<MyHomePage> createState() => _MyHomePageState();
}

class _MyHomePageState extends State<MyHomePage> {
  List<String> Activities = [
    "Create a Flutter Project",
    "Build User Interfaces (UI)",
    "Navigation",
    "State Management",
    "Networking",
    "Database Integration",
    "Local Storage",
    "Platform Integration",
    "Stateful Widgets",
    "Internationalization",
    "Custom Widgets",
    "Theming and Styling",
    "Animations",
    "Testing",
    "App Deployment"
  ];
  YoutubeAPI youtubeAPI =
      YoutubeAPI("AIzaSyBrDJJAp145DyIH2wsF2eUwsfXGXAF3jA8", maxResults: 50);

  List<ytRequest> ytContent = [];
  @override
  void initState() {
    super.initState();
    fetch();
  }

  fetch() async {
    List<YouTubeVideo> ytPuller = await youtubeAPI.search(
        'Popular music videos 2024 Funny animal compilations Top 10 tech gadgets How to [insert popular skill] [Celebrity name] interview Unboxing [new product] Behind the scenes of [popular movie/show] [Sport] highlights Travel vlog - [Destination] ASMR [relaxing activity]');
    for (int i = 0; i < 50; i++) {
      int currentIndice = i;
      ytContent.add(ytRequest(
          title: ytPuller[currentIndice].title,
          channelName: ytPuller[currentIndice].channelTitle,
          releaseDate: ytPuller[currentIndice].duration,
          description: ytPuller[currentIndice].description));
    }
    debugPrint("heelllll${ytContent[1].channelName}");
    setState(() {});
  }

  List<String> drawer = ["Trending", "Music", "Gaming", "Sports"];
  List<String> drawer_images = [
    "trending.svg",
    "music.svg",
    "game.svg",
    "sports.svg"
  ];
  @override
  Widget build(BuildContext context) {
    final width = MediaQuery.of(context).size.width;
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
                Builder(builder: (context) {
                  return InkWell(
                    onTap: () {
                      Scaffold.of(context).openDrawer();
                    },
                    child: Container(
                      padding: const EdgeInsets.all(3),
                      margin: const EdgeInsets.all(5),
                      decoration: const BoxDecoration(
                        borderRadius: BorderRadius.all(Radius.circular(7)),
                        color: Color.fromARGB(255, 66, 66, 68),
                      ),
                      height: 40,
                      child: SvgPicture.asset("assets/compass.svg"),
                    ),
                  );
                }),
                Expanded(
                  child: ListView.builder(
                    shrinkWrap: true,
                    scrollDirection: Axis.horizontal,
                    itemCount: Activities.length,
                    itemBuilder: (BuildContext context, int index) {
                      return Container(
                        alignment: Alignment.center,
                        padding: const EdgeInsets.all(3),
                        margin: const EdgeInsets.all(5),
                        decoration: const BoxDecoration(
                          borderRadius: BorderRadius.all(Radius.circular(7)),
                          color: Color.fromARGB(255, 66, 66, 68),
                        ),
                        child: Text(
                          Activities[index],
                          style: const TextStyle(color: Colors.white),
                        ),
                      );
                    },
                  ),
                ),
                Container(
                  alignment: Alignment.center,
                  margin: const EdgeInsets.all(5),
                  child: const Text(
                    "Send feedback",
                    style: TextStyle(color: Colors.blue),
                  ),
                )
              ])),
        ),
        Expanded(
          flex: 22,
          child: ListView.builder(
              itemCount: ytContent.length,
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
                          // child: Image.asset("${ytContent[index].thumbnail}"),
                        ),
                        const SizedBox(
                          height: 10,
                        ),
                        SizedBox(
                          width: width - 50,
                          child: Row(
                            children: [
                              const CircleAvatar(
                                backgroundColor:
                                    Color.fromARGB(255, 66, 66, 68),
                              ),
                              const SizedBox(
                                width: 10,
                              ),
                              Column(
                                children: [
                                  SizedBox(
                                    width: width - 100,
                                    child: Text(
                                      ytContent[index].title,
                                      softWrap: true,
                                      style: const TextStyle(
                                        color: Colors.white,
                                      ),
                                    ),
                                  ),
                                  SizedBox(
                                    width: width - 100,
                                    child: Text(
                                      "${ytContent[index].channelName} • ${randomBetween(0, 100)}k views • release",
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
        )
      ]),
      drawer: Drawer(
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(0),
        ),
        backgroundColor: const Color.fromARGB(255, 5, 5, 5),
        width: 230,
        elevation: 1.0,
        child: ListView(children: [
          const SizedBox(height: 8),
          Row(
            children: [
              const SizedBox(width: 15),
              SvgPicture.asset(
                "assets/youtubegh3.svg",
                fit: BoxFit.contain,
                alignment: Alignment.topLeft,
              ),
            ],
          ),
          const SizedBox(height: 15),
          ListView.builder(
            shrinkWrap: true,
            scrollDirection: Axis.vertical,
            itemCount: drawer.length,
            itemBuilder: (BuildContext context, int index) {
              return Container(
                padding: const EdgeInsets.all(3),
                margin: const EdgeInsets.all(5),
                decoration: const BoxDecoration(
                  borderRadius: BorderRadius.all(Radius.circular(7)),
                ),
                child: Row(children: [
                  const SizedBox(width: 10),
                  SvgPicture.asset(
                    "assets/${drawer_images[index]}",
                    width: 16,
                    height: 16,
                  ),
                  const SizedBox(width: 10),
                  Text(
                    drawer[index],
                    style: const TextStyle(color: Colors.white),
                  ),
                ]),
              );
            },
          ),
          const Divider(),
          const SizedBox(height: 15),
          Row(children: [
            const SizedBox(width: 10),
            SvgPicture.asset(
              "assets/studio.svg",
              width: 20,
              height: 20,
            ),
            const SizedBox(width: 10),
            const Text(
              "YouTube Studio",
              style: TextStyle(color: Colors.white),
            ),
          ]),
          const SizedBox(height: 15),
          Row(children: [
            const SizedBox(width: 10),
            SvgPicture.asset(
              "assets/ytkids.svg",
              width: 20,
              height: 20,
            ),
            const SizedBox(width: 10),
            const Text(
              "YouTube Kids",
              style: TextStyle(color: Colors.white),
            ),
          ])
        ]),
      ),
    );
  }
}
