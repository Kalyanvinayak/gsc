import 'dart:convert';

import 'dart:math';

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

import 'earthquake_details_page.dart';

import 'flood_details_page.dart';

import '../../../../models/disaster_event.dart';

import '../../../../models/cyclone_prediction.dart';

import '../../../../models/earthquake_prediction.dart';

import '../../../../models/flood_prediction.dart';

import 'package:flutter_map/flutter_map.dart';

import 'package:latlong2/latlong.dart';

import 'cyclone_details_page.dart';

import '../../../../services/translation_service.dart';
import 'dart:math';



class IndianLocationGenerator {
  static final Random _random = Random();
  
  // India's approximate geographical bounds
  static const double _minLatitude = 8.0;    // Southern tip (near Kanyakumari)
  static const double _maxLatitude = 37.0;   // Northern tip (Ladakh)
  static const double _minLongitude = 68.0;  // Western tip (Gujarat)
  static const double _maxLongitude = 97.0;  // Eastern tip (Arunachal Pradesh)
  
  // Optional: List of major Indian cities for reference names
  static final List<String> _indianCities = [
    'Delhi', 'Mumbai', 'Bangalore', 'Hyderabad', 'Ahmedabad', 'Chennai',
    'Kolkata', 'Surat', 'Pune', 'Jaipur', 'Lucknow', 'Kanpur', 'Nagpur',
    'Indore', 'Thane', 'Bhopal', 'Visakhapatnam', 'Pimpri', 'Patna',
    'Vadodara', 'Ghaziabad', 'Ludhiana', 'Agra', 'Nashik', 'Faridabad',
    'Meerut', 'Rajkot', 'Kalyan', 'Vasai', 'Varanasi', 'Srinagar',
    'Aurangabad', 'Dhanbad', 'Amritsar', 'Navi Mumbai', 'Allahabad',
    'Ranchi', 'Howrah', 'Coimbatore', 'Jabalpur', 'Gwalior', 'Vijayawada',
    'Jodhpur', 'Madurai', 'Raipur', 'Kota', 'Guwahati', 'Chandigarh',
    'Solapur', 'Hubli', 'Tiruchirappalli', 'Bareilly', 'Mysore', 'Tiruppur'
  ];
  
  /// Generate a random coordinate within India's bounds
  static List<double> generateRandomLocation() {
    double lat = _minLatitude + _random.nextDouble() * (_maxLatitude - _minLatitude);
    double lon = _minLongitude + _random.nextDouble() * (_maxLongitude - _minLongitude);
    
    // Round to 4 decimal places for reasonable precision
    lat = double.parse(lat.toStringAsFixed(4));
    lon = double.parse(lon.toStringAsFixed(4));
    
    return [lat, lon];
  }
  
  /// Generate multiple random locations
  static List<List<double>> generateMultipleLocations(int count) {
    return List.generate(count, (index) => generateRandomLocation());
  }
  
  /// Generate random locations with more realistic distribution
  /// (weighted towards populated areas)
  static List<double> generateWeightedRandomLocation() {
    // Define regions with different weights
    List<Map<String, dynamic>> regions = [
      // Northern Plains (Higher population density)
      {'minLat': 24.0, 'maxLat': 32.0, 'minLon': 72.0, 'maxLon': 88.0, 'weight': 0.4},
      // Western India (High population)
      {'minLat': 15.0, 'maxLat': 26.0, 'minLon': 68.0, 'maxLon': 77.0, 'weight': 0.3},
      // Southern India (Moderate population)
      {'minLat': 8.0, 'maxLat': 20.0, 'minLon': 74.0, 'maxLon': 80.0, 'weight': 0.2},
      // Eastern India
      {'minLat': 20.0, 'maxLat': 28.0, 'minLon': 85.0, 'maxLon': 97.0, 'weight': 0.1},
    ];
    
    // Select region based on weight
    double randomValue = _random.nextDouble();
    double cumulativeWeight = 0.0;
    Map<String, dynamic> selectedRegion = regions.first;
    
    for (var region in regions) {
      cumulativeWeight += region['weight'];
      if (randomValue <= cumulativeWeight) {
        selectedRegion = region;
        break;
      }
    }
    
    // Generate coordinates within selected region
    double lat = selectedRegion['minLat'] + 
                _random.nextDouble() * (selectedRegion['maxLat'] - selectedRegion['minLat']);
    double lon = selectedRegion['minLon'] + 
                _random.nextDouble() * (selectedRegion['maxLon'] - selectedRegion['minLon']);
    
    lat = double.parse(lat.toStringAsFixed(4));
    lon = double.parse(lon.toStringAsFixed(4));
    
    return [lat, lon];
  }
}

