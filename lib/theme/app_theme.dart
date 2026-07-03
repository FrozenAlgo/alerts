import 'package:flutter/material.dart';

class AppTheme {
  static const Color kPrimaryCyan = Color(0xFF00E5FF);
  static const Color kDarkSlate = Color(0xFF0F172A);
  static const Color kGlassBase = Color(0xFF1E293B);

  static final BoxDecoration kGlassDecoration = BoxDecoration(
    color: kGlassBase.withOpacity(0.6),
    borderRadius: BorderRadius.circular(24),
    border: Border.all(color: Colors.white.withOpacity(0.1)),
    boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.2), blurRadius: 15)],
  );
}

const Color kPrimaryCyan = AppTheme.kPrimaryCyan;
const Color kDarkSlate = AppTheme.kDarkSlate;
const Color kGlassBase = AppTheme.kGlassBase;
