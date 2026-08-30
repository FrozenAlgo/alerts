import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:url_launcher/url_launcher.dart';

import '../config/demo_config.dart';
import 'permission_service.dart';

class SmsSendResult {
  final int sentCount;
  final bool openedComposer;
  final String detail;

  const SmsSendResult({
    required this.sentCount,
    this.openedComposer = false,
    required this.detail,
  });

  bool get success => sentCount > 0 || openedComposer;
}

/// Sends emergency SMS from the device SIM (Android native) or SMS composer (fallback).
class SmsService {
  SmsService._();
  static final SmsService instance = SmsService._();

  static const _channel = MethodChannel('com.accidentalert.app/sms');

  /// Tries silent SIM send first, then alternate number formats, then SMS app.
  Future<SmsSendResult> sendEmergencySms({
    required List<String> phoneNumbers,
    required String message,
  }) async {
    final numbers = _expandNumberVariants(phoneNumbers);
    if (numbers.isEmpty) {
      return const SmsSendResult(sentCount: 0, detail: 'No valid phone number');
    }

    final smsGranted = await PermissionService.request(OnAlertPermission.sms);
    if (!smsGranted) {
      debugPrint('SMS permission denied — opening composer');
      final opened = await _launchSmsComposer(numbers.take(1).toList(), message);
      return SmsSendResult(
        sentCount: 0,
        openedComposer: opened,
        detail: opened
            ? 'SMS permission denied. Opened Messages — tap Send.'
            : 'SMS permission denied. Enable it in Settings → Permissions.',
      );
    }

    if (Platform.isAndroid) {
      for (final number in numbers) {
        final sent = await _sendViaNative(number, message);
        if (sent) {
          debugPrint('SMS sent via SIM to $number');
          return SmsSendResult(
            sentCount: 1,
            detail: 'Emergency SMS sent to $number from your SIM',
          );
        }
      }
    }

    final opened = await _launchSmsComposer(
      [DemoConfig.demoEmergencySmsNumber.replaceAll(' ', '')],
      message,
    );
    return SmsSendResult(
      sentCount: 0,
      openedComposer: opened,
      detail: opened
          ? 'Opened Messages with alert — tap Send to complete'
          : 'Could not send SMS. Check SIM and SMS permission.',
    );
  }

  Future<bool> _sendViaNative(String number, String message) async {
    try {
      final ok = await _channel.invokeMethod<bool>('sendSms', {
        'number': number,
        'message': message,
      });
      return ok == true;
    } on PlatformException catch (e) {
      debugPrint('Native SMS failed (${e.code}): ${e.message}');
      return false;
    } catch (e) {
      debugPrint('Native SMS error: $e');
      return false;
    }
  }

  Future<bool> _launchSmsComposer(List<String> numbers, String message) async {
    final target = numbers.isNotEmpty ? numbers.first : DemoConfig.demoEmergencySmsNumber;
    final uri = Uri.parse(
      'sms:$target?body=${Uri.encodeComponent(message)}',
    );
    try {
      if (await canLaunchUrl(uri)) {
        return await launchUrl(uri, mode: LaunchMode.externalApplication);
      }
    } catch (e) {
      debugPrint('SMS composer launch failed: $e');
    }
    return false;
  }

  List<String> _expandNumberVariants(List<String> rawNumbers) {
    final out = <String>{};
    for (final raw in rawNumbers) {
      for (final variant in _variantsFor(raw)) {
        if (variant.length >= 7) out.add(variant);
      }
    }
    return out.toList();
  }

  List<String> _variantsFor(String raw) {
    final cleaned = raw.replaceAll(RegExp(r'[^\d+]'), '');
    final digitsOnly = cleaned.replaceAll(RegExp(r'\D'), '');
    final variants = <String>[];

    if (cleaned.startsWith('+')) variants.add(cleaned);
    if (digitsOnly.isNotEmpty) variants.add(digitsOnly);
    if (digitsOnly.startsWith('92') && digitsOnly.length > 10) {
      variants.add('0${digitsOnly.substring(2)}');
      variants.add('+$digitsOnly');
    }
    if (digitsOnly.startsWith('0') && digitsOnly.length >= 10) {
      variants.add('+92${digitsOnly.substring(1)}');
    }
    return variants;
  }
}
