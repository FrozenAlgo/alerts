import 'package:flutter/material.dart';
import 'package:mobile_scanner/mobile_scanner.dart';

import '../services/device_service.dart';
import '../theme/app_theme.dart';

class DeviceQrScannerPage extends StatefulWidget {
  final String userId;
  const DeviceQrScannerPage({super.key, required this.userId});

  @override
  State<DeviceQrScannerPage> createState() => _DeviceQrScannerPageState();
}

class _DeviceQrScannerPageState extends State<DeviceQrScannerPage> {
  bool _processing = false;

  Future<void> _onDetect(BarcodeCapture capture) async {
    if (_processing) return;
    final raw = capture.barcodes.firstOrNull?.rawValue;
    if (raw == null || !raw.contains(':')) return;

    _processing = true;
    final parts = raw.split(':');
    final serial = parts[0].trim();
    final pin = parts.length > 1 ? parts[1].trim() : '';

    try {
      await DeviceService.pairDevice(serial, pin, widget.userId);
      if (mounted) {
        Navigator.pop(context, serial);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Paired device $serial'), backgroundColor: Colors.greenAccent),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(e.toString())));
      }
    } finally {
      _processing = false;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.kDarkSlate,
      appBar: AppBar(
        title: const Text('Scan Device QR', style: TextStyle(color: Colors.white)),
        backgroundColor: Colors.transparent,
        elevation: 0,
      ),
      body: Column(
        children: [
          const Padding(
            padding: EdgeInsets.all(16),
            child: Text(
              'Scan the QR code on your ESP32 label (format: SERIAL:PIN)',
              style: TextStyle(color: Colors.blueGrey),
              textAlign: TextAlign.center,
            ),
          ),
          Expanded(
            child: MobileScanner(onDetect: _onDetect),
          ),
        ],
      ),
    );
  }
}
