import 'dart:convert';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'dart:io';

class CounselorProfileScreen extends StatefulWidget {
  const CounselorProfileScreen({super.key});

  @override
  State<CounselorProfileScreen> createState() => _CounselorProfileScreenState();
}

class _CounselorProfileScreenState extends State<CounselorProfileScreen> {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final _formKey = GlobalKey<FormState>();

  File? _selectedImage;
  bool _isUploading = false;
  bool _isEditing = false;
  bool _isUpdating = false;

  // Controllers for editable fields
  late TextEditingController _fullNameController;
  late TextEditingController _phoneController;
  late TextEditingController _specializationController;

  @override
  void initState() {
    super.initState();
    _fullNameController = TextEditingController();
    _phoneController = TextEditingController();
    _specializationController = TextEditingController();
  }

  @override
  void dispose() {
    _fullNameController.dispose();
    _phoneController.dispose();
    _specializationController.dispose();
    super.dispose();
  }

  final List<String> _specializationOptions = [
    'Academic Counseling',
    'Spiritual Counseling',
    'Mental Health',
  ];

  Future<DocumentSnapshot<Map<String, dynamic>>> _fetchCounselorData() async {
    final userId = _auth.currentUser?.uid;
    if (userId == null) throw Exception('User not logged in');

    return _firestore.collection('counselors').doc(userId).get();
  }

