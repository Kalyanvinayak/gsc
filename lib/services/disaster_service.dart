import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:gsc/models/disaster_event.dart';
import 'package:gsc/models/flood_prediction.dart';
import 'package:gsc/models/cyclone_prediction.dart';
import 'package:gsc/models/earthquake_prediction.dart';
import 'package:firebase_database/firebase_database.dart';

class DisasterService {
  final http.Client _client;

  DisasterService({required http.Client client}) : _client = client;

  // Define representativeLocations as a private static const list
  static const List<Map<String, dynamic>> _representativeLocations = [
    // India
    {'name': 'Delhi', 'lat': 28.7041, 'lon': 77.1025, 'country': 'India'},
    {'name': 'Mumbai', 'lat': 19.0760, 'lon': 72.8777, 'country': 'India'},
    {'name': 'Kolkata', 'lat': 22.5726, 'lon': 88.3639, 'country': 'India'},
    {'name': 'Chennai', 'lat': 13.0827, 'lon': 80.2707, 'country': 'India'},
    {'name': 'Bengaluru', 'lat': 12.9716, 'lon': 77.5946, 'country': 'India'},
    {'name': 'Hyderabad', 'lat': 17.3850, 'lon': 78.4867, 'country': 'India'},
    {'name': 'Ahmedabad', 'lat': 23.0225, 'lon': 72.5714, 'country': 'India'},
    {'name': 'Pune', 'lat': 18.5204, 'lon': 73.8567, 'country': 'India'},
    {'name': 'Jaipur', 'lat': 26.9124, 'lon': 75.7873, 'country': 'India'},
    {'name': 'Lucknow', 'lat': 26.8467, 'lon': 80.9462, 'country': 'India'},
    {'name': 'Guwahati', 'lat': 26.1445, 'lon': 91.7362, 'country': 'India'},
    {'name': 'Patna', 'lat': 25.5941, 'lon': 85.1376, 'country': 'India'},
    // Neighboring Countries (kept for reference, but filtering restricts to India for now)
    {'name': 'Karachi', 'lat': 24.8607, 'lon': 67.0011, 'country': 'Pakistan'},
    {'name': 'Lahore', 'lat': 31.5204, 'lon': 74.3587, 'country': 'Pakistan'},
    {'name': 'Dhaka', 'lat': 23.8103, 'lon': 90.4125, 'country': 'Bangladesh'},
    {'name': 'Chittagong', 'lat': 22.3569, 'lon': 91.7832, 'country': 'Bangladesh'},
    {'name': 'Kathmandu', 'lat': 27.7172, 'lon': 85.3240, 'country': 'Nepal'},
    {'name': 'Colombo', 'lat': 6.9271, 'lon': 79.8612, 'country': 'Sri Lanka'},
    {'name': 'Yangon', 'lat': 16.8409, 'lon': 96.1735, 'country': 'Myanmar'},
    {'name': 'Thimphu', 'lat': 27.4728, 'lon': 89.6390, 'country': 'Bhutan'}
  ];

