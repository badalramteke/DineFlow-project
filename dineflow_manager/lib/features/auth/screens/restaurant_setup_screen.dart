import 'dart:io';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:image_picker/image_picker.dart';
import '../../../core/theme/theme.dart';
import '../../../core/services/imgbb_service.dart';
import '../../dashboard/screens/dashboard_screen.dart';

class RestaurantSetupScreen extends StatefulWidget {
  const RestaurantSetupScreen({super.key});

  @override
  State<RestaurantSetupScreen> createState() => _RestaurantSetupScreenState();
}

class _RestaurantSetupScreenState extends State<RestaurantSetupScreen> {
  final _formKey = GlobalKey<FormState>();

  // Controllers
  final _nameController = TextEditingController();
  final _taglineController = TextEditingController();
  final _phoneController = TextEditingController();
  final _addressController = TextEditingController();
  final _cityZipController = TextEditingController();
  final _cuisineController = TextEditingController();
  final _tablesController = TextEditingController();
  final _serviceChargeController = TextEditingController();
  final _currencyController = TextEditingController(text: "₹");

  // Time
  TimeOfDay _openingTime = const TimeOfDay(hour: 9, minute: 0);
  TimeOfDay _closingTime = const TimeOfDay(hour: 22, minute: 0);

  File? _logoFile;
  bool _isLoading = false;

  Future<void> _pickImage() async {
    final picker = ImagePicker();
    final pickedFile = await picker.pickImage(source: ImageSource.gallery);

    if (pickedFile != null) {
      setState(() {
        _logoFile = File(pickedFile.path);
      });
    }
  }

  Future<void> _selectTime(BuildContext context, bool isOpening) async {
    final TimeOfDay? picked = await showTimePicker(
      context: context,
      initialTime: isOpening ? _openingTime : _closingTime,
      builder: (context, child) {
        return Theme(
          data: ThemeData.dark().copyWith(
            colorScheme: const ColorScheme.dark(
              primary: AppTheme.accentGreen,
              onPrimary: Colors.white,
              surface: Color(0xFF1C1C1E),
              onSurface: Colors.white,
            ),
          ),
          child: child!,
        );
      },
    );
    if (picked != null) {
      setState(() {
        if (isOpening) {
          _openingTime = picked;
        } else {
          _closingTime = picked;
        }
      });
    }
  }

  Future<String> _uploadLogo(String restaurantId) async {
    if (_logoFile == null) return "";
    try {
      final url = await ImgBBService.uploadImage(_logoFile!);
      return url ?? "";
    } catch (e) {
      debugPrint("Error uploading logo: $e");
      return "";
    }
  }

