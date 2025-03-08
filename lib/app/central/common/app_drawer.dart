import 'package:flutter/material.dart';

class AppDrawer extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Drawer(
      backgroundColor: Colors.black,
      child: ListView(
        padding: EdgeInsets.zero,
        children: [
          DrawerHeader(
            decoration: BoxDecoration(color: Colors.grey[900]),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const CircleAvatar(
                  backgroundColor: Colors.white,
                  radius: 30,
                  child: Icon(Icons.person, color: Colors.black, size: 35),
                ),
                const SizedBox(height: 10),
                const Text(
                  "Central Government",
                  style: TextStyle(color: Colors.white, fontSize: 18),
                ),
              ],
            ),
          ),
          ListTile(
            leading: const Icon(Icons.dashboard, color: Colors.white),
            title: const Text(
              "Dashboard",
              style: TextStyle(color: Colors.white),
            ),
            onTap: () => Navigator.pop(context),
          ),
          ListTile(
            leading: const Icon(Icons.group, color: Colors.white),
            title: const Text(
              "Community",
              style: TextStyle(color: Colors.white),
            ),
            onTap: () {},
          ),
          ListTile(
            leading: const Icon(Icons.storage, color: Colors.white),
            title: const Text(
              "Inventory",
              style: TextStyle(color: Colors.white),
            ),
            onTap: () {},
          ),
          ListTile(
            leading: const Icon(Icons.settings, color: Colors.white),
            title: const Text(
              "Settings",
              style: TextStyle(color: Colors.white),
            ),
            onTap: () {},
          ),
          const Divider(color: Colors.white30),
          ListTile(
            leading: const Icon(Icons.logout, color: Colors.red),
            title: const Text("Logout", style: TextStyle(color: Colors.red)),
            onTap: () {},
          ),
        ],
      ),
    );
  }
}