  Future<List<DisasterEvent>> fetchAndFilterDisasterData() async {
    List<DisasterEvent> allFetchedDisasterData = [];
    const newFloodApiUrl = 'https://flood-api-756506665902.us-central1.run.app/predict';
    const newCycloneApiUrl = 'https://cyclone-api-756506665902.asia-south1.run.app/predict';
    const newEarthquakeApiUrl = 'https://my-python-app-wwb655aqwa-uc.a.run.app/';

    // --- Earthquake (fetches once) ---
    try {
      final response = await _client.get(Uri.parse(newEarthquakeApiUrl));
      if (response.statusCode == 200) {
        final earthquakeData = jsonDecode(response.body);
        final earthquakePrediction = EarthquakePrediction.fromJson(earthquakeData);

        // Earthquake Filtering:
        bool meetsMagnitudeCriteria = false;
        if (earthquakePrediction.highRiskCities.isNotEmpty) {
          for (var city in earthquakePrediction.highRiskCities) {
            if (city.magnitude >= 3.2) {
              meetsMagnitudeCriteria = true;
              break;
            }
          }
        }

        bool isLocatedInIndia = false;
        if (earthquakePrediction.highRiskCities.isNotEmpty) {
          for (var city in earthquakePrediction.highRiskCities) {
            // Assuming 'state' field might contain 'India' or specific Indian states.
            // A more robust check would involve a list of Indian states or better location data.
            if (city.state.toLowerCase() == 'india') {
              isLocatedInIndia = true;
              break;
            }
          }
        }

        if (meetsMagnitudeCriteria && isLocatedInIndia) {
          allFetchedDisasterData.add(DisasterEvent(
            type: DisasterType.earthquake,
            predictionData: earthquakePrediction,
            timestamp: DateTime.now(),
          ));
        }
      } else {
        print('Earthquake API Error: ${response.statusCode}');
      }
    } catch (e) {
      print('Earthquake API Exception: $e');
    }

    // --- Flood and Cyclone (iterate through _representativeLocations) ---
    for (var locData in _representativeLocations) {
      // Location Filtering: Only process locations in India.
      if (locData['country'] != 'India') {
        continue;
      }

      final double lat = locData['lat'];
      final double lon = locData['lon'];
      final String cityName = locData['name']; // For logging, if needed

      // Flood API Call for current location
      try {
        final floodResponse = await _client.post(
          Uri.parse(newFloodApiUrl),
          headers: {"Content-Type": "application/json"},
          body: jsonEncode({"lat": lat, "lon": lon}),
        );
        if (floodResponse.statusCode == 200) {
          final data = jsonDecode(floodResponse.body);
          final prediction = FloodPrediction.fromJson(data);
          // Flood Filtering: Only include events where floodRisk is "medium" or "high".
          final floodRisk = prediction.floodRisk.toLowerCase();
          if (floodRisk == "medium" || floodRisk == "high") {
            allFetchedDisasterData.add(DisasterEvent(
              type: DisasterType.flood,
              predictionData: prediction,
              timestamp: DateTime.now(),
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
        final cycloneResponse = await _client.post(
          Uri.parse(newCycloneApiUrl),
          headers: {"Content-Type": "application/json"},
          body: jsonEncode({"lat": lat, "lon": lon}),
        );
        if (cycloneResponse.statusCode == 200) {
          final data = jsonDecode(cycloneResponse.body);
          final prediction = CyclonePrediction.fromJson(data);
          // Cyclone Filtering: Only include events where cycloneCondition is Category 2 or above.
          final cycloneCondition = prediction.cycloneCondition.toLowerCase();
          bool includeCyclone = false;
          if (cycloneCondition.startsWith("category")) {
            try {
              final categoryNumber = int.parse(cycloneCondition.split(" ")[1]);
              if (categoryNumber >= 2) {
                includeCyclone = true;
              }
            } catch (e) {
              print('Error parsing cyclone category for $cityName: $cycloneCondition, Error: $e');
            }
          }
          if (includeCyclone) {
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
    return allFetchedDisasterData;
  }

  Future<void> sendDisasterAlert(DisasterEvent event) async {
    final dbRef = FirebaseDatabase.instance.ref("disaster_alerts");

    double? latitude;
    double? longitude;
    Map<String, dynamic> intensityDetails = {};

    switch (event.type) {
      case DisasterType.flood:
        if (event.predictionData is FloodPrediction) {
          final data = event.predictionData as FloodPrediction;
          latitude = data.lat;
          longitude = data.lon;
          intensityDetails = {'risk': data.floodRisk};
        }
        break;
      case DisasterType.cyclone:
        if (event.predictionData is CyclonePrediction) {
          final data = event.predictionData as CyclonePrediction;
          latitude = data.location.latitude;
          longitude = data.location.longitude;
          intensityDetails = {
            'condition': data.cycloneCondition,
            'wind_speed_knots': data.weatherData.usaWind, // usaWind is directly under weatherData
          };
        }
        break;
      case DisasterType.earthquake:
        if (event.predictionData is EarthquakePrediction) {
          final data = event.predictionData as EarthquakePrediction;
          // For earthquakes, lat/lon are not directly available from current model structure without geocoding.
          latitude = null;
          longitude = null;
          intensityDetails = {
            'cities': data.highRiskCities.map((c) => {'city': c.city, 'state': c.state, 'magnitude': c.magnitude}).toList(),
            'coordinates_note': 'Geocoding needed for precise earthquake location. Representative lat/lon not available from source.',
          };
        }
        break;
      case DisasterType.unknown:
      default:
        // Handle unknown or default case, perhaps log an error or set minimal data
        print("Attempted to send alert for unknown disaster type: ${event.type}");
        intensityDetails = {'note': 'Data not available for this type'};
        break;
    }

    final Map<String, dynamic> alertData = {
      'type': event.type.toString().split('.').last,
      'timestamp': DateTime.now().toIso8601String(),
      'locationSummary': event.locationSummary,
      'severitySummary': event.severitySummary,
      'isSignificant': event.isCategorizedAsSignificant().toString(),
      'latitude': latitude,
      'longitude': longitude,
      'intensityDetails': intensityDetails,
    };

    try {
      await dbRef.push().set(alertData);
      print("Disaster alert successfully sent to Firebase: ${event.type}");
    } catch (e) {
      print("Error sending disaster alert to Firebase: $e");
      // Rethrow or handle as per application's error handling strategy
      rethrow;
    }
  }
}
