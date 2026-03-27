import 'package:flutter/material.dart';

class AppTextStyles {
  static const headline = TextStyle(
    fontSize: 30,
    fontWeight: FontWeight.bold,
  ); // Large important text (page title, section title)

  static const title = TextStyle(fontSize: 24, fontWeight: FontWeight.w800);

  static const subtitle = TextStyle(fontSize: 18, fontWeight: FontWeight.w700);

  static const body = TextStyle(fontSize: 16);

  static const caption = TextStyle(
    fontSize: 12,
  ); // Used for labels, timestamps, hints.
}
