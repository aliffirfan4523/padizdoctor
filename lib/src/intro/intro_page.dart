import 'package:flutter/material.dart';
import 'package:padizdoctor/src/screens/signin_screen.dart';
import 'package:shared_preferences/shared_preferences.dart';

class IntroPage extends StatelessWidget {
  const IntroPage({super.key});

  Future<void> _finishIntro(BuildContext context) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool("isFirstTime", false);
    Navigator.pushReplacementNamed(context, "/home");
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
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
          ElevatedButton(
            onPressed: () => SignInScreen(context),
            child: const Text("Continue"),
          )
        ],
      ),
    );
  }
}
