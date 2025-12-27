import 'package:flutter/material.dart';
import 'package:padizdoctor/src/homepage/homepage_screens.dart';
import 'package:padizdoctor/src/settings/settings_controller.dart';
import 'package:padizdoctor/src/user/my_activity/my_activity.dart';
import 'package:padizdoctor/src/user/my_history/my_history.dart';
import 'package:padizdoctor/src/user/my_profile/my_profile.dart';

class AppScaffold extends StatefulWidget {
  AppScaffold({super.key, required this.controller, required this.user});
  var user = {};
  final SettingsController controller;
  @override
  State<AppScaffold> createState() => _AppScaffoldState();
}

class _AppScaffoldState extends State<AppScaffold> {
  var selectedIndex = 0;
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      bottomNavigationBar: bottomNavBar(),
      body: IndexedStack(
        index: selectedIndex,
        children: [
          HomepageScreens(controller: widget.controller, user: widget.user),
          MyHistory(),
          MyActivity(),
          MyProfile(
            controller: widget.controller,
            user: widget.user,
          ),
        ],
      ),
    );
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
