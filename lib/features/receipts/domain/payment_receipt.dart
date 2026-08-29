class PaymentReceipt {
  const PaymentReceipt({
    required this.id,
    required this.residenceId,
    required this.residenceName,
    required this.apartmentNumber,
    required this.amount,
    required this.periodKeys,
    required this.paidAt,
    required this.note,
  });

  final String id;
  final String residenceId;
  final String residenceName;
  final String apartmentNumber;
  final int amount;
  final List<String> periodKeys;
  final DateTime paidAt;
  final String note;

  String get url => 'https://darjar.app/r/$id';
}
