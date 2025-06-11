import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:flutter/material.dart';
import '../../common/app_drawer.dart';
import '../../common/bottom_nav.dart';
import '../../common/dashboard_card.dart';
import '../../common/translatable_text.dart';
import '../../common/language_selection_dialog.dart';
import '../community/community_page.dart';
import '../Teams/teams_page.dart';
import '../inventory/inventory_page.dart';
import '../settings/settings_page.dart';
import 'earthquake_details_page.dart'; // Renamed from disaster_details_page.dart
import 'flood_details_page.dart';
import 'package:gsc/models/disaster_event.dart';
import 'package:gsc/models/flood_prediction.dart';
import 'package:gsc/models/cyclone_prediction.dart';
import 'package:gsc/models/earthquake_prediction.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';
import 'cyclone_details_page.dart'; // Import for navigation
import 'flood_details_page.dart'; // Import for FloodDetailsPage
import 'active_disaster_details_page.dart'; // Import for the new details page
import 'package:gsc/services/disaster_service.dart'; // Added for DisasterService
// import 'package:http/http.dart' as http; // Already imported

import 'package:gsc/services/translation_service.dart';

class DashboardView extends StatefulWidget {
  const DashboardView({Key? key}) : super(key: key);

  @override
  _DashboardViewState createState() => _DashboardViewState();
}

class _DashboardViewState extends State<DashboardView> {
  List<DisasterEvent> disasterEvents = [];
  // Instantiate DisasterService
  final DisasterService _disasterService = DisasterService(client: http.Client());

  final List<Map<String, dynamic>> representativeLocations = [
    {'name': 'Delhi', 'lat': 28.7041, 'lon': 77.1025},
    {'name': 'Mumbai', 'lat': 19.0760, 'lon': 72.8777},
    {'name': 'Kolkata', 'lat': 22.5726, 'lon': 88.3639},
    {'name': 'Chennai', 'lat': 13.0827, 'lon': 80.2707},
    {'name': 'Bengaluru', 'lat': 12.9716, 'lon': 77.5946},
    {'name': 'Hyderabad', 'lat': 17.3850, 'lon': 78.4867},
    {'name': 'Ahmedabad', 'lat': 23.0225, 'lon': 72.5714},
    {'name': 'Pune', 'lat': 18.5204, 'lon': 73.8567},
    {'name': 'Jaipur', 'lat': 26.9124, 'lon': 75.7873},
    {'name': 'Lucknow', 'lat': 26.8467, 'lon': 80.9462},
    // Add more locations as desired for demonstration
  ];

  @override
  void initState() {
    super.initState();
    fetchDisasterData();
  }

