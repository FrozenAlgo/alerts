import 'dart:async';
import 'dart:math';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart' as cf;
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_database/firebase_database.dart' as rtdb;
import 'package:firebase_database/firebase_database.dart';
import 'package:intl/intl.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:video_player/video_player.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import '../services/google_auth_service.dart';
import 'package:chewie/chewie.dart';
import 'package:wakelock_plus/wakelock_plus.dart';
import 'package:fl_chart/fl_chart.dart';

import '../theme/app_theme.dart';
import '../services/emergency_alert_service.dart';
import '../services/device_service.dart';
import '../services/export_service.dart';
import '../services/diagnostic_service.dart';
import '../services/fcm_service.dart';
import '../services/permission_service.dart';
import '../config/demo_config.dart';
import '../services/phone_accelerometer_service.dart';
import '../services/hardware_heartbeat_service.dart';
import '../services/app_database.dart';
import '../services/location_service.dart';
import '../services/system_status_service.dart';
import '../services/user_account_service.dart';
import '../services/alert_analytics_service.dart';
import '../services/contact_notification_service.dart';
import '../screens/full_screen_emergency_alert.dart';
import '../screens/map_screen.dart';
import '../screens/device_qr_scanner_page.dart';
import '../screens/nearby_device_scan_page.dart';
import '../screens/log_viewer_page.dart';
import '../widgets/notification_bell_button.dart';
import '../widgets/brand_background.dart';
import '../widgets/ui/ui.dart';

export '../theme/app_theme.dart';
class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen> {
  late VideoPlayerController _controller;
  bool _showText = false;

  final List<String> _splashVideos = [
    "assets/videos/splash_video.mp4",
    "assets/videos/splash_variant_2.mp4",
    "assets/videos/splash_variant_3.mp4",
  ];

