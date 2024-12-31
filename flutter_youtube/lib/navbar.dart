import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:flutter_youtube/home.dart';
import 'package:flutter_youtube/shorts.dart';
import 'package:flutter_youtube/subscriptions.dart';
import 'package:flutter_youtube/you.dart';

class NavBar extends StatefulWidget {
  const NavBar({super.key});

  @override
  State<NavBar> createState() => _NavBarState();
}

Widget icon(icon, name) {
  return Padding(
    padding: const EdgeInsets.only(top: 5.0),
    child: NavigationDestination(
        selectedIcon: SvgPicture.asset(
          "assets/$icon",
        ),
        icon: SvgPicture.asset("assets/$icon"),
        label: "$name"),
  );
}

final pages = [
  const MyHomePage(),
  const ShortsPage(),
  const SubscriptionsPage(),
  const YouPage()
];

class _NavBarState extends State<NavBar> {
  int currentIndex = 0;
  @override
  Widget build(BuildContext context) {
    return Scaffold(
        body: pages[currentIndex],
        bottomNavigationBar: NavigationBar(
          backgroundColor: Colors.black,
          height: 60,
          destinations: [
            icon("homeicon.svg", "Home"),
            icon("shorts.svg", "Shorts"),
            icon("subscriptionsIcon.svg", "Subscribe"),
            icon("whiteprofileicon.svg", "You")
          ],
          indicatorShape: const CircleBorder(),
          selectedIndex: currentIndex,
          onDestinationSelected: (value) {
            setState(() {
              currentIndex = value;
            });
          },
        ));
  }
}
