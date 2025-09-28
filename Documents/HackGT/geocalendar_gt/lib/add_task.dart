import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:uuid/uuid.dart';
import 'package:geocalendar_gt/task_provider.dart';
import 'package:geocalendar_gt/task.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:geocalendar_gt/pick_on_map.dart';
import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:geocalendar_gt/google_api_key.dart';

class AddTaskScreen extends StatefulWidget {
  const AddTaskScreen({super.key});

  @override
  State<AddTaskScreen> createState() => _AddTaskScreenState();
}

class _AddTaskScreenState extends State<AddTaskScreen> {
  final _title = TextEditingController();
  final _location = TextEditingController();
  late TextEditingController _nlpController;
  double? _pickedLat;
  double? _pickedLng;
  String? _pickedAddress;

  @override
  void initState() {
    super.initState();
    _nlpController = TextEditingController();
  }

  @override
  void dispose() {
    _title.dispose();
    _location.dispose();
    _nlpController.dispose();
    super.dispose();
  }

  Future<void> _submitManual() async {
    final t = _title.text.trim();
    final l = _location.text.trim();
    if (t.isEmpty || l.isEmpty) return;
    // Determine coordinates: prefer picked coordinates from the map picker,
    // otherwise parse coordinates typed into the location field, otherwise fallback
    double lat;
    double lng;
    String locationText = l;

    if (_pickedLat != null && _pickedLng != null) {
      lat = _pickedLat!;
      lng = _pickedLng!;
      if (_pickedAddress != null && _pickedAddress!.isNotEmpty) {
        locationText = _pickedAddress!;
      }
    } else {
      // try parse "lat, lng"
      final coordMatch = RegExp(
        r"([-+]?[0-9]*\.?[0-9]+)\s*,\s*([-+]?[0-9]*\.?[0-9]+)",
      ).firstMatch(l);
      if (coordMatch != null) {
        lat = double.tryParse(coordMatch.group(1)!) ?? 33.7756;
        lng = double.tryParse(coordMatch.group(2)!) ?? -84.398;
        // try reverse geocode to get an address
        _pickedLat = lat;
        _pickedLng = lng;
        final addr = await _reverseGeocode(_pickedLat!, _pickedLng!);
        if (addr != null) locationText = addr;
      } else {
        // fallback fake geocode
        final id = const Uuid().v4();
        lat = 33.774 + (id.hashCode % 100) / 10000.0;
        lng = -84.3963 + (id.hashCode % 100) / 10000.0;
      }
    }

    if (!mounted) return;
    final id = const Uuid().v4();
    final task = Task(
      id: id,
      title: t,
      locationText: locationText,
      lat: lat,
      lng: lng,
    );
    context.read<TaskProvider>().addTask(task);

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: const Text('Task recorded'),
        backgroundColor: Colors.green.shade700,
      ),
    );

    _title.clear();
    _location.clear();
    _pickedLat = null;
    _pickedLng = null;
    _pickedAddress = null;
  }

  Future<void> _useNlp() async {
    final text = _nlpController.text.trim();
    if (text.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please enter a description for the AI to parse'),
        ),
      );
      return;
    }

    // parsing logic: extract title and optional location after ' at ' or quoted
    String title = text;
    String locationText = '';
    final atIndex = text.toLowerCase().indexOf(' at ');
    final atSymbolIndex = text.indexOf(' @ ');
    int idx = -1;
    if (atIndex >= 0) idx = atIndex;
    if (atSymbolIndex >= 0 && (idx == -1 || atSymbolIndex < idx)) {
      idx = atSymbolIndex;
    }
    if (idx >= 0) {
      title = text.substring(0, idx).trim();
      locationText = text.substring(idx + 4).trim();
    }
    if (locationText.isEmpty) {
      final quoteMatch = RegExp(r'"([^"]+)"').firstMatch(text);
      if (quoteMatch != null) {
        locationText = quoteMatch.group(1)!;
        title = text.replaceAll('"$locationText"', '').trim();
      }
    }

    Future<void> finishNlp() async {
      double lat = 37.422; // default demo coords
      double lng = -122.084;
      String outLocationText = locationText;

      // if locationText looks like coords, parse; otherwise keep heuristic
      final coordMatch = RegExp(
        r"([-+]?[0-9]*\.?[0-9]+)\s*,\s*([-+]?[0-9]*\.?[0-9]+)",
      ).firstMatch(locationText);
      if (coordMatch != null) {
        lat = double.tryParse(coordMatch.group(1)!) ?? lat;
        lng = double.tryParse(coordMatch.group(2)!) ?? lng;
        final addr = await _reverseGeocode(lat, lng);
        if (addr != null) outLocationText = addr;
      } else if (locationText.isNotEmpty) {
        int h = locationText.codeUnits.fold(0, (a, b) => a + b);
        lat += (h % 100) / 1000.0;
        lng -= (h % 100) / 1000.0;
      } else {
        int h = title.codeUnits.fold(0, (a, b) => a + b);
        lat += (h % 100) / 1000.0;
        lng -= (h % 100) / 1000.0;
      }

      final task = Task(
        id: const Uuid().v4(),
        title: title.isEmpty ? 'New task' : title,
        locationText: outLocationText,
        lat: lat,
        lng: lng,
      );
      if (!mounted) return;
      context.read<TaskProvider>().addTask(task);
    }

    // call async finish and then update UI
    await finishNlp();
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('Added task "${title.isEmpty ? 'New task' : title}"'),
        backgroundColor: Colors.green,
      ),
    );
    _nlpController.clear();
  }

  Future<String?> _reverseGeocode(double lat, double lng) async {
    final url = Uri.https('maps.googleapis.com', '/maps/api/geocode/json', {
      'latlng': '$lat,$lng',
      'key': kGoogleMapsApiKey,
    });
    try {
      final resp = await http.get(url);
      if (resp.statusCode == 200) {
        final data = json.decode(resp.body) as Map<String, dynamic>;
        final status = data['status'] as String? ?? '';
        if (status == 'OK' && (data['results'] as List).isNotEmpty) {
          return (data['results'] as List).first['formatted_address']
              as String?;
        }
      }
    } catch (e) {
      // ignore
    }
    return null;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Add Task')),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('Use AI (natural language) or manual input'),
            const SizedBox(height: 12),

            // NLP input field and handler (simple rule-based parsing for demo)
            TextField(
              controller: _nlpController,
              decoration: const InputDecoration(
                labelText:
                    'Describe the task (e.g. "Pick up groceries at Walmart")',
                border: OutlineInputBorder(),
              ),
              minLines: 1,
              maxLines: 3,
            ),
            const SizedBox(height: 8),
            Row(
              children: [
                Expanded(
                  child: ElevatedButton(
                    onPressed: _useNlp,
                    child: const Text('Use NLP'),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 20),
            const Text('Manual input'),
            const SizedBox(height: 8),
            TextField(
              controller: _title,
              decoration: const InputDecoration(labelText: 'Task title'),
            ),
            const SizedBox(height: 8),
            GestureDetector(
              onTap: () async {
                // default near GT
                final defaultLatLng = const LatLng(33.7756, -84.398);
                final picked = await Navigator.push<LatLng?>(
                  context,
                  MaterialPageRoute(
                    builder: (_) => PickOnMapScreen(initial: defaultLatLng),
                  ),
                );
                if (picked != null) {
                  _location.text =
                      '${picked.latitude.toStringAsFixed(6)}, ${picked.longitude.toStringAsFixed(6)}';
                }
              },
              child: AbsorbPointer(
                child: TextField(
                  controller: _location,
                  decoration: const InputDecoration(
                    labelText: 'Location (tap to pick on map)',
                    suffixIcon: Icon(Icons.location_on),
                  ),
                ),
              ),
            ),
            const SizedBox(height: 16),
            Row(
              children: [
                ElevatedButton(
                  onPressed: _submitManual,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.green.shade600,
                  ),
                  child: const Text('Enter'),
                ),
                const SizedBox(width: 12),
                OutlinedButton(
                  onPressed: () {
                    // Save any current manual input then go back
                    _submitManual();
                    Navigator.pop(context);
                  },
                  child: const Text('Done adding task'),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