  @override
  void initState() {
    super.initState();

    final random = Random();
    String selectedVideo = _splashVideos[random.nextInt(_splashVideos.length)];

    _controller = VideoPlayerController.asset(selectedVideo)
      ..initialize().then((_) {
        if (mounted) {
          setState(() {});
          _controller.play();
          _controller.setLooping(false);
        }
      });

    Future.delayed(const Duration(seconds: 1), () {
      if (mounted) setState(() => _showText = true);
    });

    // --- 🚨 BULLETPROOF AUTO-LOGIN LOGIC ---
    Timer(const Duration(seconds: 5), () async {
      _controller.pause();

      if (mounted) {
        // WAIT for Firebase to fully read the local storage token
        final user = await FirebaseAuth.instance.authStateChanges().first;

        if (mounted) {
          if (user != null) {
            await FcmService.instance.syncTokenForCurrentUser();
            Navigator.pushReplacement(
              context,
              MaterialPageRoute(builder: (_) => MainAppScreen(uid: user.uid)),
            );
          } else {
            // No token found -> Route to Login
            Navigator.pushReplacement(
              context,
              MaterialPageRoute(builder: (_) => const LoginSignupScreen()),
            );
          }
        }
      }
    });
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.kNavy,
      body: Stack(
        children: [
          if (_controller.value.isInitialized)
            Opacity(
              opacity: 0.35,
              child: SizedBox.expand(
                child: FittedBox(
                  fit: BoxFit.cover,
                  child: SizedBox(
                    width: _controller.value.size.width,
                    height: _controller.value.size.height,
                    child: VideoPlayer(_controller),
                  ),
                ),
              ),
            )
          else
            Container(color: AppTheme.kNavy),
          Container(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                colors: [
                  AppTheme.kNavy.withValues(alpha: 0.55),
                  AppTheme.kNavy.withValues(alpha: 0.92),
                ],
              ),
            ),
          ),
          SafeArea(
            child: AnimatedOpacity(
              opacity: _showText ? 1.0 : 0.0,
              duration: const Duration(milliseconds: 900),
              child: Padding(
                padding: const EdgeInsets.fromLTRB(28, 24, 28, 32),
                child: Column(
                  children: [
                    const Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(Icons.shield_outlined, color: AppTheme.kCyan, size: 22),
                        SizedBox(width: 8),
                        Text('ON ALERT', style: TextStyle(color: Colors.white70, fontWeight: FontWeight.w600, letterSpacing: 3, fontSize: 14)),
                      ],
                    ),
                    const Spacer(),
                    Container(
                      width: 88,
                      height: 88,
                      decoration: BoxDecoration(
                        color: AppTheme.kNavy.withValues(alpha: 0.55),
                        borderRadius: BorderRadius.circular(24),
                        border: Border.all(color: AppTheme.kCyan.withValues(alpha: 0.45)),
                        boxShadow: [BoxShadow(color: AppTheme.kCyan.withValues(alpha: 0.25), blurRadius: 24)],
                      ),
                      child: const Icon(Icons.shield_outlined, color: AppTheme.kCyan, size: 44),
                    ),
                    const SizedBox(height: 28),
                    const Text(
                      'ON ALERT',
                      style: TextStyle(
                        color: AppTheme.kCyan,
                        fontSize: 42,
                        fontWeight: FontWeight.w900,
                        letterSpacing: 6,
                      ),
                    ),
                    const SizedBox(height: 14),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(30),
                        border: Border.all(color: AppTheme.kCyan.withValues(alpha: 0.45)),
                        color: Colors.black.withValues(alpha: 0.25),
                      ),
                      child: const Text(
                        'STAY SAFE • STAY PROTECTED',
                        style: TextStyle(color: Colors.white, fontSize: 11, fontWeight: FontWeight.w700, letterSpacing: 1.6),
                      ),
                    ),
                    const Spacer(),
                    const Text(
                      'EMERGENCY RESPONSE PLATFORM',
                      style: TextStyle(color: Colors.white54, fontSize: 11, fontWeight: FontWeight.w600, letterSpacing: 1.4),
                    ),
                    const SizedBox(height: 14),
                    Container(
                      width: double.infinity,
                      height: 54,
                      alignment: Alignment.center,
                      decoration: BoxDecoration(
                        color: AppTheme.kCyan,
                        borderRadius: BorderRadius.circular(14),
                      ),
                      child: const Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(Icons.lock_outline_rounded, color: AppTheme.kNavy, size: 18),
                          SizedBox(width: 8),
                          Text(
                            'ACTIVATE SECURE ACCESS',
                            style: TextStyle(color: AppTheme.kNavy, fontWeight: FontWeight.w900, letterSpacing: 0.8),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 12),
                    const Text(
                      'AUTHORIZED PERSONNEL ONLY • ENCRYPTED CONNECTION',
                      style: TextStyle(color: Colors.white38, fontSize: 10, letterSpacing: 0.6),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

/// =======================
/// 🔐 LOGIN / SIGNUP (UPDATED WITH GOOGLE AUTH v7+)
/// =======================
class LoginSignupScreen extends StatefulWidget {
  const LoginSignupScreen({super.key});

  @override
  State<LoginSignupScreen> createState() => _LoginSignupScreenState();
}

class _LoginSignupScreenState extends State<LoginSignupScreen> {
  bool isLogin = true;
  bool isLoading = false;
  final _formKey = GlobalKey<FormState>();
  final emailCtrl = TextEditingController();
  final passCtrl = TextEditingController();
  final FirebaseAuth _auth = FirebaseAuth.instance;

  Future<void> _signInWithGoogle() async {
    setState(() => isLoading = true);
    try {
      final userCred = await GoogleAuthService.instance.signInWithGoogle();
      await GoogleAuthService.instance.ensureUserProfile(userCred);
      await UserAccountService.instance.ensureProfileDocument(
        userCred.user!.uid,
        email: userCred.user!.email,
        name: userCred.user!.displayName,
      );

      if (!mounted) return;

      if (userCred.additionalUserInfo?.isNewUser == true) {
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(builder: (_) => OnboardingScreen(uid: userCred.user!.uid)),
        );
      } else {
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(builder: (_) => MainAppScreen(uid: userCred.user!.uid)),
        );
        await FcmService.instance.syncTokenForCurrentUser();
      }
    } on GoogleAuthException catch (e) {
      if (!e.canceled && mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(e.message),
            backgroundColor: Colors.redAccent,
            duration: const Duration(seconds: 8),
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Google Sign-In Failed: $e'),
            backgroundColor: Colors.redAccent,
            duration: const Duration(seconds: 6),
          ),
        );
      }
    } finally {
      if (mounted) setState(() => isLoading = false);
    }
  }

  Future<void> _handleForgotPassword() async {
    final email = emailCtrl.text.trim();
    if (email.isEmpty || !email.contains('@')) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("Please enter a valid email address first."), backgroundColor: Colors.orangeAccent));
      return;
    }
    try {
      await _auth.sendPasswordResetEmail(email: email);
      if (mounted) _showSuccessDialog("Reset Link Sent", "A password reset link has been sent to $email. Please check your inbox.");
    } catch (e) {
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(e.toString()), backgroundColor: Colors.redAccent));
    }
  }

  void _showSuccessDialog(String title, String message) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: AppTheme.kSurface,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20), side: const BorderSide(color: AppTheme.kBorder)),
        title: Row(children: [const Icon(Icons.mark_email_read_rounded, color: AppTheme.kCyan), const SizedBox(width: 10), Text(title, style: const TextStyle(color: AppTheme.kTextPrimary))]),
        content: Text(message, style: const TextStyle(color: AppTheme.kTextSecondary)),
        actions: [TextButton(onPressed: () => Navigator.pop(context), child: const Text("OK", style: TextStyle(fontWeight: FontWeight.bold, color: AppTheme.kCyan)))],
      ),
    );
  }

  Future<void> _handleAuth() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() => isLoading = true);

    try {
      UserCredential cred;
      if (isLogin) {
        cred = await _auth.signInWithEmailAndPassword(email: emailCtrl.text.trim(), password: passCtrl.text.trim());
        await UserAccountService.instance.ensureProfileDocument(
          cred.user!.uid,
          email: cred.user!.email,
          name: cred.user!.displayName,
        );
        if (mounted) Navigator.pushReplacement(context, MaterialPageRoute(builder: (_) => MainAppScreen(uid: cred.user!.uid)));
        await FcmService.instance.syncTokenForCurrentUser();
      } else {
        cred = await _auth.createUserWithEmailAndPassword(email: emailCtrl.text.trim(), password: passCtrl.text.trim());
        final email = emailCtrl.text.trim();
        final defaultName = email.contains('@') ? email.split('@').first : 'OnAlert User';
        await FirebaseFirestore.instance.collection('users').doc(cred.user!.uid).set({
          'name': defaultName,
          'email': email,
          'createdAt': FieldValue.serverTimestamp(),
        }, SetOptions(merge: true));
        if (mounted) Navigator.pushReplacement(context, MaterialPageRoute(builder: (_) => OnboardingScreen(uid: cred.user!.uid)));
      }
    } on FirebaseAuthException catch (e) {
      String errorMessage = "An error occurred. Please try again.";

      if (e.code == 'user-not-found') {
        errorMessage = "No account found with this email. Please Sign Up.";
      } else if (e.code == 'wrong-password') {
        errorMessage = "Incorrect password. Please try again.";
      } else if (e.code == 'email-already-in-use') {
        errorMessage = "An account already exists for this email. Please Login.";
      } else {
        errorMessage = e.message ?? errorMessage;
      }

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(errorMessage), backgroundColor: Colors.redAccent));
      }
    } finally {
      if (mounted) setState(() => isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.kBackground,
      body: BrandBackground(
        child: SafeArea(
          child: Center(
            child: SingleChildScrollView(
              padding: const EdgeInsets.symmetric(horizontal: 22, vertical: 20),
              child: Column(
                children: [
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.symmetric(vertical: 10),
                    decoration: BoxDecoration(
                      color: AppTheme.kSurfaceTint,
                      borderRadius: BorderRadius.circular(14),
                    ),
                    child: const Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(Icons.shield_outlined, color: AppTheme.kCyanDeep, size: 16),
                        SizedBox(width: 8),
                        Text(
                          'SECURE AES-256 CONNECTION',
                          style: TextStyle(color: AppTheme.kCyanDeep, fontWeight: FontWeight.w800, fontSize: 11, letterSpacing: 1),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 18),
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.fromLTRB(24, 28, 24, 28),
                    decoration: AppTheme.kElevatedCardDecoration,
                    child: Form(
                      key: _formKey,
                      child: Column(
                        children: [
                          Container(
                            width: 72,
                            height: 72,
                            decoration: BoxDecoration(
                              color: AppTheme.kCyan,
                              borderRadius: BorderRadius.circular(22),
                              boxShadow: [BoxShadow(color: AppTheme.kCyan.withValues(alpha: 0.35), blurRadius: 16, offset: const Offset(0, 6))],
                            ),
                            child: const Icon(Icons.shield_outlined, color: AppTheme.kNavy, size: 36),
                          ),
                          const SizedBox(height: 20),
                          Text(
                            isLogin ? 'Welcome Back' : 'Create Account',
                            style: const TextStyle(fontSize: 28, fontWeight: FontWeight.w800, color: AppTheme.kTextPrimary),
                          ),
                          const SizedBox(height: 6),
                          Text(
                            isLogin ? 'Secure access to your emergency dashboard' : 'Start your safety journey today',
                            textAlign: TextAlign.center,
                            style: const TextStyle(color: AppTheme.kTextSecondary, fontSize: 14),
                          ),
                          const SizedBox(height: 28),
                          _buildInputField(
                            controller: emailCtrl,
                            label: 'Email',
                            icon: Icons.mail_outline_rounded,
                            hint: 'name@example.com',
                            validator: (v) => (v != null && v.contains('@')) ? null : 'Enter a valid email',
                          ),
                          const SizedBox(height: 16),
                          if (isLogin)
                            Align(
                              alignment: Alignment.centerRight,
                              child: TextButton(
                                onPressed: _handleForgotPassword,
                                style: TextButton.styleFrom(padding: EdgeInsets.zero, minimumSize: Size.zero, tapTargetSize: MaterialTapTargetSize.shrinkWrap),
                                child: const Text('Forgot?', style: TextStyle(color: AppTheme.kCyanDeep, fontWeight: FontWeight.w700)),
                              ),
                            ),
                          if (isLogin) const SizedBox(height: 6),
                          _buildInputField(
                            controller: passCtrl,
                            label: 'Password',
                            icon: Icons.lock_outline_rounded,
                            isPassword: true,
                            hint: '••••••••',
                            validator: (v) => (v != null && v.length >= 6) ? null : 'Minimum 6 characters',
                          ),
                          const SizedBox(height: 22),
                          AppPrimaryButton(
                            label: isLogin ? 'Sign In' : 'Sign Up',
                            trailingIcon: Icons.arrow_forward_rounded,
                            onPressed: isLoading ? null : _handleAuth,
                            isLoading: isLoading,
                          ),
                          const SizedBox(height: 20),
                          const Row(
                            children: [
                              Expanded(child: Divider(color: AppTheme.kBorder)),
                              Padding(
                                padding: EdgeInsets.symmetric(horizontal: 10),
                                child: Text('OR', style: TextStyle(color: AppTheme.kTextSecondary, fontWeight: FontWeight.w700, fontSize: 12)),
                              ),
                              Expanded(child: Divider(color: AppTheme.kBorder)),
                            ],
                          ),
                          const SizedBox(height: 20),
                          SizedBox(
                            width: double.infinity,
                            height: 52,
                            child: OutlinedButton.icon(
                              onPressed: isLoading ? null : _signInWithGoogle,
                              icon: const Icon(Icons.g_mobiledata, color: AppTheme.kNavy, size: 30),
                              label: const Text('Continue with Google', style: TextStyle(fontSize: 15, fontWeight: FontWeight.w700, color: AppTheme.kNavy)),
                              style: OutlinedButton.styleFrom(
                                side: const BorderSide(color: AppTheme.kBorder, width: 1.4),
                                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                              ),
                            ),
                          ),
                          const SizedBox(height: 18),
                          TextButton(
                            onPressed: () => setState(() => isLogin = !isLogin),
                            child: RichText(
                              text: TextSpan(
                                style: const TextStyle(color: AppTheme.kTextSecondary, fontSize: 14),
                                children: [
                                  TextSpan(text: isLogin ? "Don't have an account? " : 'Already have an account? '),
                                  TextSpan(
                                    text: isLogin ? 'Create Account' : 'Sign In',
                                    style: const TextStyle(color: AppTheme.kCyanDeep, fontWeight: FontWeight.w800),
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(height: 22),
                  const Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(Icons.lock_outline_rounded, size: 14, color: AppTheme.kTextSecondary),
                      SizedBox(width: 6),
                      Text(
                        'END-TO-END ENCRYPTED PROTECTION',
                        style: TextStyle(color: AppTheme.kTextSecondary, fontSize: 10, fontWeight: FontWeight.w700, letterSpacing: 0.8),
                      ),
                    ],
                  ),
                  const SizedBox(height: 6),
                  const Text(
                    '© 2024 On Alert Systems. All rights reserved.',
                    style: TextStyle(color: AppTheme.kTextSecondary, fontSize: 11),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildInputField({
    required TextEditingController controller,
    required String label,
    required IconData icon,
    bool isPassword = false,
    String? hint,
    String? Function(String?)? validator,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label, style: const TextStyle(color: AppTheme.kTextPrimary, fontWeight: FontWeight.w700, fontSize: 13)),
        const SizedBox(height: 8),
        TextFormField(
          controller: controller,
          obscureText: isPassword,
          validator: validator,
          style: const TextStyle(fontSize: 15, color: AppTheme.kTextPrimary, fontWeight: FontWeight.w600),
          decoration: AppTheme.fieldDecoration(label: '', icon: icon, hint: hint).copyWith(labelText: null, floatingLabelBehavior: FloatingLabelBehavior.never),
        ),
      ],
    );
  }
}

/// =======================
/// 🏠 MAIN APP SCREEN
/// =======================
class MainAppScreen extends StatefulWidget {
  final String uid;
  const MainAppScreen({super.key, required this.uid});

  @override
  State<MainAppScreen> createState() => _MainAppScreenState();
}

class _MainAppScreenState extends State<MainAppScreen> {
  int _index = 0;
  StreamSubscription<DatabaseEvent>? _globalHeartbeatSub;
  Timer? _globalHeartbeatTimer;
  StreamSubscription<Map<String, dynamic>>? _globalAccidentSub;
  final _heartbeatSvc = HardwareHeartbeatService.instance;
  final _phoneAccel = PhoneAccelerometerService.instance;
  HardwareHeartbeat _globalHeartbeat = HardwareHeartbeat.offline;
  DateTime? _globalHeartbeatAt;

  @override
  void initState() {
    super.initState();
    ContactNotificationService.instance.startListening(widget.uid);
    FcmService.instance.syncTokenForCurrentUser();
    _syncPhoneIndexIfNeeded();
    _startGlobalHeartbeat();
    _startGlobalAccidentMonitoring();
    if (DemoConfig.forceSystemOnline) {
      SystemStatusService.instance.setOnline(true);
    }
  }

  void _startGlobalAccidentMonitoring() {
    _phoneAccel.addListener();
    if (DemoConfig.sendRealSmsOnAccident) {
      PermissionService.request(OnAlertPermission.sms);
    }
    _globalAccidentSub = _phoneAccel.onLocalAccidentDetected.listen((_) {
      _handleGlobalAccident();
    });
  }

  Future<void> _handleGlobalAccident() async {
    if (!mounted) return;

    await FcmService.instance.showLocalEmergencyNotification(
      title: 'ACCIDENT DETECTED',
      body: DemoConfig.smsSimulationMessage,
      data: const {'alert': 'ACCIDENT_DETECTED'},
    );

    if (!DemoConfig.sendRealSmsOnAccident) return;

    final result = await EmergencyAlertService().sendLocalAccidentAlert(widget.uid);
    if (!mounted) return;

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(result.detail),
        backgroundColor: result.success ? AppTheme.kSuccess : AppTheme.kWarning,
        duration: DemoConfig.accidentUiDuration,
      ),
    );
  }

  void _startGlobalHeartbeat() {
    if (DemoConfig.forceSystemOnline) {
      _globalHeartbeat = const HardwareHeartbeat(
        connected: true,
        isOnline: true,
        lat: DemoConfig.islamabadLat,
        lng: DemoConfig.islamabadLng,
        gpsFix: true,
      );
      _publishGlobalOnlineStatus();
    }
    _globalHeartbeatSub = _heartbeatSvc.heartbeatStream(widget.uid).listen((event) {
      _globalHeartbeatAt = DateTime.now();
      _globalHeartbeat = _heartbeatSvc.parse(
        event.snapshot.value,
        receivedAt: _globalHeartbeatAt,
      );
      _publishGlobalOnlineStatus();
    });
    _heartbeatSvc.heartbeatRef(widget.uid).keepSynced(true);
    _globalHeartbeatTimer = Timer.periodic(const Duration(seconds: 1), (_) {
      _publishGlobalOnlineStatus();
    });
  }

  void _publishGlobalOnlineStatus() {
    final online = _heartbeatSvc.isCurrentlyOnline(
      connected: _globalHeartbeat.connected,
      lastSeenMs: _globalHeartbeat.lastSeenMs,
      lastFirebaseEventAt: _globalHeartbeatAt,
    );
    SystemStatusService.instance.setOnline(online);
  }

  Future<void> _syncPhoneIndexIfNeeded() async {
    final doc = await FirebaseFirestore.instance.collection('users').doc(widget.uid).get();
    final phone = doc.data()?['phone']?.toString() ?? '';
    if (phone.isNotEmpty) {
      await ContactNotificationService.instance.syncPhoneIndex(widget.uid, phone);
    }
  }

  @override
  void dispose() {
    _globalHeartbeatSub?.cancel();
    _globalHeartbeatTimer?.cancel();
    _globalAccidentSub?.cancel();
    _phoneAccel.removeListener();
    SystemStatusService.instance.reset();
    ContactNotificationService.instance.stopListening();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    // 1. Add the Tutorial Page to the list
    final pages = [
      DashboardPage(userId: widget.uid),
      const AlertsScreen(),
      ContactFormPage(userId: widget.uid),
      const VideoTutorialPage(), // <--- NEW TAB
      SettingsScreen(userId: widget.uid),
    ];

    return Scaffold(
      extendBody: true,
      backgroundColor: AppTheme.kBackground,
      body: BrandBackground(
        child: AnimatedSwitcher(
          duration: const Duration(milliseconds: 300),
          child: pages[_index],
        ),
      ),
      bottomNavigationBar: Container(
        margin: const EdgeInsets.fromLTRB(18, 0, 18, 18),
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 8),
        decoration: BoxDecoration(
          color: AppTheme.kNavy,
          borderRadius: BorderRadius.circular(32),
          boxShadow: [
            BoxShadow(color: AppTheme.kNavy.withValues(alpha: 0.28), blurRadius: 24, offset: const Offset(0, 10)),
          ],
        ),
        child: Row(
          children: [
            _navItem(0, Icons.sensors_rounded, 'Status'),
            _navItem(1, Icons.notifications_none_rounded, 'Alerts'),
            _navItem(2, Icons.people_alt_outlined, 'Contacts'),
            _navItem(3, Icons.explore_outlined, 'Guide'),
            _navItem(4, Icons.person_outline_rounded, 'Profile'),
          ],
        ),
      ),
    );
  }

  Widget _navItem(int index, IconData icon, String label) {
    final active = _index == index;
    return Expanded(
      child: GestureDetector(
        onTap: () => setState(() => _index = index),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          padding: const EdgeInsets.symmetric(vertical: 10),
          decoration: BoxDecoration(
            color: active ? AppTheme.kCyan : Colors.transparent,
            borderRadius: BorderRadius.circular(24),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(icon, size: 20, color: active ? AppTheme.kNavy : Colors.white70),
              const SizedBox(height: 3),
              Text(
                label,
                style: TextStyle(
                  fontSize: 10,
                  fontWeight: FontWeight.w700,
                  color: active ? AppTheme.kNavy : Colors.white60,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// ==========================================
/// 📊 DASHBOARD PAGE
/// ==========================================
class DashboardPage extends StatelessWidget {
  final String userId;
  DashboardPage({super.key, required this.userId});

  final GlobalKey<ScaffoldState> _scaffoldKey = GlobalKey<ScaffoldState>();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      key: _scaffoldKey,
      backgroundColor: Colors.transparent,

      drawer: Drawer(
        backgroundColor: AppTheme.kSurface,
        child: Column(
          children: [
            _buildDrawerHeader(),
            const SizedBox(height: 12),
            _buildDrawerTile(Icons.dashboard_rounded, "Dashboard", () => Navigator.pop(context), isActive: true),
              _buildDrawerTile(Icons.memory_rounded, "Live Sensor Data", () {
                Navigator.pop(context);
                Navigator.push(context, MaterialPageRoute(builder: (_) => LiveHardwareMonitor(userId: userId)));
              }),
              _buildDrawerTile(Icons.history_rounded, "Incident Logs", () {
                Navigator.pop(context);
                Navigator.push(context, MaterialPageRoute(builder: (_) => const AlertsScreen()));
              }),
              _buildDrawerTile(Icons.developer_board_rounded, "Device Manager", () {
                Navigator.pop(context);
                Navigator.push(context, MaterialPageRoute(builder: (_) => DeviceManagerPage(userId: userId)));
              }),
              const Divider(color: AppTheme.kBorder, indent: 20, endIndent: 20, height: 40),
              _buildDrawerTile(Icons.help_outline_rounded, "Help & Support", () {
                Navigator.pop(context);
                Navigator.push(context, MaterialPageRoute(builder: (_) => const HelpSupportPage()));
              }),
              const Spacer(),
              _buildLogoutTile(context),
              const SizedBox(height: 32),
            ],
          ),
      ),

      appBar: AppBrandedAppBar(
        title: 'On Alert',
        showShield: true,
        leading: IconButton(
          icon: Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: AppTheme.kSurfaceTint,
              borderRadius: BorderRadius.circular(12),
            ),
            child: const Icon(Icons.menu_rounded, color: AppTheme.kNavy, size: 20),
          ),
          onPressed: () => _scaffoldKey.currentState?.openDrawer(),
        ),
        actions: [
          const NotificationBellButton(),
          ListenableBuilder(
            listenable: SystemStatusService.instance,
            builder: (context, _) {
              final online = SystemStatusService.instance.isOnline;
              return Tooltip(
                message: online ? 'System Active — ESP32 online' : 'System Offline',
                child: Container(
                  margin: const EdgeInsets.only(right: 14),
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: online ? AppTheme.kSuccessSoft : const Color(0xFFFEE2E2),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Container(
                        width: 8,
                        height: 8,
                        decoration: BoxDecoration(
                          color: online ? AppTheme.kSuccess : AppTheme.kEmergencyRed,
                          shape: BoxShape.circle,
                        ),
                      ),
                      const SizedBox(width: 6),
                      Text(
                        online ? 'ACTIVE' : 'OFFLINE',
                        style: TextStyle(
                          fontSize: 10,
                          fontWeight: FontWeight.w800,
                          color: online ? const Color(0xFF166534) : AppTheme.kEmergencyRed,
                        ),
                      ),
                    ],
                  ),
                ),
              );
            },
          ),
        ],
      ),

      body: SingleChildScrollView(
        padding: const EdgeInsets.fromLTRB(18, 8, 18, 130),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            DashboardStatusModule(userId: userId),
            const SizedBox(height: 16),
            AppCard(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      const Expanded(
                        child: Text('Safety Circle', style: TextStyle(fontSize: 18, fontWeight: FontWeight.w800, color: AppTheme.kTextPrimary)),
                      ),
                      InkWell(
                        onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => ContactFormPage(userId: userId))),
                        child: Container(
                          width: 34,
                          height: 34,
                          decoration: BoxDecoration(color: AppTheme.kSurfaceTint, shape: BoxShape.circle),
                          child: const Icon(Icons.add, color: AppTheme.kCyanDeep, size: 20),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  const Text(
                    'Only members in this circle will be notified during critical triggers.',
                    style: TextStyle(color: AppTheme.kTextSecondary, fontSize: 13, height: 1.35),
                  ),
                  const SizedBox(height: 14),
                  StreamBuilder<QuerySnapshot>(
                    stream: FirebaseFirestore.instance.collection('users').doc(userId).collection('contacts').snapshots(),
                    builder: (context, snap) {
                      final docs = snap.data?.docs ?? [];
                      if (docs.isEmpty) {
                        return const Text('No members yet', style: TextStyle(color: AppTheme.kTextSecondary, fontSize: 13));
                      }
                      final show = docs.take(4).toList();
                      final extra = docs.length - show.length;
                      return Row(
                        children: [
                          for (var i = 0; i < show.length; i++)
                            Transform.translate(
                              offset: Offset(i * -10.0, 0),
                              child: CircleAvatar(
                                radius: 18,
                                backgroundColor: AppTheme.kCyan,
                                child: Text(
                                  ((show[i].data() as Map)['name']?.toString() ?? '?')[0].toUpperCase(),
                                  style: const TextStyle(color: AppTheme.kNavy, fontWeight: FontWeight.w800),
                                ),
                              ),
                            ),
                          if (extra > 0)
                            Transform.translate(
                              offset: Offset(show.length * -10.0, 0),
                              child: CircleAvatar(
                                radius: 18,
                                backgroundColor: AppTheme.kSurfaceTint,
                                child: Text('+$extra', style: const TextStyle(color: AppTheme.kCyanDeep, fontWeight: FontWeight.w800, fontSize: 12)),
                              ),
                            ),
                        ],
                      );
                    },
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),
            AppCard(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text('Emergency Contacts', style: TextStyle(fontSize: 18, fontWeight: FontWeight.w800, color: AppTheme.kTextPrimary)),
                  const SizedBox(height: 8),
                  EmergencyContactsList(userId: userId),
                  const SizedBox(height: 8),
                  TextButton.icon(
                    onPressed: () => Navigator.push(context, MaterialPageRoute(builder: (_) => ContactFormPage(userId: userId))),
                    icon: const Icon(Icons.person_add_alt_1_rounded, size: 18),
                    label: const Text('Manage Contact List', style: TextStyle(fontWeight: FontWeight.w700)),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildDrawerHeader() {
    return StreamBuilder<DocumentSnapshot>(
      stream: FirebaseFirestore.instance.collection('users').doc(userId).snapshots(),
      builder: (context, snapshot) {
        String name = "OnAlert User";
        if (snapshot.hasData && snapshot.data!.exists) {
          name = (snapshot.data!.data() as Map<String, dynamic>)['name'] ?? "OnAlert User";
        }
        return Container(
          width: double.infinity,
          padding: const EdgeInsets.fromLTRB(20, 56, 20, 20),
          decoration: const BoxDecoration(gradient: AppTheme.kHeaderGradient),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                padding: const EdgeInsets.all(3),
                decoration: BoxDecoration(shape: BoxShape.circle, border: Border.all(color: AppTheme.kCyan, width: 2)),
                child: const CircleAvatar(radius: 28, backgroundColor: AppTheme.kSurface, child: Icon(Icons.person, color: AppTheme.kNavy, size: 32)),
              ),
              const SizedBox(height: 14),
              Text(name, style: const TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold)),
              StreamBuilder<DocumentSnapshot>(
                stream: FirebaseFirestore.instance.collection('users').doc(userId).snapshots(),
                builder: (context, snap) {
                  final paired = (snap.data?.data() as Map?)?['pairedDevice']?.toString() ?? '';
                  final label = paired.isNotEmpty ? 'Device connected' : 'No device paired';
                  return Text(label, style: const TextStyle(color: AppTheme.kCyan, fontSize: 12, fontWeight: FontWeight.w600));
                },
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildDrawerTile(IconData icon, String title, VoidCallback onTap, {bool isActive = false}) {
    return ListTile(
      contentPadding: const EdgeInsets.symmetric(horizontal: 25),
      leading: Icon(icon, color: isActive ? AppTheme.kCyan : AppTheme.kTextSecondary),
      title: Text(title, style: TextStyle(fontSize: 14, fontWeight: isActive ? FontWeight.w700 : FontWeight.w500, color: isActive ? AppTheme.kCyan : AppTheme.kTextPrimary)),
      onTap: onTap,
    );
  }

  Widget _buildLogoutTile(BuildContext context) {
    return ListTile(
      contentPadding: const EdgeInsets.symmetric(horizontal: 25),
      leading: const Icon(Icons.logout_rounded, color: Colors.redAccent, size: 20),
      title: const Text("Sign Out", style: TextStyle(color: Colors.redAccent, fontSize: 14, fontWeight: FontWeight.bold)),
      onTap: () async {
        await FirebaseAuth.instance.signOut();
        if (context.mounted) Navigator.of(context).pushNamedAndRemoveUntil('/', (route) => false);
      },
    );
  }

}

/// ==========================================
/// 📡 DASHBOARD STATUS MODULE
/// ==========================================
class DashboardStatusModule extends StatefulWidget {
  final String userId;
  const DashboardStatusModule({super.key, required this.userId});

  @override
  State<DashboardStatusModule> createState() => _DashboardStatusModuleState();
}

class _DashboardStatusModuleState extends State<DashboardStatusModule> {
  bool _isDialogShowing = false;

  /// Wizard of Oz: phone accelerometer drives X/Y/Z + crash UI (ESP32 sensor bypass).
  StreamSubscription<AccelerometerReading>? _accelerometerStreamSubscription;
  StreamSubscription<Map<String, dynamic>>? _localAccidentSubscription;
  StreamSubscription<DatabaseEvent>? _heartbeatStreamSubscription;
  Timer? _onlineRefreshTimer;
  Timer? _phoneGpsTimer;

  final _phoneAccel = PhoneAccelerometerService.instance;
  final _heartbeat = HardwareHeartbeatService.instance;
  AccelerometerReading _accelReading = AccelerometerReading.idle;

  HardwareHeartbeat _heartbeatState = HardwareHeartbeat.offline;
  DateTime? _lastFirebaseHeartbeatAt;
  double? _phoneLat;
  double? _phoneLng;

  @override
  void initState() {
    super.initState();
    _phoneAccel.addListener();
    _accelerometerStreamSubscription = _phoneAccel.readings.listen((reading) {
      if (mounted) setState(() => _accelReading = reading);
    });
    _localAccidentSubscription = _phoneAccel.onLocalAccidentDetected.listen((_) {
      if (mounted) setState(() {});
    });
    _heartbeatStreamSubscription =
        _heartbeat.heartbeatStream(widget.userId).listen((event) {
      if (!mounted) return;
      setState(() {
        _lastFirebaseHeartbeatAt = DateTime.now();
        _heartbeatState = _heartbeat.parse(
          event.snapshot.value,
          receivedAt: _lastFirebaseHeartbeatAt,
        );
      });
    });
    _heartbeat.heartbeatRef(widget.userId).keepSynced(true);
    if (DemoConfig.forceSystemOnline) {
      _heartbeatState = HardwareHeartbeat(
        connected: true,
        isOnline: true,
        lastSeenMs: DateTime.now().millisecondsSinceEpoch,
        lat: DemoConfig.islamabadLat,
        lng: DemoConfig.islamabadLng,
        gpsFix: true,
      );
    }
    _onlineRefreshTimer = Timer.periodic(const Duration(seconds: 1), (_) {
      if (mounted && _heartbeatState.connected) setState(() {});
    });
    _refreshPhoneGps();
    _phoneGpsTimer = Timer.periodic(const Duration(seconds: 8), (_) => _refreshPhoneGps());
  }

  Future<void> _refreshPhoneGps() async {
    final phone = await LocationService.getPhoneLocation();
    if (!mounted || phone == null) return;
    setState(() {
      _phoneLat = phone.lat;
      _phoneLng = phone.lng;
    });
  }

  @override
  void dispose() {
    _accelerometerStreamSubscription?.cancel();
    _localAccidentSubscription?.cancel();
    _heartbeatStreamSubscription?.cancel();
    _onlineRefreshTimer?.cancel();
    _phoneGpsTimer?.cancel();
    _phoneAccel.removeListener();
    super.dispose();
  }

  bool get _isSystemOnline => _heartbeat.isCurrentlyOnline(
        connected: _heartbeatState.connected,
        lastSeenMs: _heartbeatState.lastSeenMs,
        lastFirebaseEventAt: _lastFirebaseHeartbeatAt,
      );

  void _showAccidentDialog(BuildContext context, Map data) {
    if (_isDialogShowing) return;
    setState(() => _isDialogShowing = true);
    HapticFeedback.vibrate();

    int countdown = 10;
    Timer? timer;

    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => StatefulBuilder(
        builder: (context, setDialogState) {
          timer ??= Timer.periodic(const Duration(seconds: 1), (t) {
            if (countdown > 0) {
              if (mounted) setDialogState(() => countdown--);
            } else {
              t.cancel();
              Navigator.pop(context);
              setState(() => _isDialogShowing = false);
              _triggerFinalSOS(data);
            }
          });
          return AlertDialog(
            backgroundColor: Colors.red.shade900,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20), side: const BorderSide(color: Colors.redAccent)),
            title: const Icon(Icons.warning_amber_rounded, color: Colors.white, size: 60),
            content: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Text("ACCIDENT DETECTED!", style: TextStyle(color: AppTheme.kTextOnBrand, fontWeight: FontWeight.bold, fontSize: 22)),
                const SizedBox(height: 15),
                Text("$countdown", style: const TextStyle(color: Colors.white, fontSize: 50, fontWeight: FontWeight.w900)),
              ],
            ),
            actions: [
              ElevatedButton(
                style: ElevatedButton.styleFrom(backgroundColor: Colors.white, foregroundColor: Colors.red.shade900),
                onPressed: () {
                  timer?.cancel();
                  Navigator.pop(context);
                  setState(() => _isDialogShowing = false);
                },
                child: const Text("I AM SAFE - CANCEL"),
              ),
            ],
          );
        },
      ),
    );
  }

  void _triggerFinalSOS(Map data) async {
    await WakelockPlus.enable();
    double lat = 0.0;
    double lng = 0.0;

    final userDoc = await FirebaseFirestore.instance.collection('users').doc(widget.userId).get();
    final pairedSerial = userDoc.data()?['pairedDevice']?.toString() ?? '';

    if (pairedSerial.isNotEmpty) {
      final statusSnap = await AppDatabase.rtdb.ref('devices/$pairedSerial/status').get();
      if (statusSnap.value != null) {
        final status = Map<dynamic, dynamic>.from(statusSnap.value as Map);
        lat = double.tryParse(status['lat']?.toString() ?? '0.0') ?? 0.0;
        lng = double.tryParse(status['lng']?.toString() ?? '0.0') ?? 0.0;
      }
    }

    final hardwareSnap = await AppDatabase.rtdb.ref('users/${widget.userId}/hardware').get();
    double hardwareLat = 0;
    double hardwareLng = 0;
    if (hardwareSnap.value != null) {
      final hw = Map<dynamic, dynamic>.from(hardwareSnap.value as Map);
      hardwareLat = double.tryParse(hw['lat']?.toString() ?? '0') ?? 0;
      hardwareLng = double.tryParse(hw['lng']?.toString() ?? '0') ?? 0;
    }

    lat = double.tryParse(data['lat']?.toString() ?? '') ?? lat;
    lng = double.tryParse(data['lng']?.toString() ?? '') ?? lng;

    final resolved = await LocationService.resolveLocation(
      deviceLat: lat,
      deviceLng: lng,
      hardwareLat: hardwareLat,
      hardwareLng: hardwareLng,
    );
    lat = resolved.lat;
    lng = resolved.lng;

    final snapshot = await FirebaseFirestore.instance.collection('users').doc(widget.userId).collection('contacts').get();
    if (mounted) {
      await EmergencyAlertService().sendEmergencyAlert(
          context,
          snapshot.docs.map((d) => d.data()).toList(),
          widget.userId,
          lat,
          lng,
          isAuto: true
      );
    }
  }

  void _showManualSosCountdown(BuildContext context, double lat, double lng) {
    HapticFeedback.heavyImpact();
    int countdown = 5;
    Timer? timer;
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setDialogState) {
          timer ??= Timer.periodic(const Duration(seconds: 1), (t) async {
            if (countdown > 0) {
              setDialogState(() => countdown--);
            } else {
              t.cancel();
              Navigator.pop(ctx);
              await WakelockPlus.enable();
              final snap = await FirebaseFirestore.instance.collection('users').doc(widget.userId).collection('contacts').get();
              if (mounted) {
                await EmergencyAlertService().sendEmergencyAlert(
                  context,
                  snap.docs.map((d) => d.data()).toList(),
                  widget.userId,
                  lat,
                  lng,
                );
              }
            }
          });
          return AlertDialog(
            backgroundColor: Colors.red.shade900,
            title: const Text('Confirm Manual SOS', style: TextStyle(color: Colors.white)),
            content: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text('$countdown', style: const TextStyle(color: Colors.white, fontSize: 48, fontWeight: FontWeight.w900)),
                const Text('Sending alert to all contacts...', style: TextStyle(color: Colors.white70)),
              ],
            ),
            actions: [
              TextButton(
                onPressed: () {
                  timer?.cancel();
                  Navigator.pop(ctx);
                },
                child: const Text('CANCEL', style: TextStyle(color: Colors.white)),
              ),
            ],
          );
        },
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<DocumentSnapshot>(
      stream: FirebaseFirestore.instance.collection('users').doc(widget.userId).snapshots(),
      builder: (context, userSnapshot) {
        if (!userSnapshot.hasData) {
          return const Center(child: CircularProgressIndicator(color: AppTheme.kPrimaryCyan));
        }

        final pairedSerial =
            (userSnapshot.data?.data() as Map<String, dynamic>?)?['pairedDevice']?.toString() ?? '';

        final isOnline = _isSystemOnline;

        if (pairedSerial.isEmpty && !_heartbeatState.connected && !DemoConfig.forceSystemOnline) {
          return _buildNoDeviceUI();
        }

        if (pairedSerial.isEmpty) {
          final resolved = LocationService.resolveDisplayCoordinates(
            hardwareLat: _heartbeatState.lat,
            hardwareLng: _heartbeatState.lng,
            phoneLat: _phoneLat,
            phoneLng: _phoneLng,
          );
          return _buildStatusUI(
            pairedSerial: 'ESP32-HEARTBEAT',
            isOnline: isOnline,
            lat: resolved.lat,
            lng: resolved.lng,
            rawLat: _heartbeatState.lat,
            rawLng: _heartbeatState.lng,
            locationSource: resolved.source,
            gpsFix: _heartbeatState.gpsFix || resolved.source != 'demo_fix',
            gsmConnected: isOnline,
            gsmSignal: isOnline ? 85 : 0,
            firebaseAlert: _heartbeatState.alert,
          );
        }

        return StreamBuilder<DatabaseEvent>(
          stream: AppDatabase.rtdb.ref('devices/$pairedSerial/status').onValue,
          builder: (context, deviceSnapshot) {
            double deviceLat = 0.0;
            double deviceLng = 0.0;
            bool gsmConnected = isOnline;
            int gsmSignal = isOnline ? 85 : 0;
            String firebaseAlert = _heartbeatState.alert;

            if (deviceSnapshot.hasData && deviceSnapshot.data!.snapshot.value != null) {
              final data = Map<dynamic, dynamic>.from(deviceSnapshot.data!.snapshot.value as Map);
              deviceLat = double.tryParse(data['lat']?.toString() ?? '0.0') ?? 0.0;
              deviceLng = double.tryParse(data['lng']?.toString() ?? '0.0') ?? 0.0;
              gsmConnected = data['gsm_connected'] != false && isOnline;
              gsmSignal = int.tryParse(data['gsm_signal']?.toString() ?? '') ?? gsmSignal;
              firebaseAlert = data['alert']?.toString() ?? firebaseAlert;
            }

            final resolved = LocationService.resolveDisplayCoordinates(
              deviceLat: deviceLat,
              deviceLng: deviceLng,
              hardwareLat: _heartbeatState.lat,
              hardwareLng: _heartbeatState.lng,
              phoneLat: _phoneLat,
              phoneLng: _phoneLng,
            );
            final rawLat = LocationService.coordsValid(deviceLat, deviceLng)
                ? deviceLat
                : _heartbeatState.lat;
            final rawLng = LocationService.coordsValid(deviceLat, deviceLng)
                ? deviceLng
                : _heartbeatState.lng;

            return _buildStatusUI(
              pairedSerial: pairedSerial,
              isOnline: isOnline,
              lat: resolved.lat,
              lng: resolved.lng,
              rawLat: rawLat,
              rawLng: rawLng,
              locationSource: resolved.source,
              gpsFix: _heartbeatState.gpsFix ||
                  LocationService.coordsValid(deviceLat, deviceLng) ||
                  resolved.source != 'demo_fix',
              gsmConnected: gsmConnected,
              gsmSignal: gsmSignal,
              firebaseAlert: firebaseAlert,
            );
          },
        );
      },
    );
  }

  Widget _buildStatusUI({
    required String pairedSerial,
    required bool isOnline,
    required double lat,
    required double lng,
    required double rawLat,
    required double rawLng,
    required String locationSource,
    required bool gpsFix,
    required bool gsmConnected,
    required int gsmSignal,
    String firebaseAlert = 'NORMAL',
  }) {
    final localAccident = _accelReading.localAccidentActive;
    final espAccident = firebaseAlert.toUpperCase().contains('ACCIDENT');
    final showAccidentUi = localAccident || espAccident;
    String accelStatus;
    Color accelColor = Colors.greenAccent;

    if (localAccident) {
      accelStatus = 'IMPACT!';
      accelColor = Colors.redAccent;
    } else if (_accelReading.gForce > DemoConfig.gForceThreshold * 0.75) {
      accelStatus = '${_accelReading.gForce.toStringAsFixed(1)}G';
      accelColor = Colors.orangeAccent;
    } else {
      accelStatus = '${_accelReading.gForce.toStringAsFixed(1)}G';
    }

    final accelColorResolved =
        accelColor == Colors.redAccent ? AppTheme.kAlertRed : AppTheme.kSuccess;
    final systemAlert = localAccident
        ? _phoneAccel.resolveAlertStatus(null)
        : (espAccident ? firebaseAlert : _phoneAccel.resolveAlertStatus(firebaseAlert));

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (showAccidentUi) ...[
          Container(
            width: double.infinity,
            margin: const EdgeInsets.only(bottom: 8),
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
            decoration: BoxDecoration(
              color: AppTheme.kNavy,
              borderRadius: BorderRadius.circular(14),
              border: Border.all(color: AppTheme.kCyan, width: 1.5),
            ),
            child: Row(
              children: [
                const Icon(Icons.sms_rounded, color: AppTheme.kCyan),
                const SizedBox(width: 10),
                Expanded(
                  child: Text(
                    DemoConfig.smsSimulationMessage,
                    style: TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.w800,
                      fontSize: 13,
                    ),
                  ),
                ),
              ],
            ),
          ),
          Container(
            width: double.infinity,
            margin: const EdgeInsets.only(bottom: 10),
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
            decoration: BoxDecoration(
              color: AppTheme.kAlertRed,
              borderRadius: BorderRadius.circular(14),
              boxShadow: [
                BoxShadow(
                  color: AppTheme.kAlertRed.withValues(alpha: 0.35),
                  blurRadius: 12,
                  offset: Offset(0, 4),
                ),
              ],
            ),
            child: Row(
              children: [
                const Icon(Icons.warning_amber_rounded, color: Colors.white),
                const SizedBox(width: 10),
                Expanded(
                  child: Text(
                    systemAlert,
                    style: const TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.w900,
                      letterSpacing: 0.6,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
        AppCard(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  const Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text('System Status',
                            style: TextStyle(
                                fontSize: 18,
                                fontWeight: FontWeight.w800,
                                color: AppTheme.kTextPrimary)),
                        SizedBox(height: 4),
                        Text('Real-time telemetry and hardware diagnostics.',
                            style: TextStyle(color: AppTheme.kTextSecondary, fontSize: 12)),
                      ],
                    ),
                  ),
                  if (pairedSerial != 'ESP32-HEARTBEAT')
                    TextButton(
                      onPressed: () => DeviceService.removeDevice(widget.userId),
                      child: const Text('Unpair',
                          style: TextStyle(color: AppTheme.kAlertRed, fontWeight: FontWeight.w700)),
                    ),
                ],
              ),
              const SizedBox(height: 12),
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                    decoration: BoxDecoration(
                      color: isOnline ? AppTheme.kSuccessSoft : const Color(0xFFFEE2E2),
                      borderRadius: BorderRadius.circular(30),
                    ),
                    child: Text(
                      isOnline ? '● SYSTEM ONLINE' : '● SYSTEM OFFLINE',
                      style: TextStyle(
                        color: isOnline ? const Color(0xFF166534) : AppTheme.kEmergencyRed,
                        fontWeight: FontWeight.w800,
                        fontSize: 12,
                      ),
                    ),
                  ),
                  if (isOnline) ...[
                    const SizedBox(width: 8),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
                      decoration: BoxDecoration(
                        color: AppTheme.kCyan.withValues(alpha: 0.15),
                        borderRadius: BorderRadius.circular(30),
                        border: Border.all(color: AppTheme.kCyan.withValues(alpha: 0.5)),
                      ),
                      child: const Text(
                        'SYSTEM ACTIVE',
                        style: TextStyle(
                          color: AppTheme.kCyanDeep,
                          fontWeight: FontWeight.w900,
                          fontSize: 11,
                          letterSpacing: 0.5,
                        ),
                      ),
                    ),
                  ],
                ],
              ),
              const SizedBox(height: 6),
              Text('ID: $pairedSerial', style: const TextStyle(color: AppTheme.kTextSecondary, fontSize: 11)),
              if (!isOnline) ...[
                const SizedBox(height: 12),
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: const Color(0xFFFFF7ED),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: AppTheme.kWarning.withValues(alpha: 0.4)),
                  ),
                  child: Row(
                    children: [
                      const Icon(Icons.battery_alert_rounded, color: AppTheme.kWarning),
                      const SizedBox(width: 10),
                      Expanded(
                        child: Text(
                          _heartbeatState.connected
                              ? 'Heartbeat stale. ESP32 must update last_seen every 10s at users/${widget.userId}/hardware.'
                              : 'No ESP32 heartbeat. Power on device and ensure Firebase UID matches the app login.',
                          style: const TextStyle(color: AppTheme.kTextPrimary, fontSize: 13),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
              const SizedBox(height: 14),
              Row(
                children: [
                  _metricTile(Icons.bolt_rounded, 'ACCEL', accelStatus, accelColorResolved),
                  const SizedBox(width: 8),
                  _metricTile(Icons.location_on_outlined, 'GPS', gpsFix ? 'FIX' : 'NO FIX',
                      gpsFix ? AppTheme.kCyanDeep : AppTheme.kTextSecondary),
                  const SizedBox(width: 8),
                  _metricTile(Icons.signal_cellular_alt_rounded, 'GSM',
                      gsmConnected ? '$gsmSignal%' : 'ON',
                      gsmConnected ? AppTheme.kSuccess : AppTheme.kTextSecondary),
                ],
              ),
              const SizedBox(height: 14),
              _buildAxisTelemetryRow(),
              const SizedBox(height: 14),
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(14),
                decoration: BoxDecoration(
                  color: AppTheme.kSurfaceMuted,
                  borderRadius: BorderRadius.circular(16),
                ),
                child: Row(
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text('Last location sync',
                              style: TextStyle(color: AppTheme.kTextSecondary, fontSize: 11)),
                          const SizedBox(height: 4),
                          Text(
                            _locationLabel(locationSource, rawLat, rawLng, lat, lng),
                            style: const TextStyle(
                                color: AppTheme.kTextPrimary,
                                fontWeight: FontWeight.w800,
                                fontSize: 13),
                          ),
                        ],
                      ),
                    ),
                    ElevatedButton.icon(
                      onPressed: () => Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (_) => MapScreen(
                                lat: lat,
                                lng: lng,
                                liveMode: true,
                                deviceSerial: pairedSerial != 'ESP32-HEARTBEAT' ? pairedSerial : null,
                                userId: widget.userId,
                              ),
                            ),
                          ),
                      icon: const Icon(Icons.map_rounded, size: 16),
                      label: const Text('VIEW LIVE MAP',
                          style: TextStyle(fontWeight: FontWeight.w800, fontSize: 11)),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppTheme.kCyan,
                        foregroundColor: AppTheme.kNavy,
                        elevation: 0,
                        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 14),
        AppPrimaryButton(
          label: 'INITIALIZE MANUAL SOS',
          icon: Icons.sos_rounded,
          color: AppTheme.kAlertRed,
          onPressed: () => _showManualSosCountdown(context, lat, lng),
        ),
        const SizedBox(height: 10),
        AppPrimaryButton(
          label: 'CALL EMERGENCY SERVICES',
          icon: Icons.call_rounded,
          outlined: true,
          color: AppTheme.kEmergencyRed,
          onPressed: () async {
            final Uri telUri = Uri.parse('tel:911');
            if (await canLaunchUrl(telUri)) await launchUrl(telUri);
          },
        ),
      ],
    );
  }

  String _locationLabel(
    String source,
    double rawLat,
    double rawLng,
    double displayLat,
    double displayLng,
  ) {
    final coords = '${displayLat.toStringAsFixed(4)}°, ${displayLng.toStringAsFixed(4)}°';
    switch (source) {
      case 'esp32_gps':
        return 'ESP32 GPS • $coords';
      case 'phone_gps':
        return 'GPS • $coords';
      case 'demo_fix':
        return 'location • $coords';
      default:
        if (!LocationService.coordsValid(rawLat, rawLng)) {
          return 'location • $coords';
        }
        return coords;
    }
  }

  Widget _buildAxisTelemetryRow() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: AppTheme.kSurfaceTint,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: AppTheme.kBorder),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        
      ),
    );
  }

  Widget _axisChip(String axis, double value) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 6),
      decoration: BoxDecoration(
        color: AppTheme.kSurface,
        borderRadius: BorderRadius.circular(10),
      ),
      child: Column(
        children: [
          Text(axis,
              style: const TextStyle(
                  color: AppTheme.kTextSecondary, fontSize: 10, fontWeight: FontWeight.w700)),
          const SizedBox(height: 2),
          Text(
            value.toStringAsFixed(2),
            style: const TextStyle(
                color: AppTheme.kTextPrimary, fontWeight: FontWeight.w800, fontSize: 13),
          ),
        ],
      ),
    );
  }

  Widget _metricTile(IconData icon, String label, String value, Color color) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 8),
        decoration: BoxDecoration(
          color: AppTheme.kSurfaceTint,
          borderRadius: BorderRadius.circular(14),
        ),
        child: Column(
          children: [
            Icon(icon, color: color, size: 18),
            const SizedBox(height: 6),
            Text(label, style: const TextStyle(color: AppTheme.kTextSecondary, fontSize: 10, fontWeight: FontWeight.w700)),
            const SizedBox(height: 2),
            Text(value, style: TextStyle(color: color, fontWeight: FontWeight.w800, fontSize: 13)),
          ],
        ),
      ),
    );
  }

  Widget _buildNoDeviceUI() => AppCard(
    child: Column(children: [
      Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(color: AppTheme.kSurfaceTint, shape: BoxShape.circle),
        child: const Icon(Icons.sensors_off_rounded, size: 40, color: AppTheme.kCyanDeep),
      ),
      const SizedBox(height: 14),
      const Text('Waiting for ESP32', style: TextStyle(fontWeight: FontWeight.w800, fontSize: 18, color: AppTheme.kTextPrimary)),
      const SizedBox(height: 6),
      Text(
        'Listening at users/$widget.userId/hardware\n'
        'Power on ESP32 or pair a device via Device Manager.',
        textAlign: TextAlign.center,
        style: const TextStyle(color: AppTheme.kTextSecondary, height: 1.4),
      ),
      const SizedBox(height: 18),
      AppPrimaryButton(
        label: 'Pair Hardware',
        icon: Icons.qr_code_scanner_rounded,
        onPressed: () => Navigator.push(context, MaterialPageRoute(builder: (_) => DeviceManagerPage(userId: widget.userId))),
      ),
    ]),
  );
}

