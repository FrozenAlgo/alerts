import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter_blue_plus/flutter_blue_plus.dart';

class DiscoveredDevice {
  final String name;
  final String serial;
  final String deviceId;
  final int rssi;

  const DiscoveredDevice({
    required this.name,
    required this.serial,
    required this.deviceId,
    required this.rssi,
  });
}

class ScanStartResult {
  final bool ok;
  final String? error;

  const ScanStartResult._(this.ok, this.error);

  const ScanStartResult.success() : this._(true, null);

  const ScanStartResult.failure(String message) : this._(false, message);
}

class DeviceDiscoveryService {
  static final DeviceDiscoveryService instance = DeviceDiscoveryService._();

  static final RegExp _serialPattern = RegExp(r'ESP[-_]?ACC[-_]?(\w+)', caseSensitive: false);

  static const Duration _scanTimeout = Duration(seconds: 15);
  static const Duration _minGapBetweenScans = Duration(seconds: 6);
  static const Duration _stopSettleDelay = Duration(milliseconds: 800);

  StreamSubscription<List<ScanResult>>? _scanSub;
  final _devicesController = StreamController<List<DiscoveredDevice>>.broadcast();
  final Map<String, DiscoveredDevice> _found = {};
  DateTime? _lastScanEnded;
  bool _starting = false;

  Stream<List<DiscoveredDevice>> get devices => _devicesController.stream;

  Stream<bool> get isScanning => FlutterBluePlus.isScanning;

  bool get isScanningNow => FlutterBluePlus.isScanningNow || _starting;

  DeviceDiscoveryService._() {
    FlutterBluePlus.isScanning.listen((scanning) {
      if (!scanning) _lastScanEnded = DateTime.now();
    });
  }

  Future<bool> isBluetoothAvailable() async {
    try {
      if (await FlutterBluePlus.isSupported == false) return false;
      final state = await FlutterBluePlus.adapterState.where((s) => s != BluetoothAdapterState.unknown).first;
      return state == BluetoothAdapterState.on;
    } catch (e) {
      debugPrint('BLE availability check failed: $e');
      return false;
    }
  }

  Future<ScanStartResult> startScan({Duration timeout = _scanTimeout}) async {
    if (_starting) {
      return const ScanStartResult.failure('A scan is already starting. Please wait.');
    }

    _starting = true;
    try {
      if (_lastScanEnded != null) {
        final elapsed = DateTime.now().difference(_lastScanEnded!);
        if (elapsed < _minGapBetweenScans) {
          await Future.delayed(_minGapBetweenScans - elapsed);
        }
      }

      await _ensureScanFullyStopped();

      _found.clear();
      _emit();

      await _scanSub?.cancel();
      _scanSub = FlutterBluePlus.scanResults.listen(
        _onScanResults,
        onError: (Object e) {
          debugPrint('BLE scan stream error: $e');
          _emitError('Bluetooth scan failed. Wait a few seconds and try again.');
        },
      );
      FlutterBluePlus.cancelWhenScanComplete(_scanSub!);

      try {
        await FlutterBluePlus.startScan(
          timeout: timeout,
          androidScanMode: AndroidScanMode.lowLatency,
          androidUsesFineLocation: false,
          androidCheckLocationServices: false,
        );
      } on FlutterBluePlusException catch (e) {
        return ScanStartResult.failure(_mapScanException(e));
      } catch (e) {
        return ScanStartResult.failure('Could not start Bluetooth scan: $e');
      }

      return const ScanStartResult.success();
    } finally {
      _starting = false;
    }
  }

  void _onScanResults(List<ScanResult> results) {
    for (final result in results) {
      final advName = result.advertisementData.advName;
      final platformName = result.device.platformName;
      final name = advName.isNotEmpty ? advName : platformName;
      if (name.isEmpty) continue;

      final serial = _extractSerial(name);
      if (serial == null) continue;

      final id = result.device.remoteId.str;
      _found[id] = DiscoveredDevice(
        name: name,
        serial: serial,
        deviceId: id,
        rssi: result.rssi,
      );
    }
    _emit();
  }

  String _mapScanException(FlutterBluePlusException e) {
    if (e.code == 6) {
      return 'Scanning too quickly. Wait 10 seconds, then tap Scan Again.';
    }
    if (e.code == 2) {
      return 'Bluetooth permission denied. Enable Nearby devices in app settings.';
    }
    final desc = e.description?.toLowerCase() ?? '';
    if (desc.contains('too frequently') || desc.contains('too quickly')) {
      return 'Scanning too quickly. Wait 10 seconds, then tap Scan Again.';
    }
    if (desc.contains('permission')) {
      return 'Bluetooth permission denied. Enable Nearby devices in app settings.';
    }
    return e.description ?? 'Bluetooth scan failed.';
  }

  final _errorController = StreamController<String>.broadcast();
  Stream<String> get errors => _errorController.stream;

  void _emitError(String message) {
    if (!_errorController.isClosed) {
      _errorController.add(message);
    }
  }

  Future<void> stopScan() async {
    _starting = false;
    await _scanSub?.cancel();
    _scanSub = null;
    await _ensureScanFullyStopped();
    _lastScanEnded = DateTime.now();
  }

  Future<void> _ensureScanFullyStopped() async {
    try {
      if (FlutterBluePlus.isScanningNow) {
        await FlutterBluePlus.stopScan();
      }
    } catch (e) {
      debugPrint('stopScan: $e');
    }

    final deadline = DateTime.now().add(const Duration(seconds: 4));
    while (FlutterBluePlus.isScanningNow && DateTime.now().isBefore(deadline)) {
      await Future.delayed(const Duration(milliseconds: 120));
    }

    await Future.delayed(_stopSettleDelay);
  }

  String? _extractSerial(String name) {
    final upper = name.toUpperCase();

    if (upper.contains('ESP-ACC') || upper.contains('ESP_ACC')) {
      final direct = RegExp(r'ESP[-_]?ACC[-_]?(\d+)', caseSensitive: false).firstMatch(name);
      if (direct != null) return 'ESP-ACC-${direct.group(1)}';
    }

    if (upper.contains('ONALERT') || upper.contains('ESP-ACC') || upper.contains('ESP_ACC')) {
      final match = _serialPattern.firstMatch(name);
      if (match != null) {
        final suffix = match.group(1) ?? '';
        return 'ESP-ACC-$suffix'.toUpperCase();
      }
      if (upper.startsWith('ESP-ACC')) return upper.split(' ').first;
    }

    if (upper.startsWith('ESP')) {
      return name.trim().split(' ').first.toUpperCase();
    }

    return null;
  }

  void _emit() {
    final list = _found.values.toList()
      ..sort((a, b) => b.rssi.compareTo(a.rssi));
    if (!_devicesController.isClosed) {
      _devicesController.add(list);
    }
  }
}
