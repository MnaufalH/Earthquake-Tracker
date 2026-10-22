import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../models/earthquake.dart';
import '../utils/magnitude_utils.dart';

class DetailScreen extends StatelessWidget {
  final Earthquake quake;

  const DetailScreen({super.key, required this.quake});

  @override
  Widget build(BuildContext context) {
    final info = magnitudeInfo(quake.magnitude);
    final waktu =
    DateFormat('EEEE, d MMMM yyyy, HH:mm', 'id_ID').format(quake.time);
    final koordinat = '${quake.latitude.toStringAsFixed(3)}, '
        '${quake.longitude.toStringAsFixed(3)}';

    return Scaffold(
      appBar: AppBar(title: const Text('Detail Gempa')),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          Center(
            child: CircleAvatar(
              radius: 48,
              backgroundColor: info.color,
              child: Text(
                quake.magnitude.toStringAsFixed(1),
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 32,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ),
          const SizedBox(height: 12),
          Text(
            quake.place,
            textAlign: TextAlign.center,
            style: Theme.of(context).textTheme.titleLarge,
          ),
          const SizedBox(height: 4),
          Text(
            'Kategori: ${info.label}',
            textAlign: TextAlign.center,
            style: TextStyle(color: info.color, fontWeight: FontWeight.w600),
          ),
          const SizedBox(height: 16),
          _InfoRow(
            icon: Icons.schedule,
            label: 'Waktu kejadian',
            value: '$waktu ${quake.time.timeZoneName} (${timeAgo(quake.time)})',
          ),
          _InfoRow(icon: Icons.place, label: 'Koordinat', value: koordinat),
          _InfoRow(
            icon: Icons.vertical_align_bottom,
            label: 'Kedalaman',
            value: '${quake.depthKm.toStringAsFixed(1)} km',
          ),
          _InfoRow(
            icon: Icons.speed,
            label: 'Tipe magnitudo',
            value: quake.magType,
          ),
          _InfoRow(
            icon: Icons.waves,
            label: 'Potensi tsunami',
            value: quake.tsunami == 1 ? 'Ada peringatan tsunami' : 'Tidak ada',
          ),
          _InfoRow(
            icon: Icons.people,
            label: 'Dirasakan oleh',
            value: quake.felt == null
                ? 'Belum ada laporan'
                : '${quake.felt} orang',
          ),
          _InfoRow(
            icon: Icons.warning_amber,
            label: 'Level PAGER',
            value: quake.alert ?? 'Tidak tersedia',
          ),
          _InfoRow(
            icon: Icons.insights,
            label: 'Signifikansi',
            value: '${quake.significance}',
          ),
          _InfoRow(
            icon: Icons.verified,
            label: 'Status data',
            value: quake.status,
          ),
          if (quake.url.isNotEmpty)
            _InfoRow(
              icon: Icons.link,
              label: 'Halaman USGS',
              value: quake.url,
              selectable: true,
            ),
        ],
      ),
    );
  }
}

class _InfoRow extends StatelessWidget {
  final IconData icon;
  final String label;
  final String value;
  final bool selectable;

  const _InfoRow({
    required this.icon,
    required this.label,
    required this.value,
    this.selectable = false,
  });

  @override
  Widget build(BuildContext context) {
    final style = Theme.of(context).textTheme.bodyLarge;
    return ListTile(
      leading: Icon(icon),
      title: Text(label, style: Theme.of(context).textTheme.bodySmall),
      subtitle: selectable
          ? SelectableText(value, style: style)
          : Text(value, style: style),
    );
  }
}
