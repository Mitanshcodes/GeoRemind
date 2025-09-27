import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/task_provider.dart';

class HomeWithMap extends StatelessWidget {
  const HomeWithMap({super.key});

  @override
  Widget build(BuildContext context) {
  final tasks = context.watch<TaskProvider>().tasks;

  return Scaffold(
      appBar: AppBar(
        leading: IconButton(
          icon: const Icon(Icons.menu),
          onPressed: () {},
        ),
        centerTitle: true,
        title: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            ElevatedButton.icon(
              onPressed: () {
                Navigator.pushNamed(context, '/add');
              },
              icon: const Icon(Icons.add),
              label: const Text('Add Task'),
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.greenAccent.shade700,
                foregroundColor: Colors.white,
                elevation: 4,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                textStyle: const TextStyle(fontWeight: FontWeight.bold),
              ),
            ),
          ],
        ),
        actions: [
          Padding(
            padding: const EdgeInsets.only(right: 12.0),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: const [
                Text('GeoRemind', style: TextStyle(fontWeight: FontWeight.bold)),
                SizedBox(width: 8),
                CircleAvatar(child: Text('GR')),
              ],
            ),
          )
        ],
      ),
      body: Column(
        children: [
          const SizedBox(height: 8),
          Expanded(
            child: Padding(
              padding: const EdgeInsets.all(12.0),
              child: ClipRRect(
                borderRadius: BorderRadius.circular(12),
                child: LayoutBuilder(
                  builder: (context, constraints) {
                    // static tile image (centered near Georgia Tech)
                    final mapUrl = 'https://tile.openstreetmap.org/15/12000/16000.png';

                    // simple equirectangular projection (not geospatially accurate but fine for demo)
                    double lonToX(double lon) => (lon + 180) / 360;
                    double latToY(double lat) => (90 - lat) / 180;

                    return Stack(
                      children: [
                        Positioned.fill(
                          child: Image.network(
                            mapUrl,
                            fit: BoxFit.cover,
                            errorBuilder: (c, e, st) => Container(color: Colors.blueGrey.shade100, child: const Center(child: Text('Map'))),
                          ),
                        ),
                        // overlay markers
                        for (var t in tasks)
                          Builder(builder: (ctx) {
                            final rx = lonToX(t.lng);
                            final ry = latToY(t.lat);
                            final ax = (rx - 0.5) * 2;
                            final ay = (ry - 0.5) * 2;
                            return Align(
                              alignment: Alignment(ax.clamp(-1.0, 1.0), ay.clamp(-1.0, 1.0)),
                              child: GestureDetector(
                                onTap: () => showModalBottomSheet(
                                  context: context,
                                  builder: (_) => Padding(
                                    padding: const EdgeInsets.all(12.0),
                                    child: Column(
                                      mainAxisSize: MainAxisSize.min,
                                      crossAxisAlignment: CrossAxisAlignment.start,
                                      children: [
                                        Text(t.title, style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                                        const SizedBox(height: 6),
                                        Text(t.locationText),
                                      ],
                                    ),
                                  ),
                                ),
                                child: const Icon(Icons.location_on, color: Colors.red, size: 36),
                              ),
                            );
                          }),
                      ],
                    );
                  },
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