// Usage Examples:

// Generate 20 random coordinate pairs [lat, lon]
List<List<double>> coordinatePairs = 
    IndianLocationGenerator.generateMultipleLocations(20);

// Or generate weighted random coordinates (more realistic distribution)
List<List<double>> weightedCoordinates = 
    List.generate(20, (index) => IndianLocationGenerator.generateWeightedRandomLocation());

// Single random coordinate pair
List<double> singleCoordinate = IndianLocationGenerator.generateRandomLocation();

// Example: Creating your list format from random coordinates
List<Map<String, dynamic>> representativeLocations = List.generate(18, (index) {
  List<double> coords = IndianLocationGenerator.generateRandomLocation();
  return {
    'name': 'Location_$index',
    'lat': coords[0],
    'lon': coords[1],
  };
});

// Or if you just want the coordinate pairs:
List<List<double>> randomCoordinates = IndianLocationGenerator.generateMultipleLocations(18);

class DashboardView extends StatefulWidget {
  const DashboardView({Key? key}) : super(key: key);

  @override
  _DashboardViewState createState() => _DashboardViewState();
}

class _DashboardViewState extends State<DashboardView> {
  // Renamed to better reflect it holds all events before processing

  List<DisasterEvent> allDisasterEvents = [];

  // NEW: State variables to hold separated lists of disasters

  List<DisasterEvent> topPriorityDisasters = [];

  List<dynamic> combinedDisasterListForUI = [];

  int _topPriorityDisasterCount = 0;

  bool _isLoading = true;

  bool _isFloodSignificant(FloodPrediction prediction) {
    final risk = prediction.floodRisk.toLowerCase();
    // Only show medium, high, or severe floods
    return risk == 'medium' || risk == 'high' || risk == 'severe';
  }

  // MODIFIED: Helper function to check if cyclone meets minimum category criteria
  bool _isCycloneSignificant(CyclonePrediction prediction) {
    final category = _getCycloneCategory(prediction.cycloneCondition);
    // Only show category 1 and above
    return category >= 1;
  }

  @override
  void initState() {
    super.initState();

    fetchDisasterData();
  }

  int _getCycloneCategory(String condition) {
    if (condition.toLowerCase().contains("category")) {
      try {
        var catNumberString =
            condition.toLowerCase().split("category")[1].trim().split(" ")[0];

        return int.tryParse(catNumberString) ?? 0;
      } catch (e) {
        print("Could not parse cyclone category: $e");

        return 0;
      }
    }

    return 0;
  }

  // NEW: Helper function to assign a numeric severity score to each disaster for sorting.

  double _getSeverityScore(DisasterEvent event) {
    switch (event.type) {
      case DisasterType.earthquake:
        final data = event.predictionData as EarthquakePrediction;
        if (data.highRiskCities.isEmpty) return 0.0;
        return data.highRiskCities.map((c) => c.magnitude).reduce(max);

      case DisasterType.cyclone:
        final data = event.predictionData as CyclonePrediction;
        final category = _getCycloneCategory(data.cycloneCondition);
        // Return 0 if below category 1, otherwise return the category
        return category >= 1 ? category.toDouble() : 0.0;

      case DisasterType.flood:
        final data = event.predictionData as FloodPrediction;
        final risk = data.floodRisk.toLowerCase();
        // Only assign scores to medium and above
        if (risk == 'severe' || risk == 'extreme') return 4.0;
        if (risk == 'high') return 3.0;
        if (risk == 'medium') return 2.0;
        return 0.0; // Low risk gets 0, effectively filtering it out

      default:
        return 0.0;
    }
  }
  
