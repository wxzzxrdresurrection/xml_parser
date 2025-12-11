class Product {
  final int? id;
  final String description;
  final String identificationNumber;
  final String unitCode;
  final String unitName;
  final double quantity;
  final double unitPrice;
  final double totalAmount;
  final DateTime createdAt;

  const Product({
    this.id,
    required this.description,
    required this.identificationNumber,
    required this.unitCode,
    required this.unitName,
    required this.quantity,
    required this.unitPrice,
    required this.totalAmount,
    required this.createdAt,
  });

  Map<String, dynamic> toMap() {
    final map = {
      'description': description,
      'identificationNumber': identificationNumber,
      'unitCode': unitCode,
      'unitName': unitName,
      'quantity': quantity,
      'unitPrice': unitPrice,
      'totalAmount': totalAmount,
      'createdAt': createdAt.toIso8601String(),
    };
    if (id != null) {
      map['id'] = id!;
    }
    return map;
  }

  @override
  String toString() {
    return 'Product{id: $id, description: $description, identificationNumber: $identificationNumber, unitCode: $unitCode, unitName: $unitName, quantity: $quantity, unitPrice: $unitPrice, totalAmount: $totalAmount, createdAt: $createdAt}';
  }
}
