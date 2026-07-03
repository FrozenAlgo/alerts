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
import 'package:google_sign_in/google_sign_in.dart';
import 'package:chewie/chewie.dart';
import 'package:wakelock_plus/wakelock_plus.dart';

import '../theme/app_theme.dart';
import '../services/emergency_alert_service.dart';
import '../services/device_service.dart';
import '../services/export_service.dart';
import '../services/diagnostic_service.dart';
import '../services/fcm_service.dart';
import '../services/permission_service.dart';
import '../services/location_service.dart';
import '../screens/full_screen_emergency_alert.dart';
import '../screens/map_screen.dart';
import '../screens/device_qr_scanner_page.dart';
import '../screens/log_viewer_page.dart';
import '../widgets/notification_bell_button.dart';

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
      backgroundColor: kDarkSlate, // Applied Dark Slate Base
      body: Stack(
        children: [
          // Cyber-Glass Radial Gradient Background
          Container(
            decoration: const BoxDecoration(
              gradient: RadialGradient(
                colors: [Color(0xFF1E3A8A), kDarkSlate],
                radius: 1.5,
              ),
            ),
          ),
          _controller.value.isInitialized
              ? SizedBox.expand(
            child: FittedBox(
              fit: BoxFit.cover,
              child: SizedBox(
                width: _controller.value.size.width,
                height: _controller.value.size.height,
                child: VideoPlayer(_controller),
              ),
            ),
          )
              : const Center(child: CircularProgressIndicator(color: kPrimaryCyan)), // Cyan Loader

          Center(
            child: AnimatedOpacity(
              opacity: _showText ? 1.0 : 0.0,
              duration: const Duration(seconds: 2),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Text(
                    "ON ALERT",
                    style: TextStyle(
                        fontSize: 48,
                        fontWeight: FontWeight.bold,
                        color: kPrimaryCyan, // Cyan Neon Text
                        letterSpacing: 10,
                        shadows: [Shadow(blurRadius: 20, color: kPrimaryCyan)] // Cyber Glow Effect
                    ),
                  ),
                  const SizedBox(height: 10),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                    // Glassmorphism transparent cyan box
                    decoration: BoxDecoration(
                      color: kPrimaryCyan.withOpacity(0.2),
                      borderRadius: BorderRadius.circular(10),
                      border: Border.all(color: kPrimaryCyan),
                    ),
                    child: const Text(
                        "STAY SAFE • STAY PROTECTED",
                        style: TextStyle(color: Colors.white, fontSize: 12, fontWeight: FontWeight.bold, letterSpacing: 2)
                    ),
                  ),
                ],
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

  // --- 🚨 UPDATED GOOGLE SIGN-IN FOR v7.0+ API ---
  Future<void> _signInWithGoogle() async {
    setState(() => isLoading = true);
    try {
      final googleSignIn = GoogleSignIn.instance;
      await googleSignIn.initialize();

      final GoogleSignInAccount? googleUser = await googleSignIn.authenticate();
      if (googleUser == null) {
        setState(() => isLoading = false);
        return;
      }

      final authentication = await googleUser.authentication;
      final authorization = await googleUser.authorizationClient?.authorizeScopes(['email', 'profile']);

      final AuthCredential credential = GoogleAuthProvider.credential(
        idToken: authentication.idToken,
        accessToken: authorization?.accessToken,
      );

      UserCredential userCred = await _auth.signInWithCredential(credential);

      if (userCred.additionalUserInfo?.isNewUser == true) {
        await FirebaseFirestore.instance.collection('users').doc(userCred.user!.uid).set({
          'name': userCred.user!.displayName ?? "OnAlert User",
          'email': userCred.user!.email,
        }, SetOptions(merge: true));

        if (mounted) {
          Navigator.pushReplacement(context, MaterialPageRoute(builder: (_) => OnboardingScreen(uid: userCred.user!.uid)));
        }
      } else {
        if (mounted) {
          Navigator.pushReplacement(context, MaterialPageRoute(builder: (_) => MainAppScreen(uid: userCred.user!.uid)));
          await FcmService.instance.syncTokenForCurrentUser();
        }
      }
    } catch (e) {
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text("Google Sign-In Failed: $e")));
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
        backgroundColor: kGlassBase,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20), side: BorderSide(color: Colors.white.withOpacity(0.1))),
        title: Row(children: [const Icon(Icons.mark_email_read_rounded, color: kPrimaryCyan), const SizedBox(width: 10), Text(title, style: const TextStyle(color: Colors.white))]),
        content: Text(message, style: TextStyle(color: Colors.blueGrey.shade300)),
        actions: [TextButton(onPressed: () => Navigator.pop(context), child: const Text("OK", style: TextStyle(fontWeight: FontWeight.bold, color: kPrimaryCyan)))],
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
        if (mounted) Navigator.pushReplacement(context, MaterialPageRoute(builder: (_) => MainAppScreen(uid: cred.user!.uid)));
        await FcmService.instance.syncTokenForCurrentUser();
      } else {
        cred = await _auth.createUserWithEmailAndPassword(email: emailCtrl.text.trim(), password: passCtrl.text.trim());
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
      backgroundColor: kDarkSlate, // Applied Dark Slate Base
      body: Center(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 30),
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 30, vertical: 40),
            // Cyber-Glass Container
            decoration: BoxDecoration(
              color: kGlassBase.withOpacity(0.6),
              borderRadius: BorderRadius.circular(24),
              border: Border.all(color: Colors.white.withOpacity(0.1)),
              boxShadow: [
                BoxShadow(color: Colors.black.withOpacity(0.3), blurRadius: 20)
              ],
            ),
            child: Form(
              key: _formKey,
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Container(
                    padding: const EdgeInsets.all(20),
                    decoration: BoxDecoration(color: kPrimaryCyan.withOpacity(0.1), shape: BoxShape.circle),
                    child: const Icon(Icons.security, size: 70, color: kPrimaryCyan),
                  ),
                  const SizedBox(height: 30),
                  Text(isLogin ? 'Welcome Back' : 'Create Account', style: const TextStyle(fontSize: 32, fontWeight: FontWeight.bold, color: Colors.white)),
                  const SizedBox(height: 8),
                  Text(isLogin ? 'Please sign in to your account' : 'Sign up to start your safety journey', textAlign: TextAlign.center, style: TextStyle(color: Colors.blueGrey.shade300, fontSize: 16)),
                  const SizedBox(height: 40),

                  _buildInputField(controller: emailCtrl, label: 'Email Address', icon: Icons.email_outlined, validator: (v) => (v != null && v.contains('@')) ? null : 'Enter a valid email'),
                  const SizedBox(height: 20),
                  _buildInputField(controller: passCtrl, label: 'Password', icon: Icons.lock_outline, isPassword: true, validator: (v) => (v != null && v.length >= 6) ? null : 'Minimum 6 characters'),

                  if (isLogin)
                    Align(
                      alignment: Alignment.centerRight,
                      child: TextButton(onPressed: _handleForgotPassword, child: const Text("Forgot Password?", style: TextStyle(color: kPrimaryCyan, fontWeight: FontWeight.w600))),
                    ),

                  const SizedBox(height: 30),

                  SizedBox(
                    width: double.infinity,
                    height: 55,
                    child: ElevatedButton(
                      onPressed: isLoading ? null : _handleAuth,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: kPrimaryCyan,
                        foregroundColor: Colors.black, // Dark text on Cyan button
                        elevation: 5,
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
                      ),
                      child: isLoading
                          ? const SizedBox(height: 25, width: 25, child: CircularProgressIndicator(color: Colors.black, strokeWidth: 3))
                          : Text(isLogin ? 'LOGIN' : 'SIGN UP', style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold, letterSpacing: 1.1)),
                    ),
                  ),

                  const SizedBox(height: 25),
                  Row(
                    children: [
                      const Expanded(child: Divider(color: Colors.white24)),
                      Padding(padding: const EdgeInsets.symmetric(horizontal: 10), child: Text("OR", style: TextStyle(color: Colors.blueGrey.shade400, fontWeight: FontWeight.bold))),
                      const Expanded(child: Divider(color: Colors.white24)),
                    ],
                  ),
                  const SizedBox(height: 25),

                  SizedBox(
                    width: double.infinity,
                    height: 55,
                    child: OutlinedButton.icon(
                      onPressed: isLoading ? null : _signInWithGoogle,
                      icon: const Icon(Icons.g_mobiledata, color: Colors.white, size: 32),
                      label: const Text("Continue with Google", style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Colors.white)),
                      style: OutlinedButton.styleFrom(
                        backgroundColor: Colors.transparent,
                        side: BorderSide(color: Colors.white.withOpacity(0.3), width: 1.5),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
                      ),
                    ),
                  ),

                  const SizedBox(height: 25),
                  TextButton(
                    onPressed: () => setState(() => isLogin = !isLogin),
                    child: RichText(
                      text: TextSpan(
                        style: TextStyle(color: Colors.blueGrey.shade300, fontSize: 15),
                        children: [
                          TextSpan(text: isLogin ? "Don't have an account? " : "Already have an account? "),
                          TextSpan(text: isLogin ? "Sign Up" : "Login", style: const TextStyle(color: kPrimaryCyan, fontWeight: FontWeight.bold, decoration: TextDecoration.underline)),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildInputField({required TextEditingController controller, required String label, required IconData icon, bool isPassword = false, String? Function(String?)? validator}) {
    return TextFormField(
      controller: controller, obscureText: isPassword, validator: validator,
      style: const TextStyle(fontSize: 16, color: Colors.white), // White text input
      decoration: InputDecoration(
        labelText: label,
        labelStyle: TextStyle(color: Colors.blueGrey.shade300),
        prefixIcon: Icon(icon, color: kPrimaryCyan),
        filled: true,
        fillColor: Colors.white10, // Dark mode field background
        contentPadding: const EdgeInsets.symmetric(vertical: 20),
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(15), borderSide: BorderSide.none),
        focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(15), borderSide: const BorderSide(color: kPrimaryCyan, width: 2)),
      ),
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
      backgroundColor: kDarkSlate, // Applied Dark Slate Base
      body: AnimatedSwitcher(
        duration: const Duration(milliseconds: 300),
        child: pages[_index],
      ),
      bottomNavigationBar: Container(
        margin: const EdgeInsets.all(20),
        // Cyber-Glass Container for the Nav Bar
        decoration: BoxDecoration(
          color: kGlassBase.withOpacity(0.6),
          borderRadius: BorderRadius.circular(30),
          border: Border.all(color: Colors.white.withOpacity(0.1)),
          boxShadow: [
            BoxShadow(color: Colors.black.withOpacity(0.3), blurRadius: 20, offset: const Offset(0, 10))
          ],
        ),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(30),
          child: BottomNavigationBar(
            currentIndex: _index,
            onTap: (index) => setState(() => _index = index),
            type: BottomNavigationBarType.fixed,
            backgroundColor: Colors.transparent, // Let the glass background show through
            selectedItemColor: kPrimaryCyan, // Glowing Cyan for active tab
            unselectedItemColor: Colors.blueGrey.shade400, // Dimmed for inactive tabs
            elevation: 0, // Remove default shadow
            items: const [
              BottomNavigationBarItem(icon: Icon(Icons.dashboard_rounded), label: 'Home'),
              BottomNavigationBarItem(icon: Icon(Icons.history_rounded), label: 'Logs'),
              BottomNavigationBarItem(icon: Icon(Icons.people_alt_rounded), label: 'Contacts'),
              BottomNavigationBarItem(icon: Icon(Icons.play_circle_fill), label: 'Tutorial'), // <--- NEW ICON
              BottomNavigationBarItem(icon: Icon(Icons.settings_rounded), label: 'Settings'),
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
      backgroundColor: AppTheme.kDarkSlate,

      // --- 1. PREMIUM DRAWER ---
      drawer: Drawer(
        backgroundColor: AppTheme.kDarkSlate,
        child: Container(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
              colors: [AppTheme.kGlassBase.withOpacity(0.9), AppTheme.kDarkSlate],
            ),
          ),
          child: Column(
            children: [
              _buildDrawerHeader(),
              const SizedBox(height: 20),
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
              const Divider(color: Colors.white10, indent: 20, endIndent: 20, height: 40),
              _buildDrawerTile(Icons.help_outline_rounded, "Help & Support", () {
                Navigator.pop(context);
                Navigator.push(context, MaterialPageRoute(builder: (_) => const HelpSupportPage()));
              }),
              const Spacer(),
              _buildLogoutTile(context),
              const SizedBox(height: 40),
            ],
          ),
        ),
      ),

      // --- 2. PROFESSIONAL APP BAR ---
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        centerTitle: true,
        leading: IconButton(
          icon: Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(color: AppTheme.kGlassBase, borderRadius: BorderRadius.circular(12)),
            child: const Icon(Icons.menu_rounded, color: AppTheme.kPrimaryCyan, size: 20),
          ),
          onPressed: () => _scaffoldKey.currentState?.openDrawer(),
        ),
        title: const Text('ON ALERT', style: TextStyle(color: Colors.white, fontWeight: FontWeight.w900, letterSpacing: 2, fontSize: 18)),
        actions: [
          const NotificationBellButton(),
          IconButton(
            onPressed: () => Navigator.push(context, MaterialPageRoute(builder: (_) => ContactFormPage(userId: userId))),
            icon: const Icon(Icons.person_add_alt_1_rounded, color: AppTheme.kPrimaryCyan),
          ),
          const SizedBox(width: 10),
        ],
      ),

      // --- 3. MAIN CONTENT ---
      body: SingleChildScrollView(
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            DashboardStatusModule(userId: userId),
            const SizedBox(height: 35),

            // --- SAFETY CIRCLE SECTION ---
            Container(
              padding: const EdgeInsets.all(20),
              decoration: AppTheme.kGlassDecoration.copyWith(
                border: Border.all(color: AppTheme.kPrimaryCyan.withOpacity(0.2)),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text("Safety Circle", style: TextStyle(fontSize: 18, fontWeight: FontWeight.w900, color: Colors.white)),
                      const SizedBox(height: 4),
                      Text("Trusted Emergency Contacts", style: TextStyle(fontSize: 12, color: Colors.blueGrey.shade400)),
                    ],
                  ),
                  _buildAddButton(context),
                ],
              ),
            ),
            const SizedBox(height: 20),
            EmergencyContactsList(userId: userId),
            const SizedBox(height: 120),
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
          padding: const EdgeInsets.fromLTRB(20, 60, 20, 20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                padding: const EdgeInsets.all(3),
                decoration: BoxDecoration(shape: BoxShape.circle, border: Border.all(color: AppTheme.kPrimaryCyan, width: 2)),
                child: const CircleAvatar(radius: 30, backgroundColor: AppTheme.kGlassBase, child: Icon(Icons.person, color: Colors.white, size: 35)),
              ),
              const SizedBox(height: 15),
              Text(name, style: const TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold)),
              StreamBuilder<DocumentSnapshot>(
                stream: FirebaseFirestore.instance.collection('users').doc(userId).snapshots(),
                builder: (context, snap) {
                  final paired = (snap.data?.data() as Map?)?['pairedDevice']?.toString() ?? '';
                  final label = paired.isNotEmpty ? '● System Active' : '● No Device';
                  return Text(label, style: const TextStyle(color: AppTheme.kPrimaryCyan, fontSize: 12, fontWeight: FontWeight.bold));
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
      leading: Icon(icon, color: isActive ? AppTheme.kPrimaryCyan : Colors.blueGrey),
      title: Text(title, style: TextStyle(fontSize: 14, fontWeight: isActive ? FontWeight.bold : FontWeight.w500, color: isActive ? AppTheme.kPrimaryCyan : Colors.white)),
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

  Widget _buildAddButton(BuildContext context) {
    return InkWell(
      onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => ContactFormPage(userId: userId))),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
        decoration: BoxDecoration(color: AppTheme.kPrimaryCyan, borderRadius: BorderRadius.circular(12)),
        child: const Text("ADD", style: TextStyle(color: Colors.black, fontWeight: FontWeight.w900, fontSize: 12)),
      ),
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
  StreamSubscription? _hardwareSubscription;

  @override
  void initState() {
    super.initState();
    _initHardwareListener();
  }

  @override
  void dispose() {
    _hardwareSubscription?.cancel();
    super.dispose();
  }

  void _initHardwareListener() async {
    final userDoc = await FirebaseFirestore.instance.collection('users').doc(widget.userId).get();
    String? pairedSerial = userDoc.data()?['pairedDevice'];
    if (pairedSerial != null && pairedSerial.isNotEmpty) {
      _hardwareSubscription = FirebaseDatabase.instance.ref("devices/$pairedSerial/status").onValue.listen((event) {
        if (event.snapshot.value != null) {
          final data = Map<dynamic, dynamic>.from(event.snapshot.value as Map);
          if (data['alert'] == "ACCIDENT_DETECTED" && !_isDialogShowing) {
            _showAccidentDialog(context, data);
          }
        }
      });
    }
  }

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
                const Text("ACCIDENT DETECTED!", style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 22)),
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
    double lat = double.tryParse(data['lat']?.toString() ?? '0.0') ?? 0.0;
    double lng = double.tryParse(data['lng']?.toString() ?? '0.0') ?? 0.0;
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
        if (!userSnapshot.hasData) return const Center(child: CircularProgressIndicator(color: AppTheme.kPrimaryCyan));

        String pairedSerial = (userSnapshot.data?.data() as Map<String, dynamic>?)?['pairedDevice'] ?? "";
        if (pairedSerial.isEmpty) return _buildNoDeviceUI();

        return StreamBuilder<DatabaseEvent>(
          stream: FirebaseDatabase.instance.ref("devices/$pairedSerial/status").onValue,
          builder: (context, snapshot) {
            bool isOnline = false;
            String accelStatus = "STABLE";
            Color accelColor = Colors.greenAccent;
            double lat = 0.0, lng = 0.0;

            bool gpsFix = isOnline;
            bool gsmConnected = isOnline;
            int gsmSignal = 0;
            if (snapshot.hasData && snapshot.data!.snapshot.value != null) {
              final data = Map<dynamic, dynamic>.from(snapshot.data!.snapshot.value as Map);
              int lastSeen = int.tryParse(data['last_seen']?.toString() ?? '0') ?? 0;
              isOnline = (DateTime.now().millisecondsSinceEpoch - lastSeen).abs() < 30000;
              lat = double.tryParse(data['lat']?.toString() ?? '0.0') ?? 0.0;
              lng = double.tryParse(data['lng']?.toString() ?? '0.0') ?? 0.0;
              gpsFix = data['gps_fix'] == true || isOnline;
              gsmConnected = data['gsm_connected'] != false;
              gsmSignal = int.tryParse(data['gsm_signal']?.toString() ?? '0') ?? 0;
              if (data['alert'] == "ACCIDENT_DETECTED") {
                accelStatus = "IMPACT!";
                accelColor = Colors.redAccent;
              }
            }

            return Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text("System Status", style: TextStyle(fontSize: 18, fontWeight: FontWeight.w800, color: Colors.white)),
                      TextButton(
                          onPressed: () => DeviceService.removeDevice(widget.userId),
                          child: const Text("Unpair", style: TextStyle(color: Colors.redAccent))
                      ),
                    ]
                ),

                if (!isOnline)
                  Container(
                    margin: const EdgeInsets.only(bottom: 15),
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: Colors.orange.withOpacity(0.2),
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: Colors.orangeAccent),
                    ),
                    child: Row(
                      children: [
                        const Icon(Icons.battery_alert_rounded, color: Colors.orangeAccent),
                        const SizedBox(width: 10),
                        Expanded(child: Text("Hardware connection lost. Check ESP32 power source.", style: TextStyle(color: Colors.orangeAccent.shade100, fontSize: 13))),
                      ],
                    ),
                  ),

                Container(
                  padding: const EdgeInsets.all(20),
                  decoration: AppTheme.kGlassDecoration.copyWith(
                      border: Border.all(color: isOnline ? Colors.greenAccent.withOpacity(0.5) : Colors.redAccent.withOpacity(0.5))
                  ),
                  child: Column(
                    children: [
                      Row(children: [
                        Icon(isOnline ? Icons.sensors : Icons.report_problem, color: isOnline ? Colors.greenAccent : Colors.redAccent),
                        const SizedBox(width: 12),
                        Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(isOnline ? "System Online" : "System Offline", style: const TextStyle(fontWeight: FontWeight.bold, color: Colors.white)),
                              Text("ID: $pairedSerial", style: TextStyle(fontSize: 10, color: Colors.blueGrey.shade300))
                            ]
                        )
                      ]),
                      const Divider(height: 32, color: Colors.white10),
                      Row(mainAxisAlignment: MainAxisAlignment.spaceAround, children: [
                        Column(children: [Icon(Icons.bolt, color: accelColor), Text('ACCEL', style: TextStyle(color: Colors.blueGrey.shade300, fontSize: 10)), Text(accelStatus, style: TextStyle(color: accelColor, fontWeight: FontWeight.bold))]),
                        Column(children: [Icon(Icons.satellite_alt, color: gpsFix ? AppTheme.kPrimaryCyan : Colors.grey), Text('GPS', style: TextStyle(color: Colors.blueGrey.shade300, fontSize: 10)), Text(gpsFix ? 'FIX' : 'NO FIX', style: TextStyle(color: gpsFix ? AppTheme.kPrimaryCyan : Colors.grey, fontWeight: FontWeight.bold))]),
                        Column(children: [Icon(Icons.cell_tower, color: gsmConnected ? Colors.greenAccent : Colors.grey), Text('GSM', style: TextStyle(color: Colors.blueGrey.shade300, fontSize: 10)), Text(gsmConnected ? '$gsmSignal%' : 'OFF', style: TextStyle(color: gsmConnected ? Colors.greenAccent : Colors.grey, fontWeight: FontWeight.bold))]),
                      ]),
                      const SizedBox(height: 12),
                      TextButton.icon(
                        onPressed: () => Navigator.push(context, MaterialPageRoute(
                          builder: (_) => MapScreen(lat: lat, lng: lng, liveMode: true, deviceSerial: pairedSerial),
                        )),
                        icon: const Icon(Icons.map, color: AppTheme.kPrimaryCyan),
                        label: const Text('View Live Map', style: TextStyle(color: AppTheme.kPrimaryCyan)),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 25),

                // Manual SOS Button
                InkWell(
                  onTap: () => _showManualSosCountdown(context, lat, lng),
                  child: Container(
                    width: double.infinity,
                    height: 60,
                    decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(16),
                        gradient: const LinearGradient(colors: [Color(0xFFFF5252), Color(0xFFD32F2F)])
                    ),
                    child: const Center(child: Text("INITIALIZE MANUAL SOS", style: TextStyle(color: Colors.white, fontWeight: FontWeight.w900, letterSpacing: 1.2))),
                  ),
                ),
                const SizedBox(height: 15),

                // 911 Call Button
                InkWell(
                  onTap: () async {
                    final Uri telUri = Uri.parse("tel:911");
                    if (await canLaunchUrl(telUri)) {
                      await launchUrl(telUri);
                    }
                  },
                  child: Container(
                    width: double.infinity,
                    height: 50,
                    decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(color: Colors.redAccent),
                        color: Colors.transparent
                    ),
                    child: const Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(Icons.call, color: Colors.redAccent),
                        SizedBox(width: 10),
                        Text("CALL EMERGENCY SERVICES", style: TextStyle(color: Colors.redAccent, fontWeight: FontWeight.bold, letterSpacing: 1.2)),
                      ],
                    ),
                  ),
                ),
              ],
            );
          },
        );
      },
    );
  }

  Widget _buildNoDeviceUI() => Container(
    width: double.infinity,
    padding: const EdgeInsets.all(30),
    decoration: AppTheme.kGlassDecoration,
    child: Column(children: [
      const Icon(Icons.sensors_off_rounded, size: 60, color: Colors.blueGrey),
      const SizedBox(height: 15),
      const Text("No Device Paired", style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18, color: Colors.white)),
      const SizedBox(height: 25),
      ElevatedButton(
          style: ElevatedButton.styleFrom(backgroundColor: AppTheme.kPrimaryCyan, foregroundColor: Colors.black),
          onPressed: () => Navigator.push(context, MaterialPageRoute(builder: (_) => DeviceManagerPage(userId: widget.userId))),
          child: const Text("Pair Hardware", style: TextStyle(fontWeight: FontWeight.bold))
      )
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

        return ListView.builder(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          itemCount: docs.length,
          itemBuilder: (c, i) {
            final doc = docs[i];
            final data = doc.data() as Map<String, dynamic>;
            final String name = data['name'] ?? "Unknown";
            final String number = data['number'] ?? "No Number";

            return Container(
              margin: const EdgeInsets.symmetric(vertical: 10),
              decoration: AppTheme.kGlassDecoration,
              child: ListTile(
                contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                leading: _buildGlassAvatar(name),
                title: Text(name, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 17, color: Colors.white)),
                subtitle: Padding(
                  padding: const EdgeInsets.only(top: 4),
                  child: Row(
                    children: [
                      Icon(Icons.phone_iphone_rounded, size: 14, color: Colors.blueGrey.shade300),
                      const SizedBox(width: 8),
                      Text(number, style: TextStyle(color: Colors.blueGrey.shade300, fontWeight: FontWeight.w600, fontSize: 14)),
                    ],
                  ),
                ),
                trailing: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    IconButton(
                      icon: const Icon(Icons.edit_rounded, color: AppTheme.kPrimaryCyan, size: 22),
                      onPressed: () => _showEditContactDialog(context, doc.id, name, number),
                    ),
                    _buildDeleteButton(context, doc.id),
                  ],
                ),
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
        backgroundColor: AppTheme.kGlassBase,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20), side: BorderSide(color: Colors.white.withOpacity(0.1))),
        title: const Text("Edit Contact", style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(controller: nameCtrl, style: const TextStyle(color: Colors.white), decoration: InputDecoration(labelText: "Full Name", labelStyle: const TextStyle(color: Colors.blueGrey), prefixIcon: const Icon(Icons.person, color: AppTheme.kPrimaryCyan), border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)))),
            const SizedBox(height: 15),
            TextField(controller: phoneCtrl, keyboardType: TextInputType.phone, style: const TextStyle(color: Colors.white), decoration: InputDecoration(labelText: "Phone Number", labelStyle: const TextStyle(color: Colors.blueGrey), prefixIcon: const Icon(Icons.phone, color: AppTheme.kPrimaryCyan), border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)))),
          ],
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text("CANCEL", style: TextStyle(color: Colors.blueGrey))),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: AppTheme.kPrimaryCyan),
            onPressed: () async {
              await FirebaseFirestore.instance.collection('users').doc(userId).collection('contacts').doc(docId).update({
                'name': nameCtrl.text.trim(),
                'number': phoneCtrl.text.trim(),
              });
              if (context.mounted) Navigator.pop(context);
            },
            child: const Text("SAVE", style: TextStyle(color: Colors.black, fontWeight: FontWeight.bold)),
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
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(40),
      decoration: AppTheme.kGlassDecoration,
      child: Column(
        children: [
          Icon(Icons.person_add_disabled_rounded, size: 60, color: Colors.blueGrey.withOpacity(0.5)),
          const SizedBox(height: 16),
          const Text("Security Circle Empty", style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 16)),
          const Text("Add contacts to enable SOS alerts", style: TextStyle(color: Colors.blueGrey, fontSize: 13)),
        ],
      ),
    );
  }

  void _confirmDelete(BuildContext context, String docId) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: AppTheme.kGlassBase,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20), side: const BorderSide(color: Colors.redAccent)),
        title: const Text("Remove Contact?", style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
        content: const Text("This person will no longer receive emergency alerts.", style: TextStyle(color: Colors.white70)),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text("KEEP", style: TextStyle(color: Colors.blueGrey))),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: Colors.redAccent),
            onPressed: () {
              FirebaseFirestore.instance.collection('users').doc(userId).collection('contacts').doc(docId).delete();
              Navigator.pop(context);
            },
            child: const Text("DELETE", style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
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
        data: Theme.of(context).copyWith(colorScheme: const ColorScheme.dark(primary: AppTheme.kPrimaryCyan)),
        child: child!,
      ),
    );
    if (range != null) setState(() => _dateRange = range);
  }

  bool _inRange(DateTime ts) {
    if (_dateRange == null) return true;
    return !ts.isBefore(_dateRange!.start) && !ts.isAfter(_dateRange!.end.add(const Duration(days: 1)));
  }

  @override
  Widget build(BuildContext context) {
    final String currentUid = FirebaseAuth.instance.currentUser?.uid ?? "";

    return Scaffold(
      backgroundColor: AppTheme.kDarkSlate,
      appBar: AppBar(
        title: const Text("Incident History", style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
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
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.history_rounded, size: 60, color: Colors.blueGrey.shade800),
                  const SizedBox(height: 15),
                  const Text("No incident history recorded.", style: TextStyle(color: Colors.blueGrey)),
                ],
              ),
            );
          }

          return ListView.builder(
            padding: const EdgeInsets.all(16),
            itemCount: filtered.length,
            itemBuilder: (context, index) {
              final alert = filtered[index].data() as Map<String, dynamic>;
              final DateTime ts = (alert['timestamp'] as cf.Timestamp).toDate();

              return Container(
                margin: const EdgeInsets.only(bottom: 12),
                decoration: AppTheme.kGlassDecoration,
                child: ListTile(
                  contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
                  leading: CircleAvatar(
                    backgroundColor: Colors.redAccent.withOpacity(0.2),
                    child: const Icon(Icons.warning_rounded, color: Colors.redAccent),
                  ),
                  title: Text(alert['type'] ?? "Alert", style: const TextStyle(fontWeight: FontWeight.bold, color: Colors.white)),
                  subtitle: Text(DateFormat('MMM dd, yyyy • hh:mm a').format(ts), style: TextStyle(color: Colors.blueGrey.shade300)),
                  trailing: const Icon(Icons.chevron_right_rounded, color: AppTheme.kPrimaryCyan),
                  onTap: () => Navigator.push(
                    context,
                    MaterialPageRoute(builder: (_) => DetailedAlertView(alert: alert)),
                  ),
                ),
              );
            },
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

    return Scaffold(
      backgroundColor: AppTheme.kDarkSlate,
      appBar: AppBar(
        title: const Text('Incident Analysis', style: TextStyle(fontWeight: FontWeight.bold, color: Colors.white)),
        centerTitle: true,
        backgroundColor: Colors.transparent,
        elevation: 0,
        actions: [
          IconButton(
            icon: const Icon(Icons.picture_as_pdf_rounded, color: AppTheme.kPrimaryCyan),
            tooltip: "Export Report",
            onPressed: () => _exportIncidentReport(context),
          )
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: Column(
          children: [
            // Header Card
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                  gradient: LinearGradient(colors: [Colors.red.shade900, Colors.red.shade800]),
                  borderRadius: BorderRadius.circular(24),
                  boxShadow: [BoxShadow(color: Colors.red.withOpacity(0.3), blurRadius: 15, offset: const Offset(0, 8))]
              ),
              child: Column(
                children: [
                  const Icon(Icons.emergency_share_rounded, color: Colors.white, size: 40),
                  const SizedBox(height: 12),
                  Text(alert['type'].toString().toUpperCase(),
                      style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w900, fontSize: 20, letterSpacing: 1.5)),
                  const Text("Notification Sent to Emergency Contacts",
                      style: TextStyle(color: Colors.white70, fontSize: 12)),
                ],
              ),
            ),
            const SizedBox(height: 30),

            // Info Row
            Row(
              children: [
                _buildInfoCard("Time", DateFormat('hh:mm a').format(ts), Icons.access_time_filled_rounded, AppTheme.kPrimaryCyan),
                const SizedBox(width: 15),
                _buildInfoCard("G-Force", "${alert['g_force'] ?? '0.0'} G", Icons.speed_rounded, Colors.orangeAccent),
              ],
            ),
            const SizedBox(height: 15),

            // Coordinates Container
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(18),
              decoration: AppTheme.kGlassDecoration,
              child: Row(
                children: [
                  const CircleAvatar(backgroundColor: AppTheme.kPrimaryCyan, child: Icon(Icons.location_on, color: Colors.black, size: 20)),
                  const SizedBox(width: 15),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text("Coordinates", style: TextStyle(color: Colors.blueGrey, fontSize: 12)),
                      Text("${alert['lat']}, ${alert['lng']}",
                          style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16, color: Colors.white)),
                    ],
                  )
                ],
              ),
            ),

            const SizedBox(height: 40),

            // Action Buttons
            SizedBox(
              width: double.infinity,
              height: 60,
              child: ElevatedButton.icon(
                onPressed: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (_) => MapScreen(
                        lat: double.tryParse(alert['lat'].toString()) ?? 33.6844,
                        lng: double.tryParse(alert['lng'].toString()) ?? 73.0479,
                      ),
                    ),
                  );
                },
                icon: const Icon(Icons.map_rounded),
                label: const Text("VIEW ON SATELLITE MAP", style: TextStyle(fontWeight: FontWeight.bold, letterSpacing: 1)),
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppTheme.kPrimaryCyan,
                  foregroundColor: Colors.black,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                  elevation: 5,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildInfoCard(String title, String val, IconData icon, Color color) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: AppTheme.kGlassDecoration.copyWith(
          border: Border.all(color: color.withOpacity(0.3)),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Icon(icon, color: color, size: 24),
            const SizedBox(height: 12),
            Text(title, style: const TextStyle(color: Colors.blueGrey, fontSize: 12)),
            Text(val, style: const TextStyle(fontWeight: FontWeight.w900, fontSize: 18, color: Colors.white)),
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
        backgroundColor: AppTheme.kGlassBase,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20), side: BorderSide(color: Colors.white.withOpacity(0.1))),
        title: const Text("Update Profile", style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              _buildDialogField("Full Name", _nameController, Icons.person),
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
              await FirebaseFirestore.instance.collection('users').doc(widget.userId).set({
                'name': _nameController.text.trim(),
                'bloodType': _bloodTypeController.text.trim(),
                'medicalConditions': _medicalController.text.trim(),
                'vehiclePlate': _vehicleController.text.trim(),
              }, SetOptions(merge: true));
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
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: AppTheme.kGlassBase,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20), side: const BorderSide(color: Colors.redAccent)),
        title: const Row(children: [Icon(Icons.warning_amber_rounded, color: Colors.redAccent), SizedBox(width: 10), Text("Delete Account?", style: TextStyle(color: Colors.white))]),
        content: const Text("This action is irreversible. All incident logs, contacts, and pairing data will be permanently deleted.", style: TextStyle(color: Colors.white70)),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text("CANCEL", style: TextStyle(color: Colors.blueGrey))),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: Colors.redAccent),
            onPressed: () async {
              try {
                await FirebaseFirestore.instance.collection('users').doc(widget.userId).delete();
                await FirebaseAuth.instance.currentUser?.delete();
                if (mounted) Navigator.pushAndRemoveUntil(context, MaterialPageRoute(builder: (_) => const LoginSignupScreen()), (r) => false);
              } catch (e) {
                if (mounted) ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("Please re-authenticate to delete account."), backgroundColor: Colors.redAccent));
              }
            },
            child: const Text("DELETE PERMANENTLY", style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
          ),
        ],
      ),
    );
  }

  Widget _buildDialogField(String label, TextEditingController ctrl, IconData icon) {
    return TextField(
      controller: ctrl,
      style: const TextStyle(color: Colors.white),
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
      backgroundColor: AppTheme.kDarkSlate,
      appBar: AppBar(
        title: const Text("Settings", style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
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
                    const CircleAvatar(radius: 50, backgroundColor: AppTheme.kGlassBase, child: Icon(Icons.person, size: 60, color: AppTheme.kPrimaryCyan)),
                    GestureDetector(
                      onTap: _showEditProfile,
                      child: const CircleAvatar(radius: 18, backgroundColor: AppTheme.kPrimaryCyan, child: Icon(Icons.edit, size: 16, color: Colors.black)),
                    ),
                  ],
                ),
                const SizedBox(height: 15),
                Text(_nameController.text.isEmpty ? "OnAlert User" : _nameController.text, style: const TextStyle(fontSize: 22, fontWeight: FontWeight.w900, color: Colors.white)),
                Text(user?.email ?? "No Email", style: TextStyle(color: Colors.blueGrey.shade300, fontSize: 13)),
              ],
            ),
          ),

          const SizedBox(height: 20),
          _sectionHeader("EMERGENCY PROFILE"),
          _settingsGroup([
            _buildActionTile("Blood Type", _bloodTypeController.text.isEmpty ? "Not Set" : _bloodTypeController.text, Icons.water_drop, _showEditProfile),
            const Divider(height: 1, color: Colors.white10),
            _buildActionTile("Medical Conditions", _medicalController.text.isEmpty ? "None listed" : _medicalController.text, Icons.medical_information, _showEditProfile),
            const Divider(height: 1, color: Colors.white10),
            _buildActionTile("Vehicle Plate", _vehicleController.text.isEmpty ? "Not Set" : _vehicleController.text, Icons.directions_car, _showEditProfile),
          ]),

          const SizedBox(height: 30),
          _sectionHeader("PREFERENCES"),
          _settingsGroup([
            _buildSwitchTile("Push Notifications", "Receive safety alerts", Icons.notifications_active_rounded, _pushNotifications, (v) => _updateNotification('push_active', v)),
            const Divider(height: 1, color: Colors.white10),
            _buildSwitchTile("SMS Alerts", "Emergency text notifications", Icons.sms_rounded, _smsAlerts, (v) => _updateNotification('sms_active', v)),
          ]),

          const SizedBox(height: 30),
          _sectionHeader("ACCOUNT & PRIVACY"),
          _settingsGroup([
            _buildActionTile("Permissions Manager", "Location, SMS, notifications", Icons.security_rounded, () {
              Navigator.push(context, MaterialPageRoute(builder: (_) => const PermissionsManagerPage()));
            }),
            const Divider(height: 1, color: Colors.white10),
            _buildActionTile("Privacy Policy", "How we handle your data", Icons.policy_rounded, () {
              Navigator.push(context, MaterialPageRoute(builder: (_) => const PrivacyPolicyPage()));
            }),
            const Divider(height: 1, color: Colors.white10),
            _buildActionTile("Safety Tips", "Emergency best practices", Icons.health_and_safety_rounded, () {
              Navigator.push(context, MaterialPageRoute(builder: (_) => const SafetyTipsPage()));
            }),
            const Divider(height: 1, color: Colors.white10),
            _buildActionTile("Change Password", "Send reset link to email", Icons.lock_reset_rounded, () async {
              if (user?.email != null) {
                await FirebaseAuth.instance.sendPasswordResetEmail(email: user!.email!);
                ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("Password reset link sent! Check your inbox."), backgroundColor: AppTheme.kPrimaryCyan));
              }
            }),
            const Divider(height: 1, color: Colors.white10),
            _buildActionTile("Export Data", "Download your incident history", Icons.download_rounded, () async {
              await ExportService.exportUserData(widget.userId);
            }),
            const Divider(height: 1, color: Colors.white10),
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
    title: Text(title, style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
    subtitle: Text(sub, style: TextStyle(color: Colors.blueGrey.shade300, fontSize: 12)),
    activeColor: AppTheme.kPrimaryCyan,
    value: val,
    onChanged: onChanged,
  );

  Widget _buildActionTile(String title, String sub, IconData icon, VoidCallback onTap) => ListTile(
    leading: Icon(icon, color: AppTheme.kPrimaryCyan),
    title: Text(title, style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
    subtitle: Text(sub, style: TextStyle(color: Colors.blueGrey.shade300, fontSize: 12)),
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
      backgroundColor: AppTheme.kDarkSlate,
      drawer: Drawer(
        backgroundColor: AppTheme.kDarkSlate,
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
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        centerTitle: true,
        leading: IconButton(
          icon: Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(color: AppTheme.kGlassBase, borderRadius: BorderRadius.circular(10)),
            child: const Icon(Icons.menu_rounded, color: AppTheme.kPrimaryCyan, size: 20),
          ),
          onPressed: () => _scaffoldKey.currentState?.openDrawer(),
        ),
        title: const Text("Add Secure Contact", style: TextStyle(color: Colors.white, fontWeight: FontWeight.w900, fontSize: 18, letterSpacing: 0.5)),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(25.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildLivePreview(),
            const SizedBox(height: 35),
            Text("CONTACT DETAILS", style: TextStyle(color: AppTheme.kPrimaryCyan.withOpacity(0.7), fontWeight: FontWeight.bold, fontSize: 12, letterSpacing: 1.2)),
            const SizedBox(height: 15),
            _buildFancyTextField(controller: nameCtrl, label: "Full Name", icon: Icons.person_outline_rounded, hint: "e.g. John Doe", onChanged: (v) => setState(() {})),
            const SizedBox(height: 20),
            _buildFancyTextField(controller: phoneCtrl, label: "Phone Number", icon: Icons.phone_android_rounded, hint: "+1 234 567 890", keyboardType: TextInputType.phone, onChanged: (v) => setState(() {})),
            const SizedBox(height: 40),
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
        gradient: LinearGradient(begin: Alignment.topLeft, end: Alignment.bottomRight, colors: [Color(0xFF1E3A8A), AppTheme.kDarkSlate]),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          CircleAvatar(radius: 35, backgroundColor: AppTheme.kGlassBase, child: const Icon(Icons.person, color: AppTheme.kPrimaryCyan, size: 40)),
          const SizedBox(height: 15),
          const Text("OnAlert User", style: TextStyle(color: Colors.white, fontSize: 20, fontWeight: FontWeight.bold)),
          const Text("Safety Status: Secure", style: TextStyle(color: Colors.blueGrey, fontSize: 13)),
        ],
      ),
    );
  }

  Widget _buildDrawerTile(IconData icon, String title, VoidCallback onTap) => ListTile(
    contentPadding: const EdgeInsets.symmetric(horizontal: 25),
    leading: Icon(icon, color: Colors.blueGrey),
    title: Text(title, style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w500, color: Colors.white)),
    onTap: onTap,
  );

  Widget _buildLogoutTile(BuildContext context) => ListTile(
    contentPadding: const EdgeInsets.symmetric(horizontal: 25),
    leading: const Icon(Icons.logout_rounded, color: Colors.redAccent),
    title: const Text("Sign Out", style: TextStyle(color: Colors.redAccent, fontWeight: FontWeight.bold)),
    onTap: () async { await FirebaseAuth.instance.signOut(); if (context.mounted) Navigator.of(context).pushNamedAndRemoveUntil('/', (route) => false); },
  );

  Widget _buildLivePreview() => Container(
    width: double.infinity,
    padding: const EdgeInsets.all(20),
    decoration: AppTheme.kGlassDecoration,
    child: Row(
      children: [
        CircleAvatar(radius: 35, backgroundColor: AppTheme.kPrimaryCyan.withOpacity(0.1), child: Text(nameCtrl.text.isNotEmpty ? nameCtrl.text[0].toUpperCase() : "?", style: const TextStyle(color: AppTheme.kPrimaryCyan, fontSize: 28, fontWeight: FontWeight.w900))),
        const SizedBox(width: 20),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(nameCtrl.text.isEmpty ? "Contact Name" : nameCtrl.text, style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w900, color: Colors.white)),
              Text(phoneCtrl.text.isEmpty ? "Phone Number" : phoneCtrl.text, style: const TextStyle(color: Colors.blueGrey, fontWeight: FontWeight.w500)),
            ],
          ),
        ),
      ],
    ),
  );

  Widget _buildFancyTextField({required TextEditingController controller, required String label, required IconData icon, required String hint, TextInputType keyboardType = TextInputType.text, Function(String)? onChanged}) => Container(
    decoration: AppTheme.kGlassDecoration,
    child: TextField(
      controller: controller, onChanged: onChanged, keyboardType: keyboardType,
      style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
      decoration: InputDecoration(
        labelText: label, hintText: hint, labelStyle: const TextStyle(color: Colors.blueGrey),
        prefixIcon: Icon(icon, color: AppTheme.kPrimaryCyan),
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(18), borderSide: BorderSide.none),
        contentPadding: const EdgeInsets.symmetric(vertical: 20),
      ),
    ),
  );

  Widget _buildSaveButton() => GestureDetector(
    onTap: _saveContact,
    child: Container(
      height: 60,
      decoration: BoxDecoration(color: AppTheme.kPrimaryCyan, borderRadius: BorderRadius.circular(20)),
      child: const Center(child: Text("SAVE CONTACT", style: TextStyle(color: Colors.black, fontWeight: FontWeight.w900, letterSpacing: 1.5, fontSize: 16))),
    ),
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
      backgroundColor: AppTheme.kDarkSlate,
      child: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [AppTheme.kGlassBase.withOpacity(0.9), AppTheme.kDarkSlate],
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
                        child: const CircleAvatar(radius: 30, backgroundColor: AppTheme.kGlassBase, child: Icon(Icons.person, color: Colors.white, size: 35)),
                      ),
                      const SizedBox(height: 15),
                      Text(name, style: const TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold)),
                      const Text("Status: Active", style: TextStyle(color: AppTheme.kPrimaryCyan, fontSize: 12, fontWeight: FontWeight.bold)),
                    ],
                  ),
                );
              },
            ),
            const Divider(color: Colors.white10, indent: 20, endIndent: 20, height: 40),
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
      title: Text(title, style: const TextStyle(fontSize: 14, color: Colors.white, fontWeight: FontWeight.w500)),
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
      backgroundColor: AppTheme.kDarkSlate,
      appBar: AppBar(
        title: const Text("Privacy Policy", style: TextStyle(fontWeight: FontWeight.bold, color: Colors.white)),
        centerTitle: true,
        elevation: 0,
        backgroundColor: Colors.transparent,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new_rounded, color: Colors.white, size: 20),
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
            const Text("Your Safety is Our Priority", style: TextStyle(fontSize: 22, fontWeight: FontWeight.w900, color: Colors.white)),
            const SizedBox(height: 10),
            Text("Last Updated: January 2026", style: TextStyle(color: Colors.blueGrey.shade300, fontSize: 13)),
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
                  style: TextStyle(color: Colors.blueGrey.shade400, fontSize: 12, height: 1.5)
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
                Text(title, style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Colors.white)),
                const SizedBox(height: 8),
                Text(content, style: TextStyle(fontSize: 14, color: Colors.blueGrey.shade300, height: 1.5)),
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
      backgroundColor: AppTheme.kDarkSlate,
      appBar: AppBar(
        title: const Text("Safety Guide", style: TextStyle(fontWeight: FontWeight.bold, color: Colors.white)),
        centerTitle: true,
        elevation: 0,
        backgroundColor: Colors.transparent,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new_rounded, color: Colors.white, size: 20),
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
          Center(child: Text("Stay Safe. Stay Alert.", style: TextStyle(color: Colors.blueGrey.shade400, fontStyle: FontStyle.italic))),
          const SizedBox(height: 40),
        ],
      ),
    );
  }

  Widget _buildHeader() {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: LinearGradient(colors: [AppTheme.kPrimaryCyan.withOpacity(0.2), AppTheme.kGlassBase]),
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
                Text("Safety Knowledge", style: TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold)),
                Text("Essential tips for your daily commute", style: TextStyle(color: Colors.white70, fontSize: 13)),
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
                Text(title, style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Colors.white)),
                const SizedBox(height: 5),
                Text(desc, style: TextStyle(fontSize: 14, color: Colors.blueGrey.shade300, height: 1.4)),
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
      backgroundColor: AppTheme.kDarkSlate,
      appBar: AppBar(
        title: const Text("Help & Support", style: TextStyle(fontWeight: FontWeight.bold, color: Colors.white)),
        centerTitle: true,
        elevation: 0,
        backgroundColor: Colors.transparent,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new_rounded, color: Colors.white, size: 20),
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
              Center(child: Text("OnAlert Support Team is available 24/7", style: TextStyle(color: Colors.blueGrey.shade400, fontSize: 12))),
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
          const Text("How can we help you?", style: TextStyle(fontSize: 20, fontWeight: FontWeight.w900, color: Colors.white)),
          const SizedBox(height: 8),
          Text("Our team is here to ensure your journey is safe.", textAlign: TextAlign.center, style: TextStyle(color: Colors.blueGrey.shade300, fontSize: 14)),
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
        title: Text(question, style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 14)),
        children: [
          Padding(padding: const EdgeInsets.fromLTRB(55, 0, 20, 15), child: Text(answer, style: TextStyle(color: Colors.blueGrey.shade300, fontSize: 13, height: 1.5)))
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
                Text(title, style: const TextStyle(fontWeight: FontWeight.bold, color: Colors.white)),
                Text(sub, style: TextStyle(color: Colors.blueGrey.shade300, fontSize: 12)),
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
  @override
  void initState() {
    super.initState();
    rtdb.FirebaseDatabase.instance.setPersistenceEnabled(true);
  }

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<cf.DocumentSnapshot>(
      stream: cf.FirebaseFirestore.instance.collection('users').doc(widget.userId).snapshots(),
      builder: (context, userSnapshot) {
        if (!userSnapshot.hasData) {
          return const Scaffold(backgroundColor: AppTheme.kDarkSlate, body: Center(child: CircularProgressIndicator(color: AppTheme.kPrimaryCyan)));
        }

        var userData = userSnapshot.data?.data() as Map<String, dynamic>?;
        String pairedSerial = userData?['pairedDevice'] ?? "";

        if (pairedSerial.isEmpty) {
          return const Scaffold(
            backgroundColor: AppTheme.kDarkSlate,
            body: Center(child: Text("Please pair a device in Dashboard first.", style: TextStyle(color: Colors.white))),
          );
        }

        final rtdb.Query dbRef = rtdb.FirebaseDatabase.instance.ref("devices/$pairedSerial/status");
        rtdb.FirebaseDatabase.instance.ref("devices/$pairedSerial/status").keepSynced(true);

        return Scaffold(
          backgroundColor: AppTheme.kDarkSlate,
          appBar: AppBar(
            title: const Text("Live Sensor Diagnostics", style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18, color: Colors.white)),
            elevation: 0,
            backgroundColor: Colors.transparent,
            centerTitle: true,
          ),
          body: StreamBuilder(
            stream: dbRef.onValue,
            builder: (context, AsyncSnapshot<rtdb.DatabaseEvent> snapshot) {
              if (!snapshot.hasData || snapshot.data!.snapshot.value == null) {
                return const Center(child: Text("Establishing High-Speed Link...", style: TextStyle(color: Colors.blueGrey)));
              }

              final data = Map<dynamic, dynamic>.from(snapshot.data!.snapshot.value as Map);
              String x = data['accel_x']?.toString() ?? "0.00";
              String y = data['accel_y']?.toString() ?? "0.00";
              String z = data['accel_z']?.toString() ?? "0.00";
              String alert = data['alert']?.toString() ?? "NORMAL";
              String lat = data['lat']?.toString() ?? "Searching...";
              String lng = data['lng']?.toString() ?? "Searching...";

              return SingleChildScrollView(
                padding: const EdgeInsets.all(20),
                child: Column(
                  children: [
                    _buildMetricCard("Real-time Motion (m/s²)", Icons.speed_rounded, AppTheme.kPrimaryCyan, ["X-Axis Accel: $x", "Y-Axis Accel: $y", "Z-Axis Accel: $z"], isLive: true),
                    const SizedBox(height: 20),
                    _buildMetricCard("Satellite Telemetry", Icons.location_on, Colors.greenAccent, ["Latitude: $lat", "Longitude: $lng", "System Status: $alert"], isLive: false),
                    const SizedBox(height: 30),
                    const Text("Data updates every 200ms from ESP32", style: TextStyle(color: Colors.blueGrey, fontSize: 11)),
                  ],
                ),
              );
            },
          ),
        );
      },
    );
  }

  // --- THIS IS THE METHOD THAT WAS REPORTED MISSING ---
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
                Text(title, style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 16, color: Colors.white))
              ]),
              if (isLive) Container(width: 10, height: 10, decoration: BoxDecoration(color: color, shape: BoxShape.circle, boxShadow: [BoxShadow(color: color, blurRadius: 8)]))
            ],
          ),
          const Divider(height: 35, thickness: 1, color: Colors.white10),
          ...stats.map((s) => Padding(
            padding: const EdgeInsets.symmetric(vertical: 6.0),
            child: Text(s, style: const TextStyle(fontSize: 15, fontFamily: 'monospace', fontWeight: FontWeight.w600, letterSpacing: 0.5, color: Colors.white70)),
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
            backgroundColor: AppTheme.kGlassBase,
            title: const Text('Update Available', style: TextStyle(color: Colors.white)),
            content: Text(
              'Device: v${current ?? "?"}\nLatest: v${DeviceService.latestFirmwareVersion}',
              style: const TextStyle(color: Colors.white70),
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
        backgroundColor: AppTheme.kGlassBase,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20), side: BorderSide(color: Colors.white.withOpacity(0.1))),
        title: const Column(
          children: [
            Icon(Icons.check_circle_outline, color: Colors.greenAccent, size: 60),
            SizedBox(height: 15),
            Text('System Up to Date', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
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
      backgroundColor: AppTheme.kDarkSlate,
      appBar: AppBar(
        title: const Text("Device Manager", style: TextStyle(fontWeight: FontWeight.bold, color: Colors.white)),
        centerTitle: true,
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(icon: const Icon(Icons.arrow_back_ios_new_rounded, color: Colors.white), onPressed: () => Navigator.pop(context)),
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
              _actionTile(
                title: 'Firmware Update',
                subtitle: 'Check for hardware patches',
                icon: Icons.system_update_alt_rounded,
                trailing: _isCheckingUpdate ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(strokeWidth: 2, color: AppTheme.kPrimaryCyan)) : null,
                onTap: _isCheckingUpdate || !isPaired ? null : () => _checkFirmware(serial),
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
                Text(title, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 18, color: Colors.white)),
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
        title: Text(title, style: const TextStyle(fontWeight: FontWeight.w600, color: Colors.white)),
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
        Text(value, style: const TextStyle(fontWeight: FontWeight.bold, color: Colors.white)),
      ],
    ),
  );

  void _showPairingDialog() {
    final sCtrl = TextEditingController();
    final pCtrl = TextEditingController();
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: AppTheme.kGlassBase,
        title: const Text("Pair Device", style: TextStyle(color: Colors.white)),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(controller: sCtrl, style: const TextStyle(color: Colors.white), decoration: const InputDecoration(labelText: "Serial Number", labelStyle: TextStyle(color: Colors.blueGrey))),
            TextField(controller: pCtrl, style: const TextStyle(color: Colors.white), decoration: const InputDecoration(labelText: "PIN", labelStyle: TextStyle(color: Colors.blueGrey)), keyboardType: TextInputType.number),
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
        placeholder: Container(color: AppTheme.kGlassBase),
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
      backgroundColor: AppTheme.kDarkSlate,
      appBar: AppBar(
        title: const Text("System Architecture", style: TextStyle(fontWeight: FontWeight.w900, letterSpacing: 0.5, color: Colors.white)),
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
                color: AppTheme.kGlassBase.withOpacity(0.5),
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
        const Text("Watch: Initial Hardware Setup", style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14, color: Colors.white)),
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
          const Text("Could not load tutorial video", style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
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
          title: Text(title, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15, color: Colors.white)),
          subtitle: Text(subtitle, style: TextStyle(color: Colors.blueGrey.shade300, fontSize: 12)),
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 0, 20, 20),
              child: Text(description, style: TextStyle(color: Colors.blueGrey.shade300, fontSize: 13, height: 1.5)),
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

  final Color primaryBlue = const Color(0xFF64B5F6);
  final Color darkBlue = const Color(0xFF1A237E);

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
      backgroundColor: Colors.white,
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
      backgroundColor: AppTheme.kDarkSlate,
      appBar: AppBar(
        title: const Text("Permissions Manager", style: TextStyle(fontWeight: FontWeight.bold, color: Colors.white)),
        centerTitle: true,
        elevation: 0,
        backgroundColor: Colors.transparent,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new_rounded, color: Colors.white, size: 20),
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
                const Divider(height: 1, color: Colors.white10),
                _buildPermissionTile(
                  icon: Icons.sms_rounded,
                  title: "Send SMS",
                  subtitle: "Required to notify contacts.",
                  permission: OnAlertPermission.sms,
                ),
                const Divider(height: 1, color: Colors.white10),
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
      title: Text(title, style: const TextStyle(fontWeight: FontWeight.bold, color: Colors.white)),
      subtitle: Text(subtitle, style: TextStyle(color: Colors.blueGrey.shade300, fontSize: 12)),
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
            backgroundColor: AppTheme.kGlassBase,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20), side: BorderSide(color: Colors.white.withOpacity(0.1))),
            title: Row(children: [
              Icon(
                results.every((r) => r.passed) ? Icons.check_circle : Icons.warning,
                color: results.every((r) => r.passed) ? Colors.greenAccent : Colors.orangeAccent,
              ),
              const SizedBox(width: 10),
              const Text('Diagnostic Results', style: TextStyle(color: Colors.white)),
            ]),
            content: SingleChildScrollView(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: results
                    .map((r) => Padding(
                          padding: const EdgeInsets.symmetric(vertical: 4),
                          child: Text('${r.passed ? "✓" : "✗"} ${r.label}: ${r.detail}',
                              style: const TextStyle(color: Colors.white70)),
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
    if (serial.isEmpty) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('No paired device')));
      }
      return;
    }
    try {
      final ms = await DeviceService.measureSignalLatency(serial);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('RTDB latency: ${ms}ms'), backgroundColor: Colors.green));
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
      backgroundColor: AppTheme.kDarkSlate,
      appBar: AppBar(
        title: const Text("System Testing", style: TextStyle(fontWeight: FontWeight.bold, color: Colors.white)),
        centerTitle: true,
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(icon: const Icon(Icons.arrow_back_ios_new_rounded, color: Colors.white), onPressed: () => Navigator.pop(context)),
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
              subtitle: "Ping the ESP32 module to check latency.",
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
        title: Text(title, style: const TextStyle(fontWeight: FontWeight.bold, color: Colors.white)),
        subtitle: Text(subtitle, style: TextStyle(color: Colors.blueGrey.shade300, fontSize: 12)),
        trailing: trailing ?? const Icon(Icons.chevron_right, size: 20, color: Colors.blueGrey),
        onTap: onTap,
      ),
    );
  }
}