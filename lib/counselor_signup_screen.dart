import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'counselor_login_screen.dart';

class CounselorSignupScreen extends StatefulWidget {
  const CounselorSignupScreen({super.key});

  @override
  State<CounselorSignupScreen> createState() => _CounselorSignupScreenState();
}

class _CounselorSignupScreenState extends State<CounselorSignupScreen> {
  final PageController _pageController = PageController();
  int _currentIndex = 0;

  // Form controllers
  final TextEditingController _firstNameController = TextEditingController();
  final TextEditingController _lastNameController = TextEditingController();
  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();
  final TextEditingController _phoneController = TextEditingController();
  final TextEditingController _specializationController =
      TextEditingController();

  final _formKey = GlobalKey<FormState>();
  bool _isLoading = false;

  final List<String> _slideImages = [
    'assets/images/counsel1.jpg',
    'assets/images/counsel2.jpg',
    'assets/images/counsel3.png',
  ];

  final List<String> _slideTexts = [
    "Get Support when You Need\nAcademic Counseling",
    "We Listen, Support, and Guide\nYou Through School Life",
    "Speak Freely, Feel Better\nWe're Here for You",
  ];

  void _nextSlide() {
    setState(() {
      _currentIndex = (_currentIndex + 1) % _slideImages.length;
      _pageController.animateToPage(
        _currentIndex,
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeInOut,
      );
    });
  }

  // Helper function to extract name from email (fallback option)
  Map<String, String> _extractNameFromEmail(String email) {
    final namePart = email.split('@')[0];
    final nameParts = namePart.split('.');

    if (nameParts.length >= 2) {
      return {
        'firstName': _capitalize(nameParts[0]),
        'lastName': _capitalize(nameParts[1]),
      };
    } else {
      return {'firstName': _capitalize(namePart), 'lastName': ''};
    }
  }

  String _capitalize(String text) {
    if (text.isEmpty) return text;
    return text[0].toUpperCase() + text.substring(1).toLowerCase();
  }

  Future<void> _createCounselorProfile(String userId) async {
    try {
      // Get name from form fields or extract from email as fallback
      String firstName = _firstNameController.text.trim();
      String lastName = _lastNameController.text.trim();

      // If name fields are empty, try to extract from email
      if (firstName.isEmpty && lastName.isEmpty) {
        final extractedNames = _extractNameFromEmail(
          _emailController.text.trim(),
        );
        firstName = extractedNames['firstName']!;
        lastName = extractedNames['lastName']!;
      }
      bool isProfileComplete() {
        return firstName.trim().isNotEmpty &&
            lastName.trim().isNotEmpty &&
            _emailController.text.trim().isNotEmpty &&
            _phoneController.text.trim().isNotEmpty &&
            _specializationController.text.trim().isNotEmpty;
      }

      await FirebaseFirestore.instance.collection('counselors').doc(userId).set(
        {
          'firstName': firstName,
          'lastName': lastName,
          'fullName': '$firstName $lastName'.trim(),
          'email': _emailController.text.trim(),
          'phone': _phoneController.text.trim(),
          'specialization': _specializationController.text.trim(),
          'isActive': true,
          'createdAt': FieldValue.serverTimestamp(),
          'updatedAt': FieldValue.serverTimestamp(),
          'profileComplete': isProfileComplete(),
          'profileImageUrl': null, // Placeholder for image later
        },
      );
    } catch (e) {
      print('Error creating counselor profile: $e');
      rethrow;
    }
  }

