import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter_cache_manager/flutter_cache_manager.dart';

class CacheImage extends StatelessWidget {
  final String imageUrl;

  // Constructor to make this a reusable custom widget
  const CacheImage({
    Key? key,
    required this.imageUrl,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return CachedNetworkImage(
      imageUrl: imageUrl,
      cacheManager: CacheManager(
        Config('customCacheKey', stalePeriod: const Duration(days: 7)),
      ),
      placeholder: (context, url) => Image.asset(
        'assets/pill.png',
        width: 200,
        height: 200,
      ),
      errorWidget: (context, url, error) => Icon(Icons.error),
      imageBuilder: (context, imageProvider) => Container(
        width: 200,
        height: 200,
        decoration: BoxDecoration(
          image: DecorationImage(
            image: imageProvider,
            fit: BoxFit.fill,
          ),
        ),
      ),
    );
  }
}
