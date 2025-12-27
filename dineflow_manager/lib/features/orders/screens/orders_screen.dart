import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../../core/theme/theme.dart';
import '../models/order_model.dart';

class OrdersScreen extends StatefulWidget {
  const OrdersScreen({super.key});

  @override
  State<OrdersScreen> createState() => _OrdersScreenState();
}

class _OrdersScreenState extends State<OrdersScreen>
    with SingleTickerProviderStateMixin {
  String _selectedFilter = 'Pending'; // Pending, Cooking, Ready, Completed
  late TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 5, vsync: this);
    _tabController.addListener(() {
      setState(() {
        switch (_tabController.index) {
          case 0:
            _selectedFilter = 'Pending';
            break;
          case 1:
            _selectedFilter = 'Cooking';
            break;
          case 2:
            _selectedFilter = 'Ready';
            break;
          case 3:
            _selectedFilter = 'Served';
            break;
          case 4:
            _selectedFilter = 'Completed';
            break;
        }
      });
    });
  }

  Future<void> _updateStatus(
    String restaurantId,
    String orderId,
    String newStatus,
  ) async {
    await FirebaseFirestore.instance
        .collection('restaurants')
        .doc(restaurantId)
        .collection('orders')
        .doc(orderId)
        .update({
          'orderStatus': newStatus.toLowerCase(),
          'updatedAt': FieldValue.serverTimestamp(),
        });
  }

  Future<void> _markAsPaid(
    String restaurantId,
    String orderId,
    String paymentMethod,
  ) async {
    await FirebaseFirestore.instance
        .collection('restaurants')
        .doc(restaurantId)
        .collection('orders')
        .doc(orderId)
        .update({
          'paymentStatus': 'Paid',
          'paymentMethod': paymentMethod,
          'orderStatus': 'completed',
          'completedAt': FieldValue.serverTimestamp(),
        });
  }

  void _showPaymentDialog(
    BuildContext context,
    String restaurantId,
    OrderModel order,
  ) {
    String selectedMethod = 'Cash';

    showModalBottomSheet(
      context: context,
      backgroundColor: AppTheme.cardColor,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setModalState) {
            return Padding(
              padding: const EdgeInsets.all(24.0),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    "Confirm Payment",
                    style: GoogleFonts.poppins(
                      color: Colors.white,
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 16),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        "Table ${order.tableNumber}",
                        style: GoogleFonts.poppins(
                          color: Colors.white70,
                          fontSize: 16,
                        ),
                      ),
                      Text(
                        "Total: ₹${order.grandTotal}",
                        style: GoogleFonts.poppins(
                          color: AppTheme.accentGreen,
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: Colors.white10,
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          "Ordered Items:",
                          style: GoogleFonts.poppins(
                            color: Colors.grey,
                            fontSize: 12,
                          ),
                        ),
                        const SizedBox(height: 8),
                        ...order.items.map(
                          (item) => Padding(
                            padding: const EdgeInsets.symmetric(vertical: 4),
                            child: Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Text(
                                  "${item.qty}x ${item.name}",
                                  style: GoogleFonts.poppins(
                                    color: Colors.white70,
                                  ),
                                ),
                                Text(
                                  "₹${item.price * item.qty}",
                                  style: GoogleFonts.poppins(
                                    color: Colors.white,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                  const Divider(color: Colors.white24, height: 32),
                  Text(
                    "Payment Method",
                    style: GoogleFonts.poppins(
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 12),
                  Wrap(
                    spacing: 10,
                    children: ['Cash', 'UPI', 'Card'].map((method) {
                      final isSelected = selectedMethod == method;
                      return ChoiceChip(
                        label: Text(method),
                        selected: isSelected,
                        onSelected: (selected) {
                          if (selected) {
                            setModalState(() {
                              selectedMethod = method;
                            });
                          }
                        },
                        selectedColor: AppTheme.accentGreen,
                        backgroundColor: Colors.white10,
                        labelStyle: GoogleFonts.poppins(
                          color: isSelected ? Colors.white : Colors.white70,
                          fontWeight: FontWeight.bold,
                        ),
                      );
                    }).toList(),
                  ),
                  const SizedBox(height: 24),
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton(
                      onPressed: () {
                        _markAsPaid(restaurantId, order.id, selectedMethod);
                        Navigator.pop(context);
                      },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.purple,
                        padding: const EdgeInsets.symmetric(vertical: 16),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                      child: Text(
                        "Confirm Payment Received",
                        style: GoogleFonts.poppins(
                          color: Colors.white,
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            );
          },
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final user = FirebaseAuth.instance.currentUser;

    return Scaffold(
      backgroundColor: AppTheme.backgroundColor,
      appBar: AppBar(
        backgroundColor: AppTheme.backgroundColor,
        title: Text(
          "Kitchen Orders",
          style: GoogleFonts.poppins(
            color: Colors.white,
            fontWeight: FontWeight.bold,
          ),
        ),
        bottom: TabBar(
          controller: _tabController,
          indicatorColor: AppTheme.accentGreen,
          labelColor: AppTheme.accentGreen,
          unselectedLabelColor: Colors.grey,
          labelStyle: GoogleFonts.poppins(fontWeight: FontWeight.bold),
          tabs: const [
            Tab(text: "New"),
            Tab(text: "Cooking"),
            Tab(text: "Ready"),
            Tab(text: "Payments"),
            Tab(text: "Done"),
          ],
        ),
      ),
      body: StreamBuilder<DocumentSnapshot>(
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
                .orderBy('createdAt', descending: false) // Oldest orders first
                .snapshots(),
            builder: (context, orderSnapshot) {
              if (!orderSnapshot.hasData) {
                return const Center(child: CircularProgressIndicator());
              }

              final docs = orderSnapshot.data!.docs;

              // Filter orders based on selected tab
              final filteredOrders = docs
                  .map((doc) {
                    return OrderModel.fromSnapshot(doc);
                  })
                  .where((order) {
                    // Map 'served' to 'completed' tab for simplicity in this view
                    if (_selectedFilter == 'Completed') {
                      return [
                        'completed',
                        'cancelled',
                      ].contains(order.orderStatus.toLowerCase());
                    }
                    return order.orderStatus.toLowerCase() ==
                        _selectedFilter.toLowerCase();
                  })
                  .toList();

              if (filteredOrders.isEmpty) {
                return Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(
                        Icons.receipt_long,
                        size: 60,
                        color: Colors.white.withOpacity(0.2),
                      ),
                      const SizedBox(height: 16),
                      Text(
                        "No ${_selectedFilter.toLowerCase()} orders",
                        style: GoogleFonts.poppins(color: Colors.grey),
                      ),
                    ],
                  ),
                );
              }

              return ListView.builder(
                padding: const EdgeInsets.all(16),
                itemCount: filteredOrders.length,
                itemBuilder: (context, index) {
                  final order = filteredOrders[index];
                  return _buildOrderCard(restaurantId, order);
                },
              );
            },
          );
        },
      ),
    );
  }

  Widget _buildOrderCard(String restId, OrderModel order) {
    Color statusColor = AppTheme.accentGreen;
    String status = order.orderStatus;

    if (status == 'pending') statusColor = Colors.orange;
    if (status == 'cooking') statusColor = Colors.blue;
    if (status == 'ready') statusColor = Colors.green;
    if (status == 'completed') statusColor = Colors.grey;
    if (status == 'served') statusColor = Colors.purple;

    String displayStatus = status.toUpperCase();
    if (status == 'served') displayStatus = 'PAYMENT PENDING';

    return Card(
      color: AppTheme.cardColor,
      margin: const EdgeInsets.only(bottom: 16),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header: Table & Status
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      "Table ${order.tableNumber}",
                      style: GoogleFonts.poppins(
                        color: Colors.white,
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    Text(
                      order.orderId,
                      style: GoogleFonts.poppins(
                        color: Colors.grey,
                        fontSize: 12,
                      ),
                    ),
                  ],
                ),
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 12,
                    vertical: 4,
                  ),
                  decoration: BoxDecoration(
                    color: statusColor.withOpacity(0.2),
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(color: statusColor),
                  ),
                  child: Text(
                    displayStatus,
                    style: GoogleFonts.poppins(
                      color: statusColor,
                      fontSize: 12,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ],
            ),
            const Divider(color: Colors.white24, height: 24),

            // Items List
            ...order.items.map(
              (item) => Padding(
                padding: const EdgeInsets.only(bottom: 8),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Container(
                      padding: const EdgeInsets.all(6),
                      decoration: BoxDecoration(
                        color: Colors.white10,
                        borderRadius: BorderRadius.circular(4),
                      ),
                      child: Text(
                        "${item.qty}x",
                        style: GoogleFonts.poppins(
                          color: AppTheme.accentGreen,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            item.name,
                            style: GoogleFonts.poppins(color: Colors.white70),
                          ),
                          if (item.variant != null)
                            Text(
                              item.variant!,
                              style: GoogleFonts.poppins(
                                color: Colors.grey,
                                fontSize: 12,
                              ),
                            ),
                          if (item.customization != null)
                            Text(
                              "Note: ${item.customization}",
                              style: GoogleFonts.poppins(
                                color: Colors.orangeAccent,
                                fontSize: 12,
                                fontStyle: FontStyle.italic,
                              ),
                            ),
                        ],
                      ),
                    ),
                    Text(
                      "₹${item.price}",
                      style: GoogleFonts.poppins(color: Colors.white),
                    ),
                  ],
                ),
              ),
            ),

            const Divider(color: Colors.white24, height: 24),

            // Footer: Total & Actions
            Row(
              children: [
                Text(
                  "Total: ₹${order.grandTotal}",
                  style: GoogleFonts.poppins(
                    color: Colors.white,
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const Spacer(),
                if (status == 'pending')
                  ElevatedButton(
                    onPressed: () => _updateStatus(restId, order.id, 'cooking'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppTheme.accentGreen,
                    ),
                    child: const Text(
                      "Accept Order",
                      style: TextStyle(color: Colors.white),
                    ),
                  ),
                if (status == 'cooking')
                  ElevatedButton(
                    onPressed: () => _updateStatus(restId, order.id, 'ready'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.blue,
                    ),
                    child: const Text(
                      "Mark Ready",
                      style: TextStyle(color: Colors.white),
                    ),
                  ),
                if (status == 'ready')
                  ElevatedButton(
                    onPressed: () => _updateStatus(restId, order.id, 'served'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.green,
                    ),
                    child: const Text(
                      "Mark Served",
                      style: TextStyle(color: Colors.white),
                    ),
                  ),
                if (status == 'served')
                  ElevatedButton(
                    onPressed: () => _showPaymentDialog(context, restId, order),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.purple,
                    ),
                    child: const Text(
                      "View Bill & Pay",
                      style: TextStyle(color: Colors.white),
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
