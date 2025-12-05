import 'package:flutter/material.dart';
import 'package:sidebarx/sidebarx.dart';

import '../common_widget/sidebar.dart';

class HomepageView extends StatefulWidget {
  const HomepageView({super.key});

  @override
  State<HomepageView> createState() => _HomepageViewState();
}

class _HomepageViewState extends State<HomepageView> {
  final _controller = SidebarXController(selectedIndex: 0, extended: true);
  final _key = GlobalKey<ScaffoldState>();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      key: _key,
      appBar: AppBar(
        centerTitle: true,
        leading: IconButton(
            onPressed: () {
              _key.currentState?.openDrawer();
            },
            icon: Icon(Icons.menu)),
        title: Text("PadizDoctor"),
        actions: [
          IconButton(
            icon: const Icon(Icons.person),
            onPressed: () {},
          ),
        ],
      ),
      drawer: Sidebar(
        controller: _controller,
      ),
      body: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          Center(
              child: Text(
            "Welcome to PadizDoctor",
            style: TextStyle(fontSize: 25),
          )),
          SizedBox(height: 20),
          Divider(
            thickness: 1,
            indent: 40,
            endIndent: 40,
          ),
          SizedBox(height: 20),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            children: [
              Column(
                children: [
                  Text("fasfagadsaad"),
                  Text("Test Test Test Test Test Test Test"),
                ],
              ),
              Container(
                width: 100,
                color: Colors.amber,
                child: SizedBox(
                  height: 100,
                ),
              )
            ],
          ),
          SizedBox(height: 20),
          Divider(
            thickness: 1,
            indent: 40,
            endIndent: 40,
          ),
          SizedBox(height: 20),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            children: [
              Container(
                width: 100,
                color: Colors.amber,
                child: SizedBox(
                  height: 100,
                ),
              ),
              Column(
                children: [
                  Text("fasfagadsaad"),
                  Text("Test Test Test Test Test Test Test"),
                ],
              ),
            ],
          ),
          SizedBox(height: 20),
          Divider(
            thickness: 1,
            indent: 40,
            endIndent: 40,
          ),
          SizedBox(height: 20),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            children: [
              Column(
                children: [
                  Text("fasfagadsaad"),
                  Text("Test Test Test Test Test Test Test"),
                ],
              ),
              Container(
                width: 100,
                color: Colors.amber,
                child: SizedBox(
                  height: 100,
                ),
              )
            ],
          ),
          SizedBox(height: 20),
          TextButton(
            onPressed: () {},
            child: Text('Start'),
          )
        ],
      ),
    );
  }
}