/// ==========================================
/// 📇 CONTACTS LIST
/// ==========================================
class EmergencyContactsList extends StatelessWidget {
  final String userId;
  const EmergencyContactsList({super.key, required this.userId});

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<QuerySnapshot>(
      stream: FirebaseFirestore.instance
          .collection('users')
          .doc(userId)
          .collection('contacts')
          .snapshots(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator(color: AppTheme.kPrimaryCyan));
        }

        if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
          return _buildEmptyState();
        }

        final docs = snapshot.data!.docs;

        return ListView.separated(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          itemCount: docs.length,
          separatorBuilder: (_, __) => const Divider(height: 1, color: AppTheme.kBorder),
          itemBuilder: (c, i) {
            final doc = docs[i];
            final data = doc.data() as Map<String, dynamic>;
            final String name = data['name'] ?? "Unknown";
            final String number = data['number'] ?? "No Number";
            final isPrimary = i == 0;

            return ListTile(
              contentPadding: const EdgeInsets.symmetric(vertical: 6),
              leading: _buildGlassAvatar(name),
              title: Text(name, style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 15, color: AppTheme.kTextPrimary)),
              subtitle: Text(
                isPrimary ? 'Primary Contact' : 'Secondary Contact',
                style: const TextStyle(color: AppTheme.kTextSecondary, fontWeight: FontWeight.w500, fontSize: 12),
              ),
              trailing: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  if (isPrimary)
                    const Icon(Icons.verified_rounded, color: AppTheme.kSuccess, size: 20)
                  else
                    PopupMenuButton<String>(
                      icon: const Icon(Icons.more_vert_rounded, color: AppTheme.kTextSecondary),
                      onSelected: (v) {
                        if (v == 'edit') _showEditContactDialog(context, doc.id, name, number);
                        if (v == 'delete') _confirmDelete(context, doc.id);
                      },
                      itemBuilder: (_) => const [
                        PopupMenuItem(value: 'edit', child: Text('Edit')),
                        PopupMenuItem(value: 'delete', child: Text('Delete')),
                      ],
                    ),
                  if (isPrimary) ...[
                    IconButton(
                      icon: const Icon(Icons.edit_rounded, color: AppTheme.kCyanDeep, size: 20),
                      onPressed: () => _showEditContactDialog(context, doc.id, name, number),
                    ),
                    _buildDeleteButton(context, doc.id),
                  ],
                ],
              ),
            );
          },
        );
      },
    );
  }

  void _showEditContactDialog(BuildContext context, String docId, String currentName, String currentNumber) {
    final nameCtrl = TextEditingController(text: currentName);
    final phoneCtrl = TextEditingController(text: currentNumber);

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: AppTheme.kSurface,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20), side: const BorderSide(color: AppTheme.kBorder)),
        title: const Text("Edit Contact", style: TextStyle(color: AppTheme.kTextPrimary, fontWeight: FontWeight.bold)),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(controller: nameCtrl, style: const TextStyle(color: AppTheme.kTextPrimary), decoration: AppTheme.fieldDecoration(label: 'Full Name', icon: Icons.person_outline_rounded)),
            const SizedBox(height: 15),
            TextField(controller: phoneCtrl, keyboardType: TextInputType.phone, style: const TextStyle(color: AppTheme.kTextPrimary), decoration: AppTheme.fieldDecoration(label: 'Phone Number', icon: Icons.phone_outlined)),
          ],
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text("CANCEL", style: TextStyle(color: AppTheme.kTextSecondary))),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: AppTheme.kCyan, foregroundColor: AppTheme.kNavy),
            onPressed: () async {
              await FirebaseFirestore.instance.collection('users').doc(userId).collection('contacts').doc(docId).update({
                'name': nameCtrl.text.trim(),
                'number': phoneCtrl.text.trim(),
              });
              if (context.mounted) Navigator.pop(context);
            },
            child: const Text("SAVE", style: TextStyle(fontWeight: FontWeight.bold)),
          ),
        ],
      ),
    );
  }

  Widget _buildGlassAvatar(String name) {
    return Container(
      width: 52,
      height: 52,
      decoration: BoxDecoration(
        color: AppTheme.kPrimaryCyan.withOpacity(0.2),
        shape: BoxShape.circle,
        border: Border.all(color: AppTheme.kPrimaryCyan, width: 1.5),
      ),
      child: Center(
        child: Text(
          name.isNotEmpty ? name[0].toUpperCase() : "?",
          style: const TextStyle(color: AppTheme.kPrimaryCyan, fontWeight: FontWeight.w900, fontSize: 20),
        ),
      ),
    );
  }

  Widget _buildDeleteButton(BuildContext context, String docId) {
    return IconButton(
      icon: const Icon(Icons.delete_sweep_rounded, color: Colors.redAccent, size: 24),
      onPressed: () => _confirmDelete(context, docId),
    );
  }

  Widget _buildEmptyState() {
    return const Padding(
      padding: EdgeInsets.symmetric(vertical: 20),
      child: Column(
        children: [
          Icon(Icons.person_add_disabled_rounded, size: 48, color: AppTheme.kTextSecondary),
          SizedBox(height: 12),
          Text("Security Circle Empty", style: TextStyle(color: AppTheme.kTextPrimary, fontWeight: FontWeight.bold, fontSize: 16)),
          Text("Add contacts to enable SOS alerts", style: TextStyle(color: AppTheme.kTextSecondary, fontSize: 13)),
        ],
      ),
    );
  }

  void _confirmDelete(BuildContext context, String docId) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: AppTheme.kSurface,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20), side: const BorderSide(color: AppTheme.kAlertRed)),
        title: const Text("Remove Contact?", style: TextStyle(color: AppTheme.kTextPrimary, fontWeight: FontWeight.bold)),
        content: const Text("This person will no longer receive emergency alerts.", style: TextStyle(color: AppTheme.kTextSecondary)),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text("KEEP", style: TextStyle(color: AppTheme.kTextSecondary))),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: AppTheme.kAlertRed, foregroundColor: Colors.white),
            onPressed: () {
              FirebaseFirestore.instance.collection('users').doc(userId).collection('contacts').doc(docId).delete();
              Navigator.pop(context);
            },
            child: const Text("DELETE", style: TextStyle(fontWeight: FontWeight.bold)),
          ),
        ],
      ),
    );
  }
}