  Future<void> _updateProfileImage(File image) async {
    final userId = _auth.currentUser?.uid;
    if (userId == null) return;

    try {
      // Convert file to base64 and store as string if not using Firebase Storage
      final bytes = await image.readAsBytes();
      final base64Image = base64Encode(bytes);

      await _firestore.collection('counselors').doc(userId).update({
        'profileImageBase64': base64Image,
      });

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Profile image updated successfully!'),
            backgroundColor: Colors.green,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to update profile image: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  Future<void> _updateProfile() async {
    if (!_formKey.currentState!.validate()) return;

    final userId = _auth.currentUser?.uid;
    if (userId == null) return;

    setState(() {
      _isUpdating = true;
    });

    try {
      await _firestore.collection('counselors').doc(userId).update({
        'fullName': _fullNameController.text.trim(),
        'phone': _phoneController.text.trim(),
        'specialization': _specializationController.text.trim(),
      });

      setState(() {
        _isEditing = false;
        _isUpdating = false;
      });

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Profile updated successfully!'),
            backgroundColor: Colors.green,
          ),
        );
      }
    } catch (e) {
      setState(() {
        _isUpdating = false;
      });

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to update profile: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  Future<void> _pickImage() async {
    try {
      final picker = ImagePicker();
      final pickedFile = await picker.pickImage(
        source: ImageSource.gallery,
        maxWidth: 800,
        maxHeight: 800,
        imageQuality: 85,
      );

      if (pickedFile != null) {
        setState(() {
          _selectedImage = File(pickedFile.path);
          _isUploading = true;
        });

        await _updateProfileImage(_selectedImage!);

        setState(() {
          _isUploading = false;
        });
      }
    } catch (e) {
      setState(() {
        _isUploading = false;
      });

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to pick image: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  Widget _buildProfileImage(Map<String, dynamic> data) {
    final profileImageBase64 = data['profileImageBase64'];

    if (_selectedImage != null) {
      return CircleAvatar(
        radius: 60,
        backgroundImage: FileImage(_selectedImage!),
      );
    } else if (profileImageBase64 != null && profileImageBase64 != '') {
      return CircleAvatar(
        radius: 60,
        backgroundImage: MemoryImage(base64Decode(profileImageBase64)),
      );
    } else {
      // Use user icon when no image is present
      return CircleAvatar(
        radius: 60,
        backgroundColor: Colors.blue.shade100,
        child: Icon(Icons.person, size: 60, color: Colors.blue.shade400),
      );
    }
  }

  Widget _buildEditableField({
    required TextEditingController controller,
    required String label,
    required IconData icon,
    Color? iconColor,
    TextInputType? keyboardType,
    String? Function(String?)? validator,
  }) {
    return Card(
      elevation: 2,
      margin: const EdgeInsets.symmetric(vertical: 4),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Row(
          children: [
            CircleAvatar(
              backgroundColor: (iconColor ?? Colors.blue).withOpacity(0.1),
              child: Icon(icon, color: iconColor ?? Colors.blue),
            ),
            const SizedBox(width: 16),
            Expanded(
              child:
                  _isEditing
                      ? TextFormField(
                        controller: controller,
                        decoration: InputDecoration(
                          labelText: label,
                          border: const OutlineInputBorder(),
                          isDense: true,
                        ),
                        keyboardType: keyboardType,
                        validator: validator,
                      )
                      : Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            label,
                            style: const TextStyle(
                              fontWeight: FontWeight.w500,
                              fontSize: 14,
                              color: Colors.grey,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            controller.text.isEmpty ? 'N/A' : controller.text,
                            style: const TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ],
                      ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildNonEditableField({
    required IconData icon,
    required String title,
    required String value,
    Color? iconColor,
  }) {
    return Card(
      elevation: 2,
      margin: const EdgeInsets.symmetric(vertical: 4),
      child: ListTile(
        leading: CircleAvatar(
          backgroundColor: (iconColor ?? Colors.blue).withOpacity(0.1),
          child: Icon(icon, color: iconColor ?? Colors.blue),
        ),
        title: Text(
          title,
          style: const TextStyle(fontWeight: FontWeight.w500, fontSize: 14),
        ),
        subtitle: Text(
          value,
          style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey.shade50,
      appBar: AppBar(
        title: const Text("My Profile"),
        backgroundColor: Colors.blue,
        foregroundColor: Colors.white,
        elevation: 0,
        actions: [
          if (!_isEditing)
            IconButton(
              icon: const Icon(Icons.edit),
              onPressed: () {
                setState(() {
                  _isEditing = true;
                });
              },
            ),
        ],
      ),
      body: FutureBuilder<DocumentSnapshot<Map<String, dynamic>>>(
        future: _fetchCounselorData(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  CircularProgressIndicator(),
                  SizedBox(height: 16),
                  Text('Loading profile...'),
                ],
              ),
            );
          }

          if (snapshot.hasError) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(Icons.error_outline, size: 64, color: Colors.red),
                  const SizedBox(height: 16),
                  Text(
                    'Error loading profile: ${snapshot.error}',
                    textAlign: TextAlign.center,
                  ),
                ],
              ),
            );
          }

          if (!snapshot.hasData || !snapshot.data!.exists) {
            return const Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.person_off_outlined, size: 64, color: Colors.grey),
                  SizedBox(height: 16),
                  Text("Profile data not found."),
                ],
              ),
            );
          }

          final data = snapshot.data!.data()!;
          final fullName = data['fullName'] ?? '';
          final email = data['email'] ?? '';
          final phone = data['phone'] ?? '';
          final specialization = data['specialization'] ?? '';

          // Update controllers with current data
          if (_fullNameController.text.isEmpty) {
            _fullNameController.text = fullName;
          }
          if (_phoneController.text.isEmpty) {
            _phoneController.text = phone;
          }
          if (_specializationController.text.isEmpty) {
            _specializationController.text = specialization;
          }

          return Form(
            key: _formKey,
            child: SingleChildScrollView(
              child: Column(
                children: [
                  // Header section with gradient background
                  Container(
                    width: double.infinity,
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        begin: Alignment.topCenter,
                        end: Alignment.bottomCenter,
                        colors: [Colors.blue, Colors.blue.shade400],
                      ),
                    ),
                    child: Column(
                      children: [
                        const SizedBox(height: 20),
                        Stack(
                          alignment: Alignment.bottomRight,
                          children: [
                            _buildProfileImage(data),
                            if (_isUploading)
                              Positioned.fill(
                                child: Container(
                                  decoration: BoxDecoration(
                                    color: Colors.black.withOpacity(0.5),
                                    shape: BoxShape.circle,
                                  ),
                                  child: const Center(
                                    child: CircularProgressIndicator(
                                      color: Colors.white,
                                    ),
                                  ),
                                ),
                              )
                            else
                              Container(
                                decoration: const BoxDecoration(
                                  color: Colors.white,
                                  shape: BoxShape.circle,
                                ),
                                child: IconButton(
                                  icon: const Icon(
                                    Icons.camera_alt,
                                    color: Colors.blue,
                                    size: 20,
                                  ),
                                  onPressed: _pickImage,
                                ),
                              ),
                          ],
                        ),
                        const SizedBox(height: 16),
                        Text(
                          fullName.isEmpty ? 'N/A' : fullName,
                          style: const TextStyle(
                            fontSize: 24,
                            fontWeight: FontWeight.bold,
                            color: Colors.white,
                          ),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          email.isEmpty ? 'N/A' : email,
                          style: TextStyle(
                            fontSize: 16,
                            color: Colors.white.withOpacity(0.9),
                          ),
                        ),
                        const SizedBox(height: 32),
                      ],
                    ),
                  ),

                  // Profile information section
                  Padding(
                    padding: const EdgeInsets.all(16.0),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            const Text(
                              'Profile Information',
                              style: TextStyle(
                                fontSize: 18,
                                fontWeight: FontWeight.bold,
                                color: Colors.black87,
                              ),
                            ),
                            if (_isEditing)
                              Text(
                                'Edit Mode',
                                style: TextStyle(
                                  fontSize: 14,
                                  color: Colors.blue.shade600,
                                  fontWeight: FontWeight.w500,
                                ),
                              ),
                          ],
                        ),
                        const SizedBox(height: 12),

                        _buildEditableField(
                          controller: _fullNameController,
                          label: 'Full Name',
                          icon: Icons.person,
                          iconColor: Colors.blue,
                          validator: (value) {
                            if (value == null || value.trim().isEmpty) {
                              return 'Full name is required';
                            }
                            return null;
                          },
                        ),

                        _buildNonEditableField(
                          icon: Icons.email,
                          title: 'Email Address',
                          value: email.isEmpty ? 'N/A' : email,
                          iconColor: Colors.orange,
                        ),

                        _buildEditableField(
                          controller: _phoneController,
                          label: 'Phone Number',
                          icon: Icons.phone,
                          iconColor: Colors.green,
                          keyboardType: TextInputType.phone,
                          validator: (value) {
                            if (value == null || value.trim().isEmpty) {
                              return 'Phone number is required';
                            }
                            return null;
                          },
                        ),

                        Card(
                          elevation: 2,
                          margin: const EdgeInsets.symmetric(vertical: 4),
                          child: Padding(
                            padding: const EdgeInsets.all(16),
                            child: Row(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                CircleAvatar(
                                  backgroundColor: Colors.purple.withOpacity(
                                    0.1,
                                  ),
                                  child: const Icon(
                                    Icons.psychology,
                                    color: Colors.purple,
                                  ),
                                ),
                                const SizedBox(width: 16),
                                Expanded(
                                  child:
                                      _isEditing
                                          ? DropdownButtonFormField<String>(
                                            value:
                                                _specializationController
                                                        .text
                                                        .isNotEmpty
                                                    ? _specializationController
                                                        .text
                                                    : null,
                                            decoration: const InputDecoration(
                                              labelText: 'Specialization',
                                              border: OutlineInputBorder(),
                                              isDense: true,
                                            ),
                                            items:
                                                _specializationOptions.map((
                                                  String option,
                                                ) {
                                                  return DropdownMenuItem<
                                                    String
                                                  >(
                                                    value: option,
                                                    child: Text(option),
                                                  );
                                                }).toList(),
                                            onChanged: (String? newValue) {
                                              if (newValue != null) {
                                                _specializationController.text =
                                                    newValue;
                                              }
                                            },
                                            validator: (value) {
                                              if (value == null ||
                                                  value.isEmpty) {
                                                return 'Please select a specialization';
                                              }
                                              return null;
                                            },
                                          )
                                          : Column(
                                            crossAxisAlignment:
                                                CrossAxisAlignment.start,
                                            children: [
                                              const Text(
                                                'Specialization',
                                                style: TextStyle(
                                                  fontWeight: FontWeight.w500,
                                                  fontSize: 14,
                                                  color: Colors.grey,
                                                ),
                                              ),
                                              const SizedBox(height: 4),
                                              Text(
                                                _specializationController
                                                        .text
                                                        .isEmpty
                                                    ? 'N/A'
                                                    : _specializationController
                                                        .text,
                                                style: const TextStyle(
                                                  fontSize: 16,
                                                  fontWeight: FontWeight.w600,
                                                ),
                                              ),
                                            ],
                                          ),
                                ),
                              ],
                            ),
                          ),
                        ),

                        const SizedBox(height: 24),

                        // Action buttons
                        if (_isEditing)
                          Row(
                            children: [
                              Expanded(
                                child: ElevatedButton(
                                  onPressed:
                                      _isUpdating ? null : _updateProfile,
                                  style: ElevatedButton.styleFrom(
                                    backgroundColor: Colors.blue,
                                    foregroundColor: Colors.white,
                                    padding: const EdgeInsets.symmetric(
                                      vertical: 12,
                                    ),
                                  ),
                                  child:
                                      _isUpdating
                                          ? const SizedBox(
                                            height: 20,
                                            width: 20,
                                            child: CircularProgressIndicator(
                                              color: Colors.white,
                                              strokeWidth: 2,
                                            ),
                                          )
                                          : const Text('Save Changes'),
                                ),
                              ),
                              const SizedBox(width: 12),
                              Expanded(
                                child: OutlinedButton(
                                  onPressed:
                                      _isUpdating
                                          ? null
                                          : () {
                                            setState(() {
                                              _isEditing = false;
                                              // Reset controllers to original values
                                              _fullNameController.text =
                                                  fullName;
                                              _phoneController.text = phone;
                                              _specializationController.text =
                                                  specialization;
                                            });
                                          },
                                  style: OutlinedButton.styleFrom(
                                    foregroundColor: Colors.grey,
                                    padding: const EdgeInsets.symmetric(
                                      vertical: 12,
                                    ),
                                  ),
                                  child: const Text('Cancel'),
                                ),
                              ),
                            ],
                          ),

                        const SizedBox(height: 32),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }
}
