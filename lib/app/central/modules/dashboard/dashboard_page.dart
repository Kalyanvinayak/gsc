import 'package:flutter/material.dart';
import '../../common/app_drawer.dart';
import '../../common/bottom_nav.dart';
import '../../common/dashboard_card.dart';
import '../community/community_page.dart';
import '../inventory/inventory_page.dart';
import '../settings/settings_page.dart';

class CentralDashboardPage extends StatefulWidget {
  const CentralDashboardPage({super.key});

  @override
  State<CentralDashboardPage> createState() => _CentralDashboardPageState();
}

class _CentralDashboardPageState extends State<CentralDashboardPage> {
  int _selectedIndex = 0;

  final List<Widget> _pages = [
    DashboardView(),
    CommunityPage(),
    InventoryPage(),
    SettingsPage(),
  ];

  void _onItemTapped(int index) {
    setState(() {
      _selectedIndex = index;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        backgroundColor: Colors.black,
        title: const Text("Central Government Dashboard"),
        actions: [
          IconButton(
            icon: const Icon(Icons.language, color: Colors.white),
            onPressed: () {
              // TODO: Implement Language Change Feature
            },
          ),
          IconButton(
            icon: const Icon(Icons.account_circle, color: Colors.white),
            onPressed: () {
              // TODO: Implement Profile Page Navigation
            },
          ),
        ],
      ),
      drawer: AppDrawer(), // Sidebar Menu
      body: _pages[_selectedIndex], // Dynamic Content
      bottomNavigationBar: BottomNavBar(
        selectedIndex: _selectedIndex,
        onTap: _onItemTapped,
      ),
    );
  }
}

// **Dashboard Content**
class DashboardView extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    double screenWidth = MediaQuery.of(context).size.width;

    return SingleChildScrollView(
      padding: const EdgeInsets.all(16.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            "Overview",
            style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.bold,
              color: Colors.white,
            ),
          ),
          const SizedBox(height: 10),

          LayoutBuilder(
            builder: (context, constraints) {
              int crossAxisCount = (screenWidth < 600) ? 1 : 2;

              return GridView.builder(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                  crossAxisCount: crossAxisCount,
                  crossAxisSpacing: 10,
                  mainAxisSpacing: 10,
                  childAspectRatio: (screenWidth < 400) ? 2.5 : 1.8,
                ),
                itemCount: 4,
                itemBuilder: (context, index) {
                  List<Map<String, dynamic>> cardData = [
                    {
                      "title": "Active Disasters",
                      "count": "5",
                      "icon": Icons.warning,
                    },
                    {
                      "title": "Central Inventory",
                      "count": "150 Items",
                      "icon": Icons.storage,
                    },
                    {
                      "title": "Ongoing SOS Alerts",
                      "count": "12",
                      "icon": Icons.sos,
                    },
                    {
                      "title": "Rescue Teams Deployed",
                      "count": "30",
                      "icon": Icons.people,
                    },
                  ];
                  return DashboardCard(
                    title: cardData[index]["title"],
                    count: cardData[index]["count"],
                    icon: cardData[index]["icon"],
                  );
                },
              );
            },
          ),
        ],
      ),
    );
  }
}
