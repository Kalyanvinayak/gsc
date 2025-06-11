import 'package:flutter_test/flutter_test.dart';
import 'package:gsc/models/disaster_event.dart';
import 'package:gsc/models/cyclone_prediction.dart';
import 'package:gsc/models/earthquake_prediction.dart';
import 'package:gsc/models/flood_prediction.dart';

// Helper to create dummy WeatherData
WeatherData _dummyWeatherData({
  double minTemp = 0.0,
  double maxTemp = 0.0,
  int humidity = 0,
  double windSpeed = 0.0,
  int pressure = 0,
  double usaWind = 0.0,
  int visibility = 0,
  double precipitation = 0.0,
  int clouds = 0,
  int sunrise = 0,
  int sunset = 0,
  String weatherDescription = '',
  String weatherIcon = '',
}) {
  return WeatherData(
    minTemp: minTemp,
    maxTemp: maxTemp,
    humidity: humidity,
    windSpeed: windSpeed,
    pressure: pressure,
    usaWind: usaWind,
    visibility: visibility,
    precipitation: precipitation,
    clouds: clouds,
    sunrise: sunrise,
    sunset: sunset,
    weatherDescription: weatherDescription,
    weatherIcon: weatherIcon,
  );
}

// Helper to create dummy Location
Location _dummyLocation({
  String district = 'Test District',
  double latitude = 0.0,
  double longitude = 0.0,
}) {
  return Location(
    district: district,
    latitude: latitude,
    longitude: longitude,
  );
}