  Future<void> _completeSetup() async {
    if (_formKey.currentState!.validate()) {
      setState(() {
        _isLoading = true;
      });

      try {
        final user = FirebaseAuth.instance.currentUser;
        if (user == null) throw Exception("No user logged in");

        // 1. Generate Auto ID
        final restaurantRef = FirebaseFirestore.instance
            .collection('restaurants')
            .doc();
        final String newRestaurantId = restaurantRef.id;

        // 2. Upload Logo
        String logoUrl = await _uploadLogo(newRestaurantId);

        // 3. Create Restaurant Document
        await restaurantRef.set({
          'restaurantId': newRestaurantId,
          'ownerId': user.uid,
          'name': _nameController.text.trim(),
          'tagline': _taglineController.text.trim(),
          'phone': _phoneController.text.trim(),
          'address': _addressController.text.trim(),
          'cityZip': _cityZipController.text.trim(),
          'cuisineType': _cuisineController.text.trim(),
          'totalTables': int.tryParse(_tablesController.text) ?? 0,
          'openingTime': '${_openingTime.hour}:${_openingTime.minute}',
          'closingTime': '${_closingTime.hour}:${_closingTime.minute}',
          'serviceCharge':
              double.tryParse(_serviceChargeController.text) ?? 0.0,
          'currencySymbol': _currencyController.text.trim(),
          'logoUrl': logoUrl,
          'createdAt': FieldValue.serverTimestamp(),
        });

        // 4. Link to User
        await FirebaseFirestore.instance
            .collection('users')
            .doc(user.uid)
            .update({'restaurantID': newRestaurantId, 'profilePic': logoUrl});

        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text("Setup Completed Successfully!")),
          );

          Navigator.pushReplacement(
            context,
            MaterialPageRoute(
              builder: (context) =>
                  DashboardScreen(restaurantName: _nameController.text),
            ),
          );
        }
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(
            context,
          ).showSnackBar(SnackBar(content: Text("Error: $e")));
        }
      } finally {
        if (mounted) {
          setState(() {
            _isLoading = false;
          });
        }
      }
    }
  }

  @override
  void dispose() {
    _nameController.dispose();
    _taglineController.dispose();
    _phoneController.dispose();
    _addressController.dispose();
    _cityZipController.dispose();
    _cuisineController.dispose();
    _tablesController.dispose();
    _serviceChargeController.dispose();
    _currencyController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        title: Text(
          "Setup Restaurant",
          style: GoogleFonts.poppins(
            color: Colors.white,
            fontWeight: FontWeight.bold,
          ),
        ),
        centerTitle: true,
      ),
      body: _isLoading
          ? const Center(
              child: CircularProgressIndicator(color: AppTheme.accentGreen),
            )
          : SingleChildScrollView(
              padding: const EdgeInsets.all(AppTheme.outerPadding),
              child: Form(
                key: _formKey,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Logo Upload
                    Center(
                      child: GestureDetector(
                        onTap: _pickImage,
                        child: Container(
                          width: 120,
                          height: 120,
                          decoration: BoxDecoration(
                            color: const Color(0xFF1C1C1E),
                            shape: BoxShape.circle,
                            border: Border.all(
                              color: AppTheme.accentGreen.withOpacity(0.5),
                              width: 2,
                            ),
                            image: _logoFile != null
                                ? DecorationImage(
                                    image: FileImage(_logoFile!),
                                    fit: BoxFit.cover,
                                  )
                                : null,
                          ),
                          child: _logoFile == null
                              ? const Icon(
                                  Icons.add_a_photo,
                                  color: Colors.white,
                                  size: 30,
                                )
                              : null,
                        ),
                      ),
                    ),
                    const SizedBox(height: 8),
                    Center(
                      child: Text(
                        "Upload Logo",
                        style: GoogleFonts.poppins(
                          color: Colors.white.withOpacity(0.5),
                          fontSize: 12,
                        ),
                      ),
                    ),
                    const SizedBox(height: 30),

                    _buildSectionTitle("Basic Info"),
                    _buildTextField("Restaurant Name", _nameController),
                    const SizedBox(height: 16),
                    _buildTextField(
                      "Tagline / Slogan (Optional)",
                      _taglineController,
                    ),
                    const SizedBox(height: 16),
                    _buildTextField(
                      "Official Phone Number",
                      _phoneController,
                      keyboardType: TextInputType.phone,
                    ),
                    const SizedBox(height: 24),

                    _buildSectionTitle("Location"),
                    _buildTextField(
                      "Full Address",
                      _addressController,
                      maxLines: 3,
                    ),
                    const SizedBox(height: 16),
                    _buildTextField("City / Zip Code", _cityZipController),
                    const SizedBox(height: 24),

                    _buildSectionTitle("Details"),
                    _buildTextField(
                      "Cuisine Type (e.g. Italian)",
                      _cuisineController,
                    ),
                    const SizedBox(height: 16),
                    Row(
                      children: [
                        Expanded(
                          child: _buildTextField(
                            "Total Tables",
                            _tablesController,
                            keyboardType: TextInputType.number,
                          ),
                        ),
                        const SizedBox(width: 16),
                        Expanded(
                          child: _buildTextField(
                            "Service Charge (%)",
                            _serviceChargeController,
                            keyboardType: TextInputType.number,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),
                    _buildTextField("Currency Symbol", _currencyController),
                    const SizedBox(height: 24),

                    _buildSectionTitle("Operating Hours"),
                    Row(
                      children: [
                        Expanded(
                          child: _buildTimePicker(
                            "Opening Time",
                            _openingTime,
                            true,
                          ),
                        ),
                        const SizedBox(width: 16),
                        Expanded(
                          child: _buildTimePicker(
                            "Closing Time",
                            _closingTime,
                            false,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 40),

                    // Complete Button
                    SizedBox(
                      width: double.infinity,
                      height: 50,
                      child: ElevatedButton(
                        onPressed: _isLoading ? null : _completeSetup,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: AppTheme.accentGreen,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                        ),
                        child: Text(
                          "COMPLETE SETUP",
                          style: GoogleFonts.poppins(
                            color: Colors.white,
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(height: 40),
                  ],
                ),
              ),
            ),
    );
  }

  Widget _buildSectionTitle(String title) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Text(
        title,
        style: GoogleFonts.poppins(
          color: AppTheme.accentGreen,
          fontSize: 14,
          fontWeight: FontWeight.w600,
          letterSpacing: 1,
        ),
      ),
    );
  }

  Widget _buildTimePicker(String label, TimeOfDay time, bool isOpening) {
    return GestureDetector(
      onTap: () => _selectTime(context, isOpening),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
        decoration: BoxDecoration(
          color: const Color(0xFF1C1C1E),
          borderRadius: BorderRadius.circular(12),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              label,
              style: GoogleFonts.poppins(
                color: Colors.white.withOpacity(0.5),
                fontSize: 12,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              time.format(context),
              style: GoogleFonts.poppins(
                color: Colors.white,
                fontSize: 16,
                fontWeight: FontWeight.w500,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildTextField(
    String label,
    TextEditingController controller, {
    TextInputType keyboardType = TextInputType.text,
    int maxLines = 1,
  }) {
    return Container(
      decoration: BoxDecoration(
        color: const Color(0xFF1C1C1E),
        borderRadius: BorderRadius.circular(12),
      ),
      child: TextFormField(
        controller: controller,
        keyboardType: keyboardType,
        maxLines: maxLines,
        style: GoogleFonts.poppins(color: Colors.white),
        validator: (value) {
          if (value == null || value.isEmpty) {
            return 'Required';
          }
          return null;
        },
        decoration: InputDecoration(
          labelText: label,
          labelStyle: GoogleFonts.poppins(color: Colors.white.withOpacity(0.5)),
          border: InputBorder.none,
          contentPadding: const EdgeInsets.symmetric(
            horizontal: 16,
            vertical: 16,
          ),
        ),
      ),
    );
  }
}
