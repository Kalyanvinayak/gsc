import 'package:flutter/material.dart';
import 'package:gsc/models/disaster_event.dart';
import 'package:gsc/models/flood_prediction.dart';
import 'package:gsc/models/cyclone_prediction.dart';
import 'package:gsc/models/earthquake_prediction.dart'; // Though not used for coords, good for consistency
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';

class ActiveDisasterDetailsPage extends StatefulWidget {
  final DisasterEvent selectedEvent;
  final List<DisasterEvent> allDisasterEvents;

  const ActiveDisasterDetailsPage({
    Key? key,
    required this.selectedEvent,
    required this.allDisasterEvents,
  }) : super(key: key);

  @override
  State<ActiveDisasterDetailsPage> createState() => _ActiveDisasterDetailsPageState();
}

class _ActiveDisasterDetailsPageState extends State<ActiveDisasterDetailsPage> {
  LatLng _getCoordinatesForEvent(DisasterEvent event) {
    if (event.type == DisasterType.flood && event.predictionData is FloodPrediction) {
      final data = event.predictionData as FloodPrediction;
      return LatLng(data.lat, data.lon);
    } else if (event.type == DisasterType.cyclone && event.predictionData is CyclonePrediction) {
      final data = event.predictionData as CyclonePrediction;
      return LatLng(data.location.latitude, data.location.longitude);
    }
    // For earthquakes or unknown, return a placeholder or handle as null
    // For this map, we'll return a default that won't be shown if no specific coords for marker
    return LatLng(0,0); // Should be filtered out if not valid for a marker
  }

  bool _hasValidCoordinates(DisasterEvent event) {
    if (event.type == DisasterType.flood && event.predictionData is FloodPrediction) {
      return true; // lat/lon are directly available
    } else if (event.type == DisasterType.cyclone && event.predictionData is CyclonePrediction) {
      return true; // lat/lon are directly available
    }
    return false; // Earthquakes currently don't have direct lat/lon for markers
  }


  @override
  Widget build(BuildContext context) {
    LatLng initialMapCenter;
    double initialMapZoom = 6.0;

    if (_hasValidCoordinates(widget.selectedEvent)) {
      initialMapCenter = _getCoordinatesForEvent(widget.selectedEvent);
    } else {
      initialMapCenter = const LatLng(20.5937, 78.9629); // Center of India
      initialMapZoom = 4.5;
    }

    List<Marker> mapMarkers = widget.allDisasterEvents.where(_hasValidCoordinates).map((event) {
      LatLng point = _getCoordinatesForEvent(event);
      Color markerColor;
      IconData iconData;

      if (event == widget.selectedEvent) {
        markerColor = Colors.purple.shade700; // Distinct color for selected event
        iconData = Icons.location_pin; // Larger or distinct icon
      } else {
        markerColor = event.isCategorizedAsSignificant() ? Colors.red.shade700 : Colors.blue.shade700;
        iconData = Icons.circle; // Smaller icon for other events
      }

      return Marker(
        width: event == widget.selectedEvent ? 40.0 : 24.0,
        height: event == widget.selectedEvent ? 40.0 : 24.0,
        point: point,
        child: Tooltip(
          message: "${event.type.toString().split('.').last}: ${event.locationSummary}\nSeverity: ${event.severitySummary}",
          child: Icon(iconData, color: markerColor, size: event == widget.selectedEvent ? 30.0 : 15.0),
        )
      );
    }).toList();

    return Scaffold(
      appBar: AppBar(
        title: Text('Details: ${widget.selectedEvent.type.toString().split('.').last}'),
        backgroundColor: const Color(0xFF1A324C),
        iconTheme: const IconThemeData(color: Colors.white),
        titleTextStyle: const TextStyle(color: Colors.white, fontSize: 20),
      ),
      body: Column(
        children: [
          SizedBox(
            height: 300,
            child: FlutterMap(
              options: MapOptions(
                initialCenter: initialMapCenter,
                initialZoom: initialMapZoom,
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
          Padding(
            padding: const EdgeInsets.all(12.0),
            child: Text(
              "All Active Disasters (${widget.allDisasterEvents.length})",
              style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Color(0xFF1A324C)),
            ),
          ),
          Expanded(
            child: ListView.builder(
              itemCount: widget.allDisasterEvents.length,
              itemBuilder: (context, index) {
                final event = widget.allDisasterEvents[index];
                final bool isSelected = event == widget.selectedEvent;
                final bool isSignificant = event.isCategorizedAsSignificant();

                return Card(
                  elevation: isSelected ? 6 : 2,
                  margin: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  color: isSelected ? Colors.lightBlue.shade50 : (isSignificant ? Colors.orange.withOpacity(0.15) : null),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(8),
                    side: isSelected ? BorderSide(color: Colors.blue.shade600, width: 2) : BorderSide.none,
                  ),
                  child: ListTile(
                    title: Text(
                      "${event.type.toString().split('.').last.toUpperCase()} - ${event.locationSummary}",
                      style: TextStyle(
                        fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                        color: isSignificant ? Colors.deepOrange.shade800 : Colors.black87,
                      ),
                    ),
                    subtitle: Text(event.severitySummary),
                    trailing: isSignificant
                                ? Icon(Icons.warning_amber_rounded, color: Colors.orange.shade700, size: 20)
                                : null,
                    dense: true,
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}