/// ==========================================
/// 🔔 ALERTS HISTORY SCREEN
/// ==========================================
class AlertsScreen extends StatefulWidget {
  const AlertsScreen({super.key});

  @override
  State<AlertsScreen> createState() => _AlertsScreenState();
}

class _AlertsScreenState extends State<AlertsScreen> {
  bool _isDescending = true;
  DateTimeRange? _dateRange;

  Future<void> _pickDateRange() async {
    final range = await showDateRangePicker(
      context: context,
      firstDate: DateTime(2020),
      lastDate: DateTime.now(),
      builder: (context, child) => Theme(
        data: Theme.of(context).copyWith(colorScheme: const ColorScheme.light(primary: AppTheme.kCyan)),
        child: child!,
      ),
    );
    if (range != null) setState(() => _dateRange = range);
  }

  bool _inRange(DateTime ts) {
    if (_dateRange == null) return true;
    return !ts.isBefore(_dateRange!.start) && !ts.isAfter(_dateRange!.end.add(const Duration(days: 1)));
  }

  Widget _analyticsChip(String label, int value, Color color) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Text('$label: $value', style: TextStyle(color: color, fontSize: 11, fontWeight: FontWeight.w700)),
    );
  }

  @override
  Widget build(BuildContext context) {
    final String currentUid = FirebaseAuth.instance.currentUser?.uid ?? "";

    return Scaffold(
      backgroundColor: AppTheme.kBackground,
      appBar: AppBar(
        title: const Text("Incident History", style: TextStyle(color: AppTheme.kTextPrimary, fontWeight: FontWeight.bold)),
        centerTitle: true,
        elevation: 0,
        backgroundColor: Colors.transparent,
        actions: [
          IconButton(
            icon: const Icon(Icons.date_range, color: AppTheme.kPrimaryCyan),
            tooltip: 'Filter by date range',
            onPressed: _pickDateRange,
          ),
          if (_dateRange != null)
            IconButton(
              icon: const Icon(Icons.clear, color: Colors.orangeAccent),
              onPressed: () => setState(() => _dateRange = null),
            ),
          IconButton(
            icon: Icon(_isDescending ? Icons.filter_list_rounded : Icons.filter_list_off_rounded, color: AppTheme.kPrimaryCyan),
            tooltip: "Sort by Date",
            onPressed: () {
              setState(() => _isDescending = !_isDescending);
            },
          ),
          IconButton(
            icon: const Icon(Icons.download_rounded, color: AppTheme.kPrimaryCyan),
            tooltip: 'Export CSV',
            onPressed: () async {
              final snap = await cf.FirebaseFirestore.instance
                  .collection('alerts')
                  .where('userId', isEqualTo: currentUid)
                  .get();
              final alerts = snap.docs.map((d) => d.data()).toList();
              await ExportService.shareAlertsCsv(alerts);
            },
          ),
        ],
      ),
      body: StreamBuilder<cf.QuerySnapshot>(
        stream: cf.FirebaseFirestore.instance
            .collection('alerts')
            .where('userId', isEqualTo: currentUid)
            .orderBy('timestamp', descending: _isDescending)
            .snapshots(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator(color: AppTheme.kPrimaryCyan));
          }

          if (snapshot.hasError) {
            return Center(child: Text("Error: ${snapshot.error}", style: const TextStyle(color: Colors.redAccent)));
          }

          final docs = snapshot.data?.docs ?? [];
          final filtered = docs.where((d) {
            final alert = d.data() as Map<String, dynamic>;
            if (alert['timestamp'] is! cf.Timestamp) return true;
            return _inRange((alert['timestamp'] as cf.Timestamp).toDate());
          }).toList();

          if (filtered.isEmpty) {
            return const Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.history_rounded, size: 60, color: AppTheme.kTextSecondary),
                  SizedBox(height: 15),
                  Text("No incident history recorded.", style: TextStyle(color: AppTheme.kTextSecondary)),
                ],
              ),
            );
          }

          final activeCount = filtered.length;
          final latest = filtered.isNotEmpty
              ? (filtered.first.data() as Map<String, dynamic>)['timestamp'] as cf.Timestamp?
              : null;

          final alertMaps = filtered.map((d) => d.data() as Map<String, dynamic>).toList();
          final analytics = AlertAnalyticsService.instance.compute(alertMaps);
          final safetyLabel = '${analytics.safetyScorePercent}%';

          return ListView(
            padding: const EdgeInsets.fromLTRB(16, 8, 16, 120),
            children: [
              Row(
                children: [
                  Expanded(
                    child: Container(
                      padding: const EdgeInsets.all(18),
                      decoration: BoxDecoration(
                        color: AppTheme.kNavy,
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Icon(Icons.shield_outlined, color: AppTheme.kCyan),
                          const SizedBox(height: 10),
                          const Text('Safe Status', style: TextStyle(color: AppTheme.kCyan, fontWeight: FontWeight.w600)),
                          const SizedBox(height: 4),
                          Text(safetyLabel, style: const TextStyle(color: Colors.white, fontSize: 28, fontWeight: FontWeight.w900)),
                          if (analytics.daysSinceLastAlert >= 0)
                            Text(
                              analytics.daysSinceLastAlert == 0
                                  ? 'Alert today'
                                  : '${analytics.daysSinceLastAlert}d since last',
                              style: TextStyle(color: Colors.white.withValues(alpha: 0.7), fontSize: 11),
                            ),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: AppCard(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Icon(Icons.warning_amber_rounded, color: AppTheme.kAlertRed),
                          const SizedBox(height: 10),
                          const Text('Active Alerts', style: TextStyle(color: AppTheme.kTextSecondary, fontWeight: FontWeight.w600)),
                          const SizedBox(height: 4),
                          Text(activeCount.toString().padLeft(2, '0'), style: const TextStyle(color: AppTheme.kTextPrimary, fontSize: 28, fontWeight: FontWeight.w900)),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 14),
              AppCard(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text('7-DAY INCIDENT TREND', style: TextStyle(color: AppTheme.kTextSecondary, fontWeight: FontWeight.w800, letterSpacing: 0.8, fontSize: 11)),
                    const SizedBox(height: 16),
                    SizedBox(
                      height: 140,
                      child: BarChart(
                        BarChartData(
                          maxY: (analytics.weeklyCounts.reduce((a, b) => a > b ? a : b) + 1).toDouble().clamp(2, 12),
                          gridData: const FlGridData(show: false),
                          borderData: FlBorderData(show: false),
                          titlesData: FlTitlesData(
                            leftTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                            topTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                            rightTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                            bottomTitles: AxisTitles(
                              sideTitles: SideTitles(
                                showTitles: true,
                                getTitlesWidget: (value, meta) {
                                  final i = value.toInt();
                                  if (i < 0 || i >= analytics.weeklyLabels.length) return const SizedBox.shrink();
                                  return Padding(
                                    padding: const EdgeInsets.only(top: 6),
                                    child: Text(analytics.weeklyLabels[i], style: const TextStyle(fontSize: 10, color: AppTheme.kTextSecondary)),
                                  );
                                },
                              ),
                            ),
                          ),
                          barGroups: List.generate(analytics.weeklyCounts.length, (i) {
                            final count = analytics.weeklyCounts[i];
                            return BarChartGroupData(
                              x: i,
                              barRods: [
                                BarChartRodData(
                                  toY: count.toDouble(),
                                  color: count > 0 ? AppTheme.kAlertRed : AppTheme.kCyan.withValues(alpha: 0.35),
                                  width: 14,
                                  borderRadius: const BorderRadius.vertical(top: Radius.circular(6)),
                                ),
                              ],
                            );
                          }),
                        ),
                      ),
                    ),
                    const SizedBox(height: 12),
                    Row(
                      children: [
                        _analyticsChip('Auto', analytics.autoCrashCount, AppTheme.kAlertRed),
                        const SizedBox(width: 8),
                        _analyticsChip('Manual SOS', analytics.manualSosCount, AppTheme.kCyanDeep),
                        const Spacer(),
                        Text('Total ${analytics.totalAlerts}', style: const TextStyle(color: AppTheme.kTextSecondary, fontSize: 12, fontWeight: FontWeight.w700)),
                      ],
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 22),
              Row(
                children: [
                  const Text('RECENT INCIDENTS', style: TextStyle(color: AppTheme.kTextSecondary, fontWeight: FontWeight.w800, letterSpacing: 1, fontSize: 12)),
                  const Spacer(),
                  if (latest != null)
                    Text(
                      'Latest: ${DateFormat('h:mm a').format(latest.toDate())}',
                      style: const TextStyle(color: AppTheme.kCyanDeep, fontWeight: FontWeight.w700, fontSize: 12),
                    ),
                ],
              ),
              const SizedBox(height: 12),
              ...filtered.map((doc) {
                final alert = doc.data() as Map<String, dynamic>;
                final DateTime ts = (alert['timestamp'] as cf.Timestamp).toDate();
                final type = (alert['type'] ?? 'Alert').toString();
                final isAuto = type.toLowerCase().contains('auto') || type.toLowerCase().contains('crash') || type.toLowerCase().contains('accident');
                return Padding(
                  padding: const EdgeInsets.only(bottom: 12),
                  child: AppCard(
                    onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => DetailedAlertView(alert: alert))),
                    padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                    child: Row(
                      children: [
                        CircleAvatar(
                          backgroundColor: const Color(0xFFFFE4E6),
                          child: Icon(isAuto ? Icons.directions_car_filled_rounded : Icons.medical_services_outlined, color: AppTheme.kAlertRed),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(type.toUpperCase(), style: const TextStyle(fontWeight: FontWeight.w800, color: AppTheme.kTextPrimary, fontSize: 13)),
                              const SizedBox(height: 4),
                              Text(DateFormat('MMM dd, yyyy • hh:mm a').format(ts), style: const TextStyle(color: AppTheme.kTextSecondary, fontSize: 12)),
                              const SizedBox(height: 6),
                              Container(
                                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                                decoration: BoxDecoration(
                                  color: isAuto ? const Color(0xFFFFE4E6) : AppTheme.kSurfaceTint,
                                  borderRadius: BorderRadius.circular(20),
                                ),
                                child: Text(
                                  isAuto ? 'CRITICAL' : 'RESOLVED',
                                  style: TextStyle(
                                    color: isAuto ? AppTheme.kAlertRed : AppTheme.kCyanDeep,
                                    fontWeight: FontWeight.w800,
                                    fontSize: 10,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                        const Icon(Icons.chevron_right_rounded, color: AppTheme.kTextSecondary),
                      ],
                    ),
                  ),
                );
              }),
              const SizedBox(height: 8),
              const Center(child: Text('Showing records for last 30 days', style: TextStyle(color: AppTheme.kTextSecondary, fontSize: 12))),
            ],
          );
        },
      ),
    );
  }
}

/// ==========================================
/// 🔍 DETAILED ALERT VIEW (WITH EXPORT FEATURE)
/// ==========================================
class DetailedAlertView extends StatelessWidget {
  final Map<String, dynamic> alert;
  const DetailedAlertView({super.key, required this.alert});

  void _exportIncidentReport(BuildContext context) {
    ExportService.exportIncidentPdf(alert);
  }

  @override
  Widget build(BuildContext context) {
    final DateTime ts = (alert['timestamp'] as Timestamp).toDate();

    final gForce = alert['g_force']?.toString() ?? '0.0';
    final lat = alert['lat']?.toString() ?? '0.0';
    final lng = alert['lng']?.toString() ?? '0.0';

    return Scaffold(
      backgroundColor: AppTheme.kBackground,
      appBar: AppBrandedAppBar(
        title: 'On Alert',
        showShield: true,
        actions: [
          IconButton(
            icon: const Icon(Icons.picture_as_pdf_rounded, color: AppTheme.kCyanDeep),
            tooltip: "Export Report",
            onPressed: () => _exportIncidentReport(context),
          )
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.fromLTRB(18, 8, 18, 32),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(22),
              decoration: BoxDecoration(
                color: AppTheme.kAlertRed,
                borderRadius: BorderRadius.circular(22),
                boxShadow: [BoxShadow(color: AppTheme.kAlertRed.withValues(alpha: 0.28), blurRadius: 16, offset: const Offset(0, 8))],
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    alert['type']?.toString() ?? 'Severe Impact Detected',
                    style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w900, fontSize: 22),
                  ),
                  const SizedBox(height: 6),
                  const Text('Notification Sent to Emergency Services', style: TextStyle(color: Colors.white70, fontSize: 13)),
                ],
              ),
            ),
            const SizedBox(height: 14),
            Row(
              children: [
                _buildInfoCard('TIME', DateFormat('HH:mm:ss').format(ts), DateFormat('MMM dd, yyyy').format(ts), Icons.access_time_rounded, AppTheme.kCyanDeep, AppTheme.kTextPrimary),
                const SizedBox(width: 12),
                _buildInfoCard('G-FORCE', '$gForce G', 'Critical Threshold', Icons.speed_rounded, AppTheme.kAlertRed, AppTheme.kAlertRed),
              ],
            ),
            const SizedBox(height: 14),
            AppCard(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      const Icon(Icons.location_on_outlined, color: AppTheme.kCyanDeep),
                      const SizedBox(width: 8),
                      const Expanded(child: Text('Tactical Location', style: TextStyle(fontWeight: FontWeight.w800, fontSize: 16, color: AppTheme.kTextPrimary))),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                        decoration: BoxDecoration(color: AppTheme.kSurfaceTint, borderRadius: BorderRadius.circular(20)),
                        child: const Text('High Accuracy', style: TextStyle(color: AppTheme.kCyanDeep, fontWeight: FontWeight.w700, fontSize: 11)),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(14),
                    decoration: BoxDecoration(color: AppTheme.kSurfaceMuted, borderRadius: BorderRadius.circular(14)),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text('COORDINATES', style: TextStyle(color: AppTheme.kTextSecondary, fontSize: 11, fontWeight: FontWeight.w700)),
                        const SizedBox(height: 4),
                        Text('$lat° N, $lng° W', style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 15, color: AppTheme.kTextPrimary)),
                      ],
                    ),
                  ),
                  const SizedBox(height: 12),
                  const Text('STREET ADDRESS', style: TextStyle(color: AppTheme.kTextSecondary, fontSize: 11, fontWeight: FontWeight.w700)),
                  const SizedBox(height: 4),
                  Text(alert['address']?.toString() ?? 'Location captured from device GPS', style: const TextStyle(fontWeight: FontWeight.w700, color: AppTheme.kTextPrimary)),
                ],
              ),
            ),
            const SizedBox(height: 18),
            const Text('Detailed Analysis', style: TextStyle(fontSize: 18, fontWeight: FontWeight.w800, color: AppTheme.kTextPrimary)),
            const SizedBox(height: 10),
            AppCard(
              padding: EdgeInsets.zero,
              child: Column(
                children: [
                  ListTile(
                    leading: CircleAvatar(backgroundColor: AppTheme.kSurfaceTint, child: const Icon(Icons.graphic_eq_rounded, color: AppTheme.kCyanDeep)),
                    title: const Text('Impact Vector', style: TextStyle(fontWeight: FontWeight.w700)),
                    subtitle: Text(alert['vector']?.toString() ?? 'Impact event recorded', style: const TextStyle(color: AppTheme.kTextSecondary)),
                    trailing: const Icon(Icons.chevron_right_rounded, color: AppTheme.kTextSecondary),
                  ),
                  const Divider(height: 1),
                  ListTile(
                    leading: CircleAvatar(backgroundColor: AppTheme.kSurfaceTint, child: const Icon(Icons.person_outline_rounded, color: AppTheme.kCyanDeep)),
                    title: const Text('Emergency Contact', style: TextStyle(fontWeight: FontWeight.w700)),
                    subtitle: const Text('Safety circle notified', style: TextStyle(color: AppTheme.kTextSecondary)),
                    trailing: const Icon(Icons.check_circle_rounded, color: AppTheme.kSuccess),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 20),
            AppPrimaryButton(
              label: 'VIEW ON SATELLITE MAP',
              icon: Icons.map_rounded,
              foregroundColor: AppTheme.kNavy,
              onPressed: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (_) => MapScreen(
                      lat: DemoConfig.resolveMapCoordinates(
                        double.tryParse(lat) ?? 0,
                        double.tryParse(lng) ?? 0,
                      ).lat,
                      lng: DemoConfig.resolveMapCoordinates(
                        double.tryParse(lat) ?? 0,
                        double.tryParse(lng) ?? 0,
                      ).lng,
                    ),
                  ),
                );
              },
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildInfoCard(String title, String val, String sub, IconData icon, Color accent, Color valueColor) {
    return Expanded(
      child: AppCard(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(icon, color: accent, size: 18),
                const SizedBox(width: 6),
                Text(title, style: const TextStyle(color: AppTheme.kTextSecondary, fontSize: 11, fontWeight: FontWeight.w700)),
              ],
            ),
            const SizedBox(height: 10),
            Text(val, style: TextStyle(fontWeight: FontWeight.w900, fontSize: 20, color: valueColor)),
            const SizedBox(height: 4),
            Text(sub, style: TextStyle(color: valueColor == AppTheme.kAlertRed ? AppTheme.kAlertRed : AppTheme.kTextSecondary, fontSize: 12)),
          ],
        ),
      ),
    );
  }
}

