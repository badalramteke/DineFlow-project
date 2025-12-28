import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:fl_chart/fl_chart.dart';
import '../../../core/theme/theme.dart';
import '../../menu/screens/menu_screen.dart';
import '../../orders/screens/orders_screen.dart';
import '../../settings/screens/settings_screen.dart';
import '../../profile/screens/profile_screen.dart';
import '../../notifications/screens/notifications_screen.dart';
import '../widgets/dashboard_widgets.dart';

class DashboardScreen extends StatefulWidget {
  final String? restaurantName;
  const DashboardScreen({super.key, this.restaurantName});

  @override
  State<DashboardScreen> createState() => _DashboardScreenState();
}

class _DashboardScreenState extends State<DashboardScreen> {
  int _navIndex = 0;
  String _moneyRange = '1D';
  String _salesGoalRange = 'Today';
  String _topPerformerRange = 'Today';

  // static const _avatarUrl = 'https://i.pravatar.cc/150?img=5'; // Removed hardcoded URL

  Widget _pillTab({
    required String label,
    required bool active,
    required VoidCallback onTap,
    EdgeInsets padding = const EdgeInsets.symmetric(
      horizontal: 10,
      vertical: 5,
    ),
    double fontSize = 11,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(9),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 160),
        padding: padding,
        decoration: BoxDecoration(
          color: active
              ? AppTheme.accentGreen.withOpacity(0.22)
              : Colors.white.withOpacity(0.06),
          borderRadius: BorderRadius.circular(9),
          border: Border.all(
            color: active
                ? AppTheme.accentGreen.withOpacity(0.45)
                : Colors.white.withOpacity(0.06),
          ),
        ),
        child: Text(
          label,
          style: GoogleFonts.poppins(
            color: active
                ? AppTheme.accentGreen
                : Colors.white.withOpacity(0.65),
            fontSize: fontSize,
            fontWeight: FontWeight.w500,
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.backgroundColor,
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: _navIndex,
        onTap: (i) => setState(() => _navIndex = i),
        backgroundColor: AppTheme.cardColor,
        selectedItemColor: AppTheme.accentGreen,
        unselectedItemColor: Colors.white.withOpacity(0.6),
        type: BottomNavigationBarType.fixed,
        elevation: 0,
        selectedFontSize: 11,
        unselectedFontSize: 11,
        items: const [
          BottomNavigationBarItem(icon: Icon(Icons.home), label: "Home"),
          BottomNavigationBarItem(
            icon: Icon(Icons.receipt_long),
            label: "Orders",
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.restaurant_menu),
            label: "Menu",
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.settings),
            label: "Settings",
          ),
        ],
      ),
      body: SafeArea(
        child: Container(
          decoration: const BoxDecoration(gradient: AppTheme.bgGradient),
          child: Column(
            children: [
              // 1. TOP HEADER
              Padding(
                padding: const EdgeInsets.fromLTRB(
                  AppTheme.outerPadding,
                  AppTheme.outerPadding,
                  AppTheme.outerPadding,
                  0,
                ),
                child: StreamBuilder<DocumentSnapshot>(
                  stream: FirebaseFirestore.instance
                      .collection('users')
                      .doc(FirebaseAuth.instance.currentUser?.uid)
                      .snapshots(),
                  builder: (context, userSnapshot) {
                    String ownerName = "Owner";
                    String restaurantId = "";
                    String? profilePicUrl;

                    if (userSnapshot.hasData && userSnapshot.data!.exists) {
                      final userData =
                          userSnapshot.data!.data() as Map<String, dynamic>;
                      ownerName = userData['name'] ?? "Owner";
                      restaurantId = userData['restaurantID'] ?? "";
                      profilePicUrl = userData['profilePic'];
                    }

                    return Row(
                      children: [
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              if (restaurantId.isNotEmpty)
                                StreamBuilder<DocumentSnapshot>(
                                  stream: FirebaseFirestore.instance
                                      .collection('restaurants')
                                      .doc(restaurantId)
                                      .snapshots(),
                                  builder: (context, restSnapshot) {
                                    String restName =
                                        widget.restaurantName ?? "Grand Bistro";
                                    if (restSnapshot.hasData &&
                                        restSnapshot.data!.exists) {
                                      restName =
                                          restSnapshot.data!['name'] ??
                                          restName;
                                    }
                                    return Text(
                                      restName,
                                      style: GoogleFonts.poppins(
                                        color: Colors.white.withOpacity(0.95),
                                        fontSize: 20,
                                        fontWeight: FontWeight.w600,
                                      ),
                                      overflow: TextOverflow.ellipsis,
                                    );
                                  },
                                )
                              else
                                Text(
                                  widget.restaurantName ?? "Grand Bistro",
                                  style: GoogleFonts.poppins(
                                    color: Colors.white.withOpacity(0.95),
                                    fontSize: 20,
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                              Text(
                                "Hello, $ownerName",
                                style: GoogleFonts.poppins(
                                  color: AppTheme.accentGreen,
                                  fontSize: 12,
                                  fontWeight: FontWeight.w500,
                                ),
                              ),
                            ],
                          ),
                        ),
                        InkWell(
                          onTap: () {
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (context) =>
                                    const NotificationsScreen(),
                              ),
                            );
                          },
                          borderRadius: BorderRadius.circular(10),
                          child: Padding(
                            padding: const EdgeInsets.all(6),
                            child: Icon(
                              Icons.notifications_none,
                              color: Colors.white.withOpacity(0.85),
                              size: 22,
                            ),
                          ),
                        ),
                        const SizedBox(width: 10),
                        InkWell(
                          onTap: () {
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (context) => const ProfileScreen(),
                              ),
                            );
                          },
                          borderRadius: BorderRadius.circular(20),
                          child: CircleAvatar(
                            radius: 16,
                            backgroundColor: Colors.white.withOpacity(0.08),
                            child: ClipOval(
                              child:
                                  profilePicUrl != null &&
                                      profilePicUrl.isNotEmpty
                                  ? Image.network(
                                      profilePicUrl,
                                      width: 32,
                                      height: 32,
                                      fit: BoxFit.cover,
                                      errorBuilder:
                                          (context, error, stackTrace) {
                                            return Icon(
                                              Icons.person,
                                              size: 18,
                                              color: Colors.white.withOpacity(
                                                0.75,
                                              ),
                                            );
                                          },
                                    )
                                  : Icon(
                                      Icons.person,
                                      size: 18,
                                      color: Colors.white.withOpacity(0.75),
                                    ),
                            ),
                          ),
                        ),
                      ],
                    );
                  },
                ),
              ),
              const SizedBox(height: 18),

              // 2. CONTENT
              Expanded(
                child: _navIndex == 0
                    ? _buildDashboardContent()
                    : _navIndex == 1
                    ? const OrdersScreen()
                    : _navIndex == 2
                    ? const MenuScreen()
                    : _navIndex == 3
                    ? const SettingsScreen()
                    : Center(
                        child: Text(
                          "Coming Soon",
                          style: GoogleFonts.poppins(
                            color: Colors.white.withOpacity(0.5),
                          ),
                        ),
                      ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildDashboardContent() {
    final user = FirebaseAuth.instance.currentUser;

    return StreamBuilder<DocumentSnapshot>(
      stream: FirebaseFirestore.instance
          .collection('users')
          .doc(user?.uid)
          .snapshots(),
      builder: (context, userSnapshot) {
        if (!userSnapshot.hasData) {
          return const Center(child: CircularProgressIndicator());
        }

        final restaurantId = userSnapshot.data?.get('restaurantID');
        if (restaurantId == null || restaurantId == '') {
          return const Center(
            child: Text(
              "No Restaurant Linked",
              style: TextStyle(color: Colors.white),
            ),
          );
        }

        return StreamBuilder<QuerySnapshot>(
          stream: FirebaseFirestore.instance
              .collection('restaurants')
              .doc(restaurantId)
              .collection('orders')
              .snapshots(),
          builder: (context, orderSnapshot) {
            if (!orderSnapshot.hasData) {
              return const Center(child: CircularProgressIndicator());
            }

            final orders = orderSnapshot.data!.docs.map((doc) {
              final data = doc.data() as Map<String, dynamic>;
              return {
                'id': doc.id,
                'orderId': data['orderId'] ?? '',
                'grandTotal': (data['grandTotal'] ?? 0).toDouble(),
                'status': data['orderStatus'] ?? 'pending',
                'paymentMethod': data['paymentMethod'] ?? 'Cash',
                'createdAt': data['createdAt'] as Timestamp?,
                'items': data['items'] as List<dynamic>? ?? [],
              };
            }).toList();

            // --- CALCULATIONS ---
            double totalRevenue = 0;
            double cashRevenue = 0;
            double onlineRevenue = 0;
            int totalOrders = orders.length;
            List<Map<String, dynamic>> ongoingOrders = [];
            Map<String, double> itemSales = {};

            // Chart Data
            Map<int, double> dailyRevenue = {};
            DateTime now = DateTime.now();
            for (int i = 0; i < 7; i++) dailyRevenue[i] = 0;

            for (var order in orders) {
              // Revenue
              if (order['status'] == 'completed' ||
                  order['status'] == 'served') {
                // Assuming served orders are paid or will be paid
                // Ideally only 'completed' (paid) orders count for revenue
                if (order['status'] == 'completed') {
                  totalRevenue += order['grandTotal'];
                  if (order['paymentMethod'] == 'Cash') {
                    cashRevenue += order['grandTotal'];
                  } else {
                    onlineRevenue += order['grandTotal'];
                  }

                  // Chart Data Population
                  if (order['createdAt'] != null) {
                    DateTime date = (order['createdAt'] as Timestamp).toDate();
                    int diff = now.difference(date).inDays;
                    if (diff >= 0 && diff < 7) {
                      int index = 6 - diff;
                      dailyRevenue[index] =
                          (dailyRevenue[index] ?? 0) +
                          (order['grandTotal'] as double);
                    }
                  }
                }
              }

              // Ongoing Orders
              if ([
                'pending',
                'cooking',
                'ready',
                'served',
              ].contains((order['status'] as String).toLowerCase())) {
                ongoingOrders.add(order);
              }

              // Top Performers
              if (order['status'] != 'cancelled') {
                for (var item in order['items']) {
                  final name = item['name'];
                  final price = (item['price'] ?? 0).toDouble();
                  final qty = (item['qty'] ?? 1) as int;
                  itemSales[name] = (itemSales[name] ?? 0) + (price * qty);
                }
              }
            }

            // Sort Top Performers
            var sortedItems = itemSales.entries.toList()
              ..sort((a, b) => b.value.compareTo(a.value));
            var topPerformers = sortedItems.take(3).toList();

            // Sort Ongoing Orders by Time
            ongoingOrders.sort((a, b) {
              Timestamp? tA = a['createdAt'];
              Timestamp? tB = b['createdAt'];
              if (tA == null) return 1;
              if (tB == null) return -1;
              return tB.compareTo(tA); // Newest first
            });

            // AOV
            double aov = totalOrders > 0 ? totalRevenue / totalOrders : 0;

            List<FlSpot> spots = [];
            for (int i = 0; i < 7; i++) {
              spots.add(FlSpot(i.toDouble(), dailyRevenue[i] ?? 0));
            }

            return SingleChildScrollView(
              padding: const EdgeInsets.all(AppTheme.outerPadding),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // 1. MONEY ZONE
                  Container(
                    padding: const EdgeInsets.all(20),
                    decoration: BoxDecoration(
                      color: AppTheme.cardColor,
                      borderRadius: BorderRadius.circular(AppTheme.radius),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withOpacity(0.35),
                          blurRadius: 14,
                          offset: const Offset(0, 6),
                        ),
                      ],
                      border: Border.all(color: Colors.white.withOpacity(0.05)),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text(
                              "Money Zone",
                              style: GoogleFonts.poppins(
                                color: Colors.white,
                                fontSize: 16,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                            const SizedBox(width: 10),
                            Expanded(
                              child: SingleChildScrollView(
                                scrollDirection: Axis.horizontal,
                                reverse: true,
                                child: Row(
                                  children: [
                                    _pillTab(
                                      label: "1D",
                                      active: _moneyRange == '1D',
                                      onTap: () =>
                                          setState(() => _moneyRange = '1D'),
                                    ),
                                    const SizedBox(width: 6),
                                    _pillTab(
                                      label: "1W",
                                      active: _moneyRange == '1W',
                                      onTap: () =>
                                          setState(() => _moneyRange = '1W'),
                                    ),
                                    const SizedBox(width: 6),
                                    _pillTab(
                                      label: "1M",
                                      active: _moneyRange == '1M',
                                      onTap: () =>
                                          setState(() => _moneyRange = '1M'),
                                    ),
                                    const SizedBox(width: 6),
                                    _pillTab(
                                      label: "1Y",
                                      active: _moneyRange == '1Y',
                                      onTap: () =>
                                          setState(() => _moneyRange = '1Y'),
                                    ),
                                  ],
                                ),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 20),
                        Text(
                          "Total Revenue",
                          style: GoogleFonts.poppins(
                            color: Colors.white.withOpacity(0.6),
                            fontSize: 12,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          "₹${totalRevenue.toStringAsFixed(2)}",
                          style: GoogleFonts.poppins(
                            color: Colors.white,
                            fontSize: 32,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const SizedBox(height: 20),
                        MoneyZoneChart(spots: spots),
                      ],
                    ),
                  ),
                  const SizedBox(height: 20),

                  // SALES GOALS & QUICK STATS ROW
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Sales Goal
                      Expanded(
                        flex: 5,
                        child: Container(
                          height: 280,
                          padding: const EdgeInsets.all(16),
                          decoration: BoxDecoration(
                            color: AppTheme.cardColor,
                            borderRadius: BorderRadius.circular(
                              AppTheme.radius,
                            ),
                            border: Border.all(
                              color: Colors.white.withOpacity(0.05),
                            ),
                          ),
                          child: Column(
                            children: [
                              Row(
                                mainAxisAlignment:
                                    MainAxisAlignment.spaceBetween,
                                children: [
                                  Text(
                                    "Sales Goals",
                                    style: GoogleFonts.poppins(
                                      color: Colors.white,
                                      fontWeight: FontWeight.w600,
                                      fontSize: 14,
                                    ),
                                  ),
                                ],
                              ),
                              const Spacer(),
                              Stack(
                                alignment: Alignment.center,
                                children: [
                                  SizedBox(
                                    width: 120,
                                    height: 120,
                                    child: CircularProgressIndicator(
                                      value: 0.75,
                                      strokeWidth: 12,
                                      backgroundColor: Colors.white.withOpacity(
                                        0.1,
                                      ),
                                      color: AppTheme.accentGreen,
                                    ),
                                  ),
                                  Column(
                                    mainAxisSize: MainAxisSize.min,
                                    children: [
                                      Text(
                                        "75%",
                                        style: GoogleFonts.poppins(
                                          color: Colors.white,
                                          fontSize: 24,
                                          fontWeight: FontWeight.bold,
                                        ),
                                      ),
                                      Text(
                                        "Achieved",
                                        style: GoogleFonts.poppins(
                                          color: Colors.white.withOpacity(0.7),
                                          fontSize: 10,
                                        ),
                                      ),
                                    ],
                                  ),
                                ],
                              ),
                              const Spacer(),
                              Container(
                                padding: const EdgeInsets.all(4),
                                decoration: BoxDecoration(
                                  color: Colors.white.withOpacity(0.05),
                                  borderRadius: BorderRadius.circular(8),
                                ),
                                child: FittedBox(
                                  fit: BoxFit.scaleDown,
                                  child: Row(
                                    mainAxisAlignment:
                                        MainAxisAlignment.spaceBetween,
                                    children: [
                                      _pillTab(
                                        label: "Today",
                                        active: _salesGoalRange == 'Today',
                                        onTap: () => setState(
                                          () => _salesGoalRange = 'Today',
                                        ),
                                        padding: const EdgeInsets.symmetric(
                                          horizontal: 6,
                                          vertical: 4,
                                        ),
                                        fontSize: 10,
                                      ),
                                      _pillTab(
                                        label: "Weekly",
                                        active: _salesGoalRange == 'Weekly',
                                        onTap: () => setState(
                                          () => _salesGoalRange = 'Weekly',
                                        ),
                                        padding: const EdgeInsets.symmetric(
                                          horizontal: 6,
                                          vertical: 4,
                                        ),
                                        fontSize: 10,
                                      ),
                                      _pillTab(
                                        label: "Yearly",
                                        active: _salesGoalRange == 'Yearly',
                                        onTap: () => setState(
                                          () => _salesGoalRange = 'Yearly',
                                        ),
                                        padding: const EdgeInsets.symmetric(
                                          horizontal: 6,
                                          vertical: 4,
                                        ),
                                        fontSize: 10,
                                      ),
                                    ],
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                      const SizedBox(width: 16),

                      // Quick Stats
                      Expanded(
                        flex: 5,
                        child: Container(
                          height: 280,
                          padding: const EdgeInsets.all(16),
                          decoration: BoxDecoration(
                            color: AppTheme.cardColor,
                            borderRadius: BorderRadius.circular(
                              AppTheme.radius,
                            ),
                            border: Border.all(
                              color: Colors.white.withOpacity(0.05),
                            ),
                          ),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                mainAxisAlignment:
                                    MainAxisAlignment.spaceBetween,
                                children: [
                                  Text(
                                    "Quick Stats",
                                    style: GoogleFonts.poppins(
                                      color: Colors.white,
                                      fontWeight: FontWeight.w600,
                                      fontSize: 14,
                                    ),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 20),
                              Expanded(
                                child: Column(
                                  children: [
                                    Expanded(
                                      child: Row(
                                        children: [
                                          Expanded(
                                            child: Column(
                                              crossAxisAlignment:
                                                  CrossAxisAlignment.start,
                                              mainAxisAlignment:
                                                  MainAxisAlignment.center,
                                              children: [
                                                Text(
                                                  "Orders:",
                                                  style: GoogleFonts.poppins(
                                                    color: Colors.white
                                                        .withOpacity(0.7),
                                                    fontSize: 12,
                                                  ),
                                                ),
                                                const SizedBox(height: 4),
                                                Text(
                                                  "$totalOrders",
                                                  style: GoogleFonts.poppins(
                                                    color: Colors.white,
                                                    fontSize: 20,
                                                    fontWeight: FontWeight.bold,
                                                  ),
                                                ),
                                              ],
                                            ),
                                          ),
                                          Container(
                                            width: 1,
                                            color: Colors.white.withOpacity(
                                              0.1,
                                            ),
                                          ),
                                          Expanded(
                                            child: Padding(
                                              padding: const EdgeInsets.only(
                                                left: 16,
                                              ),
                                              child: Column(
                                                crossAxisAlignment:
                                                    CrossAxisAlignment.start,
                                                mainAxisAlignment:
                                                    MainAxisAlignment.center,
                                                children: [
                                                  Text(
                                                    "AOV:",
                                                    style: GoogleFonts.poppins(
                                                      color: Colors.white
                                                          .withOpacity(0.7),
                                                      fontSize: 12,
                                                    ),
                                                  ),
                                                  const SizedBox(height: 4),
                                                  Text(
                                                    "₹${aov.toStringAsFixed(0)}",
                                                    style: GoogleFonts.poppins(
                                                      color: Colors.white,
                                                      fontSize: 20,
                                                      fontWeight:
                                                          FontWeight.bold,
                                                    ),
                                                  ),
                                                ],
                                              ),
                                            ),
                                          ),
                                        ],
                                      ),
                                    ),
                                    Container(
                                      height: 1,
                                      color: Colors.white.withOpacity(0.1),
                                    ),
                                    Expanded(
                                      child: Row(
                                        children: [
                                          Expanded(
                                            child: Column(
                                              crossAxisAlignment:
                                                  CrossAxisAlignment.start,
                                              mainAxisAlignment:
                                                  MainAxisAlignment.center,
                                              children: [
                                                Text(
                                                  "Cash:",
                                                  style: GoogleFonts.poppins(
                                                    color: Colors.white
                                                        .withOpacity(0.7),
                                                    fontSize: 12,
                                                  ),
                                                ),
                                                const SizedBox(height: 4),
                                                Text(
                                                  "₹${cashRevenue.toStringAsFixed(0)}",
                                                  style: GoogleFonts.poppins(
                                                    color: Colors.white,
                                                    fontSize: 20,
                                                    fontWeight: FontWeight.bold,
                                                  ),
                                                ),
                                              ],
                                            ),
                                          ),
                                          Container(
                                            width: 1,
                                            color: Colors.white.withOpacity(
                                              0.1,
                                            ),
                                          ),
                                          Expanded(
                                            child: Padding(
                                              padding: const EdgeInsets.only(
                                                left: 16,
                                              ),
                                              child: Column(
                                                crossAxisAlignment:
                                                    CrossAxisAlignment.start,
                                                mainAxisAlignment:
                                                    MainAxisAlignment.center,
                                                children: [
                                                  Text(
                                                    "Online:",
                                                    style: GoogleFonts.poppins(
                                                      color: Colors.white
                                                          .withOpacity(0.7),
                                                      fontSize: 12,
                                                    ),
                                                  ),
                                                  const SizedBox(height: 4),
                                                  Text(
                                                    "₹${onlineRevenue.toStringAsFixed(0)}",
                                                    style: GoogleFonts.poppins(
                                                      color: Colors.white,
                                                      fontSize: 20,
                                                      fontWeight:
                                                          FontWeight.bold,
                                                    ),
                                                  ),
                                                ],
                                              ),
                                            ),
                                          ),
                                        ],
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 24),

                  // ONGOING ORDERS
                  Text(
                    "Ongoing Orders",
                    style: GoogleFonts.poppins(
                      color: Colors.white,
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const SizedBox(height: 12),
                  if (ongoingOrders.isEmpty)
                    Text(
                      "No active orders",
                      style: GoogleFonts.poppins(
                        color: Colors.white.withOpacity(0.5),
                        fontSize: 14,
                      ),
                    )
                  else
                    SizedBox(
                      height: 80,
                      child: ListView.builder(
                        scrollDirection: Axis.horizontal,
                        itemCount: ongoingOrders.length,
                        itemBuilder: (context, index) {
                          final order = ongoingOrders[index];
                          Color statusColor = Colors.orange;
                          String status = order['status'] as String;
                          if (status.toLowerCase() == 'ready') {
                            statusColor = AppTheme.accentGreen;
                          } else if (status.toLowerCase() == 'served') {
                            statusColor = Colors.purple;
                          }

                          return Container(
                            width: 160,
                            margin: const EdgeInsets.only(right: 12),
                            padding: const EdgeInsets.all(12),
                            decoration: BoxDecoration(
                              color: AppTheme.cardColor,
                              borderRadius: BorderRadius.circular(12),
                              border: Border.all(
                                color: Colors.white.withOpacity(0.05),
                              ),
                            ),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Text(
                                  "Order ${order['orderId']}",
                                  style: GoogleFonts.poppins(
                                    color: Colors.white,
                                    fontWeight: FontWeight.w600,
                                    fontSize: 14,
                                  ),
                                ),
                                const SizedBox(height: 4),
                                Row(
                                  children: [
                                    Text(
                                      status.toUpperCase(),
                                      style: GoogleFonts.poppins(
                                        color: statusColor,
                                        fontSize: 12,
                                        fontWeight: FontWeight.bold,
                                      ),
                                    ),
                                  ],
                                ),
                              ],
                            ),
                          );
                        },
                      ),
                    ),
                  const SizedBox(height: 24),

                  // TOP PERFORMERS
                  Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: AppTheme.cardColor,
                      borderRadius: BorderRadius.circular(AppTheme.radius),
                      border: Border.all(color: Colors.white.withOpacity(0.05)),
                    ),
                    child: Column(
                      children: [
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text(
                              "Top Performers",
                              style: GoogleFonts.poppins(
                                color: Colors.white,
                                fontSize: 16,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                            Row(
                              children: [
                                PopupMenuButton<String>(
                                  initialValue: _topPerformerRange,
                                  onSelected: (value) => setState(
                                    () => _topPerformerRange = value,
                                  ),
                                  itemBuilder: (context) => [
                                    const PopupMenuItem(
                                      value: 'Today',
                                      child: Text('Today'),
                                    ),
                                    const PopupMenuItem(
                                      value: 'Week',
                                      child: Text('Week'),
                                    ),
                                    const PopupMenuItem(
                                      value: 'Month',
                                      child: Text('Month'),
                                    ),
                                  ],
                                  child: Row(
                                    children: [
                                      Text(
                                        _topPerformerRange,
                                        style: GoogleFonts.poppins(
                                          color: Colors.blue,
                                          fontSize: 14,
                                          fontWeight: FontWeight.w500,
                                        ),
                                      ),
                                      const Icon(
                                        Icons.arrow_drop_down,
                                        color: Colors.blue,
                                      ),
                                    ],
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ),
                        const SizedBox(height: 16),
                        if (topPerformers.isEmpty)
                          Padding(
                            padding: const EdgeInsets.all(16.0),
                            child: Text(
                              "No sales yet",
                              style: GoogleFonts.poppins(
                                color: Colors.white.withOpacity(0.5),
                              ),
                            ),
                          )
                        else
                          ...topPerformers.asMap().entries.map((entry) {
                            int idx = entry.key;
                            String name = entry.value.key;
                            double revenue = entry.value.value;
                            return Column(
                              children: [
                                _buildPerformerRow(
                                  "${idx + 1}.",
                                  name,
                                  "",
                                  "₹${revenue.toStringAsFixed(0)}",
                                ),
                                if (idx < topPerformers.length - 1)
                                  const Divider(
                                    color: Colors.white10,
                                    height: 24,
                                  ),
                              ],
                            );
                          }),
                      ],
                    ),
                  ),
                  const SizedBox(height: 40),
                ],
              ),
            );
          },
        );
      },
    );
  }

  Widget _buildPerformerRow(
    String rank,
    String name,
    String orders,
    String revenue,
  ) {
    return Row(
      children: [
        Container(
          width: 24,
          height: 24,
          alignment: Alignment.center,
          decoration: BoxDecoration(
            color: rank == "1"
                ? Colors.amber.withOpacity(0.2)
                : Colors.white.withOpacity(0.05),
            shape: BoxShape.circle,
          ),
          child: Text(
            rank,
            style: TextStyle(
              color: rank == "1" ? Colors.amber : Colors.white,
              fontWeight: FontWeight.bold,
              fontSize: 12,
            ),
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                name,
                style: const TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.w500,
                  fontSize: 14,
                ),
              ),
              Text(
                orders,
                style: TextStyle(
                  color: Colors.white.withOpacity(0.5),
                  fontSize: 12,
                ),
              ),
            ],
          ),
        ),
        Text(
          revenue,
          style: const TextStyle(
            color: AppTheme.accentGreen,
            fontWeight: FontWeight.bold,
            fontSize: 14,
          ),
        ),
      ],
    );
  }
}
