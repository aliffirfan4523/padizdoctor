import 'package:flutter/material.dart';

InkWell TextColorButton(Color color, String text, Function()? onTap) {
  return InkWell(
    onTap: onTap,
    child: Container(
        alignment: Alignment.center,
        width: double.infinity,
        height: 40,
        decoration: BoxDecoration(
            color: color, borderRadius: BorderRadius.all(Radius.circular(25))),
        child: Text(text,
            style: TextStyle(fontSize: 15, fontWeight: FontWeight.bold))),
  );
}