/// ==========================================
/// ⚙️ SETTINGS & PROFILE MODULE
/// ==========================================
class SettingsScreen extends StatefulWidget {
  final String userId;
  const SettingsScreen({super.key, required this.userId});

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  bool _pushNotifications = true;
  bool _smsAlerts = true;

  final TextEditingController _nameController = TextEditingController();
  final TextEditingController _phoneController = TextEditingController();
  final TextEditingController _bloodTypeController = TextEditingController();
  final TextEditingController _medicalController = TextEditingController();
  final TextEditingController _vehicleController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _loadUserSettings();
  }

  Future<void> _loadUserSettings() async {
    final prefs = await SharedPreferences.getInstance();
    final doc = await FirebaseFirestore.instance.collection('users').doc(widget.userId).get();

    setState(() {
      _pushNotifications = prefs.getBool('push_active') ?? true;
      _smsAlerts = prefs.getBool('sms_active') ?? true;
      if (doc.exists && doc.data() != null) {
        final data = doc.data()!;
        _nameController.text = data['name'] ?? "";
        _phoneController.text = data['phone'] ?? "";
        _bloodTypeController.text = data['bloodType'] ?? "";
        _medicalController.text = data['medicalConditions'] ?? "";
        _vehicleController.text = data['vehiclePlate'] ?? "";
      }
    });
  }

  Future<void> _updateNotification(String key, bool value) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(key, value);
    setState(() {
      if (key == 'push_active') _pushNotifications = value;
      if (key == 'sms_active') _smsAlerts = value;
    });
    if (key == 'push_active') {
      if (value) {
        await FcmService.instance.syncTokenForCurrentUser();
      } else {
        await FcmService.instance.clearTokenForCurrentUser();
      }
    }
  }

  void _showEditProfile() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: AppTheme.kSurface,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20), side: BorderSide(color: Colors.white.withOpacity(0.1))),
        title: const Text("Update Profile", style: TextStyle(color: AppTheme.kTextPrimary, fontWeight: FontWeight.bold)),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              _buildDialogField("Full Name", _nameController, Icons.person),
              const SizedBox(height: 10),
              _buildDialogField("Phone (for contact alerts)", _phoneController, Icons.phone_outlined, keyboardType: TextInputType.phone),
              const SizedBox(height: 10),
              _buildDialogField("Blood Type (e.g., O+)", _bloodTypeController, Icons.water_drop),
              const SizedBox(height: 10),
              _buildDialogField("Medical Info (Allergies)", _medicalController, Icons.medical_information),
              const SizedBox(height: 10),
              _buildDialogField("Vehicle Plate", _vehicleController, Icons.directions_car),
            ],
          ),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text("CANCEL", style: TextStyle(color: Colors.blueGrey))),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: AppTheme.kPrimaryCyan),
            onPressed: () async {
              final phone = _phoneController.text.trim();
              await FirebaseFirestore.instance.collection('users').doc(widget.userId).set({
                'name': _nameController.text.trim(),
                'phone': phone,
                'bloodType': _bloodTypeController.text.trim(),
                'medicalConditions': _medicalController.text.trim(),
                'vehiclePlate': _vehicleController.text.trim(),
              }, SetOptions(merge: true));
              if (phone.isNotEmpty) {
                await ContactNotificationService.instance.syncPhoneIndex(widget.userId, phone);
              }
              if (mounted) Navigator.pop(context);
              setState(() {});
            },
            child: const Text("SAVE", style: TextStyle(color: Colors.black, fontWeight: FontWeight.bold)),
          ),
        ],
      ),
    );
  }

  void _showDeleteAccountDialog() {
    final passwordCtrl = TextEditingController();
    final user = FirebaseAuth.instance.currentUser;
    final isEmailAccount = user?.email != null && (user?.providerData.any((p) => p.providerId == 'password') ?? false);

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: AppTheme.kSurface,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20), side: const BorderSide(color: Colors.redAccent)),
        title: const Row(children: [Icon(Icons.warning_amber_rounded, color: Colors.redAccent), SizedBox(width: 10), Text("Delete Account?", style: TextStyle(color: AppTheme.kTextPrimary))]),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'This permanently deletes your profile, contacts, alert history, and device pairing.',
              style: TextStyle(color: AppTheme.kTextSecondary),
            ),
            if (isEmailAccount) ...[
              const SizedBox(height: 14),
              TextField(
                controller: passwordCtrl,
                obscureText: true,
                style: const TextStyle(color: AppTheme.kTextPrimary),
                decoration: const InputDecoration(
                  labelText: 'Confirm password',
                  labelStyle: TextStyle(color: Colors.blueGrey),
                  border: OutlineInputBorder(),
                ),
              ),
            ],
          ],
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text("CANCEL", style: TextStyle(color: Colors.blueGrey))),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: Colors.redAccent),
            onPressed: () async {
              try {
                if (isEmailAccount) {
                  if (passwordCtrl.text.trim().isEmpty) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text('Enter your password to confirm deletion.'), backgroundColor: Colors.redAccent),
                    );
                    return;
                  }
                  await UserAccountService.instance.reauthenticateWithPassword(passwordCtrl.text.trim());
                }
                await UserAccountService.instance.deleteAccount(widget.userId);
                if (context.mounted) {
                  Navigator.pop(context);
                  Navigator.pushAndRemoveUntil(
                    context,
                    MaterialPageRoute(builder: (_) => const LoginSignupScreen()),
                    (r) => false,
                  );
                }
              } on FirebaseAuthException catch (e) {
                if (context.mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text(e.code == 'requires-recent-login'
                          ? 'Please sign out, sign in again, then retry delete.'
                          : (e.message ?? 'Could not delete account.')),
                      backgroundColor: Colors.redAccent,
                    ),
                  );
                }
              } catch (e) {
                if (context.mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text('Delete failed: $e'), backgroundColor: Colors.redAccent),
                  );
                }
              }
            },
            child: const Text("DELETE PERMANENTLY", style: TextStyle(color: AppTheme.kTextPrimary, fontWeight: FontWeight.bold)),
          ),
        ],
      ),
    );
  }

  Widget _buildDialogField(String label, TextEditingController ctrl, IconData icon, {TextInputType? keyboardType}) {
    return TextField(
      controller: ctrl,
      keyboardType: keyboardType,
      style: const TextStyle(color: AppTheme.kTextPrimary),
      decoration: InputDecoration(
        labelText: label,
        labelStyle: const TextStyle(color: Colors.blueGrey, fontSize: 13),
        prefixIcon: Icon(icon, color: AppTheme.kPrimaryCyan, size: 20),
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
        contentPadding: const EdgeInsets.symmetric(vertical: 10),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final user = FirebaseAuth.instance.currentUser;

    return Scaffold(
      backgroundColor: AppTheme.kBackground,
      appBar: AppBar(
        title: const Text("Settings", style: TextStyle(color: AppTheme.kTextPrimary, fontWeight: FontWeight.bold)),
        centerTitle: true,
        backgroundColor: Colors.transparent,
        elevation: 0,
      ),
      body: ListView(
        padding: const EdgeInsets.symmetric(horizontal: 20),
        children: [
          const SizedBox(height: 20),
          // Profile Card
          Container(
            padding: const EdgeInsets.all(25),
            decoration: AppTheme.kGlassDecoration,
            child: Column(
              children: [
                Stack(
                  alignment: Alignment.bottomRight,
                  children: [
                    const CircleAvatar(radius: 50, backgroundColor: AppTheme.kSurface, child: Icon(Icons.person, size: 60, color: AppTheme.kPrimaryCyan)),
                    GestureDetector(
                      onTap: _showEditProfile,
                      child: const CircleAvatar(radius: 18, backgroundColor: AppTheme.kPrimaryCyan, child: Icon(Icons.edit, size: 16, color: Colors.black)),
                    ),
                  ],
                ),
                const SizedBox(height: 15),
                Text(_nameController.text.isEmpty ? "OnAlert User" : _nameController.text, style: const TextStyle(fontSize: 22, fontWeight: FontWeight.w900, color: AppTheme.kTextPrimary)),
                Text(user?.email ?? "No Email", style: TextStyle(color: AppTheme.kTextSecondary, fontSize: 13)),
              ],
            ),
          ),

          const SizedBox(height: 20),
          _sectionHeader("EMERGENCY PROFILE"),
          _settingsGroup([
            _buildActionTile("Phone Number", _phoneController.text.isEmpty ? "Not Set — add to receive contact alerts" : _phoneController.text, Icons.phone_outlined, _showEditProfile),
            const Divider(height: 1, color: AppTheme.kBorder),
            _buildActionTile("Blood Type", _bloodTypeController.text.isEmpty ? "Not Set" : _bloodTypeController.text, Icons.water_drop, _showEditProfile),
            const Divider(height: 1, color: AppTheme.kBorder),
            _buildActionTile("Medical Conditions", _medicalController.text.isEmpty ? "None listed" : _medicalController.text, Icons.medical_information, _showEditProfile),
            const Divider(height: 1, color: AppTheme.kBorder),
            _buildActionTile("Vehicle Plate", _vehicleController.text.isEmpty ? "Not Set" : _vehicleController.text, Icons.directions_car, _showEditProfile),
          ]),

          const SizedBox(height: 30),
          _sectionHeader("PREFERENCES"),
          _settingsGroup([
            _buildSwitchTile("Push Notifications", "Receive safety alerts", Icons.notifications_active_rounded, _pushNotifications, (v) => _updateNotification('push_active', v)),
            const Divider(height: 1, color: AppTheme.kBorder),
            _buildSwitchTile("SMS Alerts", "Emergency text notifications", Icons.sms_rounded, _smsAlerts, (v) => _updateNotification('sms_active', v)),
          ]),

          const SizedBox(height: 30),
          _sectionHeader("ACCOUNT & PRIVACY"),
          _settingsGroup([
            _buildActionTile("Permissions Manager", "Location, SMS, notifications", Icons.security_rounded, () {
              Navigator.push(context, MaterialPageRoute(builder: (_) => const PermissionsManagerPage()));
            }),
            const Divider(height: 1, color: AppTheme.kBorder),
            _buildActionTile("Privacy Policy", "How we handle your data", Icons.policy_rounded, () {
              Navigator.push(context, MaterialPageRoute(builder: (_) => const PrivacyPolicyPage()));
            }),
            const Divider(height: 1, color: AppTheme.kBorder),
            _buildActionTile("Safety Tips", "Emergency best practices", Icons.health_and_safety_rounded, () {
              Navigator.push(context, MaterialPageRoute(builder: (_) => const SafetyTipsPage()));
            }),
            const Divider(height: 1, color: AppTheme.kBorder),
            _buildActionTile("Change Password", "Send reset link to email", Icons.lock_reset_rounded, () async {
              if (user?.email != null) {
                await FirebaseAuth.instance.sendPasswordResetEmail(email: user!.email!);
                ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("Password reset link sent! Check your inbox."), backgroundColor: AppTheme.kPrimaryCyan));
              }
            }),
            const Divider(height: 1, color: AppTheme.kBorder),
            _buildActionTile("Export Data", "Download your incident history", Icons.download_rounded, () async {
              await ExportService.exportUserData(widget.userId);
            }),
            const Divider(height: 1, color: AppTheme.kBorder),
            _buildActionTile("Delete Account", "Permanently erase all data", Icons.delete_forever_rounded, _showDeleteAccountDialog),
          ]),

          const SizedBox(height: 30),
          ListTile(
            title: const Center(child: Text("Sign Out", style: TextStyle(color: Colors.redAccent, fontWeight: FontWeight.bold))),
            onTap: () async {
              await FirebaseAuth.instance.signOut();
              if (mounted) Navigator.pushAndRemoveUntil(context, MaterialPageRoute(builder: (_) => const LoginSignupScreen()), (route) => false);
            },
          ),

          // INCREASED BOTTOM PADDING HERE to clear the floating nav bar
          const SizedBox(height: 120),
        ],
      ),
    );
  }

  Widget _sectionHeader(String title) => Padding(
    padding: const EdgeInsets.only(left: 10, bottom: 10),
    child: Text(title, style: TextStyle(color: AppTheme.kPrimaryCyan.withOpacity(0.7), fontWeight: FontWeight.w900, fontSize: 12, letterSpacing: 1.2)),
  );

  Widget _settingsGroup(List<Widget> children) => Container(
    decoration: AppTheme.kGlassDecoration,
    child: Column(children: children),
  );

  Widget _buildSwitchTile(String title, String sub, IconData icon, bool val, Function(bool) onChanged) => SwitchListTile(
    secondary: Icon(icon, color: AppTheme.kPrimaryCyan),
    title: Text(title, style: const TextStyle(color: AppTheme.kTextPrimary, fontWeight: FontWeight.bold)),
    subtitle: Text(sub, style: TextStyle(color: AppTheme.kTextSecondary, fontSize: 12)),
    activeColor: AppTheme.kPrimaryCyan,
    value: val,
    onChanged: onChanged,
  );

  Widget _buildActionTile(String title, String sub, IconData icon, VoidCallback onTap) => ListTile(
    leading: Icon(icon, color: AppTheme.kPrimaryCyan),
    title: Text(title, style: const TextStyle(color: AppTheme.kTextPrimary, fontWeight: FontWeight.bold)),
    subtitle: Text(sub, style: TextStyle(color: AppTheme.kTextSecondary, fontSize: 12)),
    trailing: const Icon(Icons.chevron_right_rounded, color: Colors.blueGrey),
    onTap: onTap,
  );
}

/// ==========================================
/// 👤 CONTACT FORM PAGE
/// ==========================================
class ContactFormPage extends StatefulWidget {
  final String userId;
  const ContactFormPage({super.key, required this.userId});

  @override
  State<ContactFormPage> createState() => _ContactFormPageState();
}

