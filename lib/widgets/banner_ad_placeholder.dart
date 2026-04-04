import 'package:flutter/material.dart';

class BannerAdPlaceholder extends StatelessWidget {
  const BannerAdPlaceholder({super.key});

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      top: false,
      child: SizedBox(
        width: double.infinity,
        height: 50,
        // TODO: Replace this container with AdWidget when AdMob is integrated.
        child: Container(
          color: Colors.grey.shade300,
          alignment: Alignment.center,
          child: const Text('広告エリア（Banner Ad）'),
        ),
      ),
    );
  }
}
