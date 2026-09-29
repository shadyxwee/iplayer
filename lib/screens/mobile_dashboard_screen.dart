import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'dashboard_screen.dart';

class MobileDashboardScreen extends StatefulWidget {
  final bool showWelcomeDialog;

  const MobileDashboardScreen({Key? key, this.showWelcomeDialog = false}) : super(key: key);

  @override
  State<MobileDashboardScreen> createState() => _MobileDashboardScreenState();
}

class _MobileDashboardScreenState extends State<MobileDashboardScreen> {
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
    return DashboardScreen(showWelcomeDialog: widget.showWelcomeDialog);
  }
}
