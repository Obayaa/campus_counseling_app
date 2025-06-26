import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'counselor_login_screen.dart';
import 'counselor_dashboard_screen.dart';

class RoleSelectionScreen extends StatefulWidget {
  const RoleSelectionScreen({super.key});

  @override
  State<RoleSelectionScreen> createState() => _RoleSelectionScreenState();
}

class _RoleSelectionScreenState extends State<RoleSelectionScreen> {
  final PageController _pageController = PageController();
  int _currentIndex = 0;
  bool _isLoading = false;

  final List<String> imagePaths = [
    'assets/images/onboarding1.png',
    'assets/images/onboarding2.png',
    'assets/images/onboarding3.png',
  ];

  void _nextPage() {
    if (_currentIndex < imagePaths.length - 1) {
      _pageController.nextPage(
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeInOut,
      );
    }
  }

  Future<void> _signInAnonymously() async {
    setState(() => _isLoading = true);

    try {
      await FirebaseAuth.instance.signInAnonymously();

      if (!mounted) return; // ✅ Context-safe check

      Navigator.pushReplacementNamed(context, '/welcome');
    } catch (e) {
      if (!mounted) return;

      setState(() => _isLoading = false);
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text("Login failed: $e")));
    }
  }

  void _prevPage() {
    if (_currentIndex > 0) {
      _pageController.previousPage(
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeInOut,
      );
    }
  }

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  void _onCounselorPressed() async {
    final bool signedIn =
        await Navigator.push(
          context,
          MaterialPageRoute(builder: (_) => const CounselorLoginScreen()),
        ) ??
        false;

    if (signedIn) {
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (_) => const CounselorDashboardScreen()),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: Column(
          children: [
            // Image slider
            Expanded(
              flex: 6,
              child: Stack(
                children: [
                  PageView.builder(
                    controller: _pageController,
                    onPageChanged: (index) {
                      setState(() {
                        _currentIndex = index;
                      });
                    },
                    itemCount: imagePaths.length,
                    itemBuilder: (context, index) {
                      return Image.asset(
                        imagePaths[index],
                        fit: BoxFit.cover,
                        width: double.infinity,
                      );
                    },
                  ),
                  Positioned(
                    right: 16,
                    top: 120,
                    child: GestureDetector(
                      onTap: _nextPage,
                      child: const CircleAvatar(
                        backgroundColor: Colors.white,
                        child: Icon(
                          Icons.arrow_forward_ios,
                          size: 18,
                          color: Colors.black,
                        ),
                      ),
                    ),
                  ),
                  Positioned(
                    left: 16,
                    top: 120,
                    child: GestureDetector(
                      onTap: _prevPage,
                      child: const CircleAvatar(
                        backgroundColor: Colors.white,
                        child: Icon(
                          Icons.arrow_back_ios,
                          size: 18,
                          color: Colors.black,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),

            // Role selection panel
            Expanded(
              flex: 4,
              child: Container(
                padding: const EdgeInsets.all(24),
                decoration: const BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.vertical(top: Radius.circular(32)),
                ),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    // Page indicators
                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: List.generate(
                        imagePaths.length,
                        (index) => AnimatedContainer(
                          duration: const Duration(milliseconds: 300),
                          margin: const EdgeInsets.symmetric(horizontal: 4),
                          height: 8,
                          width: _currentIndex == index ? 24 : 8,
                          decoration: BoxDecoration(
                            color:
                                _currentIndex == index
                                    ? Colors.blue
                                    : Colors.grey[300],
                            borderRadius: BorderRadius.circular(8),
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(height: 24),
                    const Text(
                      'Sign In As',
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        fontSize: 22,
                        fontWeight: FontWeight.bold,
                        color: Colors.black87,
                      ),
                    ),
                    const SizedBox(height: 32),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                      children: [
                        ElevatedButton.icon(
                          onPressed: _onCounselorPressed,
                          icon: const Icon(Icons.person),
                          label: const Text("Counselor"),
                          style: ElevatedButton.styleFrom(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 20,
                              vertical: 14,
                            ),
                          ),
                        ),
                        ElevatedButton.icon(
                          onPressed: _signInAnonymously,
                          icon: const Icon(Icons.school),
                          label: const Text("Student"),
                          style: ElevatedButton.styleFrom(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 20,
                              vertical: 14,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
