import 'package:http/http.dart' as http;

class LatLng {
  final double lat;
  final double lng;
  LatLng(this.lat, this.lng);
}

/// Coba ekstrak koordinat dari teks link Google Maps.
/// Kalau link masih berbentuk pendek (goo.gl), redirect diikuti dulu
/// untuk mendapatkan URL panjang aslinya sebelum parsing koordinat.
Future<LatLng?> resolveLatLngFromMapsUrl(String url) async {
  var targetUrl = url.trim();
  if (targetUrl.isEmpty) return null;

  // Kalau ini link pendek (goo.gl / maps.app.goo.gl), ikuti redirect-nya
  if (targetUrl.contains('goo.gl')) {
    try {
      final request = http.Request('GET', Uri.parse(targetUrl))
        ..followRedirects = false;
      final streamedResponse = await request.send();

      // Kode 301/302 = redirect, lokasi tujuan ada di header 'location'
      if (streamedResponse.statusCode >= 300 &&
          streamedResponse.statusCode < 400) {
        final location = streamedResponse.headers['location'];
        if (location != null) targetUrl = location;
      }
    } catch (_) {
      // Kalau gagal resolve (misal tidak ada internet), lanjut coba parsing
      // langsung dari URL asli -- mungkin saja tetap ada polanya
    }
  }

  final regex = RegExp(r'@(-?\d+\.\d+),(-?\d+\.\d+)');
  final match = regex.firstMatch(targetUrl);
  if (match == null) return null;

  final lat = double.tryParse(match.group(1)!);
  final lng = double.tryParse(match.group(2)!);
  if (lat == null || lng == null) return null;

  return LatLng(lat, lng);
}
