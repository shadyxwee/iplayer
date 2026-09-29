import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'live_tv_screen.dart';

class MobileLiveTVScreen extends StatefulWidget {
  const MobileLiveTVScreen({Key? key}) : super(key: key);

  @override
  State<MobileLiveTVScreen> createState() => _MobileLiveTVScreenState();
}

class _MobileLiveTVScreenState extends State<MobileLiveTVScreen> {
  @override
  void initState() {
    super.initState();
    // Default landscape orientation for mobile
    SystemChrome.setPreferredOrientations([
      DeviceOrientation.landscapeLeft,
      DeviceOrientation.landscapeRight,
    ]);
  }

  @override
  Widget build(BuildContext context) {
    return const LiveTVScreen();
  }
}