  Future<void> fetchDisasterData() async {
    if (mounted) {
      setState(() {
        _isLoading = true;
      });
    }

    const newFloodApiUrl =
        'https://flood-api-756506665902.us-central1.run.app/predict';

    const newCycloneApiUrl =
        'https://cyclone-api-756506665902.asia-south1.run.app/predict';

    const newEarthquakeApiUrl =
        'https://my-python-app-wwb655aqwa-uc.a.run.app/';

    final List<Future> apiCallFutures = [
      http.get(Uri.parse(newEarthquakeApiUrl)),
    ];

    for (final locData in representativeLocations) {
      final double lat = locData['lat'];

      final double lon = locData['lon'];

      apiCallFutures.add(
        http.post(
          Uri.parse(newFloodApiUrl),

          headers: {"Content-Type": "application/json"},

          body: jsonEncode({"lat": lat, "lon": lon}),
        ),
      );

      apiCallFutures.add(
        http.post(
          Uri.parse(newCycloneApiUrl),

          headers: {"Content-Type": "application/json"},

          body: jsonEncode({"lat": lat, "lon": lon}),
        ),
      );
    }

    List<DisasterEvent> fetchedEvents = [];

    try {
      final List<dynamic> responses = await Future.wait(
        apiCallFutures.map((f) => f.catchError((e) => e)),
      );

      final earthquakeResponse = responses[0];

      if (earthquakeResponse is http.Response &&
          earthquakeResponse.statusCode == 200) {
        fetchedEvents.add(
          DisasterEvent(
            type: DisasterType.earthquake,

            predictionData: EarthquakePrediction.fromJson(
              jsonDecode(earthquakeResponse.body),
            ),

            timestamp: DateTime.now(),
          ),
        );
      }

      int locationIndex = 0;

      for (int i = 1; i < responses.length; i += 2) {
        final floodResponse = responses[i];

        if (floodResponse is http.Response && floodResponse.statusCode == 200) {
          final prediction = FloodPrediction.fromJson(
            jsonDecode(floodResponse.body),
          );

          if (prediction.floodRisk.toLowerCase() != "no flood") {
            fetchedEvents.add(
              DisasterEvent(
                type: DisasterType.flood,

                predictionData: prediction,

                timestamp: DateTime.now(),
              ),
            );
          }
        }

        final cycloneResponse = responses[i + 1];

        if (cycloneResponse is http.Response &&
            cycloneResponse.statusCode == 200) {
          final prediction = CyclonePrediction.fromJson(
            jsonDecode(cycloneResponse.body),
          );

          if (prediction.cycloneCondition.toLowerCase() != "no cyclone" &&
              prediction.cycloneCondition.toLowerCase() !=
                  "no active cyclones detected") {
            fetchedEvents.add(
              DisasterEvent(
                type: DisasterType.cyclone,

                predictionData: prediction,

                timestamp: DateTime.now(),
              ),
            );
          }
        }

        locationIndex++;
      }

      // --- NEW: Sort, separate, and prepare lists for the UI ---

      // Sort all fetched events by severity score in descending order

      fetchedEvents.sort(
        (a, b) => _getSeverityScore(b).compareTo(_getSeverityScore(a)),
      );

      // Separate the sorted list into top priority and low risk

      List<DisasterEvent> topList = fetchedEvents.take(6).toList();

      List<DisasterEvent> lowList = fetchedEvents.skip(6).toList();

      // Create a single list for the overview page's ListView

      List<dynamic> combinedList = [];

      if (topList.isNotEmpty) {
        combinedList.add("Top Priority");

        combinedList.addAll(topList);
      }

      if (lowList.isNotEmpty) {
        combinedList.add("Low Risk");

        combinedList.addAll(lowList);
      }

      // --- Update the state with the new, processed lists ---

      if (mounted) {
        setState(() {
          allDisasterEvents = fetchedEvents; // Keep the full sorted list

          topPriorityDisasters = topList;

          combinedDisasterListForUI = combinedList;

          _topPriorityDisasterCount = topList.length;
        });
      }
    } catch (e) {
      print("An unexpected error occurred during parallel data fetching: $e");
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    // MODIFIED: Map markers are now generated ONLY from the top priority list.

    List<Marker> mapMarkers =
        topPriorityDisasters
            .map((event) {
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
                markerColor = Colors.brown;

                markerIcon = Icons.volcano;

                // For earthquakes, we can try to get a location from the first high-risk city if available

                final data = event.predictionData as EarthquakePrediction;

                if (data.highRiskCities.isNotEmpty) {
                  // This is a placeholder. You'd need actual lat/lon in your city data.

                  // For now, earthquakes might not appear on the map unless you add coordinates.
                }
              }

              if (point != null) {
                return Marker(
                  width: 80.0,

                  height: 80.0,

                  point: point,

                  child: GestureDetector(
                    onTap: () {
                      final eventData = event.predictionData;

                      if (event.type == DisasterType.cyclone &&
                          eventData is CyclonePrediction) {
                        Navigator.push(
                          context,

                          MaterialPageRoute(
                            builder:
                                (context) => CycloneDetailsPage(
                                  cyclonePrediction: eventData,
                                ),
                          ),
                        );
                      } else if (event.type == DisasterType.flood &&
                          eventData is FloodPrediction) {
                        Navigator.push(
                          context,

                          MaterialPageRoute(
                            builder:
                                (context) => FloodDetailsPage(
                                  floodPrediction: eventData,
                                ),
                          ),
                        );
                      } else if (event.type == DisasterType.earthquake &&
                          eventData is EarthquakePrediction) {
                        Navigator.push(
                          context,

                          MaterialPageRoute(
                            builder:
                                (context) => EarthquakeDetailsPage(
                                  earthquakePrediction: eventData,
                                ),
                          ),
                        );
                      }
                    },

                    child: Tooltip(
                      message:
                          "${event.type.toString().split('.').last}: ${event.locationSummary}",

                      child: Icon(
                        markerIcon,

                        color: markerColor,

                        size: 40.0,

                        semanticLabel:
                            "${event.type.toString().split('.').last} marker",
                      ),
                    ),
                  ),
                );
              }

              return null;
            })
            .whereType<Marker>()
            .toList();

    return Scaffold(
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,

            end: Alignment.bottomRight,

            transform: GradientRotation(-40 * 3.14159 / 180),

            colors: [Color(0xFF87CEEB), Color(0xFF4682B4)],

            stops: [0.3, 1.0],
          ),
        ),

