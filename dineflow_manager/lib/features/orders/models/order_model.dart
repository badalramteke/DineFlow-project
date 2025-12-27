import 'package:cloud_firestore/cloud_firestore.dart';

class OrderItem {
  final String menuId;
  final String name;
  final double price;
  final int qty;
  final String? variant;
  final String? customization;
  final String itemStatus; // 'cooking', 'ready', 'served'

  OrderItem({
    required this.menuId,
    required this.name,
    required this.price,
    required this.qty,
    this.variant,
    this.customization,
    this.itemStatus = 'pending',
  });

  Map<String, dynamic> toMap() {
    return {
      'menuId': menuId,
      'name': name,
      'price': price,
      'qty': qty,
      'variant': variant,
      'customization': customization,
      'itemStatus': itemStatus,
    };
  }

  factory OrderItem.fromMap(Map<String, dynamic> map) {
    return OrderItem(
      menuId: map['menuId'] ?? '',
      name: map['name'] ?? '',
      price: (map['price'] ?? 0).toDouble(),
      qty: map['qty'] ?? 1,
      variant: map['variant'],
      customization: map['customization'],
      itemStatus: map['itemStatus'] ?? 'pending',
    );
  }
}

class OrderModel {
  final String id; // Firestore Document ID
  final String orderId; // Display ID e.g. #1045
  final String tableNumber;
  final String? customerName;
  final String? customerPhone;
  final String? waiterId;
  final String orderType; // 'Dine-in', 'Takeaway'

  final List<OrderItem> items;

  final double subTotal;
  final double taxAmount;
  final double serviceCharge;
  final double discountAmount;
  final double grandTotal;

  final String paymentMethod; // 'Cash', 'UPI', 'Card'
  final String paymentStatus; // 'Pending', 'Paid'

  final String
  orderStatus; // 'pending', 'cooking', 'ready', 'served', 'completed', 'cancelled'
  final String? kitchenNote;
  final String? cancellationReason;

  final Timestamp createdAt;
  final Timestamp? updatedAt;
  final Timestamp? completedAt;

  final List<String> searchKeywords;

  OrderModel({
    required this.id,
    required this.orderId,
    required this.tableNumber,
    this.customerName,
    this.customerPhone,
    this.waiterId,
    required this.orderType,
    required this.items,
    required this.subTotal,
    required this.taxAmount,
    required this.serviceCharge,
    required this.discountAmount,
    required this.grandTotal,
    required this.paymentMethod,
    required this.paymentStatus,
    required this.orderStatus,
    this.kitchenNote,
    this.cancellationReason,
    required this.createdAt,
    this.updatedAt,
    this.completedAt,
    required this.searchKeywords,
  });

  Map<String, dynamic> toMap() {
    return {
      'orderId': orderId,
      'tableNumber': tableNumber,
      'customerName': customerName,
      'customerPhone': customerPhone,
      'waiterId': waiterId,
      'orderType': orderType,
      'items': items.map((x) => x.toMap()).toList(),
      'subTotal': subTotal,
      'taxAmount': taxAmount,
      'serviceCharge': serviceCharge,
      'discountAmount': discountAmount,
      'grandTotal': grandTotal,
      'paymentMethod': paymentMethod,
      'paymentStatus': paymentStatus,
      'orderStatus': orderStatus,
      'kitchenNote': kitchenNote,
      'cancellationReason': cancellationReason,
      'createdAt': createdAt,
      'updatedAt': updatedAt,
      'completedAt': completedAt,
      'searchKeywords': searchKeywords,
    };
  }

  factory OrderModel.fromSnapshot(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    return OrderModel(
      id: doc.id,
      orderId: data['orderId'] ?? '',
      tableNumber: data['tableNumber'] ?? '',
      customerName: data['customerName'],
      customerPhone: data['customerPhone'],
      waiterId: data['waiterId'],
      orderType: data['orderType'] ?? 'Dine-in',
      items: List<OrderItem>.from(
        (data['items'] as List<dynamic>? ?? []).map(
          (x) => OrderItem.fromMap(x),
        ),
      ),
      subTotal: (data['subTotal'] ?? 0).toDouble(),
      taxAmount: (data['taxAmount'] ?? 0).toDouble(),
      serviceCharge: (data['serviceCharge'] ?? 0).toDouble(),
      discountAmount: (data['discountAmount'] ?? 0).toDouble(),
      grandTotal: (data['grandTotal'] ?? 0).toDouble(),
      paymentMethod: data['paymentMethod'] ?? 'Cash',
      paymentStatus: data['paymentStatus'] ?? 'Pending',
      orderStatus: data['orderStatus'] ?? 'pending',
      kitchenNote: data['kitchenNote'],
      cancellationReason: data['cancellationReason'],
      createdAt: data['createdAt'] ?? Timestamp.now(),
      updatedAt: data['updatedAt'],
      completedAt: data['completedAt'],
      searchKeywords: List<String>.from(data['searchKeywords'] ?? []),
    );
  }
}