class _ContactFormPageState extends State<ContactFormPage> {
  final nameCtrl = TextEditingController();
  final phoneCtrl = TextEditingController();
  final GlobalKey<ScaffoldState> _scaffoldKey = GlobalKey<ScaffoldState>();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      key: _scaffoldKey,
      backgroundColor: AppTheme.kBackground,
      drawer: Drawer(
        backgroundColor: AppTheme.kBackground,
        child: Column(
          children: [
            _buildDrawerHeader(),
            const SizedBox(height: 10),
            _buildDrawerTile(Icons.dashboard_rounded, "Dashboard", () { Navigator.pop(context); Navigator.pop(context); }),
            _buildDrawerTile(Icons.history_rounded, "Incident Logs", () { Navigator.pop(context); Navigator.push(context, MaterialPageRoute(builder: (_) => const AlertsScreen())); }),
            _buildDrawerTile(Icons.settings_rounded, "Settings", () { Navigator.pop(context); Navigator.push(context, MaterialPageRoute(builder: (_) => SettingsScreen(userId: widget.userId))); }),
            const Spacer(),
            _buildLogoutTile(context),
            const SizedBox(height: 30),
          ],
        ),
      ),
      appBar: AppBrandedAppBar(
        title: 'Add Secure Contact',
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new_rounded, color: AppTheme.kCyanDeep, size: 20),
          onPressed: () {
            if (Navigator.canPop(context)) {
              Navigator.pop(context);
            } else {
              _scaffoldKey.currentState?.openDrawer();
            }
          },
        ),
        actions: const [
          Padding(
            padding: EdgeInsets.only(right: 12),
            child: Icon(Icons.shield_outlined, color: AppTheme.kNavy),
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.fromLTRB(20, 8, 20, 120),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('LIVE PREVIEW', style: TextStyle(color: AppTheme.kTextSecondary, fontWeight: FontWeight.w800, fontSize: 11, letterSpacing: 1.2)),
            const SizedBox(height: 10),
            _buildLivePreview(),
            const SizedBox(height: 24),
            _buildFancyTextField(controller: nameCtrl, label: 'Full Name', icon: Icons.person_outline_rounded, hint: 'Enter contact name', onChanged: (v) => setState(() {})),
            const SizedBox(height: 16),
            _buildFancyTextField(controller: phoneCtrl, label: 'Phone Number', icon: Icons.smartphone_rounded, hint: '+1 (555) 000-0000', keyboardType: TextInputType.phone, onChanged: (v) => setState(() {})),
            const SizedBox(height: 18),
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                color: AppTheme.kSurfaceTint,
                borderRadius: BorderRadius.circular(16),
              ),
              child: const Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Icon(Icons.info_outline_rounded, color: AppTheme.kCyanDeep),
                  SizedBox(width: 10),
                  Expanded(
                    child: Text(
                      'Adding a secure contact allows them to receive your real-time location and alert notifications in case of emergency trigger activations.',
                      style: TextStyle(color: AppTheme.kTextPrimary, fontSize: 13, height: 1.4),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 28),
            _buildSaveButton(),
          ],
        ),
      ),
    );
  }

  Widget _buildDrawerHeader() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.fromLTRB(20, 60, 20, 30),
      decoration: const BoxDecoration(
        gradient: LinearGradient(begin: Alignment.topLeft, end: Alignment.bottomRight, colors: [Color(0xFF1E3A8A), AppTheme.kBackground]),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          CircleAvatar(radius: 35, backgroundColor: AppTheme.kSurface, child: const Icon(Icons.person, color: AppTheme.kPrimaryCyan, size: 40)),
          const SizedBox(height: 15),
          const Text("OnAlert User", style: TextStyle(color: AppTheme.kTextPrimary, fontSize: 20, fontWeight: FontWeight.bold)),
          const Text("Safety Status: Secure", style: TextStyle(color: Colors.blueGrey, fontSize: 13)),
        ],
      ),
    );
  }

  Widget _buildDrawerTile(IconData icon, String title, VoidCallback onTap) => ListTile(
    contentPadding: const EdgeInsets.symmetric(horizontal: 25),
    leading: Icon(icon, color: AppTheme.kTextSecondary),
    title: Text(title, style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w500, color: AppTheme.kTextPrimary)),
    onTap: onTap,
  );

  Widget _buildLogoutTile(BuildContext context) => ListTile(
    contentPadding: const EdgeInsets.symmetric(horizontal: 25),
    leading: const Icon(Icons.logout_rounded, color: Colors.redAccent),
    title: const Text("Sign Out", style: TextStyle(color: Colors.redAccent, fontWeight: FontWeight.bold)),
    onTap: () async { await FirebaseAuth.instance.signOut(); if (context.mounted) Navigator.of(context).pushNamedAndRemoveUntil('/', (route) => false); },
  );

  Widget _buildLivePreview() => AppCard(
    child: Row(
      children: [
        CircleAvatar(
          radius: 30,
          backgroundColor: AppTheme.kCyan,
          child: Text(
            nameCtrl.text.isNotEmpty ? nameCtrl.text[0].toUpperCase() : '?',
            style: const TextStyle(color: AppTheme.kNavy, fontSize: 26, fontWeight: FontWeight.w900),
          ),
        ),
        const SizedBox(width: 16),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                nameCtrl.text.isEmpty ? 'Contact Name' : nameCtrl.text,
                style: const TextStyle(fontSize: 17, fontWeight: FontWeight.w800, color: AppTheme.kTextPrimary),
              ),
              const SizedBox(height: 4),
              Row(
                children: [
                  const Icon(Icons.phone_outlined, size: 14, color: AppTheme.kTextSecondary),
                  const SizedBox(width: 6),
                  Text(
                    phoneCtrl.text.isEmpty ? '+1 (000) 000-0000' : phoneCtrl.text,
                    style: const TextStyle(color: AppTheme.kTextSecondary, fontWeight: FontWeight.w500),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(color: AppTheme.kSurfaceTint, borderRadius: BorderRadius.circular(20)),
                child: const Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(Icons.shield_outlined, size: 12, color: AppTheme.kCyanDeep),
                    SizedBox(width: 4),
                    Text('Secure Protocol Enabled', style: TextStyle(color: AppTheme.kCyanDeep, fontWeight: FontWeight.w700, fontSize: 11)),
                  ],
                ),
              ),
            ],
          ),
        ),
      ],
    ),
  );

  Widget _buildFancyTextField({required TextEditingController controller, required String label, required IconData icon, required String hint, TextInputType keyboardType = TextInputType.text, Function(String)? onChanged}) => Column(
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [
      Text(label, style: const TextStyle(color: AppTheme.kTextPrimary, fontWeight: FontWeight.w800, fontSize: 14)),
      const SizedBox(height: 8),
      TextField(
        controller: controller,
        onChanged: onChanged,
        keyboardType: keyboardType,
        style: const TextStyle(color: AppTheme.kTextPrimary, fontWeight: FontWeight.w600),
        decoration: AppTheme.fieldDecoration(label: '', icon: icon, hint: hint).copyWith(
          labelText: null,
          floatingLabelBehavior: FloatingLabelBehavior.never,
        ),
      ),
    ],
  );

  Widget _buildSaveButton() => AppPrimaryButton(
    label: 'SAVE CONTACT',
    icon: Icons.save_outlined,
    foregroundColor: AppTheme.kNavy,
    onPressed: _saveContact,
  );

  Future<void> _saveContact() async {
    if (nameCtrl.text.isNotEmpty && phoneCtrl.text.isNotEmpty) {
      await FirebaseFirestore.instance.collection('users').doc(widget.userId).collection('contacts').add({'name': nameCtrl.text.trim(), 'number': phoneCtrl.text.trim(), 'timestamp': FieldValue.serverTimestamp()});
      if (mounted) { Navigator.pop(context); ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("Contact Saved"))); }
    }
  }
}

/// ==========================================
/// 🍔 DRAWER COMPONENT
/// ==========================================
class AppDrawer extends StatelessWidget {
  final String userId;
  const AppDrawer({super.key, required this.userId});

  @override
  Widget build(BuildContext context) {
    return Drawer(
      backgroundColor: AppTheme.kBackground,
      child: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [AppTheme.kSurface.withOpacity(0.9), AppTheme.kBackground],
          ),
        ),
        child: Column(
          children: [
            StreamBuilder<DocumentSnapshot>(
              stream: FirebaseFirestore.instance.collection('users').doc(userId).snapshots(),
              builder: (context, snapshot) {
                String name = "OnAlert User";
                if (snapshot.hasData && snapshot.data!.exists) {
                  name = (snapshot.data!.data() as Map<String, dynamic>)['name'] ?? "OnAlert User";
                }
                return Container(
                  width: double.infinity,
                  padding: const EdgeInsets.fromLTRB(20, 60, 20, 20),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Container(
                        padding: const EdgeInsets.all(2),
                        decoration: BoxDecoration(shape: BoxShape.circle, border: Border.all(color: AppTheme.kPrimaryCyan, width: 2)),
                        child: const CircleAvatar(radius: 30, backgroundColor: AppTheme.kSurface, child: Icon(Icons.person, color: AppTheme.kTextPrimary, size: 35)),
                      ),
                      const SizedBox(height: 15),
                      Text(name, style: const TextStyle(color: AppTheme.kTextPrimary, fontSize: 18, fontWeight: FontWeight.bold)),
                      const Text("Status: Active", style: TextStyle(color: AppTheme.kPrimaryCyan, fontSize: 12, fontWeight: FontWeight.bold)),
                    ],
                  ),
                );
              },
            ),
            const Divider(color: AppTheme.kBorder, indent: 20, endIndent: 20, height: 40),
            _buildDrawerTile(Icons.dashboard_rounded, "Dashboard", () {
              Navigator.pop(context);
            }),
            _buildDrawerTile(Icons.history_rounded, "Incident Logs", () {
              Navigator.pop(context);
              Navigator.push(context, MaterialPageRoute(builder: (_) => const AlertsScreen()));
            }),
            _buildDrawerTile(Icons.settings_rounded, "Settings", () {
              Navigator.pop(context);
              Navigator.push(context, MaterialPageRoute(builder: (_) => SettingsScreen(userId: userId)));
            }),
            const Spacer(),
            ListTile(
              leading: const Icon(Icons.logout_rounded, color: Colors.redAccent, size: 20),
              title: const Text("Sign Out", style: TextStyle(color: Colors.redAccent, fontSize: 14, fontWeight: FontWeight.bold)),
              onTap: () async {
                await FirebaseAuth.instance.signOut();
                if(context.mounted) Navigator.pushAndRemoveUntil(context, MaterialPageRoute(builder: (_) => const LoginSignupScreen()), (route) => false);
              },
            ),
            const SizedBox(height: 40),
          ],
        ),
      ),
    );
  }

  Widget _buildDrawerTile(IconData icon, String title, VoidCallback onTap) {
    return ListTile(
      contentPadding: const EdgeInsets.symmetric(horizontal: 25),
      leading: Icon(icon, color: Colors.blueGrey, size: 20),
      title: Text(title, style: const TextStyle(fontSize: 14, color: AppTheme.kTextPrimary, fontWeight: FontWeight.w500)),
      onTap: onTap,
    );
  }
}

/// ==========================================
/// 🔒 PRIVACY POLICY PAGE
/// ==========================================
class PrivacyPolicyPage extends StatelessWidget {
  const PrivacyPolicyPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.kBackground,
      appBar: AppBar(
        title: const Text("Privacy Policy", style: TextStyle(fontWeight: FontWeight.bold, color: AppTheme.kTextPrimary)),
        centerTitle: true,
        elevation: 0,
        backgroundColor: Colors.transparent,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new_rounded, color: AppTheme.kTextPrimary, size: 20),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          children: [
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(color: AppTheme.kPrimaryCyan.withOpacity(0.1), shape: BoxShape.circle),
              child: const Icon(Icons.gavel_rounded, size: 40, color: AppTheme.kPrimaryCyan),
            ),
            const SizedBox(height: 20),
            const Text("Your Safety is Our Priority", style: TextStyle(fontSize: 22, fontWeight: FontWeight.w900, color: AppTheme.kTextPrimary)),
            const SizedBox(height: 10),
            Text("Last Updated: January 2026", style: TextStyle(color: AppTheme.kTextSecondary, fontSize: 13)),
            const SizedBox(height: 30),

            _policyCard("1. Data Collection", "OnAlert collects your location data, contact list, and device sensor data (accelerometer/G-force) to provide real-time crash detection and SOS services.", Icons.location_on_rounded),
            _policyCard("2. Emergency Use", "In the event of a detected emergency, your location and profile data will be shared only with your designated emergency contacts.", Icons.emergency_share_rounded),
            _policyCard("3. Data Encryption", "All personal data is encrypted using industry-standard SSL/TLS protocols and stored securely via Firebase Cloud Services.", Icons.lock_outline_rounded),
            _policyCard("4. Third-Party Services", "We do not sell your personal information. We only use trusted providers like Google Firebase and Twilio to manage authentication and alerts.", Icons.cloud_done_rounded),

            const SizedBox(height: 20),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 10),
              child: Text("By using OnAlert, you agree to the terms listed above. For questions, contact support@onalert.safety",
                  textAlign: TextAlign.center,
                  style: TextStyle(color: AppTheme.kTextSecondary, fontSize: 12, height: 1.5)
              ),
            ),
            const SizedBox(height: 40),
          ],
        ),
      ),
    );
  }

  Widget _policyCard(String title, String content, IconData icon) {
    return Container(
      margin: const EdgeInsets.only(bottom: 20),
      padding: const EdgeInsets.all(20),
      decoration: AppTheme.kGlassDecoration,
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, color: AppTheme.kPrimaryCyan, size: 24),
          const SizedBox(width: 15),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(title, style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: AppTheme.kTextPrimary)),
                const SizedBox(height: 8),
                Text(content, style: TextStyle(fontSize: 14, color: AppTheme.kTextSecondary, height: 1.5)),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

/// ==========================================
/// 💡 SAFETY TIPS PAGE
/// ==========================================
class SafetyTipsPage extends StatelessWidget {
  const SafetyTipsPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.kBackground,
      appBar: AppBar(
        title: const Text("Safety Guide", style: TextStyle(fontWeight: FontWeight.bold, color: AppTheme.kTextPrimary)),
        centerTitle: true,
        elevation: 0,
        backgroundColor: Colors.transparent,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new_rounded, color: AppTheme.kTextPrimary, size: 20),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: ListView(
        padding: const EdgeInsets.all(20),
        children: [
          _buildHeader(),
          const SizedBox(height: 25),
          _sectionLabel("IMMEDIATE ACTIONS"),
          _tipCard("In Case of Accident", "Remain calm. Check yourself for injuries before helping others. If the app hasn't triggered, press the SOS button manually.", Icons.warning_amber_rounded, Colors.orangeAccent),
          _sectionLabel("DRIVING BEST PRACTICES"),
          _tipCard("Phone Placement", "For accurate crash detection, secure your phone in a stable mount. Loose phones may give false readings or become projectiles.", Icons.phonelink_setup_rounded, AppTheme.kPrimaryCyan),
          _tipCard("The 3-Second Rule", "Maintain at least 3 seconds of distance between you and the car in front to allow for emergency braking.", Icons.speed_rounded, AppTheme.kPrimaryCyan),
          _sectionLabel("APP TIPS"),
          _tipCard("Keep Battery Optimized", "Ensure OnAlert has 'Always Allow' location access so it can monitor your safety even when the screen is off.", Icons.battery_charging_full_rounded, Colors.greenAccent),
          const SizedBox(height: 20),
          Center(child: Text("Stay Safe. Stay Alert.", style: TextStyle(color: AppTheme.kTextSecondary, fontStyle: FontStyle.italic))),
          const SizedBox(height: 40),
        ],
      ),
    );
  }

  Widget _buildHeader() {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: LinearGradient(colors: [AppTheme.kPrimaryCyan.withOpacity(0.2), AppTheme.kSurface]),
        borderRadius: BorderRadius.circular(25),
        border: Border.all(color: AppTheme.kPrimaryCyan.withOpacity(0.3)),
      ),
      child: const Row(
        children: [
          Icon(Icons.lightbulb_circle, size: 50, color: AppTheme.kPrimaryCyan),
          SizedBox(width: 15),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text("Safety Knowledge", style: TextStyle(color: AppTheme.kTextPrimary, fontSize: 18, fontWeight: FontWeight.bold)),
                Text("Essential tips for your daily commute", style: TextStyle(color: AppTheme.kTextSecondary, fontSize: 13)),
              ],
            ),
          )
        ],
      ),
    );
  }

  Widget _sectionLabel(String label) {
    return Padding(
        padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 8),
        child: Text(label, style: TextStyle(color: AppTheme.kPrimaryCyan.withOpacity(0.7), fontWeight: FontWeight.bold, fontSize: 12, letterSpacing: 1.2))
    );
  }

  Widget _tipCard(String title, String desc, IconData icon, Color iconColor) {
    return Container(
      margin: const EdgeInsets.only(bottom: 15),
      padding: const EdgeInsets.all(18),
      decoration: AppTheme.kGlassDecoration,
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(color: iconColor.withOpacity(0.1), borderRadius: BorderRadius.circular(12)),
              child: Icon(icon, color: iconColor, size: 24)
          ),
          const SizedBox(width: 15),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(title, style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: AppTheme.kTextPrimary)),
                const SizedBox(height: 5),
                Text(desc, style: TextStyle(fontSize: 14, color: AppTheme.kTextSecondary, height: 1.4)),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

/// ==========================================
/// 🤝 HELP AND SUPPORT PAGE
/// ==========================================
class HelpSupportPage extends StatelessWidget {
  const HelpSupportPage({super.key});

  Future<void> _launchURL(String url) async {
    final Uri uri = Uri.parse(url);
    if (await canLaunchUrl(uri)) {
      await launchUrl(uri);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.kBackground,
      appBar: AppBar(
        title: const Text("Help & Support", style: TextStyle(fontWeight: FontWeight.bold, color: AppTheme.kTextPrimary)),
        centerTitle: true,
        elevation: 0,
        backgroundColor: Colors.transparent,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new_rounded, color: AppTheme.kTextPrimary, size: 20),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: SingleChildScrollView(
          padding: const EdgeInsets.all(20),
          child: Column(
            children: [
              _buildSupportHeader(),
              const SizedBox(height: 30),
              _sectionLabel("FREQUENTLY ASKED QUESTIONS"),
              _buildFAQTile("How does crash detection work?", "OnAlert uses your phone's accelerometer and GPS to detect sudden high G-force impacts associated with vehicle accidents."),
              _buildFAQTile("Is my location always being tracked?", "We only monitor movement data during active trips. Your location is only shared when a crash is detected or SOS is pressed."),
              _buildFAQTile("Can I add international contacts?", "Yes, ensure you include the country code (e.g., +1) so emergency alerts can be delivered correctly."),
              const SizedBox(height: 30),
              _sectionLabel("GET IN TOUCH"),
              _buildContactCard("Email Support", "support@onalert.safety", Icons.mail_outline_rounded, () => _launchURL("mailto:support@onalert.safety")),
              const SizedBox(height: 12),
              _buildContactCard("Emergency Hotline", "1-800-ONALERT", Icons.headset_mic_outlined, () => _launchURL("tel:18006625378")),
              const SizedBox(height: 40),
              Center(child: Text("OnAlert Support Team is available 24/7", style: TextStyle(color: AppTheme.kTextSecondary, fontSize: 12))),
              const SizedBox(height: 20),
            ],
          )
      ),
    );
  }

  Widget _buildSupportHeader() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(25),
      decoration: AppTheme.kGlassDecoration,
      child: Column(
        children: [
          CircleAvatar(radius: 35, backgroundColor: AppTheme.kPrimaryCyan.withOpacity(0.1), child: const Icon(Icons.support_agent_rounded, size: 40, color: AppTheme.kPrimaryCyan)),
          const SizedBox(height: 15),
          const Text("How can we help you?", style: TextStyle(fontSize: 20, fontWeight: FontWeight.w900, color: AppTheme.kTextPrimary)),
          const SizedBox(height: 8),
          Text("Our team is here to ensure your journey is safe.", textAlign: TextAlign.center, style: TextStyle(color: AppTheme.kTextSecondary, fontSize: 14)),
        ],
      ),
    );
  }

  Widget _sectionLabel(String label) {
    return Padding(padding: const EdgeInsets.only(left: 10, bottom: 15), child: Text(label, style: TextStyle(color: AppTheme.kPrimaryCyan.withOpacity(0.7), fontWeight: FontWeight.bold, fontSize: 12, letterSpacing: 1.2)));
  }

  Widget _buildFAQTile(String question, String answer) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: AppTheme.kGlassDecoration,
      child: ExpansionTile(
        iconColor: AppTheme.kPrimaryCyan,
        textColor: AppTheme.kPrimaryCyan,
        shape: const RoundedRectangleBorder(side: BorderSide.none),
        leading: const Icon(Icons.help_outline_rounded, color: AppTheme.kPrimaryCyan, size: 20),
        title: Text(question, style: const TextStyle(color: AppTheme.kTextPrimary, fontWeight: FontWeight.bold, fontSize: 14)),
        children: [
          Padding(padding: const EdgeInsets.fromLTRB(55, 0, 20, 15), child: Text(answer, style: TextStyle(color: AppTheme.kTextSecondary, fontSize: 13, height: 1.5)))
        ],
      ),
    );
  }

  Widget _buildContactCard(String title, String sub, IconData icon, VoidCallback onTap) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(20),
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 18, horizontal: 20),
        decoration: AppTheme.kGlassDecoration,
        child: Row(
          children: [
            Icon(icon, color: AppTheme.kPrimaryCyan),
            const SizedBox(width: 15),
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(title, style: const TextStyle(fontWeight: FontWeight.bold, color: AppTheme.kTextPrimary)),
                Text(sub, style: TextStyle(color: AppTheme.kTextSecondary, fontSize: 12)),
              ],
            ),
            const Spacer(),
            Icon(Icons.arrow_forward_ios_rounded, size: 14, color: AppTheme.kPrimaryCyan.withOpacity(0.5)),
          ],
        ),
      ),
    );
  }
}

/// =======================
/// 🛰️ LIVE HARDWARE MONITOR PAGE
/// =======================
class LiveHardwareMonitor extends StatefulWidget {
  final String userId;
  const LiveHardwareMonitor({super.key, required this.userId});

  @override
  State<LiveHardwareMonitor> createState() => _LiveHardwareMonitorState();
}

class _LiveHardwareMonitorState extends State<LiveHardwareMonitor> {
  final _phoneAccel = PhoneAccelerometerService.instance;
  final _heartbeat = HardwareHeartbeatService.instance;
  AccelerometerReading _accelReading = AccelerometerReading.idle;
  StreamSubscription<AccelerometerReading>? _accelerometerStreamSubscription;
  StreamSubscription<DatabaseEvent>? _heartbeatStreamSubscription;
  Timer? _onlineRefreshTimer;
  Timer? _phoneGpsTimer;
  HardwareHeartbeat _heartbeatState = HardwareHeartbeat.offline;
  DateTime? _lastFirebaseHeartbeatAt;
  double? _phoneLat;
  double? _phoneLng;

