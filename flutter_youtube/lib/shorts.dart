import 'package:flutter/material.dart';
import 'package:flutter_svg/svg.dart';
import 'package:flutter_youtube/navbar.dart';

class ShortsPage extends StatefulWidget {
  const ShortsPage({super.key});

  @override
  State<ShortsPage> createState() => _ShortsPageState();
}

class _ShortsPageState extends State<ShortsPage> {
  final List<String> pageTitles = ['Page 1', 'Page 2', 'Page 3'];
  final List<Color> colors = [Colors.red, Colors.blue, Colors.grey];
  @override
  Widget build(BuildContext context) {
    // final width = MediaQuery.of(context).size.width;
    // final height = MediaQuery.of(context).size.height;
    return Scaffold(
      body: Stack(
        children: [
          Positioned(
              child: PageView.builder(
            physics: const BouncingScrollPhysics(),
            scrollDirection: Axis.vertical,
            itemCount: pageTitles.length,
            itemBuilder: (context, index) {
              return Container(
                color: colors[index],
                child: Center(
                  child: Text(
                    "Content ${index + 1}",
                    style: const TextStyle(color: Colors.white),
                  ),
                ),
              );
            },
          )),
          Positioned(
              top: 55,
              left: 15,
              child: InkWell(
                onTap: () {
                  Navigator.of(context).pushAndRemoveUntil(
                      MaterialPageRoute(builder: (_) => const NavBar()),
                      (route) => false);
                },
                child: const Icon(Icons.arrow_back_ios_rounded,
                    color: Color.fromARGB(255, 0, 0, 0)),
              )),
          Positioned(
              bottom: 420,
              right: 15,
              child: SvgPicture.asset(
                "assets/like.svg",
                width: 24,
                height: 24,
              )),
          Positioned(
              bottom: 340,
              right: 15,
              child: SvgPicture.asset(
                "assets/dislike.svg",
                width: 24,
                height: 24,
              )),
          Positioned(
              bottom: 260,
              right: 15,
              child: SvgPicture.asset(
                "assets/comment.svg",
                width: 24,
                height: 24,
              )),
          Positioned(
              bottom: 180,
              right: 15,
              child: SvgPicture.asset(
                "assets/share.svg",
                width: 24,
                height: 24,
              )),
          Positioned(
              bottom: 100,
              right: 15,
              child: SvgPicture.asset(
                "assets/more_horiz.svg",
                width: 24,
                height: 7,
              )),
        ],
      ),
    );
  }
}