  Future<void> fetchDisasterData() async {
    List<DisasterEvent> allFetchedDisasterData = [];
    const newFloodApiUrl = 'https://flood-api-756506665902.us-central1.run.app/predict';
    const newCycloneApiUrl = 'https://cyclone-api-756506665902.asia-south1.run.app/predict';
    const newEarthquakeApiUrl = 'https://my-python-app-wwb655aqwa-uc.a.run.app/';

    // --- Earthquake (fetches once) ---
    try {
      final response = await http.get(Uri.parse(newEarthquakeApiUrl));
      if (response.statusCode == 200) {
        final earthquakeData = jsonDecode(response.body);
        final earthquakePrediction = EarthquakePrediction.fromJson(earthquakeData);
        // Optional: Filter if earthquake API might return "no significant event"
        // For now, assuming it always returns something relevant or empty highRiskCities list
        allFetchedDisasterData.add(DisasterEvent(
          type: DisasterType.earthquake,
          predictionData: earthquakePrediction,
          timestamp: DateTime.now(),
        ));
      } else {
        print('Earthquake API Error: ${response.statusCode}');
      }
    } catch (e) {
      print('Earthquake API Exception: $e');
    }

    // --- Flood and Cyclone (iterate through representativeLocations) ---
    for (var locData in representativeLocations) {
      final double lat = locData['lat'];
      final double lon = locData['lon'];
      final String cityName = locData['name'];

      // Flood API Call for current location
      try {
        final floodResponse = await http.post(
          Uri.parse(newFloodApiUrl),
          headers: {"Content-Type": "application/json"},
          body: jsonEncode({"lat": lat, "lon": lon}),
        );
        if (floodResponse.statusCode == 200) {
          final data = jsonDecode(floodResponse.body);
          final prediction = FloodPrediction.fromJson(data);
          if (prediction.floodRisk.toLowerCase() != "no flood") {
            allFetchedDisasterData.add(DisasterEvent(
              type: DisasterType.flood,
              predictionData: prediction,
              timestamp: DateTime.now(),
              // Consider adding cityName or original lat/lon to DisasterEvent if needed for context
            ));
          }
        } else {
          print('Flood API Error for $cityName: ${floodResponse.statusCode}');
        }
      } catch (e) {
        print('Flood API Exception for $cityName: $e');
      }

      // Cyclone API Call for current location
      try {
        final cycloneResponse = await http.post(
          Uri.parse(newCycloneApiUrl),
          headers: {"Content-Type": "application/json"},
          body: jsonEncode({"lat": lat, "lon": lon}),
        );
        if (cycloneResponse.statusCode == 200) {
          final data = jsonDecode(cycloneResponse.body);
          final prediction = CyclonePrediction.fromJson(data);
          if (prediction.cycloneCondition.toLowerCase() != "no cyclone" &&
              prediction.cycloneCondition.toLowerCase() != "no active cyclones detected") {
            allFetchedDisasterData.add(DisasterEvent(
              type: DisasterType.cyclone,
              predictionData: prediction,
              timestamp: DateTime.now(),
            ));
          }
        } else {
          print('Cyclone API Error for $cityName: ${cycloneResponse.statusCode}');
        }
      } catch (e) {
        print('Cyclone API Exception for $cityName: $e');
      }
    }

    if (mounted) {
      setState(() {
        disasterEvents = allFetchedDisasterData;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    // Prepare markers for the map
    List<Marker> mapMarkers = disasterEvents.map((event) {
      LatLng? point;
      Color markerColor = Colors.grey;
      IconData markerIcon = Icons.place;

      if (event.type == DisasterType.flood) {
        final data = event.predictionData as FloodPrediction;
        point = LatLng(data.lat, data.lon);
        markerColor = Colors.blue;
        markerIcon = Icons.water_drop;
      } else if (event.type == DisasterType.cyclone) {
        final data = event.predictionData as CyclonePrediction;
        point = LatLng(data.location.latitude, data.location.longitude);
        markerColor = Colors.orange;
        markerIcon = Icons.cyclone;
      } else if (event.type == DisasterType.earthquake) {
        // final data = event.predictionData as EarthquakePrediction;
        // Simplified: Earthquake markers are skipped if direct LatLng is not available.
        // A proper implementation would require geocoding city names.
        // For now, we can assign a generic icon and color but no point unless one is available.
        markerColor = Colors.brown;
        markerIcon = Icons.volcano;
        // If you have a representative LatLng for earthquakes, assign it to `point` here.
        // Otherwise, `point` remains null and the marker won't be built.
      }

      if (point != null) {
        return Marker(
          width: 80.0,
          height: 80.0,
          point: point,
          child: GestureDetector(
            onTap: () {
              final eventData = event.predictionData;
              if (event.type == DisasterType.cyclone && eventData is CyclonePrediction) {
                Navigator.push(
                  context, // Using the main page's context
                  MaterialPageRoute(builder: (context) => CycloneDetailsPage(cyclonePrediction: eventData)),
                );
              } else if (event.type == DisasterType.flood && eventData is FloodPrediction) {
                Navigator.push(
                  context, // Using the main page's context
                  MaterialPageRoute(builder: (context) => FloodDetailsPage(floodPrediction: eventData)),
                );
              } else if (event.type == DisasterType.earthquake && eventData is EarthquakePrediction) {
                // This case might not be hit by map markers if they are not created for earthquakes without direct LatLng
                Navigator.push(
                  context, // Using the main page's context
                  MaterialPageRoute(builder: (context) => EarthquakeDetailsPage(earthquakePrediction: eventData)),
                );
              } else {
                ScaffoldMessenger.of(context).showSnackBar( // Using main page's context for ScaffoldMessenger
                  SnackBar(content: Text("No details page available for this map marker.")),
                );
              }
            },
            child: Tooltip(
              message: "${event.type.toString().split('.').last}: ${event.locationSummary}",
              child: Icon(
                markerIcon,
                color: markerColor,
                size: 40.0,
                semanticLabel: "${event.type.toString().split('.').last} marker",
              ),
            ),
          ),
        );
      }
      return null; // Return null for events that can't be mapped
    }).where((marker) => marker != null).cast<Marker>().toList(); // Filter out nulls


    return Scaffold(
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            transform: GradientRotation(-40 * 3.14159 / 180),
            colors: [
              Color(0xFF87CEEB), // Sky Blue
              Color(0xFF4682B4), // Steel Blue
            ],
            stops: [0.3, 1.0],
          ),
        ),
        child: SingleChildScrollView( // Added SingleChildScrollView
          child: Padding(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Overview Card (Kept from original layout)
              Card(
                elevation: 6,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                color: Colors.white.withOpacity(0.95),
                child: ListTile(
                  title: const TranslatableText(
                    "Disaster Overview", // Updated title
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: Color(0xFF1A324C),
                    ),
                  ),
                  leading: Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: const Color(0xFF3789BB).withOpacity(0.1),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: const Icon(
                      Icons.map_outlined, // Changed Icon
                      color: Color(0xFF3789BB),
                      size: 28,
                    ),
                  ),
                   trailing: Text(
                    "${disasterEvents.length} Active Event(s)",
                    style: TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.bold,
                      color: Color(0xFFD32F2F), // A crisis-related color
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 10),

              // Map Section
              SizedBox(
                height: 300, // Adjust height as needed
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(12.0),
                  child: FlutterMap(
                    options: MapOptions(
                      initialCenter: LatLng(20.5937, 78.9629), // Center of India
                      initialZoom: 4.0,
                    ),
                    children: [
                      TileLayer(
                        urlTemplate: 'https://{s}.tile.openstreetmap.org/{z}/{x}/{y}.png',
                        subdomains: const ['a', 'b', 'c'],
                      ),
                      MarkerLayer(markers: mapMarkers),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 10),

              // Disaster Cards List Section
              Expanded(
                child: ListView.builder(
                  itemCount: disasterEvents.length,
                  itemBuilder: (context, index) {
                    final event = disasterEvents[index];
                    return InkWell( // Wrapped Card with InkWell
                      onTap: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (context) => ActiveDisasterDetailsPage(
                              selectedEvent: event,
                              allDisasterEvents: disasterEvents, // Pass the full list
                            ),
                          ),
                        );
                      },
                      child: Card(
                        elevation: 4,
                        margin: const EdgeInsets.symmetric(vertical: 6.0, horizontal: 0),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: Padding(
                          padding: const EdgeInsets.all(12.0),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                              event.type.toString().split('.').last.toUpperCase(),
                              style: TextStyle(
                                fontWeight: FontWeight.bold,
                                fontSize: 16,
                                color: event.type == DisasterType.flood ? Colors.blue.shade700 :
                                       event.type == DisasterType.cyclone ? Colors.orange.shade700 :
                                       event.type == DisasterType.earthquake ? Colors.brown.shade700 :
                                       Colors.black,
                              ),
                            ),
                            const SizedBox(height: 6),
                            Text("Location: ${event.locationSummary}"),
                            const SizedBox(height: 4),
                            Text("Details: ${event.severitySummary}"),
                            const SizedBox(height: 10),
                            Row(
                              mainAxisAlignment: MainAxisAlignment.end,
                              children: [
                                ElevatedButton(
                                  onPressed: () {
                                    final eventData = event.predictionData; // To make conditions cleaner
                                    if (event.type == DisasterType.cyclone && eventData is CyclonePrediction) {
                                      Navigator.push(
                                        context,
                                        MaterialPageRoute(
                                          builder: (context) => CycloneDetailsPage(cyclonePrediction: eventData),
                                        ),
                                      );
                                    } else if (event.type == DisasterType.flood && eventData is FloodPrediction) {
                                      Navigator.push(
                                        context,
                                        MaterialPageRoute(
                                          builder: (context) => FloodDetailsPage(floodPrediction: eventData),
                                        ),
                                      );
                                    } else if (event.type == DisasterType.earthquake && eventData is EarthquakePrediction) {
                                      Navigator.push(
                                        context,
                                        MaterialPageRoute(builder: (context) => EarthquakeDetailsPage(earthquakePrediction: eventData)),
                                      );
                                    } else {
                                      ScaffoldMessenger.of(context).showSnackBar(
                                        SnackBar(content: Text("Details page for ${event.type.toString().split('.').last} not implemented or data mismatch.")),
                                      );
                                    }
                                  },
                                  child: const TranslatableText("View Details"),
                                  style: ElevatedButton.styleFrom(
                                    backgroundColor: Colors.grey[200],
                                    foregroundColor: Colors.black87,
                                  )
                                ),
                                const SizedBox(width: 8),
                                ElevatedButton(
                                  onPressed: () async { // Made onPressed async
                                    try {
                                      await _disasterService.sendDisasterAlert(event);
                                      if (mounted) { // Check if the widget is still in the tree
                                        ScaffoldMessenger.of(context).showSnackBar(
                                          SnackBar(content: Text("Alert sent for ${event.type.toString().split('.').last}!")),
                                        );
                                      }
                                    } catch (e) {
                                      print("Error sending disaster alert from UI: $e");
                                      if (mounted) { // Check if the widget is still in the tree
                                        ScaffoldMessenger.of(context).showSnackBar(
                                          SnackBar(content: Text("Failed to send alert for ${event.type.toString().split('.').last}. Error: $e")),
                                        );
                                      }
                                    }
                                  },
                                  child: const TranslatableText("Raise Alert"),
                                  style: ElevatedButton.styleFrom(
                                    backgroundColor: Colors.red.shade600,
                                    foregroundColor: Colors.white,
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),
                    );
                  },
                ),
              ),
               const SizedBox(height: 10), // Spacing before the GridView
              // Existing Quick Actions GridView (kept as per revised plan)
              const TranslatableText(
                "Quick Actions",
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: Colors.white,
                ),
              ),
              const SizedBox(height: 10),
              // Removed Expanded from GridView. GridView will take its natural height.
              // If scrolling is needed for the whole page, the outer Column should be in a SingleChildScrollView.
              GridView.count(
                crossAxisCount: 2,
                crossAxisSpacing: 12,
                mainAxisSpacing: 12,
                childAspectRatio: 1.2,
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                children: [
                  // Note: The "Active Disasters" card is removed as per plan
                  DashboardCard(
                      title: "Add Refugee Camp",
                      count: "4", // Example count
                      icon: Icons.add_location_alt,
                      onTap: () {
                        Navigator.pushNamed(context, '/camp');
                      },
                    ),
                    DashboardCard(
                      title: "Ongoing SOS Alerts",
                      count: "12", // Example count
                      icon: Icons.sos_outlined,
                      onTap: () {
                        Navigator.pushNamed(context, '/sos_alerts');
                      },
                    ),
                    DashboardCard(
                      title: "Rescue Teams", // Simplified title
                      count: "5", // Example count
                      icon: Icons.groups_rounded,
                      onTap: () {
                        Navigator.pushNamed(context, '/deployed_teams');
                      },
                    ),
                    DashboardCard(
                      title: "Central Inventory",
                      count: "150 Items", // Example count
                      icon: Icons.inventory,
                      onTap: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (context) => InventoryPage(),
                          ),
                        );
                      },
                    ),
                  ],
                ),
            ],
          ),
        ),
      ),
    );
  }
}

