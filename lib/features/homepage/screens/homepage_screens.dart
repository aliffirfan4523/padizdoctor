import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:padizdoctor/app.dart';
import 'package:padizdoctor/features/camera_gallery/screens/gallery.dart';
import 'package:padizdoctor/features/homepage/services/homepage_service.dart';
import 'package:padizdoctor/features/settings/services/settings_controller.dart';
import 'package:padizdoctor/model/AppRoutes.dart';

import '../../../core/widgets/Recent_Scans_List.dart';
import '../../../core/widgets/reusable_header.dart';

class HomepageScreens extends StatefulWidget {
  HomepageScreens({super.key, required this.controller, required this.user});
  final SettingsController controller;
  var user = {};
  @override
  State<HomepageScreens> createState() => _HomepageScreensState();
}

class _HomepageScreensState extends State<HomepageScreens> {
  final service = HomepageService();
  var selectedIndex = 0;

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
        padding: EdgeInsets.only(left: 20.0, right: 20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            AppBar(
              leadingWidth: 55,
              centerTitle: true,
              leading: Padding(
                padding: const EdgeInsets.all(10.0),
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(40.0),
                  child: CachedNetworkImage(
                    imageUrl: widget.user["profilePicture"] ??
                        "https://static.vecteezy.com/system/resources/previews/043/338/613/non_2x/round-anonymous-person-icon-vector.jpg",
                    placeholder: (context, url) => Icon(Icons.person_4_rounded),
                    errorWidget: (context, url, error) => Icon(Icons.error),
                  ),
                ),
              ),
              title: Text("PadizDoctor"),
            ),
            SizedBox(height: 20),
            Text(
              'Good Morning,',
              style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
              textAlign: TextAlign.left,
            ),
            Text(
              'Farmer ${widget.user["fullName"].toString()}',
              style: TextStyle(fontSize: 16),
              textAlign: TextAlign.left,
            ),
            SizedBox(height: 30),
            Container(
              child: _buildAICard(),
            ),
            SizedBox(height: 30),
            /*
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text("Weekly Summary",
                    style:
                        TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                TextButton(
                  child: Text("View Report"),
                  onPressed: () {},
                )
              ],
            ),
            SizedBox(height: 10),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: [
                Expanded(
                  child: Card(
                    child: Container(
                      padding: EdgeInsets.all(10),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text("Crop Health",
                              style: TextStyle(
                                  fontSize: 12, fontWeight: FontWeight.bold)),
                          SizedBox(height: 8),
                          Text("Healthy", style: TextStyle(fontSize: 12)),
                        ],
                      ),
                    ),
                  ),
                ),
                Expanded(
                  child: Card(
                    child: Container(
                      padding: EdgeInsets.all(10),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text("Crop Health",
                              style: TextStyle(
                                  fontSize: 12, fontWeight: FontWeight.bold)),
                          SizedBox(height: 8),
                          Text("Healthy", style: TextStyle(fontSize: 12)),
                        ],
                      ),
                    ),
                  ),
                ),
                Expanded(
                  child: Card(
                    child: Container(
                      padding: EdgeInsets.all(10),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text("Total Scans",
                              style: TextStyle(
                                  fontSize: 12, fontWeight: FontWeight.bold)),
                          SizedBox(height: 8),
                          Text("123", style: TextStyle(fontSize: 12)),
                        ],
                      ),
                    ),
                  ),
                ),
              ],
            ),
            SizedBox(height: 20),*/
            buildHeader(
              title: "Recent Scans",
              onViewAll: () => Navigator.pushNamed(context, AppRoutes.allScans),
            ),
            // Shows only the 3 most recent scans
            //SizedBox(height: 10),
            RecentScansList(userId: widget.user["user_id"], limit: 3),
          ],
        ));
  }

  Widget _buildAICard() {
    return Container(
      width: double.infinity,
      decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(20),
          boxShadow: [
            BoxShadow(
              color: Colors.black12,
              blurRadius: 10,
              offset: Offset(0, 5),
            ),
          ],
          border: Border.all()),
      child: Column(
        children: [
          // 1. TOP CONTAINER (Image as Background)
          Container(
            width: double.infinity,
            height: 200,
            padding: EdgeInsets.all(16),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
              image: DecorationImage(
                image: AssetImage("assets/images/introgif.gif"), // Your image
                fit: BoxFit.cover,
                // Darken the image so white text stands out
                colorFilter: ColorFilter.mode(
                  Colors.black.withOpacity(0.4),
                  BlendMode.darken,
                ),
              ),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisAlignment:
                  MainAxisAlignment.end, // Pushes text to the bottom
              children: [
                // AI Scanner Tag
                Container(
                  padding: EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                  decoration: BoxDecoration(
                    color: Colors.white.withOpacity(0.2),
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: Colors.white38),
                  ),
                  child: Text(
                    "AI SCANNER",
                    style: TextStyle(
                        color: Colors.white,
                        fontSize: 10,
                        fontWeight: FontWeight.bold),
                  ),
                ),
                SizedBox(height: 8),
                Text(
                  "Detect Crop Disease",
                  style: TextStyle(
                      color: Colors.white,
                      fontSize: 22,
                      fontWeight: FontWeight.bold),
                ),
                Text(
                  "Tap to start scanning your crops for immediate AI analysis.",
                  style: TextStyle(color: Colors.white70, fontSize: 12),
                ),
              ],
            ),
          ),

          // 2. BOTTOM SECTION (Button)
          Padding(
            padding: EdgeInsets.all(16),
            child: ElevatedButton.icon(
              onPressed: () {
                Navigator.push(context,
                    MaterialPageRoute(builder: (context) => GalleryPicker()));
              },
              icon: Icon(Icons.qr_code_scanner, color: Colors.white),
              label:
                  Text("Start New Scan", style: TextStyle(color: Colors.white)),
              style: ElevatedButton.styleFrom(
                backgroundColor: Color(0xFF1B9D4A), // Green theme
                minimumSize: Size(double.infinity, 50),
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12)),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