  @override
  void initState() {
    super.initState();
    _phoneAccel.addListener();
    _accelerometerStreamSubscription = _phoneAccel.readings.listen((reading) {
      if (mounted) setState(() => _accelReading = reading);
    });
    _heartbeatStreamSubscription =
        _heartbeat.heartbeatStream(widget.userId).listen((event) {
      if (!mounted) return;
      setState(() {
        _lastFirebaseHeartbeatAt = DateTime.now();
        _heartbeatState = _heartbeat.parse(
          event.snapshot.value,
          receivedAt: _lastFirebaseHeartbeatAt,
        );
      });
    });
    _heartbeat.heartbeatRef(widget.userId).keepSynced(true);
    if (DemoConfig.forceSystemOnline) {
      _heartbeatState = HardwareHeartbeat(
        connected: true,
        isOnline: true,
        lastSeenMs: DateTime.now().millisecondsSinceEpoch,
        lat: DemoConfig.islamabadLat,
        lng: DemoConfig.islamabadLng,
        gpsFix: true,
      );
    }
    _onlineRefreshTimer = Timer.periodic(const Duration(seconds: 1), (_) {
      if (mounted && _heartbeatState.connected) setState(() {});
    });
    _refreshPhoneGps();
    _phoneGpsTimer = Timer.periodic(const Duration(seconds: 8), (_) => _refreshPhoneGps());
  }

  Future<void> _refreshPhoneGps() async {
    final phone = await LocationService.getPhoneLocation();
    if (!mounted || phone == null) return;
    setState(() {
      _phoneLat = phone.lat;
      _phoneLng = phone.lng;
    });
  }

  @override
  void dispose() {
    _accelerometerStreamSubscription?.cancel();
    _heartbeatStreamSubscription?.cancel();
    _onlineRefreshTimer?.cancel();
    _phoneGpsTimer?.cancel();
    _phoneAccel.removeListener();
    super.dispose();
  }

  bool get _isSystemOnline => _heartbeat.isCurrentlyOnline(
        connected: _heartbeatState.connected,
        lastSeenMs: _heartbeatState.lastSeenMs,
        lastFirebaseEventAt: _lastFirebaseHeartbeatAt,
      );

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<cf.DocumentSnapshot>(
      stream: cf.FirebaseFirestore.instance.collection('users').doc(widget.userId).snapshots(),
      builder: (context, userSnapshot) {
        if (!userSnapshot.hasData) {
          return const Scaffold(backgroundColor: AppTheme.kBackground, body: Center(child: CircularProgressIndicator(color: AppTheme.kPrimaryCyan)));
        }

        var userData = userSnapshot.data?.data() as Map<String, dynamic>?;
        String pairedSerial = userData?['pairedDevice'] ?? "";

        final isOnline = _isSystemOnline;

        if (pairedSerial.isEmpty && !_heartbeatState.connected && !DemoConfig.forceSystemOnline) {
          return const Scaffold(
            backgroundColor: AppTheme.kBackground,
            body: Center(
              child: Text(
                'Power on ESP32 heartbeat or pair a device.',
                style: TextStyle(color: AppTheme.kTextPrimary),
              ),
            ),
          );
        }

        final deviceRef = pairedSerial.isNotEmpty
            ? AppDatabase.rtdb.ref('devices/$pairedSerial/status')
            : null;
        if (deviceRef != null) {
          deviceRef.keepSynced(true);
        }

        return Scaffold(
          backgroundColor: AppTheme.kBackground,
          appBar: AppBar(
            title: const Text(
              'Live Sensor Diagnostics',
              style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18, color: AppTheme.kTextPrimary),
            ),
            elevation: 0,
            backgroundColor: Colors.transparent,
            centerTitle: true,
          ),
          body: deviceRef == null
              ? _buildDiagnosticsBody(
                  isOnline: isOnline,
                  lat: _resolvedLat(deviceLat: 0, deviceLng: 0),
                  lng: _resolvedLng(deviceLat: 0, deviceLng: 0),
                  firebaseAlert: _heartbeatState.alert,
                )
              : StreamBuilder<rtdb.DatabaseEvent>(
                  stream: deviceRef.onValue,
                  builder: (context, deviceSnapshot) {
                    double deviceLat = 0;
                    double deviceLng = 0;
                    String firebaseAlert = _heartbeatState.alert;

                    if (deviceSnapshot.hasData && deviceSnapshot.data!.snapshot.value != null) {
                      final data = Map<dynamic, dynamic>.from(deviceSnapshot.data!.snapshot.value as Map);
                      deviceLat = double.tryParse(data['lat']?.toString() ?? '') ?? 0;
                      deviceLng = double.tryParse(data['lng']?.toString() ?? '') ?? 0;
                      firebaseAlert = data['alert']?.toString() ?? firebaseAlert;
                    }

                    final resolved = LocationService.resolveDisplayCoordinates(
                      deviceLat: deviceLat,
                      deviceLng: deviceLng,
                      hardwareLat: _heartbeatState.lat,
                      hardwareLng: _heartbeatState.lng,
                      phoneLat: _phoneLat,
                      phoneLng: _phoneLng,
                    );

                    return _buildDiagnosticsBody(
                      isOnline: isOnline,
                      lat: resolved.lat.toStringAsFixed(4),
                      lng: resolved.lng.toStringAsFixed(4),
                      firebaseAlert: firebaseAlert,
                    );
                  },
                ),
        );
      },
    );
  }

  String _resolvedLat({required double deviceLat, required double deviceLng}) {
    return LocationService.resolveDisplayCoordinates(
      deviceLat: deviceLat,
      deviceLng: deviceLng,
      hardwareLat: _heartbeatState.lat,
      hardwareLng: _heartbeatState.lng,
      phoneLat: _phoneLat,
      phoneLng: _phoneLng,
    ).lat.toStringAsFixed(4);
  }

  String _resolvedLng({required double deviceLat, required double deviceLng}) {
    return LocationService.resolveDisplayCoordinates(
      deviceLat: deviceLat,
      deviceLng: deviceLng,
      hardwareLat: _heartbeatState.lat,
      hardwareLng: _heartbeatState.lng,
      phoneLat: _phoneLat,
      phoneLng: _phoneLng,
    ).lng.toStringAsFixed(4);
  }

  Widget _buildDiagnosticsBody({
    required bool isOnline,
    required String lat,
    required String lng,
    required String firebaseAlert,
  }) {
    final x = _accelReading.x.toStringAsFixed(2);
    final y = _accelReading.y.toStringAsFixed(2);
    final z = _accelReading.z.toStringAsFixed(2);
    final gForce = _accelReading.gForce.toStringAsFixed(2);
    final alert = _phoneAccel.resolveAlertStatus(firebaseAlert);
    final espAccident = firebaseAlert.toUpperCase().contains('ACCIDENT');
    final showAccidentUi = _accelReading.localAccidentActive || espAccident;

    return SingleChildScrollView(
      padding: const EdgeInsets.all(20),
      child: Column(
        children: [
          if (showAccidentUi) ...[
            Container(
              width: double.infinity,
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
              margin: const EdgeInsets.only(bottom: 12),
              decoration: BoxDecoration(
                color: AppTheme.kNavy,
                borderRadius: BorderRadius.circular(14),
                border: Border.all(color: AppTheme.kCyan, width: 1.5),
              ),
              child: Row(
                children: [
                  const Icon(Icons.sms_rounded, color: AppTheme.kCyan),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Text(
                      DemoConfig.smsSimulationMessage,
                      style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w800, fontSize: 13),
                    ),
                  ),
                ],
              ),
            ),
            Container(
              width: double.infinity,
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
              margin: const EdgeInsets.only(bottom: 12),
              decoration: BoxDecoration(
                color: AppTheme.kAlertRed,
                borderRadius: BorderRadius.circular(14),
              ),
              child: Row(
                children: [
                  const Icon(Icons.warning_amber_rounded, color: Colors.white),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Text(
                      alert,
                      style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w900),
                    ),
                  ),
                ],
              ),
            ),
          ],
          Container(
            width: double.infinity,
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
            margin: const EdgeInsets.only(bottom: 16),
            decoration: BoxDecoration(
              color: isOnline ? AppTheme.kSuccessSoft : const Color(0xFFFEE2E2),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Text(
              isOnline ? '● ESP32 HEARTBEAT ONLINE' : '● ESP32 HEARTBEAT OFFLINE',
              style: TextStyle(
                color: isOnline ? const Color(0xFF166534) : AppTheme.kEmergencyRed,
                fontWeight: FontWeight.w800,
              ),
            ),
          ),
          _buildMetricCard(
            "Real-time Motion (phone m/s²)",
            Icons.speed_rounded,
            _accelReading.localAccidentActive ? AppTheme.kAlertRed : AppTheme.kPrimaryCyan,
            [
              "X-Axis Accel: $x",
              "Y-Axis Accel: $y",
              "Z-Axis Accel: $z",
              "Total G-Force: ${gForce}G",
            ],
            isLive: true,
          ),
          const SizedBox(height: 20),
          _buildMetricCard(
            "Satellite Telemetry (Firebase GPS)",
            Icons.location_on,
            alert == 'ACCIDENT_DETECTED' ? AppTheme.kAlertRed : Colors.greenAccent,
            ["Latitude: $lat", "Longitude: $lng", "System Status: $alert"],
            isLive: false,
          ),
          const SizedBox(height: 30),
          const Text(
            "Wizard of Oz demo: phone drives accel; ESP32 heartbeat drives Online.",
            style: TextStyle(color: Colors.blueGrey, fontSize: 11),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  Widget _buildMetricCard(String title, IconData icon, Color color, List<String> stats, {required bool isLive}) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(22),
      decoration: AppTheme.kGlassDecoration.copyWith(
          border: Border.all(color: color.withOpacity(0.3))
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Row(children: [
                Icon(icon, color: color, size: 24),
                const SizedBox(width: 12),
                Text(title, style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 16, color: AppTheme.kTextPrimary))
              ]),
              if (isLive) Container(width: 10, height: 10, decoration: BoxDecoration(color: color, shape: BoxShape.circle, boxShadow: [BoxShadow(color: color, blurRadius: 8)]))
            ],
          ),
          const Divider(height: 35, thickness: 1, color: Colors.white10),
          ...stats.map((s) => Padding(
            padding: const EdgeInsets.symmetric(vertical: 6.0),
            child: Text(s, style: const TextStyle(fontSize: 15, fontFamily: 'monospace', fontWeight: FontWeight.w600, letterSpacing: 0.5, color: AppTheme.kTextSecondary)),
          )).toList(),
        ],
      ),
    );
  }
}

/// ==========================================
/// 📱 DEVICE MANAGER PAGE
/// ==========================================
class DeviceManagerPage extends StatefulWidget {
  final String userId;
  const DeviceManagerPage({super.key, required this.userId});

  @override
  State<DeviceManagerPage> createState() => _DeviceManagerPageState();
}

class _DeviceManagerPageState extends State<DeviceManagerPage> {
  bool _isCheckingUpdate = false;

  Future<void> _checkHeartbeatFirmware() async {
    setState(() => _isCheckingUpdate = true);
    try {
      final snap = await AppDatabase.rtdb.ref('users/${widget.userId}/hardware').get();
      String? version;
      if (snap.exists && snap.value != null) {
        final data = Map<dynamic, dynamic>.from(snap.value as Map);
        version = data['firmware_version']?.toString();
      }
      if (!mounted) return;
      showDialog(
        context: context,
        builder: (ctx) => AlertDialog(
          backgroundColor: AppTheme.kSurface,
          title: const Text('ESP32 Heartbeat', style: TextStyle(color: AppTheme.kTextPrimary)),
          content: Text(
            version != null
                ? 'Heartbeat firmware: v$version\nPair a device serial for full OTA command channel.'
                : 'ESP32 heartbeat is active. Pair via Device Manager to enable OTA updates on devices/{serial}.',
            style: const TextStyle(color: AppTheme.kTextSecondary),
          ),
          actions: [
            TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('OK')),
          ],
        ),
      );
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(e.toString())));
      }
    } finally {
      if (mounted) setState(() => _isCheckingUpdate = false);
    }
  }

  Future<void> _checkFirmware(String serial) async {
    setState(() => _isCheckingUpdate = true);
    try {
      final current = await DeviceService.getFirmwareVersion(serial);
      final updateAvailable = await DeviceService.isUpdateAvailable(serial);
      if (!mounted) return;
      if (updateAvailable) {
        showDialog(
          context: context,
          builder: (ctx) => AlertDialog(
            backgroundColor: AppTheme.kSurface,
            title: const Text('Update Available', style: TextStyle(color: AppTheme.kTextPrimary)),
            content: Text(
              'Device: v${current ?? "?"}\nLatest: v${DeviceService.latestFirmwareVersion}',
              style: const TextStyle(color: AppTheme.kTextSecondary),
            ),
            actions: [
              TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('LATER')),
              ElevatedButton(
                onPressed: () async {
                  await DeviceService.triggerOtaUpdate(serial);
                  if (ctx.mounted) Navigator.pop(ctx);
                },
                child: const Text('UPDATE NOW'),
              ),
            ],
          ),
        );
      } else {
        _showUpToDateDialog(current);
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(e.toString())));
      }
    } finally {
      if (mounted) setState(() => _isCheckingUpdate = false);
    }
  }

  void _showUpToDateDialog(String? version) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: AppTheme.kSurface,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20), side: BorderSide(color: Colors.white.withOpacity(0.1))),
        title: const Column(
          children: [
            Icon(Icons.check_circle_outline, color: Colors.greenAccent, size: 60),
            SizedBox(height: 15),
            Text('System Up to Date', style: TextStyle(color: AppTheme.kTextPrimary, fontWeight: FontWeight.bold)),
          ],
        ),
        content: Text('OnAlert Firmware v${version ?? DeviceService.latestFirmwareVersion} is the latest version.', textAlign: TextAlign.center, style: const TextStyle(color: Colors.blueGrey)),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text('DISMISS', style: TextStyle(fontWeight: FontWeight.bold))),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.kBackground,
      appBar: AppBar(
        title: const Text("Device Manager", style: TextStyle(fontWeight: FontWeight.bold, color: AppTheme.kTextPrimary)),
        centerTitle: true,
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(icon: const Icon(Icons.arrow_back_ios_new_rounded, color: AppTheme.kTextPrimary), onPressed: () => Navigator.pop(context)),
      ),
      body: StreamBuilder<DocumentSnapshot>(
        stream: FirebaseFirestore.instance.collection('users').doc(widget.userId).snapshots(),
        builder: (context, snapshot) {
          if (!snapshot.hasData) return const Center(child: CircularProgressIndicator(color: AppTheme.kPrimaryCyan));

          var userData = snapshot.data?.data() as Map<String, dynamic>?;
          String serial = userData?['pairedDevice'] ?? "";
          bool isPaired = serial.isNotEmpty;

          return ListView(
            padding: const EdgeInsets.all(20),
            children: [
              _buildInfoCard(
                title: isPaired ? "Device Connected" : "No Device Paired",
                subtitle: isPaired ? "Serial: $serial" : "Pair your ESP32 to begin",
                icon: isPaired ? Icons.bluetooth_connected : Icons.bluetooth_disabled,
                color: isPaired ? Colors.greenAccent : Colors.blueGrey,
              ),
              const SizedBox(height: 25),

              _sectionHeader("HARDWARE CONTROL"),
              _actionTile(
                title: isPaired ? 'Unpair Device' : 'Pair New Device',
                icon: isPaired ? Icons.link_off : Icons.add_link,
                onTap: () => isPaired ? DeviceService.removeDevice(widget.userId) : _showPairingDialog(),
              ),
              if (!isPaired)
                _actionTile(
                  title: 'Scan Device QR',
                  subtitle: 'Discover and pair via QR code',
                  icon: Icons.qr_code_scanner,
                  onTap: () => Navigator.push(context, MaterialPageRoute(
                    builder: (_) => DeviceQrScannerPage(userId: widget.userId),
                  )),
                ),
              if (!isPaired)
                _actionTile(
                  title: 'Discover Nearby',
                  subtitle: 'Bluetooth scan for ESP32 hardware',
                  icon: Icons.bluetooth_searching,
                  onTap: () => Navigator.push(context, MaterialPageRoute(
                    builder: (_) => NearbyDeviceScanPage(userId: widget.userId),
                  )),
                ),
              _actionTile(
                title: 'Firmware Update',
                subtitle: isPaired ? 'Check for hardware patches' : 'Check heartbeat firmware / pair for OTA',
                icon: Icons.system_update_alt_rounded,
                trailing: _isCheckingUpdate ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(strokeWidth: 2, color: AppTheme.kPrimaryCyan)) : null,
                onTap: _isCheckingUpdate
                    ? null
                    : () => isPaired ? _checkFirmware(serial) : _checkHeartbeatFirmware(),
              ),
              _actionTile(
                title: 'System Diagnostics',
                subtitle: 'Run tests, view logs, simulate SOS',
                icon: Icons.bug_report_rounded,
                onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => SystemTestingPage(userId: widget.userId))),
              ),

              const SizedBox(height: 25),
              _sectionHeader("HARDWARE SPECIFICATIONS"),
              _buildSpecRow("Model", "OnAlert ESP-V1"),
              _buildSpecRow("Processor", "Dual-Core ESP32"),
              _buildSpecRow("Sensors", "MPU6050, GPS"),
            ],
          );
        },
      ),
    );
  }

  Widget _buildInfoCard({required String title, required String subtitle, required IconData icon, required Color color}) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: AppTheme.kGlassDecoration.copyWith(border: Border.all(color: color.withOpacity(0.3))),
      child: Row(
        children: [
          CircleAvatar(radius: 30, backgroundColor: color.withOpacity(0.1), child: Icon(icon, color: color, size: 30)),
          const SizedBox(width: 20),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(title, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 18, color: AppTheme.kTextPrimary)),
                Text(subtitle, style: const TextStyle(color: Colors.blueGrey, fontSize: 13)),
              ],
            ),
          )
        ],
      ),
    );
  }

  Widget _sectionHeader(String text) => Padding(
    padding: const EdgeInsets.only(left: 10, bottom: 10),
    child: Text(text, style: TextStyle(color: AppTheme.kPrimaryCyan.withOpacity(0.7), fontWeight: FontWeight.bold, fontSize: 12, letterSpacing: 1.1)),
  );

  Widget _actionTile({required String title, String? subtitle, required IconData icon, Widget? trailing, VoidCallback? onTap}) {
    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      decoration: AppTheme.kGlassDecoration,
      child: ListTile(
        leading: Icon(icon, color: AppTheme.kPrimaryCyan),
        title: Text(title, style: const TextStyle(fontWeight: FontWeight.w600, color: AppTheme.kTextPrimary)),
        subtitle: subtitle != null ? Text(subtitle, style: const TextStyle(color: Colors.blueGrey)) : null,
        trailing: trailing ?? const Icon(Icons.chevron_right, color: Colors.blueGrey),
        onTap: onTap,
      ),
    );
  }

  Widget _buildSpecRow(String label, String value) => Padding(
    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
    child: Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(label, style: const TextStyle(color: Colors.blueGrey)),
        Text(value, style: const TextStyle(fontWeight: FontWeight.bold, color: AppTheme.kTextPrimary)),
      ],
    ),
  );

  void _showPairingDialog() {
    final sCtrl = TextEditingController();
    final pCtrl = TextEditingController();
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: AppTheme.kSurface,
        title: const Text("Pair Device", style: TextStyle(color: AppTheme.kTextPrimary)),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(controller: sCtrl, style: const TextStyle(color: AppTheme.kTextPrimary), decoration: const InputDecoration(labelText: "Serial Number", labelStyle: TextStyle(color: Colors.blueGrey))),
            TextField(controller: pCtrl, style: const TextStyle(color: AppTheme.kTextPrimary), decoration: const InputDecoration(labelText: "PIN", labelStyle: TextStyle(color: Colors.blueGrey)), keyboardType: TextInputType.number),
          ],
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text("CANCEL")),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: AppTheme.kPrimaryCyan),
            onPressed: () async {
              try {
                await DeviceService.pairDevice(sCtrl.text.trim(), pCtrl.text.trim(), widget.userId);
                if (mounted) Navigator.pop(context);
              } catch (e) { if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(e.toString()))); }
            },
            child: const Text("PAIR", style: TextStyle(color: Colors.black, fontWeight: FontWeight.bold)),
          ),
        ],
      ),
    );
  }
}

