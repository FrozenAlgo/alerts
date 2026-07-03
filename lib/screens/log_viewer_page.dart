import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_database/firebase_database.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../theme/app_theme.dart';

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
        backgroundColor: AppTheme.kDarkSlate,
        appBar: AppBar(
          title: const Text('Raw Logs', style: TextStyle(color: Colors.white)),
          backgroundColor: Colors.transparent,
        ),
        body: const Center(child: Text('Pair a device to view RTDB logs', style: TextStyle(color: Colors.blueGrey))),
      );
    }

    return Scaffold(
      backgroundColor: AppTheme.kDarkSlate,
      appBar: AppBar(
        title: const Text('Raw Logs', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
        backgroundColor: Colors.transparent,
        elevation: 0,
        centerTitle: true,
      ),
      body: StreamBuilder<DatabaseEvent>(
        stream: FirebaseDatabase.instance.ref('devices/$_pairedSerial/status').onValue,
        builder: (context, snapshot) {
          if (!snapshot.hasData) {
            return const Center(child: CircularProgressIndicator(color: AppTheme.kPrimaryCyan));
          }
          final payload = snapshot.data!.snapshot.value?.toString() ?? 'No data';
          return ListView(
            padding: const EdgeInsets.all(16),
            children: [
              Text('Updated ${DateFormat('HH:mm:ss').format(DateTime.now())}',
                  style: const TextStyle(color: AppTheme.kPrimaryCyan, fontSize: 12)),
              const SizedBox(height: 12),
              Container(
                padding: const EdgeInsets.all(16),
                decoration: AppTheme.kGlassDecoration,
                child: SelectableText(payload,
                    style: const TextStyle(color: Colors.white70, fontFamily: 'monospace', fontSize: 12)),
              ),
            ],
          );
        },
      ),
    );
  }
}
