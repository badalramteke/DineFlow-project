import 'dart:io';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:image_picker/image_picker.dart';
import '../../../core/theme/theme.dart';
import '../../../core/services/imgbb_service.dart';

class AddMenuItemScreen extends StatefulWidget {
  const AddMenuItemScreen({super.key});

  @override
  State<AddMenuItemScreen> createState() => _AddMenuItemScreenState();
}

class _AddMenuItemScreenState extends State<AddMenuItemScreen> {
  final _formKey = GlobalKey<FormState>();

  // Controllers
  final _nameController = TextEditingController();
  final _descriptionController = TextEditingController();
  final _priceController = TextEditingController();
  final _prepTimeController = TextEditingController();
  final _portionSizeController = TextEditingController(); // New field

  // State variables
  String _selectedCategory = 'Main Course';
  String _selectedSpiceLevel = 'None'; // Changed to Dropdown
  bool _isVeg = true;
  bool _isAvailable = true;
  File? _imageFile;
  bool _isLoading = false;

  final List<String> _categories = [
    "Starters",
    "Main Course",
    "Breads",
    "Beverages",
    "Desserts",
  ];

  final List<String> _spiceLevels = [
    "None",
    "Mild",
    "Medium",
    "Hot",
    "Extra Hot",
  ];

  Future<void> _pickImage() async {
    final picker = ImagePicker();
    final pickedFile = await picker.pickImage(source: ImageSource.gallery);

    if (pickedFile != null) {
      setState(() {
        _imageFile = File(pickedFile.path);
      });
    }
  }

  Future<String?> _uploadImage(File image) async {
    try {
      return await ImgBBService.uploadImage(image);
    } catch (e) {
      debugPrint("Error uploading image: $e");
      return null;
    }
  }

