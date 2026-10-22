import 'package:flutter/material.dart';

import '../models/earthquake.dart';
import '../utils/magnitude_utils.dart';

class EarthquakeTile extends StatelessWidget {
  final Earthquake quake;
  final VoidCallback onTap;

  const EarthquakeTile({super.key, required this.quake, required this.onTap});

  @override
  Widget build(BuildContext context) {
    final info = magnitudeInfo(quake.magnitude);
    final depth = quake.depthKm.toStringAsFixed(0);

    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
      child: ListTile(
        onTap: onTap,
        leading: CircleAvatar(
          radius: 26,
          backgroundColor: info.color,
          child: Text(
            quake.magnitude.toStringAsFixed(1),
            style: const TextStyle(
              color: Colors.white,
              fontWeight: FontWeight.bold,
            ),
          ),
        ),
        title: Text(quake.place, maxLines: 2, overflow: TextOverflow.ellipsis),
        subtitle: Text('${timeAgo(quake.time)} • kedalaman $depth km'),
        trailing: quake.tsunami == 1
            ? const Icon(Icons.waves, color: Colors.blue)
            : const Icon(Icons.chevron_right),
      ),
    );
  }
}
