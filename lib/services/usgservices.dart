import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:http/http.dart' as http;

import '../models/earthquake.dart';

/// Exception UI  menampilkan pesan error
class ApiException implements Exception {
  final String message;
  final int? statusCode;

  const ApiException(this.message, {this.statusCode});

  @override
  String toString() => message;
}

/// Service mengambil data gempa dari USGS FDSN Event Web Service.
class UsgsService {
  static const String baseUrl =
      'https://earthquake.usgs.gov/fdsnws/event/1/query';

  final http.Client _client;

  UsgsService({http.Client? client}) : _client = client ?? http.Client();

  Future<List<Earthquake>> fetchEarthquakes({
    required Duration period,
    required double minMagnitude,
    bool indonesiaOnly = false,
    int limit = 300,
  }) async {
    final end = DateTime.now().toUtc();
    final start = end.subtract(period);

    final params = <String, String>{
      'format': 'error',
      'eventtype': 'earthquake',
      'orderby': 'time',
      'limit': '$limit',
      'starttime': _iso(start),
      'endtime': _iso(end),
      'minmagnitude': '$minMagnitude',
      if (indonesiaOnly) ...{
        'minlatitude': '-11',
        'maxlatitude': '6',
        'minlongitude': '95',
        'maxlongitude': '141',
      },
    };
    final uri = Uri.parse(baseUrl).replace(queryParameters: params);

    try {
      final response =
      await _client.get(uri).timeout(const Duration(seconds: 20));

      // 204 = tidak ada gempa yang cocok dengan filter.
      if (response.statusCode == 204) return [];

      if (response.statusCode != 200) {
        throw ApiException(
          'Server USGS merespons dengan kode ${response.statusCode}.',
          statusCode: response.statusCode,
        );
      }

      final decoded =
      jsonDecode(utf8.decode(response.bodyBytes)) as Map<String, dynamic>;
      final features = decoded['features'] as List<dynamic>;
      return features
          .map((e) => Earthquake.fromJson(e as Map<String, dynamic>))
          .toList();
    } on ApiException {
      rethrow;
    } on SocketException {
      throw const ApiException(
          'Tidak ada koneksi internet. Periksa jaringan Anda.');
    } on http.ClientException {
      throw const ApiException('Gagal terhubung ke server USGS.');
    } on TimeoutException {
      throw const ApiException('Permintaan melebihi batas waktu. Coba lagi.');
    } on FormatException {
      throw const ApiException('Format data dari server tidak valid.');
    } on TypeError {
      throw const ApiException('Struktur data dari server tidak sesuai.');
    }
  }

  // Format ISO8601 tanpa milidetik; USGS menganggap UTC jika tanpa zona.
  String _iso(DateTime t) => t.toIso8601String().split('.').first;

  void dispose() => _client.close();
}
