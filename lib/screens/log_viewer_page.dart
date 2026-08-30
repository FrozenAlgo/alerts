import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_database/firebase_database.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../services/app_database.dart';

import '../theme/app_theme.dart';
import '../widgets/ui/ui.dart';

class LogViewerPage extends StatefulWidget {
  final String userId;
  const LogViewerPage({super.key, required this.userId});

  @override
  State<LogViewerPage> createState() => _LogViewerPageState();
}

class _LogViewerPageState extends State<LogViewerPage> {
  String? _pairedSerial;

  @override
  void initState() {
    super.initState();
    _loadSerial();
  }

  Future<void> _loadSerial() async {
    final doc = await FirebaseFirestore.instance.collection('users').doc(widget.userId).get();
    setState(() => _pairedSerial = doc.data()?['pairedDevice']?.toString());
  }

  @override
  Widget build(BuildContext context) {
    if (_pairedSerial == null || _pairedSerial!.isEmpty) {
      return Scaffold(
        backgroundColor: AppTheme.kBackground,
        appBar: const AppBrandedAppBar(title: 'Raw Logs'),
        body: const Center(
          child: Text('Pair a device to view RTDB logs', style: TextStyle(color: AppTheme.kTextSecondary)),
        ),
      );
    }

    return Scaffold(
      backgroundColor: AppTheme.kBackground,
      appBar: const AppBrandedAppBar(title: 'Raw Logs'),
      body: StreamBuilder<DatabaseEvent>(
        stream: AppDatabase.rtdb.ref('devices/$_pairedSerial/status').onValue,
        builder: (context, snapshot) {
          if (!snapshot.hasData) {
            return const Center(child: CircularProgressIndicator(color: AppTheme.kCyan));
          }
          final payload = snapshot.data!.snapshot.value?.toString() ?? 'No data';
          return ListView(
            padding: const EdgeInsets.all(16),
            children: [
              Text(
                'Updated ${DateFormat('HH:mm:ss').format(DateTime.now())}',
                style: const TextStyle(color: AppTheme.kCyan, fontSize: 12, fontWeight: FontWeight.w600),
              ),
              const SizedBox(height: 12),
              AppCard(
                child: SelectableText(
                  payload,
                  style: const TextStyle(color: AppTheme.kTextPrimary, fontFamily: 'monospace', fontSize: 12),
                ),
              ),
            ],
          );
        },
      ),
    );
  }
}
