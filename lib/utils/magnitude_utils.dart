import 'package:flutter/material.dart';

class MagnitudeInfo {
  final String label;
  final Color color;
  const MagnitudeInfo(this.label, this.color);
}

/// Klasifikasi kekuatan gempa berdasarkan magnitudo.
MagnitudeInfo magnitudeInfo(double mag) {
  if (mag < 2.0) return const MagnitudeInfo('Sangat kecil', Color(0xFF43A047));
  if (mag < 4.0) return const MagnitudeInfo('Kecil', Color(0xFF9E9D24));
  if (mag < 5.0) return const MagnitudeInfo('Ringan', Color(0xFFFF8F00));
  if (mag < 6.0) return const MagnitudeInfo('Sedang', Color(0xFFEF6C00));
  if (mag < 7.0) return const MagnitudeInfo('Kuat', Color(0xFFD84315));
  return const MagnitudeInfo('Sangat kuat', Color(0xFFB71C1C));
}

String timeAgo(DateTime time) {
  final diff = DateTime.now().difference(time);
  if (diff.inMinutes < 1) return 'baru saja';
  if (diff.inMinutes < 60) return '${diff.inMinutes} menit lalu';
  if (diff.inHours < 24) return '${diff.inHours} jam lalu';
  return '${diff.inDays} hari lalu';
}
