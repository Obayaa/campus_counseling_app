import 'package:campus_counseling_app/forgot_password_screen.dart';
import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'counselor_dashboard_screen.dart'; // Update with your actual path

class CounselorLoginScreen extends StatefulWidget {
  const CounselorLoginScreen({super.key});

  @override
  State<CounselorLoginScreen> createState() => _CounselorLoginScreenState();
}

class _CounselorLoginScreenState extends State<CounselorLoginScreen> {
  final TextEditingController emailController = TextEditingController();
  final TextEditingController passwordController = TextEditingController();

  bool isPasswordVisible = false;
  bool isLoading = false;

  final FirebaseAuth _auth = FirebaseAuth.instance;

  void _login() async {
    setState(() => isLoading = true);

    try {
      await _auth.signInWithEmailAndPassword(
        email: emailController.text.trim(),
        password: passwordController.text.trim(),
      );

      // ✅ Navigate to dashboard if login is successful
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(
          builder: (context) => const CounselorDashboardScreen(),
        ),
      );
    } on FirebaseAuthException catch (e) {
      String errorMsg = 'Login failed. Please try again.';
      if (e.code == 'user-not-found')
        errorMsg = 'No user found with this email.';
      if (e.code == 'wrong-password')
        errorMsg = 'Wrong password. Please try again.';

      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text(errorMsg)));
    } catch (e) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text("Something went wrong.")));
    } finally {
      setState(() => isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: Stack(
          children: [
            Column(
              children: [
                Stack(
                  children: [
                    Image.asset(
                      'assets/images/onboarding1.png',
                      width: double.infinity,
                      height: 250,
                      fit: BoxFit.cover,
                    ),
                    Positioned(
                      top: 16,
                      left: 16,
                      child: IconButton(
                        icon: const Icon(Icons.arrow_back),
                        onPressed: () => Navigator.pop(context),
                      ),
                    ),
                    const Positioned(
                      bottom: 30,
                      left: 20,
                      child: Text(
                        'Get Support when You Need\nAcademic Counseling',
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ],
                ),
                Expanded(
                  child: SingleChildScrollView(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 24,
                      vertical: 16,
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          "Email",
                          style: TextStyle(fontWeight: FontWeight.bold),
                        ),
                        const SizedBox(height: 8),
                        TextField(
                          controller: emailController,
                          decoration: InputDecoration(
                            hintText: 'MichealAgyapong@pentvars.edu.gh',
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(10),
                            ),
                          ),
                        ),
                        const SizedBox(height: 16),
                        const Text(
                          "Password",
                          style: TextStyle(fontWeight: FontWeight.bold),
                        ),
                        const SizedBox(height: 8),
                        TextField(
                          controller: passwordController,
                          obscureText: !isPasswordVisible,
                          decoration: InputDecoration(
                            hintText: 'Enter your password',
                            suffixIcon: IconButton(
                              icon: Icon(
                                isPasswordVisible
                                    ? Icons.visibility_off
                                    : Icons.visibility,
                              ),
                              onPressed: () {
                                setState(() {
                                  isPasswordVisible = !isPasswordVisible;
                                });
                              },
                            ),
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(10),
                            ),
                          ),
                        ),
                        const SizedBox(height: 8),
                        Align(
                          alignment: Alignment.centerRight,
                          child: TextButton(
                            onPressed: () {
                              Navigator.push(
                                context,
                                MaterialPageRoute(
                                  builder:
                                      (context) => const ForgotPasswordScreen(),
                                ),
                              );
                            },
                            child: const Text("Forgot Password?"),
                          ),
                        ),
                        const SizedBox(height: 16),
                        isLoading
                            ? const Center(child: CircularProgressIndicator())
                            : SizedBox(
                              width: double.infinity,
                              height: 50,
                              child: ElevatedButton(
                                onPressed: _login,
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: Colors.blue,
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(10),
                                  ),
                                ),
                                child: const Text(
                                  "Login",
                                  style: TextStyle(fontSize: 16),
                                ),
                              ),
                            ),
                        const SizedBox(height: 16),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            const Text("Don't have an Account?"),
                            TextButton(
                              onPressed: () {
                                Navigator.pushNamed(
                                  context,
                                  '/counselor_signup',
                                );
                              },
                              child: const Text("Sign-up"),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