  Future<void> _saveItem() async {
    if (_formKey.currentState!.validate()) {
      setState(() {
        _isLoading = true;
      });

      try {
        // 1. Get Current User & Restaurant ID
        final user = FirebaseAuth.instance.currentUser;
        if (user == null) throw Exception("User not logged in");

        final userDoc = await FirebaseFirestore.instance
            .collection('users')
            .doc(user.uid)
            .get();

        if (!userDoc.exists) throw Exception("User profile not found");

        final restaurantId = userDoc.data()?['restaurantID'] as String?;
        if (restaurantId == null || restaurantId.isEmpty) {
          throw Exception("Restaurant setup not found");
        }

        // 2. Upload Image
        String imageUrl = '';
        if (_imageFile != null) {
          final url = await _uploadImage(_imageFile!);
          if (url != null) {
            imageUrl = url;
          }
        }

        // 3. Prepare Data
        final itemData = {
          'name': _nameController.text.trim(),
          'description': _descriptionController.text.trim(),
          'price': double.tryParse(_priceController.text) ?? 0,
          'category': _selectedCategory,
          'isVeg': _isVeg,
          'preparationTime': int.tryParse(_prepTimeController.text) ?? 0,
          'spicyLevel': _selectedSpiceLevel,
          'portionSize': _portionSizeController.text.trim(),
          'isAvailable': _isAvailable,
          'imageUrl': imageUrl,
          'createdAt': FieldValue.serverTimestamp(),
        };

        // 4. Save to Subcollection: restaurants/{restaurantId}/menus
        await FirebaseFirestore.instance
            .collection('restaurants')
            .doc(restaurantId)
            .collection('menus')
            .add(itemData);

        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text("Item Added Successfully")),
          );
          Navigator.pop(context);
        }
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(
            context,
          ).showSnackBar(SnackBar(content: Text("Error adding item: $e")));
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
    _descriptionController.dispose();
    _priceController.dispose();
    _prepTimeController.dispose();
    _portionSizeController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.white),
          onPressed: () => Navigator.pop(context),
        ),
        title: Text(
          "Add Menu Item",
          style: GoogleFonts.poppins(
            color: Colors.white,
            fontWeight: FontWeight.bold,
          ),
        ),
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
                    // Image Upload
                    Center(
                      child: GestureDetector(
                        onTap: _pickImage,
                        child: Container(
                          width: double.infinity,
                          height: 200,
                          decoration: BoxDecoration(
                            color: const Color(0xFF1C1C1E),
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(
                              color: Colors.white.withOpacity(0.1),
                            ),
                            image: _imageFile != null
                                ? DecorationImage(
                                    image: FileImage(_imageFile!),
                                    fit: BoxFit.cover,
                                  )
                                : null,
                          ),
                          child: _imageFile == null
                              ? Column(
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  children: [
                                    Icon(
                                      Icons.add_a_photo,
                                      color: Colors.white.withOpacity(0.5),
                                      size: 40,
                                    ),
                                    const SizedBox(height: 8),
                                    Text(
                                      "Tap to upload dish photo",
                                      style: GoogleFonts.poppins(
                                        color: Colors.white.withOpacity(0.5),
                                      ),
                                    ),
                                  ],
                                )
                              : null,
                        ),
                      ),
                    ),
                    const SizedBox(height: 24),

                    // Basic Info
                    _buildSectionTitle("Dish Details"),
                    _buildTextField(
                      "Dish Name",
                      _nameController,
                      maxLength: 30,
                    ),
                    const SizedBox(height: 16),
                    _buildTextField(
                      "Short Description",
                      _descriptionController,
                      maxLines: 3,
                      hint: "Ingredients or taste profile...",
                    ),
                    const SizedBox(height: 16),

                    Row(
                      children: [
                        Expanded(
                          child: _buildTextField(
                            "Price (₹)",
                            _priceController,
                            keyboardType: TextInputType.number,
                          ),
                        ),
                        const SizedBox(width: 16),
                        Expanded(
                          child: _buildTextField(
                            "Prep Time (mins)",
                            _prepTimeController,
                            keyboardType: TextInputType.number,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 24),

                    // Category & Type
                    _buildSectionTitle("Classification"),
                    _buildDropdown("Category", _selectedCategory, _categories, (
                      val,
                    ) {
                      setState(() => _selectedCategory = val!);
                    }),
                    const SizedBox(height: 16),

                    // Veg/Non-Veg Switch
                    Container(
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: const Color(0xFF1C1C1E),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(
                            "Dietary Type",
                            style: GoogleFonts.poppins(color: Colors.white),
                          ),
                          Row(
                            children: [
                              Text(
                                _isVeg ? "Veg" : "Non-Veg",
                                style: GoogleFonts.poppins(
                                  color: _isVeg ? Colors.green : Colors.red,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                              const SizedBox(width: 8),
                              Switch(
                                value: _isVeg,
                                activeColor: Colors.green,
                                inactiveThumbColor: Colors.red,
                                inactiveTrackColor: Colors.red.withOpacity(0.3),
                                onChanged: (val) =>
                                    setState(() => _isVeg = val),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 24),

                    // Details
                    _buildSectionTitle("Additional Info"),
                    _buildDropdown(
                      "Spice Level",
                      _selectedSpiceLevel,
                      _spiceLevels,
                      (val) {
                        setState(() => _selectedSpiceLevel = val!);
                      },
                    ),
                    const SizedBox(height: 16),

                    _buildTextField(
                      "Portion Size",
                      _portionSizeController,
                      hint: "e.g. Regular (Serves 1)",
                    ),
                    const SizedBox(height: 16),

                    // Availability
                    Container(
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: const Color(0xFF1C1C1E),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(
                            "Is Available? (In Stock)",
                            style: GoogleFonts.poppins(color: Colors.white),
                          ),
                          Switch(
                            value: _isAvailable,
                            activeColor: AppTheme.accentGreen,
                            onChanged: (val) =>
                                setState(() => _isAvailable = val),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 40),

                    // Save Button
                    SizedBox(
                      width: double.infinity,
                      height: 50,
                      child: ElevatedButton(
                        onPressed: _saveItem,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: AppTheme.accentGreen,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                        ),
                        child: Text(
                          "ADD TO MENU",
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

  Widget _buildDropdown(
    String label,
    String value,
    List<String> items,
    ValueChanged<String?> onChanged,
  ) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
      decoration: BoxDecoration(
        color: const Color(0xFF1C1C1E),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.only(top: 8),
            child: Text(
              label,
              style: GoogleFonts.poppins(
                color: Colors.white.withOpacity(0.5),
                fontSize: 12,
              ),
            ),
          ),
          DropdownButtonHideUnderline(
            child: DropdownButton<String>(
              value: value,
              dropdownColor: const Color(0xFF1C1C1E),
              isExpanded: true,
              style: GoogleFonts.poppins(color: Colors.white),
              items: items.map((String item) {
                return DropdownMenuItem<String>(value: item, child: Text(item));
              }).toList(),
              onChanged: onChanged,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTextField(
    String label,
    TextEditingController controller, {
    TextInputType keyboardType = TextInputType.text,
    int maxLines = 1,
    String? hint,
    int? maxLength,
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
        maxLength: maxLength,
        style: GoogleFonts.poppins(color: Colors.white),
        validator: (value) {
          if (value == null || value.isEmpty) {
            return 'Required';
          }
          return null;
        },
        decoration: InputDecoration(
          labelText: label,
          hintText: hint,
          counterText: "", // Hide character counter
          labelStyle: GoogleFonts.poppins(color: Colors.white.withOpacity(0.5)),
          hintStyle: GoogleFonts.poppins(color: Colors.white.withOpacity(0.3)),
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