void main() {
  group('DisasterEvent.isCategorizedAsSignificant', () {
    // Test Cases for Cyclones
    group('Cyclone Events', () {
      test('should be significant if category string is > 2', () {
        final prediction = CyclonePrediction(
          location: _dummyLocation(),
          cycloneCondition: "Major Cyclone Category 3",
          weatherData: _dummyWeatherData(usaWind: 80.0), // wind < 96 to isolate category string check
        );
        final event = DisasterEvent(
          type: DisasterType.cyclone,
          predictionData: prediction,
          timestamp: DateTime.now(),
        );
        expect(event.isCategorizedAsSignificant(), isTrue);
      });

      test('should be significant if category string is "Category 5"', () {
        final prediction = CyclonePrediction(
          location: _dummyLocation(),
          cycloneCondition: "Category 5 Hurricane",
           weatherData: _dummyWeatherData(usaWind: 150.0),
        );
        final event = DisasterEvent(
          type: DisasterType.cyclone,
          predictionData: prediction,
          timestamp: DateTime.now(),
        );
        expect(event.isCategorizedAsSignificant(), isTrue);
      });

      test('should be significant if wind speed is >= 96 knots (Category 3+)', () {
        final prediction = CyclonePrediction(
          location: _dummyLocation(),
          cycloneCondition: "Tropical Storm", // Condition without category number
          weatherData: _dummyWeatherData(usaWind: 100.0),
        );
        final event = DisasterEvent(
          type: DisasterType.cyclone,
          predictionData: prediction,
          timestamp: DateTime.now(),
        );
        expect(event.isCategorizedAsSignificant(), isTrue);
      });

      test('should not be significant if category is <= 2 and wind speed < 96', () {
        final prediction1 = CyclonePrediction(
          location: _dummyLocation(),
          cycloneCondition: "Category 1 Cyclone",
          weatherData: _dummyWeatherData(usaWind: 70.0),
        );
        final event1 = DisasterEvent(
          type: DisasterType.cyclone,
          predictionData: prediction1,
          timestamp: DateTime.now(),
        );
        expect(event1.isCategorizedAsSignificant(), isFalse);

        final prediction2 = CyclonePrediction(
          location: _dummyLocation(),
          cycloneCondition: "No direct category", // No category in string
          weatherData: _dummyWeatherData(usaWind: 90.0), // wind < 96
        );
        final event2 = DisasterEvent(
          type: DisasterType.cyclone,
          predictionData: prediction2,
          timestamp: DateTime.now(),
        );
        expect(event2.isCategorizedAsSignificant(), isFalse);

        final prediction3 = CyclonePrediction(
          location: _dummyLocation(),
          cycloneCondition: "Tropical Depression Category 2", // Category 2
          weatherData: _dummyWeatherData(usaWind: 95.0), // wind < 96
        );
        final event3 = DisasterEvent(
          type: DisasterType.cyclone,
          predictionData: prediction3,
          timestamp: DateTime.now(),
        );
        expect(event3.isCategorizedAsSignificant(), isFalse);
      });
    });

    // Test Cases for Earthquakes
    group('Earthquake Events', () {
      test('should be significant if any city magnitude > 3.2', () {
        final prediction = EarthquakePrediction(
          highRiskCities: [
            HighRiskCity(city: 'TestCity1', state: 'TS', magnitude: 3.0),
            HighRiskCity(city: 'TestCity2', state: 'TS', magnitude: 3.5),
          ],
        );
        final event = DisasterEvent(
          type: DisasterType.earthquake,
          predictionData: prediction,
          timestamp: DateTime.now(),
        );
        expect(event.isCategorizedAsSignificant(), isTrue);
      });

      test('should not be significant if all city magnitudes <= 3.2', () {
        final prediction = EarthquakePrediction(
          highRiskCities: [
            HighRiskCity(city: 'TestCity1', state: 'TS', magnitude: 3.0),
            HighRiskCity(city: 'TestCity2', state: 'TS', magnitude: 3.2),
          ],
        );
        final event = DisasterEvent(
          type: DisasterType.earthquake,
          predictionData: prediction,
          timestamp: DateTime.now(),
        );
        expect(event.isCategorizedAsSignificant(), isFalse);
      });

      test('should not be significant if highRiskCities is empty', () {
        final prediction = EarthquakePrediction(highRiskCities: []);
        final event = DisasterEvent(
          type: DisasterType.earthquake,
          predictionData: prediction,
          timestamp: DateTime.now(),
        );
        expect(event.isCategorizedAsSignificant(), isFalse);
      });
    });

    // Test Cases for Floods
    group('Flood Events', () {
      test('should be significant if floodRisk is "High"', () {
        final prediction = FloodPrediction(
          lat: 0.0, lon: 0.0, matchedDistrict: 'Test', floodRisk: "High",
        );
        final event = DisasterEvent(
          type: DisasterType.flood,
          predictionData: prediction,
          timestamp: DateTime.now(),
        );
        expect(event.isCategorizedAsSignificant(), isTrue);
      });

      test('should be significant if floodRisk is "Very High" (case-insensitive)', () {
        final prediction = FloodPrediction(
          lat: 0.0, lon: 0.0, matchedDistrict: 'Test', floodRisk: "very high",
        );
        final event = DisasterEvent(
          type: DisasterType.flood,
          predictionData: prediction,
          timestamp: DateTime.now(),
        );
        expect(event.isCategorizedAsSignificant(), isTrue);
      });

      test('should not be significant if floodRisk is "Medium" or "Low"', () {
        final predictionMedium = FloodPrediction(
          lat: 0.0, lon: 0.0, matchedDistrict: 'Test', floodRisk: "Medium",
        );
        final eventMedium = DisasterEvent(
          type: DisasterType.flood,
          predictionData: predictionMedium,
          timestamp: DateTime.now(),
        );
        expect(eventMedium.isCategorizedAsSignificant(), isFalse);

        final predictionLow = FloodPrediction(
          lat: 0.0, lon: 0.0, matchedDistrict: 'Test', floodRisk: "Low",
        );
        final eventLow = DisasterEvent(
          type: DisasterType.flood,
          predictionData: predictionLow,
          timestamp: DateTime.now(),
        );
        expect(eventLow.isCategorizedAsSignificant(), isFalse);
      });
       test('should not be significant if floodRisk is something else', () {
        final prediction = FloodPrediction(
          lat: 0.0, lon: 0.0, matchedDistrict: 'Test', floodRisk: "Moderate",
        );
        final event = DisasterEvent(
          type: DisasterType.flood,
          predictionData: prediction,
          timestamp: DateTime.now(),
        );
        expect(event.isCategorizedAsSignificant(), isFalse);
      });
    });

    // Test Case for Unknown Type
    group('Unknown Event Type', () {
      test('should not be significant if type is unknown', () {
        final event = DisasterEvent(
          type: DisasterType.unknown,
          predictionData: null, // Or some dummy data
          timestamp: DateTime.now(),
        );
        expect(event.isCategorizedAsSignificant(), isFalse);
      });
    });
     // Test cases for invalid prediction data type
    group('Invalid Prediction Data', () {
      test('should return false if predictionData is not of expected type for Cyclone', () {
        final event = DisasterEvent(
          type: DisasterType.cyclone,
          predictionData: FloodPrediction(lat: 0, lon: 0, matchedDistrict: "", floodRisk: ""), // Wrong type
          timestamp: DateTime.now(),
        );
        expect(event.isCategorizedAsSignificant(), isFalse);
      });

      test('should return false if predictionData is not of expected type for Earthquake', () {
        final event = DisasterEvent(
          type: DisasterType.earthquake,
          predictionData: CyclonePrediction(location: _dummyLocation(), cycloneCondition: "", weatherData: _dummyWeatherData()), // Wrong type
          timestamp: DateTime.now(),
        );
        expect(event.isCategorizedAsSignificant(), isFalse);
      });

      test('should return false if predictionData is not of expected type for Flood', () {
        final event = DisasterEvent(
          type: DisasterType.flood,
          predictionData: EarthquakePrediction(highRiskCities: []), // Wrong type
          timestamp: DateTime.now(),
        );
        expect(event.isCategorizedAsSignificant(), isFalse);
      });
    });
  });
}
