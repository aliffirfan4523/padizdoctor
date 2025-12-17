import 'package:flutter/material.dart';
import 'package:padizdoctor/src/camera_gallery/gallery.dart';
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
            onPressed: () {
              showModalBottomSheet(
                context: context,
                builder: (context) => Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        CircleAvatar(
                          radius: 40,
                          backgroundImage: AssetImage(
                              'assets/images/user_profile.png'), // Replace with your asset or NetworkImage
                        ),
                        SizedBox(width: 30),
                        Text(
                          'User Name', // Replace with actual user name
                          style: TextStyle(
                              fontSize: 20, fontWeight: FontWeight.bold),
                        ),
                      ],
                    ),
                    SizedBox(height: 24),
                    SizedBox(
                      width: MediaQuery.sizeOf(context).width * 0.8,
                      child: ElevatedButton.icon(
                        style: ElevatedButton.styleFrom(
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                            padding: EdgeInsets.symmetric(vertical: 16),
                            shadowColor: Colors.blueGrey),
                        onPressed: () {
                          // Add your logout logic here
                          Navigator.of(context).pop();
                        },
                        icon: Icon(Icons.logout),
                        label: Text('Logout'),
                      ),
                    ),
                  ],
                ),
              );
            },
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
          Text(
            "Hi User",
            style: TextStyle(fontSize: 25),
          ),
          Text(
            "What can i help with?",
            style: TextStyle(fontSize: 25),
          ),
          SizedBox(height: 20),
          SizedBox(height: 20),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            children: [
              IconButton(
                onPressed: () => {},
                icon: Column(
                  children: [
                    Icon(
                      Icons.camera_enhance,
                      size: 50,
                    ),
                    SizedBox(height: 10),
                    Text(
                      'Take picture',
                      style: TextStyle(),
                    ),
                  ],
                ),
              ),
              Container(
                  height: 80,
                  child: VerticalDivider(
                      color: const Color.fromARGB(255, 97, 97, 97))),
              IconButton(
                onPressed: () => {
                  Navigator.push(context,
                      MaterialPageRoute(builder: (_) => GalleryPicker()))
                },
                icon: Column(
                  children: [
                    Icon(
                      Icons.photo_library,
                      size: 50,
                    ),
                    SizedBox(height: 10),
                    Text(
                      'Upload photo',
                      style: TextStyle(),
                    ),
                  ],
                ),
              ),
            ],
          ),
          SizedBox(height: 20),
          Divider(
            thickness: 1,
            indent: 40,
            endIndent: 40,
            color: Color.fromARGB(255, 97, 97, 97),
          ),
          SizedBox(height: 20),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            children: [
              IconButton(
                onPressed: () => {},
                icon: Column(
                  children: [
                    Icon(
                      Icons.person,
                      size: 50,
                    ),
                    SizedBox(height: 10),
                    Text(
                      'My activity',
                      style: TextStyle(),
                    ),
                  ],
                ),
              ),
              Container(
                  height: 80,
                  child: VerticalDivider(
                      color: const Color.fromARGB(255, 97, 97, 97))),
              IconButton(
                onPressed: () => {},
                icon: Column(
                  children: [
                    Icon(
                      Icons.file_copy,
                      size: 50,
                    ),
                    SizedBox(height: 10),
                    Text(
                      'Diagnosis \nhistory',
                      style: TextStyle(),
                      textAlign: TextAlign.center,
                    ),
                  ],
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
