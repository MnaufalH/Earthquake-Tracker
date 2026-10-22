import 'dart:async';

import 'package:flutter/material.dart';

import '../models/earthquake.dart';
import '../services/usgservices.dart';
import '../widgets/earthquake_tile.dart';
import '../widgets/summary_card.dart';
import 'detail_screen.dart';

enum SortMode {
  terbaru('Terbaru'),
  terkuat('Magnitudo terbesar'),
  terdalam('Paling dalam');

  const SortMode(this.label);
  final String label;
}

class _PeriodOption {
  final String label;
  final Duration duration;
  const _PeriodOption(this.label, this.duration);
}

class _MagOption {
  final String label;
  final double value;
  const _MagOption(this.label, this.value);
}

const _periods = [
  _PeriodOption('1 Jam', Duration(hours: 1)),
  _PeriodOption('24 Jam', Duration(hours: 24)),
  _PeriodOption('7 Hari', Duration(days: 7)),
  _PeriodOption('30 Hari', Duration(days: 30)),
];

const _magnitudes = [
  _MagOption('Semua', 0),
  _MagOption('M2.5+', 2.5),
  _MagOption('M4.5+', 4.5),
  _MagOption('M6+', 6),
];

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  final UsgsService _service = UsgsService();
  final TextEditingController _searchController = TextEditingController();

  late Future<List<Earthquake>> _future;
  int _periodIndex = 2; // default: 7 hari
  int _magIndex = 2; // default: M4.5+
  bool _indonesiaOnly = false;
  SortMode _sort = SortMode.terbaru;
  String _query = '';

  // Debounce pencarian + cache hasil filter agar tidak dihitung ulang
  // setiap kali widget dibangun ulang.
  Timer? _debounce;
  List<Earthquake>? _cacheSource;
  String _cacheQuery = '';
  SortMode? _cacheSort;
  List<Earthquake> _cacheResult = const [];

  @override
  void initState() {
    super.initState();
    _future = _fetch();
  }

  @override
  void dispose() {
    _debounce?.cancel();
    _searchController.dispose();
    _service.dispose();
    super.dispose();
  }

  Future<List<Earthquake>> _fetch() => _service.fetchEarthquakes(
    period: _periods[_periodIndex].duration,
    minMagnitude: _magnitudes[_magIndex].value,
    indonesiaOnly: _indonesiaOnly,
  );

  /// Dipanggil saat filter ke server berubah atau tombol "Coba lagi".
  void _reload() {
    setState(() {
      _future = _fetch();
    });
  }

  /// Dipanggil oleh pull-to-refresh.
  Future<void> _refresh() async {
    final newFuture = _fetch();
    setState(() {
      _future = newFuture;
    });
    try {
      await newFuture;
    } catch (_) {
      // Error ditampilkan oleh FutureBuilder.
    }
  }

  /// Pencarian dan pengurutan dilakukan di sisi klien.
  List<Earthquake> _applyClientFilter(List<Earthquake> all) {
    if (identical(all, _cacheSource) &&
        _query == _cacheQuery &&
        _sort == _cacheSort) {
      return _cacheResult;
    }
    final q = _query.trim().toLowerCase();
    final list = all
        .where((e) => q.isEmpty || e.place.toLowerCase().contains(q))
        .toList();

    switch (_sort) {
      case SortMode.terbaru:
        list.sort((a, b) => b.time.compareTo(a.time));
      case SortMode.terkuat:
        list.sort((a, b) => b.magnitude.compareTo(a.magnitude));
      case SortMode.terdalam:
        list.sort((a, b) => b.depthKm.compareTo(a.depthKm));
    }
    _cacheSource = all;
    _cacheQuery = _query;
    _cacheSort = _sort;
    _cacheResult = list;
    return list;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Earthquake Tracker'),
        actions: [
          PopupMenuButton<SortMode>(
            icon: const Icon(Icons.sort),
            tooltip: 'Urutkan',
            initialValue: _sort,
            onSelected: (mode) {
              setState(() {
                _sort = mode;
              });
            },
            itemBuilder: (_) => [
              for (final mode in SortMode.values)
                PopupMenuItem(value: mode, child: Text(mode.label)),
            ],
          ),
          IconButton(
            icon: const Icon(Icons.refresh),
            tooltip: 'Muat ulang',
            onPressed: _reload,
          ),
        ],
      ),
      body: Column(
        children: [
          _buildFilters(),
          Expanded(
            child: FutureBuilder<List<Earthquake>>(
              future: _future,
              builder: (context, snapshot) {
                // 1) LOADING
                if (snapshot.connectionState != ConnectionState.done) {
                  return const Center(
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        CircularProgressIndicator(),
                        SizedBox(height: 16),
                        Text('Mengambil data gempa dari USGS...'),
                      ],
                    ),
                  );
                }

                // 2) ERROR
                if (snapshot.hasError) {
                  final err = snapshot.error;
                  final msg = err is ApiException
                      ? err.message
                      : 'Terjadi kesalahan yang tidak terduga.';
                  return _MessageView(
                    icon: Icons.error_outline,
                    message: msg,
                    buttonLabel: 'Coba lagi',
                    onPressed: _reload,
                  );
                }

                // 3) SUCCESS
                final quakes = _applyClientFilter(snapshot.data ?? []);
                if (quakes.isEmpty) {
                  return _MessageView(
                    icon: Icons.search_off,
                    message: 'Tidak ada gempa yang sesuai dengan filter.',
                    buttonLabel: 'Muat ulang',
                    onPressed: _reload,
                  );
                }

                return RefreshIndicator(
                  onRefresh: _refresh,
                  child: ListView.builder(
                    physics: const AlwaysScrollableScrollPhysics(),
                    itemCount: quakes.length + 1,
                    itemBuilder: (context, index) {
                      if (index == 0) return SummaryCard(quakes: quakes);
                      final quake = quakes[index - 1];
                      return EarthquakeTile(
                        key: ValueKey(quake.id),
                        quake: quake,
                        onTap: () => Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (_) => DetailScreen(quake: quake),
                          ),
                        ),
                      );
                    },
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildFilters() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(12, 8, 12, 0),
      child: Column(
        children: [
          TextField(
            controller: _searchController,
            decoration: InputDecoration(
              hintText: 'Cari lokasi (mis. Japan, Java)...',
              prefixIcon: const Icon(Icons.search),
              suffixIcon: ValueListenableBuilder<TextEditingValue>(
                valueListenable: _searchController,
                builder: (context, value, _) => value.text.isEmpty
                    ? const SizedBox.shrink()
                    : IconButton(
                  icon: const Icon(Icons.clear),
                  onPressed: () {
                    _debounce?.cancel();
                    _searchController.clear();
                    setState(() {
                      _query = '';
                    });
                  },
                ),
              ),
              isDense: true,
              border: const OutlineInputBorder(
                borderRadius: BorderRadius.all(Radius.circular(24)),
              ),
            ),
            onChanged: (value) {
              _debounce?.cancel();
              _debounce = Timer(const Duration(milliseconds: 300), () {
                if (!mounted) return;
                setState(() {
                  _query = value;
                });
              });
            },
          ),
          const SizedBox(height: 8),
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: Row(
              children: [
                for (var i = 0; i < _periods.length; i++)
                  Padding(
                    padding: const EdgeInsets.only(right: 8),
                    child: ChoiceChip(
                      label: Text(_periods[i].label),
                      selected: _periodIndex == i,
                      onSelected: (_) {
                        _periodIndex = i;
                        _reload();
                      },
                    ),
                  ),
              ],
            ),
          ),
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: Row(
              children: [
                for (var i = 0; i < _magnitudes.length; i++)
                  Padding(
                    padding: const EdgeInsets.only(right: 8),
                    child: ChoiceChip(
                      label: Text(_magnitudes[i].label),
                      selected: _magIndex == i,
                      onSelected: (_) {
                        _magIndex = i;
                        _reload();
                      },
                    ),
                  ),
                FilterChip(
                  avatar: const Icon(Icons.flag, size: 18),
                  label: const Text('Indonesia'),
                  selected: _indonesiaOnly,
                  onSelected: (value) {
                    _indonesiaOnly = value;
                    _reload();
                  },
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _MessageView extends StatelessWidget {
  final IconData icon;
  final String message;
  final String buttonLabel;
  final VoidCallback onPressed;

  const _MessageView({
    required this.icon,
    required this.message,
    required this.buttonLabel,
    required this.onPressed,
  });

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, size: 56, color: Theme.of(context).colorScheme.error),
            const SizedBox(height: 12),
            Text(message, textAlign: TextAlign.center),
            const SizedBox(height: 16),
            FilledButton.icon(
              onPressed: onPressed,
              icon: const Icon(Icons.refresh),
              label: Text(buttonLabel),
            ),
          ],
        ),
      ),
    );
  }
}