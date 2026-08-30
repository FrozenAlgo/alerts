import 'dart:async';

import 'package:flutter/material.dart';

import '../services/device_discovery_service.dart';
import '../services/device_service.dart';
import '../services/permission_service.dart';
import '../theme/app_theme.dart';
import '../widgets/ui/ui.dart';

class NearbyDeviceScanPage extends StatefulWidget {
  final String userId;
  const NearbyDeviceScanPage({super.key, required this.userId});

  @override
  State<NearbyDeviceScanPage> createState() => _NearbyDeviceScanPageState();
}

class _NearbyDeviceScanPageState extends State<NearbyDeviceScanPage> {
  final _discovery = DeviceDiscoveryService.instance;
  List<DiscoveredDevice> _devices = [];
  bool _scanning = false;
  String? _error;
  StreamSubscription<List<DiscoveredDevice>>? _devicesSub;
  StreamSubscription<bool>? _scanningSub;
  StreamSubscription<String>? _errorsSub;

  @override
  void initState() {
    super.initState();
    _devicesSub = _discovery.devices.listen((list) {
      if (mounted) setState(() => _devices = list);
    });
    _scanningSub = _discovery.isScanning.listen((scanning) {
      if (mounted) setState(() => _scanning = scanning);
    });
    _errorsSub = _discovery.errors.listen((message) {
      if (mounted) setState(() => _error = message);
    });
    WidgetsBinding.instance.addPostFrameCallback((_) => _startScan());
  }

  Future<void> _startScan() async {
    if (_scanning || _discovery.isScanningNow) return;

    setState(() {
      _scanning = true;
      _error = null;
      _devices = [];
    });

    final granted = await PermissionService.requestBluetoothForScan();
    if (!granted) {
      if (mounted) {
        setState(() {
          _scanning = false;
          _error = 'Allow Nearby devices (Bluetooth) permission to scan. '
              'Tap Open Settings if the prompt does not appear.';
        });
      }
      return;
    }

    final available = await _discovery.isBluetoothAvailable();
    if (!available) {
      if (mounted) {
        setState(() {
          _scanning = false;
          _error = 'Turn on Bluetooth to scan for OnAlert hardware nearby.';
        });
      }
      return;
    }

    final result = await _discovery.startScan();
    if (!result.ok && mounted) {
      setState(() => _error = result.error);
    }
  }

  Future<void> _pairDevice(DiscoveredDevice device) async {
    final pinCtrl = TextEditingController();
    final paired = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: AppTheme.kSurface,
        title: const Text('Pair Device', style: TextStyle(color: AppTheme.kTextPrimary)),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Serial: ${device.serial}', style: const TextStyle(color: AppTheme.kTextSecondary)),
            const SizedBox(height: 12),
            TextField(
              controller: pinCtrl,
              keyboardType: TextInputType.number,
              style: const TextStyle(color: AppTheme.kTextPrimary),
              decoration: const InputDecoration(labelText: 'Device PIN'),
            ),
          ],
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('CANCEL')),
          ElevatedButton(
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text('PAIR'),
          ),
        ],
      ),
    );

    if (paired != true || pinCtrl.text.trim().isEmpty) return;

    try {
      await DeviceService.pairDevice(device.serial, pinCtrl.text.trim(), widget.userId);
      if (mounted) {
        Navigator.pop(context, device.serial);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Paired ${device.serial}'), backgroundColor: AppTheme.kSuccess),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(e.toString())));
      }
    }
  }

  @override
  void dispose() {
    _devicesSub?.cancel();
    _scanningSub?.cancel();
    _errorsSub?.cancel();
    _discovery.stopScan();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.kBackground,
      appBar: const AppBrandedAppBar(title: 'Discover Nearby'),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(16),
            child: Text(
              _scanning
                  ? 'Scanning for OnAlert ESP32 devices (ESP-ACC-*)…'
                  : 'Tap a device to enter its PIN and pair.',
              style: const TextStyle(color: AppTheme.kTextSecondary),
              textAlign: TextAlign.center,
            ),
          ),
          if (_scanning)
            const Padding(
              padding: EdgeInsets.only(bottom: 12),
              child: CircularProgressIndicator(color: AppTheme.kPrimaryCyan),
            ),
          if (_error != null)
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              child: AppCard(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(_error!, style: const TextStyle(color: AppTheme.kAlertRed)),
                    if (_error!.contains('Settings') || _error!.contains('permission'))
                      TextButton(
                        onPressed: PermissionService.openSettings,
                        child: const Text('OPEN SETTINGS'),
                      ),
                  ],
                ),
              ),
            ),
          Expanded(
            child: _devices.isEmpty
                ? Center(
                    child: Padding(
                      padding: const EdgeInsets.all(24),
                      child: Text(
                        _scanning
                            ? 'Searching…'
                            : 'No OnAlert devices found.\n\n'
                                'Your ESP32 must broadcast a BLE name like ESP-ACC-001.\n'
                                'Otherwise use Scan QR or manual pairing.',
                        style: const TextStyle(color: AppTheme.kTextSecondary),
                        textAlign: TextAlign.center,
                      ),
                    ),
                  )
                : ListView.builder(
                    padding: const EdgeInsets.fromLTRB(16, 0, 16, 24),
                    itemCount: _devices.length,
                    itemBuilder: (context, index) {
                      final d = _devices[index];
                      return Padding(
                        padding: const EdgeInsets.only(bottom: 10),
                        child: AppCard(
                          onTap: _scanning ? null : () => _pairDevice(d),
                          child: Row(
                            children: [
                              const CircleAvatar(
                                backgroundColor: Color(0xFFE8F7FE),
                                child: Icon(Icons.bluetooth_searching, color: AppTheme.kCyan),
                              ),
                              const SizedBox(width: 12),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(d.serial, style: const TextStyle(fontWeight: FontWeight.w800, color: AppTheme.kTextPrimary)),
                                    Text(d.name, style: const TextStyle(color: AppTheme.kTextSecondary, fontSize: 12)),
                                  ],
                                ),
                              ),
                              Text('${d.rssi} dBm', style: const TextStyle(color: AppTheme.kTextSecondary, fontSize: 11)),
                            ],
                          ),
                        ),
                      );
                    },
                  ),
          ),
          Padding(
            padding: const EdgeInsets.all(16),
            child: AppPrimaryButton(
              label: _scanning ? 'SCANNING…' : 'SCAN AGAIN',
              onPressed: _scanning ? null : _startScan,
              icon: Icons.radar_rounded,
            ),
          ),
        ],
      ),
    );
  }
}
