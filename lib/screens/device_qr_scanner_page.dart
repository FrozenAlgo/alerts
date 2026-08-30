import 'package:flutter/material.dart';
import 'package:mobile_scanner/mobile_scanner.dart';

import '../services/device_service.dart';
import '../theme/app_theme.dart';
import '../widgets/ui/ui.dart';

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
          SnackBar(content: Text('Paired device $serial'), backgroundColor: AppTheme.kSuccess),
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
      backgroundColor: AppTheme.kBackground,
      appBar: const AppBrandedAppBar(title: 'Scan Device QR'),
      body: Column(
        children: [
          const Padding(
            padding: EdgeInsets.all(16),
            child: Text(
              'Scan the QR code on your ESP32 label (format: SERIAL:PIN)',
              style: TextStyle(color: AppTheme.kTextSecondary),
              textAlign: TextAlign.center,
            ),
          ),
          Expanded(
            child: ClipRRect(
              borderRadius: BorderRadius.circular(20),
              child: MobileScanner(onDetect: _onDetect),
            ),
          ),
          const SizedBox(height: 16),
        ],
      ),
    );
  }
}
