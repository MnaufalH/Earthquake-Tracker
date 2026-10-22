import 'package:flutter/material.dart';

import '../models/earthquake.dart';

/// Ringkasan statistik dari daftar gempa yang sedang ditampilkan.
class SummaryCard extends StatelessWidget {
  final List<Earthquake> quakes;

  const SummaryCard({super.key, required this.quakes});

  @override
  Widget build(BuildContext context) {
    final mags = quakes.map((e) => e.magnitude);
    final strongest = mags.reduce((a, b) => a > b ? a : b);
    final average = mags.reduce((a, b) => a + b) / quakes.length;

    return Card(
      margin: const EdgeInsets.fromLTRB(12, 8, 12, 4),
      color: Theme.of(context).colorScheme.primaryContainer,
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 14),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceEvenly,
          children: [
            _Stat(label: 'Total gempa', value: '${quakes.length}'),
            _Stat(label: 'Terkuat', value: 'M ${strongest.toStringAsFixed(1)}'),
            _Stat(label: 'Rata-rata', value: 'M ${average.toStringAsFixed(1)}'),
          ],
        ),
      ),
    );
  }
}

class _Stat extends StatelessWidget {
  final String label;
  final String value;

  const _Stat({required this.label, required this.value});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Column(
      children: [
        Text(
          value,
          style: theme.textTheme.titleLarge
              ?.copyWith(fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 2),
        Text(label, style: theme.textTheme.bodySmall),
      ],
    );
  }
}
