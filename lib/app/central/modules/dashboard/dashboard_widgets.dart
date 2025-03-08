import 'package:flutter/material.dart';

Widget sectionTitle(String title) {
  return Padding(
    padding: const EdgeInsets.symmetric(vertical: 8.0),
    child: Text(
      title,
      style: const TextStyle(
        fontSize: 20,
        fontWeight: FontWeight.bold,
        color: Colors.white,
      ),
    ),
  );
}

Widget communityPost(String postText) {
  return Padding(
    padding: const EdgeInsets.symmetric(vertical: 8),
    child: Row(
      children: [
        const Icon(Icons.campaign, color: Colors.white),
        const SizedBox(width: 10),
        Expanded(
          child: Text(postText, style: const TextStyle(color: Colors.white)),
        ),
      ],
    ),
  );
}
