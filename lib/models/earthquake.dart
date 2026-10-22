class Earthquake {
  final String id;
  final double magnitude;
  final String place;
  final DateTime time; // waktu lokal perangkat
  final double latitude;
  final double longitude;
  final double depthKm;
  final String magType;
  final String status;
  final int tsunami; // 1 = ada peringatan tsunami
  final int significance;
  final int? felt; // jumlah laporan "Did You Feel It?"
  final String? alert; // level PAGER: green/yellow/orange/red
  final String url;

  const Earthquake({
    required this.id,
    required this.magnitude,
    required this.place,
    required this.time,
    required this.latitude,
    required this.longitude,
    required this.depthKm,
    required this.magType,
    required this.status,
    required this.tsunami,
    required this.significance,
    required this.url,
    this.felt,
    this.alert,
  });

  factory Earthquake.fromJson(Map<String, dynamic> json) {
    final props = json['properties'] as Map<String, dynamic>;
    final coords = (json['geometry'] as Map<String, dynamic>)['coordinates']
    as List<dynamic>;

    return Earthquake(
      id: json['id'] as String,
      magnitude: (props['mag'] as num?)?.toDouble() ?? 0.0,
      place: (props['place'] as String?) ?? 'Lokasi tidak diketahui',
      time: DateTime.fromMillisecondsSinceEpoch(
        (props['time'] as num).toInt(),
        isUtc: true,
      ).toLocal(),
      longitude: (coords[0] as num).toDouble(),
      latitude: (coords[1] as num).toDouble(),
      depthKm: (coords[2] as num?)?.toDouble() ?? 0.0,
      magType: (props['magType'] as String?) ?? '-',
      status: (props['status'] as String?) ?? '-',
      tsunami: (props['tsunami'] as num?)?.toInt() ?? 0,
      significance: (props['sig'] as num?)?.toInt() ?? 0,
      felt: (props['felt'] as num?)?.toInt(),
      alert: props['alert'] as String?,
      url: (props['url'] as String?) ?? '',
    );
  }
}