  Future<void> _signup() async {
    if (_formKey.currentState!.validate()) {
      setState(() => _isLoading = true);
      try {
        // Create user account
        final UserCredential userCredential = await FirebaseAuth.instance
            .createUserWithEmailAndPassword(
              email: _emailController.text.trim(),
              password: _passwordController.text.trim(),
            );

        // Create counselor profile in Firestore
        if (userCredential.user != null) {
          await _createCounselorProfile(userCredential.user!.uid);
        }

        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Account created successfully!')),
        );

        Navigator.pushReplacement(
          context,
          MaterialPageRoute(builder: (context) => const CounselorLoginScreen()),
        );
      } on FirebaseAuthException catch (e) {
        print("Firebase Auth Error: ${e.code} - ${e.message}");

        String error = 'Signup failed. Please try again.';
        if (e.code == 'email-already-in-use') {
          error = 'Email is already registered.';
        } else if (e.code == 'weak-password') {
          error = 'Password is too weak.';
        }
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text(error)));
      } catch (e) {
        print("General Error: $e");
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('An error occurred. Please try again.')),
        );
      } finally {
        setState(() => _isLoading = false);
      }
    }
  }

  @override
  void dispose() {
    _pageController.dispose();
    _firstNameController.dispose();
    _lastNameController.dispose();
    _emailController.dispose();
    _passwordController.dispose();
    _phoneController.dispose();
    _specializationController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Column(
        children: [
          // Slideshow
          Expanded(
            flex: 4,
            child: Stack(
              children: [
                PageView.builder(
                  controller: _pageController,
                  itemCount: _slideImages.length,
                  itemBuilder: (context, index) {
                    return Stack(
                      fit: StackFit.expand,
                      children: [
                        Image.asset(_slideImages[index], fit: BoxFit.cover),
                        Container(color: Colors.black45),
                        Center(
                          child: Padding(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 24.0,
                            ),
                            child: Text(
                              _slideTexts[index],
                              style: const TextStyle(
                                color: Colors.white,
                                fontSize: 22,
                                fontWeight: FontWeight.bold,
                                height: 1.4,
                              ),
                              textAlign: TextAlign.center,
                            ),
                          ),
                        ),
                      ],
                    );
                  },
                  onPageChanged:
                      (index) => setState(() => _currentIndex = index),
                ),
                Positioned(
                  right: 16,
                  top: 50,
                  child: IconButton(
                    onPressed: _nextSlide,
                    icon: const Icon(
                      Icons.arrow_forward_ios,
                      color: Colors.white,
                    ),
                  ),
                ),
              ],
            ),
          ),

          // Signup Form
          Expanded(
            flex: 6,
            child: Container(
              padding: const EdgeInsets.all(20),
              decoration: const BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
              ),
              child: SingleChildScrollView(
                child: Form(
                  key: _formKey,
                  child: Column(
                    children: [
                      const Text(
                        "Create Counselor Account",
                        style: TextStyle(
                          fontSize: 24,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 20),

                      // Name fields
                      Row(
                        children: [
                          Expanded(
                            child: TextFormField(
                              controller: _firstNameController,
                              decoration: const InputDecoration(
                                labelText: "First Name",
                                prefixIcon: Icon(Icons.person),
                              ),
                              validator: (value) {
                                // Optional validation - can be empty and extracted from email
                                return null;
                              },
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: TextFormField(
                              controller: _lastNameController,
                              decoration: const InputDecoration(
                                labelText: "Last Name",
                                prefixIcon: Icon(Icons.person_outline),
                              ),
                              validator: (value) {
                                // Optional validation
                                return null;
                              },
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 16),

                      // Email
                      TextFormField(
                        controller: _emailController,
                        decoration: const InputDecoration(
                          labelText: "Email",
                          prefixIcon: Icon(Icons.email),
                        ),
                        validator: (value) {
                          if (value == null || value.isEmpty) {
                            return 'Enter your email';
                          }
                          if (!value.contains('@')) {
                            return 'Enter a valid email';
                          }
                          return null;
                        },
                      ),
                      const SizedBox(height: 16),

                      // Phone (optional)
                      TextFormField(
                        controller: _phoneController,
                        decoration: const InputDecoration(
                          labelText: "Phone (Optional)",
                          prefixIcon: Icon(Icons.phone),
                        ),
                        keyboardType: TextInputType.phone,
                        validator: (value) {
                          // Optional field, can be empty
                          if (value != null && value.isNotEmpty) {
                            final phonePattern = RegExp(r'^\+?[0-9]{10,15}$');
                            if (!phonePattern.hasMatch(value)) {
                              return 'Enter a valid phone number';
                            }
                          }
                          return null;
                        },
                      ),
                      const SizedBox(height: 16),

                      // Specialization
                      TextFormField(
                        controller: _specializationController,
                        decoration: const InputDecoration(
                          labelText: "Specialization",
                          prefixIcon: Icon(Icons.school),
                          hintText:
                              "e.g., Academic Counseling, Career Guidance",
                        ),
                        validator: (value) {
                          if (value == null || value.isEmpty) {
                            return 'Enter your specialization';
                          }
                          return null;
                        },
                      ),

                      const SizedBox(height: 16),

                      // Password
                      TextFormField(
                        controller: _passwordController,
                        obscureText: true,
                        decoration: const InputDecoration(
                          labelText: "Password",
                          prefixIcon: Icon(Icons.lock),
                        ),
                        validator: (value) {
                          if (value == null || value.length < 6) {
                            return 'Password must be at least 6 characters';
                          }
                          return null;
                        },
                      ),
                      const SizedBox(height: 24),

                      // Sign up button
                      ElevatedButton(
                        onPressed: _isLoading ? null : _signup,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.blue.shade700,
                          padding: const EdgeInsets.symmetric(vertical: 14),
                          minimumSize: const Size(double.infinity, 48),
                        ),
                        child:
                            _isLoading
                                ? const CircularProgressIndicator(
                                  color: Colors.white,
                                )
                                : const Text(
                                  "Create Account",
                                  style: TextStyle(
                                    fontSize: 16,
                                    color: Colors.white,
                                  ),
                                ),
                      ),
                      const SizedBox(height: 16),

                      // Login link
                      Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          const Text("Already have an account? "),
                          GestureDetector(
                            onTap: () {
                              Navigator.pushReplacement(
                                context,
                                MaterialPageRoute(
                                  builder: (_) => const CounselorLoginScreen(),
                                ),
                              );
                            },
                            child: const Text(
                              "Sign In",
                              style: TextStyle(
                                color: Colors.blue,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 20),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
