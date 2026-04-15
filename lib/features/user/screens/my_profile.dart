import 'package:cached_network_image/cached_network_image.dart';
import 'package:fluentui_system_icons/fluentui_system_icons.dart';
import 'package:flutter/material.dart';
import 'package:padizdoctor/features/auth/services/auth_service.dart';
import 'package:padizdoctor/features/auth/screens/change_password_page.dart';
import 'package:padizdoctor/core/widgets/theme_toggle_button.dart';
import 'package:padizdoctor/core/widgets/text_button.dart';
import 'package:padizdoctor/features/settings/services/settings_controller.dart';
import 'package:padizdoctor/features/user/services/user_service.dart';

class MyProfile extends StatefulWidget {
  MyProfile({super.key, required this.controller, required this.user});
  var user = {};
  final SettingsController controller;
  @override
  State<MyProfile> createState() => _MyProfileState();
}

class _MyProfileState extends State<MyProfile> {
  final _formKey = GlobalKey<FormState>();
  UserService service = UserService();
  TextEditingController fullNameController = TextEditingController();
  TextEditingController emailController = TextEditingController();
  bool isNameChanged = false;
  bool isEmailChanged = false;

  void loadUserData() {
    fullNameController.text = widget.user["fullName"] ?? "";
    emailController.text = widget.user["email"] ?? "";
  }

  @override
  void initState() {
    super.initState();
    loadUserData();
  }

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: SingleChildScrollView(
        child: Padding(
          padding: const EdgeInsets.only(left: 20.0, right: 20.0),
          child: Form(
            key: _formKey,
            autovalidateMode: AutovalidateMode.onUserInteraction,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                SizedBox(height: 50),
                Center(
                  child: Column(
                    children: [
                      Container(
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          border: Border.all(color: Colors.green, width: 4),
                        ),
                        height: 90,
                        child: ClipRRect(
                          borderRadius: BorderRadius.circular(200),
                          child: CachedNetworkImage(
                            imageUrl: widget.user["profilePicture"],
                            fit: BoxFit.cover,
                            placeholder: (context, url) => const Center(
                                child: CircularProgressIndicator()),
                            errorWidget: (context, url, error) =>
                                const Icon(Icons.person),
                          ),
                        ),
                      ),
                      Text(
                        widget.user["fullName"] ?? "Guest User",
                        style: TextStyle(
                            fontSize: 24, fontWeight: FontWeight.bold),
                      ),
                    ],
                  ),
                ),
                SizedBox(height: 20),
                Text("Personal Information",
                    style:
                        TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                Padding(
                  padding: const EdgeInsets.only(top: 10.0, bottom: 10.0),
                  child: Text("Full Name"),
                ),
                TextFormField(
                  controller: fullNameController,
                  decoration: InputDecoration(
                      border: OutlineInputBorder(),
                      suffixIcon: isNameChanged
                          ? IconButton(
                              onPressed: () {
                                loadUserData();
                                isNameChanged = false;
                              },
                              icon: Icon(Icons.clear))
                          : null),
                  onChanged: (value) {
                    if (widget.user["fullName"] != value) {
                      setState(() {
                        isNameChanged = true;
                      });
                    } else {
                      setState(() {
                        isNameChanged = false;
                      });
                    }
                  },
                ),
                Padding(
                  padding: const EdgeInsets.only(top: 10.0, bottom: 10.0),
                  child: Text("Email Address"),
                ),
                TextFormField(
                  controller: emailController,
                  decoration: InputDecoration(
                    border: OutlineInputBorder(),
                    suffixIcon: isEmailChanged
                        ? IconButton(
                            onPressed: () {
                              loadUserData();
                              isEmailChanged = false;
                            },
                            icon: Icon(Icons.clear),
                          )
                        : null,
                  ),
                  onChanged: (value) {
                    if (widget.user["email"] != value) {
                      setState(() {
                        isEmailChanged = true;
                      });
                    } else {
                      setState(() {
                        isEmailChanged = false;
                      });
                    }
                  },
                  validator: (value) {
                    if (value == null || value.isEmpty) {
                      return 'Please enter an email';
                    }
                    final emailRegex = RegExp(
                        r'^[^@\s]+@[^@\s]+\.[^@\s]+$'); // Simple email validation
                    if (!emailRegex.hasMatch(value)) {
                      return 'Please enter a valid email address';
                    }
                    return null;
                  },
                ),
                SizedBox(height: 20),
                Text("Account Settings",
                    style:
                        TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
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
                SizedBox(height: 10),
                Text("App Settings",
                    style:
                        TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                SizedBox(height: 10),
                ListTile(
                  title: Text("Theme"),
                  leading: Icon(FluentIcons.paint_brush_24_regular),
                  trailing: ToggleButtons(
                    borderRadius: BorderRadius.circular(1000),
                    isSelected: options
                        .map((option) =>
                            widget.controller.themeMode == option.theme)
                        .toList(),
                    onPressed: (index) {
                      widget.controller.updateThemeMode(options[index].theme);
                    },
                    children: options.map((option) => option.widget).toList(),
                  ),
                ),
                SizedBox(height: 20),
                TextColorButton(
                    isEmailChanged || isNameChanged
                        ? Colors.green
                        : Colors.grey,
                    "Save Changes", () {
                  if (isEmailChanged || isNameChanged) {
                    if (_formKey.currentState!.validate()) {
                      service.updateUserInfo(
                        fullNameController.text,
                        emailController.text,
                      );
                      setState(() {
                        isEmailChanged = false;
                        isNameChanged = false;
                      });
                    }
                  }
                }),
                SizedBox(height: 10),
                TextColorButton(Colors.red, "Log Out", () {
                  Navigator.of(context).pop();
                  AuthService.instance.signOut();
                  Navigator.pushNamed(context, "/login");
                }),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
