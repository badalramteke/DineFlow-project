import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../../core/theme/theme.dart';

class ProfileScreen extends StatelessWidget {
  const ProfileScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final user = FirebaseAuth.instance.currentUser;

    if (user == null) {
      return const Scaffold(
        body: Center(child: Text("Please login to view profile")),
      );
    }

    return Scaffold(
      backgroundColor: AppTheme.backgroundColor,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        title: Text(
          "Profile",
          style: GoogleFonts.poppins(
            color: Colors.white,
            fontWeight: FontWeight.bold,
          ),
        ),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.white),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: StreamBuilder<DocumentSnapshot>(
        stream: FirebaseFirestore.instance
            .collection('users')
            .doc(user.uid)
            .snapshots(),
        builder: (context, userSnapshot) {
          if (userSnapshot.hasError) {
            return Center(child: Text("Error: ${userSnapshot.error}"));
          }

          if (!userSnapshot.hasData) {
            return const Center(child: CircularProgressIndicator());
          }

          final userData = userSnapshot.data!.data() as Map<String, dynamic>?;
          if (userData == null) return const SizedBox();

          final restaurantId = userData['restaurantID'] as String?;

          return SingleChildScrollView(
            padding: const EdgeInsets.all(AppTheme.outerPadding),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Owner Profile Header
                Center(
                  child: Column(
                    children: [
                      CircleAvatar(
                        radius: 50,
                        backgroundColor: AppTheme.cardColor,
                        backgroundImage:
                            userData['profilePic'] != null &&
                                userData['profilePic'].isNotEmpty
                            ? NetworkImage(userData['profilePic'])
                            : null,
                        child:
                            userData['profilePic'] == null ||
                                userData['profilePic'].isEmpty
                            ? const Icon(
                                Icons.person,
                                size: 50,
                                color: Colors.white54,
                              )
                            : null,
                      ),
                      const SizedBox(height: 16),
                      Text(
                        userData['name'] ?? "Owner Name",
                        style: GoogleFonts.poppins(
                          color: Colors.white,
                          fontSize: 24,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      Text(
                        userData['role'] ?? "Owner",
                        style: GoogleFonts.poppins(
                          color: AppTheme.accentGreen,
                          fontSize: 14,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 32),

                _buildSectionTitle("Personal Information"),
                _buildInfoTile("Email", userData['email'] ?? user.email),
                _buildInfoTile("Phone", userData['phone'] ?? "Not set"),

                const SizedBox(height: 32),

                if (restaurantId != null && restaurantId.isNotEmpty)
                  StreamBuilder<DocumentSnapshot>(
                    stream: FirebaseFirestore.instance
                        .collection('restaurants')
                        .doc(restaurantId)
                        .snapshots(),
                    builder: (context, restaurantSnapshot) {
                      if (!restaurantSnapshot.hasData) {
                        return const SizedBox();
                      }
                      final restData =
                          restaurantSnapshot.data!.data()
                              as Map<String, dynamic>?;
                      if (restData == null) return const SizedBox();

                      return Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          _buildSectionTitle("Restaurant Details"),
                          _buildInfoTile("Name", restData['name']),
                          _buildInfoTile("Tagline", restData['tagline']),
                          _buildInfoTile("Address", restData['address']),
                          _buildInfoTile("City/Zip", restData['cityZip']),
                          _buildInfoTile("Phone", restData['phone']),
                          _buildInfoTile("Cuisine", restData['cuisineType']),
                          _buildInfoTile(
                            "Tables",
                            restData['totalTables'].toString(),
                          ),
                          _buildInfoTile(
                            "Hours",
                            "${restData['openingTime']} - ${restData['closingTime']}",
                          ),
                        ],
                      );
                    },
                  ),
              ],
            ),
          );
        },
      ),
    );
  }

  Widget _buildSectionTitle(String title) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: Text(
        title,
        style: GoogleFonts.poppins(
          color: Colors.white.withOpacity(0.7),
          fontSize: 14,
          fontWeight: FontWeight.w600,
          letterSpacing: 1,
        ),
      ),
    );
  }

  Widget _buildInfoTile(String label, String? value) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppTheme.cardColor,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.white.withOpacity(0.05)),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 100,
            child: Text(
              label,
              style: GoogleFonts.poppins(
                color: Colors.white.withOpacity(0.5),
                fontSize: 14,
              ),
            ),
          ),
          Expanded(
            child: Text(
              value ?? "N/A",
              style: GoogleFonts.poppins(
                color: Colors.white,
                fontSize: 14,
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
