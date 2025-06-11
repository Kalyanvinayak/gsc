// lib/models/disaster_event.dart
import 'flood_prediction.dart';
import 'cyclone_prediction.dart';
import 'earthquake_prediction.dart';

enum DisasterType { flood, cyclone, earthquake, unknown }

class DisasterEvent {
  final DisasterType type;
  final dynamic predictionData; // This will hold FloodPrediction, CyclonePrediction, or EarthquakePrediction
  final DateTime timestamp; // Common field for when the event was fetched or occurred

  DisasterEvent({
    required this.type,
    required this.predictionData,
    required this.timestamp,
  });

  // Helper to get a general location string, if possible
  String get locationSummary {
    if (type == DisasterType.flood && predictionData is FloodPrediction) {
      return (predictionData as FloodPrediction).matchedDistrict;
    } else if (type == DisasterType.cyclone && predictionData is CyclonePrediction) {
      return (predictionData as CyclonePrediction).location.district;
    } else if (type == DisasterType.earthquake && predictionData is EarthquakePrediction) {
      if ((predictionData as EarthquakePrediction).highRiskCities.isNotEmpty) {
        return (predictionData as EarthquakePrediction).highRiskCities.first.city;
      }
      return "Multiple Areas";
    }
    return "N/A";
  }

  // Helper to get a general severity string
  String get severitySummary {
     if (type == DisasterType.flood && predictionData is FloodPrediction) {
      return "Risk: ${(predictionData as FloodPrediction).floodRisk}";
    } else if (type == DisasterType.cyclone && predictionData is CyclonePrediction) {
      return (predictionData as CyclonePrediction).cycloneCondition;
    } else if (type == DisasterType.earthquake && predictionData is EarthquakePrediction) {
      if ((predictionData as EarthquakePrediction).highRiskCities.isNotEmpty) {
        // Find max magnitude or summarize
        double maxMag = 0;
        (predictionData as EarthquakePrediction).highRiskCities.forEach((city) {
          if (city.magnitude > maxMag) maxMag = city.magnitude;
        });
        return "Max Mag: $maxMag";
      }
      return "High Risk";
    }
    return "N/A";
  }

  bool isCategorizedAsSignificant() {
    switch (type) {
      case DisasterType.cyclone:
        if (predictionData is CyclonePrediction) {
          final data = predictionData as CyclonePrediction;

          // Check 1: Cyclone category string
          final RegExp categoryRegex = RegExp(r"category\s*(\d+)", caseSensitive: false);
          final Match? categoryMatch = categoryRegex.firstMatch(data.cycloneCondition);

          if (categoryMatch != null && categoryMatch.groupCount >= 1) {
            final int? categoryNumber = int.tryParse(categoryMatch.group(1)!);
            if (categoryNumber != null && categoryNumber > 2) {
              return true;
            }
          }

          // Check 2: usaWind (assuming knots)
          // Saffir-Simpson Hurricane Wind Scale: Category 3 starts at 96 knots
          if (data.usaWind >= 96) {
            return true;
          }
        }
        return false; // If not CyclonePrediction or conditions not met

      case DisasterType.earthquake:
        if (predictionData is EarthquakePrediction) {
          final data = predictionData as EarthquakePrediction;
          if (data.highRiskCities.isEmpty) {
            return false;
          }
          for (var city in data.highRiskCities) {
            if (city.magnitude > 3.2) {
              return true;
            }
          }
        }
        return false; // If not EarthquakePrediction or no city meets criteria

      case DisasterType.flood:
        if (predictionData is FloodPrediction) {
          final data = predictionData as FloodPrediction;
          final riskLower = data.floodRisk.toLowerCase();
          if (riskLower == "high" || riskLower == "very high") {
            return true;
          }
        }
        return false; // If not FloodPrediction or risk not high/very high

      case DisasterType.unknown:
      default:
        return false;
    }
  }
}
