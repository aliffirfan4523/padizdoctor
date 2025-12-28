import 'package:cached_network_image/cached_network_image.dart';
import 'package:fluentui_system_icons/fluentui_system_icons.dart';
import 'package:flutter/material.dart';
import 'package:padizdoctor/src/auth/auth_service.dart';
import 'package:padizdoctor/src/auth/change_password_page.dart';
import 'package:padizdoctor/src/common_widget/theme_toggle_button.dart';
import 'package:padizdoctor/src/reusable_widgets/text_button.dart';
import 'package:padizdoctor/src/settings/settings_controller.dart';
import 'package:padizdoctor/src/user/user_profile/user_service.dart';

class MyProfile extends StatefulWidget {
  MyProfile({super.key, required this.controller, required this.user});
  var user = {};
  final SettingsController controller;
  @override
  State<MyProfile> createState() => _MyProfileState();
}

class _MyProfileState extends State<MyProfile> {
  UserService service = UserService();
  TextEditingController fullNameController = TextEditingController();
  TextEditingController emailController = TextEditingController();
  bool isInfoChanged = false;

  @override
  void initState() {
    super.initState();

    fullNameController.text = widget.user["fullName"] ?? "";
    emailController.text = widget.user["email"] ?? "";
  }

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
        child: Padding(
      padding: const EdgeInsets.only(left: 20.0, right: 20.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(height: 20),
          Text("My Profiles",
              style: TextStyle(fontSize: 26, fontWeight: FontWeight.bold)),
          SizedBox(height: 20),
          Center(
            child: Column(
              children: [
                Container(
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    border: Border.all(color: Colors.green, width: 4),
                  ),
                  height: 120,
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(200),
                    child: CachedNetworkImage(
                      imageUrl: widget.user["profilePicture"],
                      fit: BoxFit.cover,
                      placeholder: (context, url) =>
                          const Center(child: CircularProgressIndicator()),
                      errorWidget: (context, url, error) =>
                          const Icon(Icons.person),
                    ),
                  ),
                ),
                Text(
                  widget.user["fullName"] ?? "Guest User",
                  style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
                ),
              ],
            ),
          ),
          SizedBox(height: 20),
          Text("Personal Information",
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
          Padding(
            padding: const EdgeInsets.only(top: 10.0, bottom: 10.0),
            child: Text("Full Name"),
          ),
          TextFormField(
            controller: fullNameController,
            decoration: InputDecoration(
              border: OutlineInputBorder(),
            ),
            onChanged: (value) {
              if (widget.user["fullName"] != value) {
                setState(() {
                  isInfoChanged = true;
                });
              } else {
                setState(() {
                  isInfoChanged = false;
                });
              }
            },
          ),
          Padding(
            padding: const EdgeInsets.only(top: 20.0, bottom: 10.0),
            child: Text("Email Address"),
          ),
          TextFormField(
            controller: emailController,
            decoration: InputDecoration(
              border: OutlineInputBorder(),
            ),
            onChanged: (value) {
              if (widget.user["email"] != value) {
                setState(() {
                  isInfoChanged = true;
                });
              } else {
                setState(() {
                  isInfoChanged = false;
                });
              }
            },
          ),
          SizedBox(height: 20),
          Text("Account Settings",
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
          ListTile(
            title: Text("Change Password"),
            trailing: Icon(Icons.arrow_forward_ios),
            onTap: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => ChangePasswordPage(),
                ),
              );
            },
          ),
          SizedBox(height: 20),
          Text("App Settings",
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
          SizedBox(height: 10),
          ListTile(
            title: Text("Theme"),
            leading: Icon(FluentIcons.paint_brush_24_regular),
            trailing: ToggleButtons(
              borderRadius: BorderRadius.circular(1000),
              isSelected: options
                  .map((option) => widget.controller.themeMode == option.theme)
                  .toList(),
              onPressed: (index) {
                widget.controller.updateThemeMode(options[index].theme);
              },
              children: options.map((option) => option.widget).toList(),
            ),
          ),
          SizedBox(height: 20),
          TextColorButton(
              isInfoChanged ? Colors.green : Colors.grey, "Save Changes", () {
            if (isInfoChanged) {
              service.updateUserInfo(
                fullNameController.text,
                emailController.text,
              );
              setState(() {
                isInfoChanged = false;
              });
            }
          }),
          SizedBox(height: 10),
          TextColorButton(Colors.red, "Log Out", () {
            Navigator.of(context).pop();
            AuthService.instance.signOut();
            Navigator.pushReplacementNamed(context, "/login");
          }),
        ],
      ),
    ));
  }
}
