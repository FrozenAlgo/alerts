import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

class FullScreenEmergencyAlert extends StatelessWidget {
  final DateTime time;
  final String location;
  const FullScreenEmergencyAlert({super.key, required this.time, required this.location});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF7F1D1D),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 30),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(Icons.warning_amber_rounded, size: 120, color: Colors.white),
              const SizedBox(height: 20),
              const Text('SOS ALERT ACTIVE',
                  style: TextStyle(fontSize: 30, fontWeight: FontWeight.bold, color: Colors.white)),
              const SizedBox(height: 10),
              const Text('Notifications sent to your contacts.',
                  textAlign: TextAlign.center, style: TextStyle(color: Colors.white70)),
              const SizedBox(height: 40),
              _tile(Icons.access_time, 'Triggered At', DateFormat('hh:mm:ss a').format(time)),
              _tile(Icons.map, 'Location', location),
              const SizedBox(height: 60),
              SizedBox(
                width: double.infinity,
                height: 55,
                child: ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.white,
                    foregroundColor: Colors.red.shade900,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
                  ),
                  onPressed: () => Navigator.pop(context),
                  child: const Text('CLOSE ALERT OVERLAY', style: TextStyle(fontWeight: FontWeight.bold)),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _tile(IconData i, String l, String v) => Container(
        margin: const EdgeInsets.symmetric(vertical: 8),
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Colors.white.withOpacity(0.1),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: Colors.white.withOpacity(0.1)),
        ),
        child: Row(children: [
          Icon(i, color: Colors.white70),
          const SizedBox(width: 15),
          Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Text(l, style: const TextStyle(color: Colors.white60, fontSize: 12)),
            Text(v, style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold))
          ])
        ]),
      );
}
