import 'dart:convert';
import 'dart:io';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:intl/intl.dart';
import 'package:path_provider/path_provider.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:share_plus/share_plus.dart';

class ExportService {
  static Future<void> exportIncidentPdf(Map<String, dynamic> alert) async {
    final ts = (alert['timestamp'] as Timestamp).toDate();
    final doc = pw.Document();
    doc.addPage(
      pw.Page(
        build: (context) => pw.Column(
          crossAxisAlignment: pw.CrossAxisAlignment.start,
          children: [
            pw.Text('OnAlert Incident Report',
                style: pw.TextStyle(fontSize: 22, fontWeight: pw.FontWeight.bold)),
            pw.SizedBox(height: 16),
            pw.Text('Type: ${alert['type'] ?? 'Alert'}'),
            pw.Text('Date: ${DateFormat('MMM dd, yyyy hh:mm a').format(ts)}'),
            pw.Text('Location: ${alert['lat']}, ${alert['lng']}'),
            pw.Text('Status: ${alert['status'] ?? 'Unknown'}'),
            pw.Text('G-Force: ${alert['g_force'] ?? 'N/A'}'),
          ],
        ),
      ),
    );
    final bytes = await doc.save();
    final dir = await getTemporaryDirectory();
    final file = File('${dir.path}/onalert_incident.pdf');
    await file.writeAsBytes(bytes);
    await Share.shareXFiles([XFile(file.path)], text: 'OnAlert incident report');
  }

  static Future<File> exportAlertsCsv(List<Map<String, dynamic>> alerts) async {
    final buffer = StringBuffer('type,lat,lng,status,timestamp\n');
    for (final alert in alerts) {
      final ts = alert['timestamp'] is Timestamp
          ? (alert['timestamp'] as Timestamp).toDate().toIso8601String()
          : '';
      buffer.writeln(
        '"${alert['type'] ?? ''}","${alert['lat'] ?? ''}","${alert['lng'] ?? ''}","${alert['status'] ?? ''}","$ts"',
      );
    }
    final dir = await getTemporaryDirectory();
    final file = File('${dir.path}/onalert_history.csv');
    await file.writeAsString(buffer.toString());
    return file;
  }

  static Future<void> shareAlertsCsv(List<Map<String, dynamic>> alerts) async {
    final file = await exportAlertsCsv(alerts);
    await Share.shareXFiles([XFile(file.path)], text: 'OnAlert incident history');
  }

  static Future<void> exportUserData(String userId) async {
    final userDoc =
        await FirebaseFirestore.instance.collection('users').doc(userId).get();
    final contacts = await FirebaseFirestore.instance
        .collection('users')
        .doc(userId)
        .collection('contacts')
        .get();
    final alerts = await FirebaseFirestore.instance
        .collection('alerts')
        .where('userId', isEqualTo: userId)
        .get();

    final export = {
      'exportedAt': DateTime.now().toIso8601String(),
      'profile': userDoc.data(),
      'contacts': contacts.docs.map((d) => {'id': d.id, ...d.data()}).toList(),
      'alerts': alerts.docs.map((d) => d.data()).toList(),
    };

    final dir = await getTemporaryDirectory();
    final file = File('${dir.path}/onalert_user_export.json');
    await file.writeAsString(const JsonEncoder.withIndent('  ').convert(export));
    await Share.shareXFiles([XFile(file.path)], text: 'OnAlert user data export');
  }
}