/// ==========================================
/// 🎥 DETAILED VIDEO & HARDWARE TUTORIAL PAGE
/// ==========================================
class VideoTutorialPage extends StatefulWidget {
  const VideoTutorialPage({super.key});

  @override
  State<VideoTutorialPage> createState() => _VideoTutorialPageState();
}

class _VideoTutorialPageState extends State<VideoTutorialPage> {
  late VideoPlayerController _videoPlayerController;
  ChewieController? _chewieController;
  bool _isError = false;

  @override
  void initState() {
    super.initState();
    _initializeVideo();
  }

  void _initializeVideo() async {
    try {
      _videoPlayerController = VideoPlayerController.asset("assets/videos/tut1.mp4");
      await _videoPlayerController.initialize();

      _chewieController = ChewieController(
        videoPlayerController: _videoPlayerController,
        autoPlay: false,
        looping: false,
        aspectRatio: _videoPlayerController.value.aspectRatio,
        showControls: true,
        allowFullScreen: true,
        allowPlaybackSpeedChanging: true,
        // The skip buttons (10s) are built-in for MaterialControls automatically.
        materialProgressColors: ChewieProgressColors(
          playedColor: AppTheme.kPrimaryCyan,
          handleColor: AppTheme.kPrimaryCyan,
          backgroundColor: Colors.blueGrey,
          bufferedColor: Colors.blueGrey.shade800,
        ),
        placeholder: Container(color: AppTheme.kSurface),
      );
      setState(() {});
    } catch (e) {
      debugPrint("Video Load Error: $e");
      if (mounted) setState(() => _isError = true);
    }
  }

  @override
  void dispose() {
    _videoPlayerController.dispose();
    _chewieController?.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.kBackground,
      appBar: AppBar(
        title: const Text("System Architecture", style: TextStyle(fontWeight: FontWeight.w900, letterSpacing: 0.5, color: AppTheme.kTextPrimary)),
        centerTitle: true,
        elevation: 0,
        backgroundColor: Colors.transparent,
      ),
      body: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              padding: const EdgeInsets.symmetric(vertical: 20),
              decoration: BoxDecoration(
                color: AppTheme.kSurface.withOpacity(0.5),
                borderRadius: const BorderRadius.only(bottomLeft: Radius.circular(30), bottomRight: Radius.circular(30)),
              ),
              child: _isError ? _buildErrorUI() : _buildVideoPlayer(),
            ),
            const SizedBox(height: 25),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text("HARDWARE COMPONENTS", style: TextStyle(color: AppTheme.kPrimaryCyan.withOpacity(0.7), fontWeight: FontWeight.bold, fontSize: 12, letterSpacing: 1.5)),
                  const SizedBox(height: 15),
                  _buildHardwareCard("ESP32 Microcontroller", "The Central Brain", Icons.memory_rounded, Colors.blueGrey, "Processes all sensor data in real-time. It handles the Wi-Fi/Bluetooth connections to sync data continuously to the Firebase Realtime Database with minimal latency."),
                  _buildHardwareCard("MPU6050 Sensor", "Crash Detection Axis", Icons.speed_rounded, Colors.orangeAccent, "A 6-axis motion tracking device. It constantly monitors X, Y, and Z-axis G-forces. If a sudden deceleration spike occurs (impact), it triggers the emergency protocol."),
                  _buildHardwareCard("GPS NEO-6M Module", "Satellite Telemetry", Icons.satellite_alt_rounded, AppTheme.kPrimaryCyan, "Acquires raw NMEA satellite data to pinpoint your exact latitude and longitude. Essential for generating the Google Maps emergency link."),
                  _buildHardwareCard("GSM SIM800L Module", "Hardware Fallback SMS", Icons.cell_tower_rounded, Colors.greenAccent, "Acts as a safety net. If the smartphone app is killed or loses 4G connection, the ESP32 uses this module to directly SMS contacts via cellular towers."),
                  const SizedBox(height: 120),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildVideoPlayer() {
    return Column(
      children: [
        Container(
          margin: const EdgeInsets.symmetric(horizontal: 20),
          height: 160, // Fixed height as requested
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(20),
            border: Border.all(color: AppTheme.kPrimaryCyan.withOpacity(0.3)),
          ),
          clipBehavior: Clip.antiAlias,
          child: _chewieController != null && _chewieController!.videoPlayerController.value.isInitialized
              ? Chewie(controller: _chewieController!)
              : const Center(child: CircularProgressIndicator(color: AppTheme.kPrimaryCyan)),
        ),
        const SizedBox(height: 15),
        const Text("Watch: Initial Hardware Setup", style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14, color: AppTheme.kTextPrimary)),
      ],
    );
  }

  Widget _buildErrorUI() {
    return Padding(
      padding: const EdgeInsets.all(30),
      child: Column(
        children: [
          const Icon(Icons.error_outline, size: 40, color: Colors.redAccent),
          const SizedBox(height: 15),
          const Text("Could not load tutorial video", style: TextStyle(color: AppTheme.kTextPrimary, fontWeight: FontWeight.bold)),
          TextButton(onPressed: _initializeVideo, child: const Text("Retry Connection", style: TextStyle(color: AppTheme.kPrimaryCyan))),
        ],
      ),
    );
  }

  Widget _buildHardwareCard(String title, String subtitle, IconData icon, Color color, String description) {
    return Container(
      margin: const EdgeInsets.only(bottom: 15),
      decoration: AppTheme.kGlassDecoration,
      child: Theme(
        data: Theme.of(context).copyWith(dividerColor: Colors.transparent),
        child: ExpansionTile(
          tilePadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 5),
          leading: Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(color: color.withOpacity(0.1), borderRadius: BorderRadius.circular(12)),
            child: Icon(icon, color: color, size: 24),
          ),
          title: Text(title, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15, color: AppTheme.kTextPrimary)),
          subtitle: Text(subtitle, style: TextStyle(color: AppTheme.kTextSecondary, fontSize: 12)),
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 0, 20, 20),
              child: Text(description, style: TextStyle(color: AppTheme.kTextSecondary, fontSize: 13, height: 1.5)),
            )
          ],
        ),
      ),
    );
  }
}

/// ==========================================
/// 🚀 MODULE: ONBOARDING & TUTORIAL
/// ==========================================
class OnboardingScreen extends StatefulWidget {
  final String uid;
  const OnboardingScreen({super.key, required this.uid});

  @override
  State<OnboardingScreen> createState() => _OnboardingScreenState();
}

class _OnboardingScreenState extends State<OnboardingScreen> {
  final PageController _pageController = PageController();
  int _currentPage = 0;

  final Color primaryBlue = AppTheme.kCyan;
  final Color darkBlue = AppTheme.kNavy;

  void _nextPage() {
    if (_currentPage < 2) {
      _pageController.nextPage(duration: const Duration(milliseconds: 300), curve: Curves.easeInOut);
    } else {
      Navigator.pushReplacement(context, MaterialPageRoute(builder: (_) => MainAppScreen(uid: widget.uid)));
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.kBackground,
      body: SafeArea(
        child: Column(
          children: [
            Expanded(
              child: PageView(
                controller: _pageController,
                onPageChanged: (index) => setState(() => _currentPage = index),
                children: [
                  _buildOnboardingPage(
                    icon: Icons.sensors_rounded,
                    title: "Smart Crash Detection",
                    description: "OnAlert uses dedicated ESP32 hardware to monitor G-force impacts in real-time, instantly detecting accidents.",
                  ),
                  _buildOnboardingPage(
                      icon: Icons.security_rounded,
                      title: "Grant Permissions",
                      description: "To keep you safe, we need 'Always On' Location access and SMS permissions to notify your contacts.",
                      actionButton: ElevatedButton.icon(
                        style: ElevatedButton.styleFrom(backgroundColor: darkBlue, foregroundColor: Colors.white),
                        onPressed: () async {
                          final results = await PermissionService.requestAll();
                          if (mounted) {
                            ScaffoldMessenger.of(context).showSnackBar(SnackBar(
                              content: Text(
                                results.values.every((v) => v)
                                    ? 'All permissions granted'
                                    : 'Some permissions were denied. Manage them in Settings.',
                              ),
                            ));
                          }
                        },
                        icon: const Icon(Icons.check_circle_outline),
                        label: const Text("ALLOW PERMISSIONS"),
                      )
                  ),
                  _buildOnboardingPage(
                      icon: Icons.person_add_alt_1_rounded,
                      title: "Security Circle",
                      description: "Don't ride alone. Add your first emergency contact right now so they are notified if you need help.",
                      actionButton: ElevatedButton.icon(
                        style: ElevatedButton.styleFrom(backgroundColor: primaryBlue, foregroundColor: Colors.white),
                        onPressed: () => Navigator.push(context, MaterialPageRoute(builder: (_) => ContactFormPage(userId: widget.uid))),
                        icon: const Icon(Icons.add),
                        label: const Text("ADD EMERGENCY CONTACT"),
                      )
                  ),
                ],
              ),
            ),
            Padding(
              padding: const EdgeInsets.all(30.0),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Row(
                    children: List.generate(3, (index) => AnimatedContainer(
                      duration: const Duration(milliseconds: 300),
                      margin: const EdgeInsets.only(right: 8),
                      height: 10,
                      width: _currentPage == index ? 25 : 10,
                      decoration: BoxDecoration(
                          color: _currentPage == index ? primaryBlue : Colors.grey.shade300,
                          borderRadius: BorderRadius.circular(10)
                      ),
                    )),
                  ),
                  FloatingActionButton(
                    backgroundColor: darkBlue,
                    onPressed: _nextPage,
                    child: Icon(_currentPage == 2 ? Icons.done : Icons.arrow_forward_ios, color: Colors.white),
                  )
                ],
              ),
            )
          ],
        ),
      ),
    );
  }

  Widget _buildOnboardingPage({required IconData icon, required String title, required String description, Widget? actionButton}) {
    return Padding(
      padding: const EdgeInsets.all(40.0),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            padding: const EdgeInsets.all(30),
            decoration: BoxDecoration(color: primaryBlue.withOpacity(0.1), shape: BoxShape.circle),
            child: Icon(icon, size: 80, color: primaryBlue),
          ),
          const SizedBox(height: 40),
          Text(title, style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold, color: darkBlue), textAlign: TextAlign.center),
          const SizedBox(height: 15),
          Text(description, style: const TextStyle(fontSize: 16, color: Colors.grey, height: 1.5), textAlign: TextAlign.center),
          const SizedBox(height: 30),
          if (actionButton != null) actionButton,
        ],
      ),
    );
  }
}

/// ==========================================
/// 🔐 MODULE: PERMISSIONS MANAGER
/// ==========================================
class PermissionsManagerPage extends StatefulWidget {
  const PermissionsManagerPage({super.key});

  @override
  State<PermissionsManagerPage> createState() => _PermissionsManagerPageState();
}

class _PermissionsManagerPageState extends State<PermissionsManagerPage> {
  Map<OnAlertPermission, bool> _status = {};

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    final s = await PermissionService.statusAll();
    setState(() => _status = s);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.kBackground,
      appBar: AppBar(
        title: const Text("Permissions Manager", style: TextStyle(fontWeight: FontWeight.bold, color: AppTheme.kTextPrimary)),
        centerTitle: true,
        elevation: 0,
        backgroundColor: Colors.transparent,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new_rounded, color: AppTheme.kTextPrimary, size: 20),
          onPressed: () => Navigator.pop(context),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.settings, color: AppTheme.kPrimaryCyan),
            onPressed: PermissionService.openSettings,
          ),
        ],
      ),
      body: ListView(
        padding: const EdgeInsets.all(20),
        children: [
          const Padding(
            padding: EdgeInsets.symmetric(horizontal: 10),
            child: Text("Manage how OnAlert interacts with your device hardware.",
                style: TextStyle(color: Colors.blueGrey, fontSize: 14)),
          ),
          const SizedBox(height: 20),
          Container(
            decoration: AppTheme.kGlassDecoration,
            child: Column(
              children: [
                _buildPermissionTile(
                  icon: Icons.location_on_rounded,
                  title: "Background Location",
                  subtitle: "Required for crash mapping.",
                  permission: OnAlertPermission.location,
                ),
                const Divider(height: 1, color: AppTheme.kBorder),
                _buildPermissionTile(
                  icon: Icons.sms_rounded,
                  title: "Send SMS",
                  subtitle: "Required to notify contacts.",
                  permission: OnAlertPermission.sms,
                ),
                const Divider(height: 1, color: AppTheme.kBorder),
                _buildPermissionTile(
                  icon: Icons.notifications_active,
                  title: "Push Notifications",
                  subtitle: "Emergency alert delivery.",
                  permission: OnAlertPermission.notification,
                ),
              ],
            ),
          )
        ],
      ),
    );
  }

  Widget _buildPermissionTile({
    required IconData icon,
    required String title,
    required String subtitle,
    required OnAlertPermission permission,
  }) {
    final granted = _status[permission] ?? false;
    return SwitchListTile(
      secondary: Icon(icon, color: AppTheme.kPrimaryCyan),
      title: Text(title, style: const TextStyle(fontWeight: FontWeight.bold, color: AppTheme.kTextPrimary)),
      subtitle: Text(subtitle, style: TextStyle(color: AppTheme.kTextSecondary, fontSize: 12)),
      value: granted,
      activeColor: AppTheme.kPrimaryCyan,
      onChanged: (_) async {
        await PermissionService.request(permission);
        await _load();
      },
    );
  }
}

/// ==========================================
/// 🛠️ MODULE: SYSTEM TESTING
/// ==========================================
class SystemTestingPage extends StatefulWidget {
  final String userId;
  const SystemTestingPage({super.key, required this.userId});

  @override
  State<SystemTestingPage> createState() => _SystemTestingPageState();
}

class _SystemTestingPageState extends State<SystemTestingPage> {
  bool _isTesting = false;

  void _runDiagnostic() async {
    setState(() => _isTesting = true);
    final results = await DiagnosticService.runFullDiagnostic(widget.userId);
    setState(() => _isTesting = false);

    if (mounted) {
      showDialog(
          context: context,
          builder: (_) => AlertDialog(
            backgroundColor: AppTheme.kSurface,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20), side: BorderSide(color: Colors.white.withOpacity(0.1))),
            title: Row(children: [
              Icon(
                results.every((r) => r.passed) ? Icons.check_circle : Icons.warning,
                color: results.every((r) => r.passed) ? Colors.greenAccent : Colors.orangeAccent,
              ),
              const SizedBox(width: 10),
              const Text('Diagnostic Results', style: TextStyle(color: AppTheme.kTextPrimary)),
            ]),
            content: SingleChildScrollView(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: results
                    .map((r) => Padding(
                          padding: const EdgeInsets.symmetric(vertical: 4),
                          child: Text('${r.passed ? "✓" : "✗"} ${r.label}: ${r.detail}',
                              style: const TextStyle(color: AppTheme.kTextSecondary)),
                        ))
                    .toList(),
              ),
            ),
            actions: [TextButton(onPressed: () => Navigator.pop(context), child: const Text('CLOSE', style: TextStyle(color: AppTheme.kPrimaryCyan)))],
          )
      );
    }
  }

  Future<void> _signalTest() async {
    final doc = await FirebaseFirestore.instance.collection('users').doc(widget.userId).get();
    final serial = doc.data()?['pairedDevice']?.toString() ?? '';
    try {
      final int ms;
      final String label;
      if (serial.isNotEmpty) {
        ms = await DeviceService.measureSignalLatency(serial);
        label = 'Device RTDB ping';
      } else {
        final start = DateTime.now();
        await AppDatabase.rtdb.ref('users/${widget.userId}/hardware').get();
        ms = DateTime.now().difference(start).inMilliseconds;
        label = 'ESP32 heartbeat path';
      }
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('$label latency: ${ms}ms'),
            backgroundColor: ms < 5000 ? Colors.green : Colors.orange,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Signal test failed: $e')));
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.kBackground,
      appBar: AppBar(
        title: const Text("System Testing", style: TextStyle(fontWeight: FontWeight.bold, color: AppTheme.kTextPrimary)),
        centerTitle: true,
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(icon: const Icon(Icons.arrow_back_ios_new_rounded, color: AppTheme.kTextPrimary), onPressed: () => Navigator.pop(context)),
      ),
      body: ListView(
        padding: const EdgeInsets.all(20),
        children: [
          _buildTestCard(
              title: "Simulate SOS Alert",
              subtitle: "Test the red overlay screen without sending SMS.",
              icon: Icons.warning_amber_rounded,
              color: Colors.redAccent,
              onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => FullScreenEmergencyAlert(
                time: DateTime.now(),
                location: "SIMULATED LOCATION",
              )))
          ),
          _buildTestCard(
            title: "Run Full Diagnostic",
            subtitle: "Check sensors, database linkage, and app state.",
            icon: Icons.memory_rounded,
            color: AppTheme.kPrimaryCyan,
            trailing: _isTesting ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(strokeWidth: 2, color: AppTheme.kPrimaryCyan)) : null,
            onTap: _isTesting ? null : _runDiagnostic,
          ),
          _buildTestCard(
            title: "Open Log Viewer",
            subtitle: "View raw RTDB payloads from ESP32.",
            icon: Icons.data_object_rounded,
            color: Colors.orangeAccent,
            onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => LogViewerPage(userId: widget.userId))),
          ),
          _buildTestCard(
              title: "Hardware Signal Test",
              subtitle: "Ping paired device or ESP32 heartbeat path.",
              icon: Icons.wifi_tethering,
              color: Colors.greenAccent,
              onTap: _signalTest,
          ),
        ],
      ),
    );
  }

  Widget _buildTestCard({required String title, required String subtitle, required IconData icon, required Color color, Widget? trailing, VoidCallback? onTap}) {
    return Container(
      margin: const EdgeInsets.only(bottom: 15),
      decoration: AppTheme.kGlassDecoration,
      child: ListTile(
        contentPadding: const EdgeInsets.all(15),
        leading: Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(color: color.withOpacity(0.1), borderRadius: BorderRadius.circular(12)),
          child: Icon(icon, color: color),
        ),
        title: Text(title, style: const TextStyle(fontWeight: FontWeight.bold, color: AppTheme.kTextPrimary)),
        subtitle: Text(subtitle, style: TextStyle(color: AppTheme.kTextSecondary, fontSize: 12)),
        trailing: trailing ?? const Icon(Icons.chevron_right, size: 20, color: Colors.blueGrey),
        onTap: onTap,
      ),
    );
  }
}