        child: SafeArea(
          child:
              _isLoading
                  ? const Center(
                    child: CircularProgressIndicator(color: Colors.white),
                  )
                  : SingleChildScrollView(
                    padding: const EdgeInsets.fromLTRB(16.0, 16.0, 16.0, 80.0),

                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,

                      children: [
                        DashboardCard(
                          title: "Disaster Overview",

                          // MODIFIED: Count now reflects the top priority events.
                          count:
                              "$_topPriorityDisasterCount Top Priority Event(s)",

                          icon: Icons.map_outlined,

                          onTap: () {
                            Navigator.push(
                              context,

                              MaterialPageRoute(
                                builder:
                                    (context) => DisasterOverviewPage(
                                      // MODIFIED: Pass the new combined list to the details page.
                                      combinedDisasterList:
                                          combinedDisasterListForUI,

                                      mapMarkers: mapMarkers,
                                    ),
                              ),
                            );
                          },
                        ),

                        const SizedBox(height: 24),

                        const TranslatableText(
                          "Quick Actions",

                          style: TextStyle(
                            fontSize: 18,

                            fontWeight: FontWeight.bold,

                            color: Colors.white,
                          ),
                        ),

                        const SizedBox(height: 12),

                        Column(
                          crossAxisAlignment: CrossAxisAlignment.stretch,

                          children: [
                            DashboardCard(
                              title: "Add Refugee Camp",

                              count: "4",

                              icon: Icons.add_location_alt,

                              onTap:
                                  () => Navigator.pushNamed(context, '/camp'),
                            ),

                            const SizedBox(height: 12),

                            DashboardCard(
                              title: "Ongoing SOS Alerts",

                              count: "12",

                              icon: Icons.sos_outlined,

                              onTap:
                                  () => Navigator.pushNamed(
                                    context,

                                    '/sos_alerts',
                                  ),
                            ),

                            const SizedBox(height: 12),

                            DashboardCard(
                              title: "Rescue Teams",

                              count: "5",

                              icon: Icons.groups_rounded,

                              onTap:
                                  () => Navigator.pushNamed(
                                    context,

                                    '/deployed_teams',
                                  ),
                            ),

                            const SizedBox(height: 12),

                            DashboardCard(
                              title: "Central Inventory",

                              count: "150 Items",

                              icon: Icons.inventory,

                              onTap:
                                  () => Navigator.push(
                                    context,

                                    MaterialPageRoute(
                                      builder: (context) => InventoryPage(),
                                    ),
                                  ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
        ),
      ),
    );
  }
}

class DisasterOverviewPage extends StatelessWidget {
  // MODIFIED: This page now takes a single combined list and the map markers.

  final List<dynamic> combinedDisasterList;

  final List<Marker> mapMarkers;

  const DisasterOverviewPage({
    Key? key,

    required this.combinedDisasterList,

    required this.mapMarkers,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const TranslatableText("Disaster Overview Details"),

        backgroundColor: const Color(0xFF1A324C),

        iconTheme: const IconThemeData(color: Colors.white),

        titleTextStyle: const TextStyle(color: Colors.white, fontSize: 20),
      ),

      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,

            end: Alignment.bottomRight,

            transform: GradientRotation(-40 * 3.14159 / 180),

            colors: [Color(0xFF87CEEB), Color(0xFF4682B4)],

            stops: [0.3, 1.0],
          ),
        ),

        child: SingleChildScrollView(
          padding: const EdgeInsets.all(16.0),

          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,

            children: [
              const TranslatableText(
                "Top Priority Disaster Map", // Title changed for clarity

                style: TextStyle(
                  fontSize: 18,

                  fontWeight: FontWeight.bold,

                  color: Colors.white,
                ),
              ),

              const SizedBox(height: 10),

              SizedBox(
                height: 300,

                child: ClipRRect(
                  borderRadius: BorderRadius.circular(12.0),

                  child: FlutterMap(
                    options: const MapOptions(
                      initialCenter: LatLng(
                        20.5937,

                        78.9629,
                      ), // Center of India

                      initialZoom: 4.0,
                    ),

                    children: [
                      TileLayer(
                        urlTemplate:
                            'https://{s}.tile.openstreetmap.org/{z}/{x}/{y}.png',

                        subdomains: const ['a', 'b', 'c'],
                      ),

                      MarkerLayer(
                        markers: mapMarkers,
                      ), // Markers are only for top priority
                    ],
                  ),
                ),
              ),

              const SizedBox(height: 20),

              // MODIFIED: This ListView now builds headers and event cards from a single list.
              ListView.builder(
                shrinkWrap: true,

                physics: const NeverScrollableScrollPhysics(),

                itemCount: combinedDisasterList.length,

                itemBuilder: (context, index) {
                  final item = combinedDisasterList[index];

                  // If the item is a String, build a header widget.

                  if (item is String) {
                    return Padding(
                      padding: const EdgeInsets.only(top: 20.0, bottom: 10.0),

                      child: TranslatableText(
                        item, // "Top Priority" or "Low Risk"

                        style: TextStyle(
                          fontSize: 18,

                          fontWeight: FontWeight.bold,

                          color: Colors.white,

                          shadows: [
                            Shadow(
                              blurRadius: 2.0,

                              color: Colors.black26,

                              offset: Offset(1, 1),
                            ),
                          ],
                        ),
                      ),
                    );
                  }

                  // If the item is a DisasterEvent, build the event card.

                  if (item is DisasterEvent) {
                    final event = item;

                    return Card(
                      elevation: 4,

                      margin: const EdgeInsets.symmetric(
                        vertical: 6.0,

                        horizontal: 0,
                      ),

                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(10),
                      ),

                      child: Padding(
                        padding: const EdgeInsets.all(12.0),

                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,

                          children: [
                            Text(
                              event.type
                                  .toString()
                                  .split('.')
                                  .last
                                  .toUpperCase(),

                              style: TextStyle(
                                fontWeight: FontWeight.bold,

                                fontSize: 16,

                                color:
                                    event.type == DisasterType.flood
                                        ? Colors.blue.shade700
                                        : event.type == DisasterType.cyclone
                                        ? Colors.orange.shade700
                                        : event.type == DisasterType.earthquake
                                        ? Colors.brown.shade700
                                        : Colors.black,
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
                                    final eventData = event.predictionData;

                                    if (event.type == DisasterType.cyclone &&
                                        eventData is CyclonePrediction) {
                                      Navigator.push(
                                        context,

                                        MaterialPageRoute(
                                          builder:
                                              (context) => CycloneDetailsPage(
                                                cyclonePrediction: eventData,
                                              ),
                                        ),
                                      );
                                    } else if (event.type ==
                                            DisasterType.flood &&
                                        eventData is FloodPrediction) {
                                      Navigator.push(
                                        context,

                                        MaterialPageRoute(
                                          builder:
                                              (context) => FloodDetailsPage(
                                                floodPrediction: eventData,
                                              ),
                                        ),
                                      );
                                    } else if (event.type ==
                                            DisasterType.earthquake &&
                                        eventData is EarthquakePrediction) {
                                      Navigator.push(
                                        context,

                                        MaterialPageRoute(
                                          builder:
                                              (context) =>
                                                  EarthquakeDetailsPage(
                                                    earthquakePrediction:
                                                        eventData,
                                                  ),
                                        ),
                                      );
                                    }
                                  },

                                  child: const TranslatableText("View Details"),

                                  style: ElevatedButton.styleFrom(
                                    backgroundColor: Colors.grey[200],

                                    foregroundColor: Colors.black87,
                                  ),
                                ),

                                const SizedBox(width: 8),

                                ElevatedButton(
                                  onPressed: () {
                                    /* TODO: Implement raise alert */
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
                  }

                  // Return an empty container for any other case

                  return Container();
                },
              ),
            ],
          ),
        ),
      ),
    );
  }
}

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
