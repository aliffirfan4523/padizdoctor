import 'package:flutter/material.dart';
import 'package:padizdoctor/src/my_activity/my_activity.dart';
import 'package:padizdoctor/src/my_history/my_history.dart';
import 'package:sidebarx/sidebarx.dart';

import '../settings/settings_controller.dart';
import 'homepage_screens.dart';
import 'homepage_service.dart';

class MainNavigationView extends StatefulWidget {
  const MainNavigationView({super.key, required this.controller});
  final SettingsController controller;
  @override
  State<MainNavigationView> createState() => _MainNavigationViewState();
}

class _MainNavigationViewState extends State<MainNavigationView> {
  final _controller = SidebarXController(selectedIndex: 0, extended: true);
  final _key = GlobalKey<ScaffoldState>();
  final service = HomepageService();
  var selectedIndex = 0;

  var user = {};
  @override
  void initState() {
    super.initState();

    service.loadData().then((data) {
      // The 'mounted' check must be inside the .then block
      if (mounted) {
        setState(() {
          user = data ?? {};
        });
      }
    });
  }

  List<Widget> get screens => [
        HomepageScreens(controller: widget.controller),
        MyHistory(),
        MyActivity(),
        Center(child: Text("Settings Screen")),
      ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
        key: _key,
        bottomNavigationBar: bottomNavBar(),
        body: screens[selectedIndex]);
  }

  BottomNavigationBar bottomNavBar() {
    return BottomNavigationBar(
        selectedItemColor: Colors.green,
        unselectedItemColor: Colors.grey,
        currentIndex: selectedIndex,
        onTap: (index) {
          setState(() {
            selectedIndex = index;
          });
        },
        items: [
          BottomNavigationBarItem(
            icon: Icon(Icons.home),
            label: 'Home',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.history),
            label: 'History',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.person),
            label: 'My Activity',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.settings),
            label: 'Settings',
          ),
        ]);
  }
}
