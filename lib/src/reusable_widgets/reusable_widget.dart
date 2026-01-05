import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';

Image logoWidget(String imageName) {
  return Image.asset(
    imageName,
    fit: BoxFit.fitWidth,
    width: 240,
    height: 240,
    //color: Colors.white,
  );
}

Container signInSignUpButton(BuildContext context, bool isLogin, Function onTap,
    {required int borderRadius,
    required textColor,
    required Color buttonColor}) {
  return Container(
    width: MediaQuery.of(context).size.width,
    height: 50,
    margin: const EdgeInsets.fromLTRB(0, 10, 0, 20),
    decoration: BoxDecoration(borderRadius: BorderRadius.circular(90)),
    child: ElevatedButton(
      onPressed: () {
        onTap();
      },
      style: ButtonStyle(
          backgroundColor: MaterialStateProperty.resolveWith((states) {
            if (states.contains(MaterialState.pressed)) {
              return Colors.black26;
            }
            return Colors.white;
          }),
          shape: MaterialStateProperty.all<RoundedRectangleBorder>(
              RoundedRectangleBorder(borderRadius: BorderRadius.circular(30)))),
      child: Text(
        isLogin ? 'LOG IN' : 'SIGN UP',
        style: const TextStyle(
            color: Colors.black87, fontWeight: FontWeight.bold, fontSize: 16),
      ),
    ),
  );
}

String formatTimestamp(Timestamp? timestamp) {
  if (timestamp == null) return "";
  var date = timestamp.toDate();
  return "${date.hour}:${date.minute.toString().padLeft(2, '0')}";
}

// Helpers for dynamic UI
Color getStatusColor(String? status) {
  if (status == "Healthy") return Colors.greenAccent;
  if (status == "Low") return Colors.yellowAccent;
  if (status == "MEDIUM") return Colors.orangeAccent;
  return Colors.redAccent;
}

IconData getStatusIcon(String? status) {
  if (status == "Healthy") return Icons.check_circle;
  if (status == "Moderate Risk") return Icons.warning;
  return Icons.error;
}