// Main Dashboard Page
class CentralDashboardPage extends StatefulWidget {
  const CentralDashboardPage({Key? key}) : super(key: key);

  @override
  State<CentralDashboardPage> createState() => _CentralDashboardPageState();
}

class _CentralDashboardPageState extends State<CentralDashboardPage> {
  int _selectedIndex = 0;

  final List<Widget> _pages = [
    const DashboardView(),
    CommunityPage(),
    const InventoryPage(),
    const SettingsPage(),
  ];

  void _onItemTapped(int index) {
    setState(() {
      _selectedIndex = index;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: const Color(0xFF1A324C),
        title: const TranslatableText(
          "Central Government Dashboard",
          style: TextStyle(color: Colors.white),
        ),
        iconTheme: const IconThemeData(color: Colors.white),
        actions: [
          IconButton(
            icon: const Icon(Icons.language, color: Colors.white),
            onPressed: () {
              showDialog(
                context: context,
                builder: (context) => const LanguageSelectionDialog(),
              );
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
      body: _pages[_selectedIndex],
      drawer: const AppDrawer(),
      floatingActionButton: FloatingActionButton(
        backgroundColor: const Color(0xFF3789BB),
        onPressed: () {
          Navigator.pushNamed(context, '/ai_chatbot');
        },
        child: Image.asset('assets/chatbot.png', width: 35, height: 35),
      ),
      floatingActionButtonLocation: FloatingActionButtonLocation.endFloat,
      bottomNavigationBar: BottomNavBar(
        selectedIndex: _selectedIndex,
        onTap: _onItemTapped,
      ),
    );
  }
}