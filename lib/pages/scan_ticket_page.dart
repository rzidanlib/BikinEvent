import 'package:flutter/material.dart';
import 'package:mobile_scanner/mobile_scanner.dart';
import '../services/checkin_service.dart';

class ScanTicketPage extends StatefulWidget {
  const ScanTicketPage({super.key});

  @override
  State<ScanTicketPage> createState() => _ScanTicketPageState();
}

class _ScanTicketPageState extends State<ScanTicketPage> {
  final _checkinService = CheckinService();
  final MobileScannerController _controller = MobileScannerController();

  bool _isProcessing =
      false; // mencegah scan berkali-kali beruntun untuk QR yang sama

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  Future<void> _handleDetect(BarcodeCapture capture) async {
    if (_isProcessing) return; // abaikan kalau masih proses scan sebelumnya

    final code = capture.barcodes.firstOrNull?.rawValue;
    if (code == null) return;

    setState(() => _isProcessing = true);
    await _controller.stop(); // pause kamera sementara proses berjalan

    try {
      final result = await _checkinService.checkInTicket(code);
      if (mounted) _showResultDialog(result);
    } catch (e) {
      if (mounted)
        _showResultDialog({
          'success': false,
          'message': 'Terjadi kesalahan: $e',
        });
    }
  }

  void _showResultDialog(Map<String, dynamic> result) {
    final isSuccess = result['success'] == true;

    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (_) => AlertDialog(
        icon: Icon(
          isSuccess ? Icons.check_circle : Icons.cancel,
          color: isSuccess ? Colors.green : Colors.red,
          size: 48,
        ),
        title: Text(isSuccess ? 'Check-in Berhasil' : 'Gagal'),
        content: Text(
          isSuccess
              ? '${result['ticket_name']} — ${result['event_title']}'
              : result['message'] ?? 'Terjadi kesalahan',
          textAlign: TextAlign.center,
        ),
        actions: [
          TextButton(
            onPressed: () {
              Navigator.pop(context); // tutup dialog
              setState(() => _isProcessing = false);
              _controller.start(); // lanjutkan scan lagi
            },
            child: const Text('Scan Lagi'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Scan Tiket Peserta'),
        actions: [
          IconButton(
            icon: const Icon(Icons.flash_on),
            onPressed: () => _controller.toggleTorch(),
          ),
        ],
      ),
      body: Stack(
        children: [
          MobileScanner(controller: _controller, onDetect: _handleDetect),
          // Overlay kotak bidik di tengah layar, murni visual
          Center(
            child: Container(
              width: 240,
              height: 240,
              decoration: BoxDecoration(
                border: Border.all(color: Colors.white, width: 3),
                borderRadius: BorderRadius.circular(16),
              ),
            ),
          ),
          const Positioned(
            bottom: 40,
            left: 0,
            right: 0,
            child: Text(
              'Arahkan kamera ke QR code tiket',
              textAlign: TextAlign.center,
              style: TextStyle(color: Colors.white, fontSize: 14),
            ),
          ),
        ],
      ),
    );
  }
}
