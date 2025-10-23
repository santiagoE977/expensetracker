class Expense {
  final int id;
  final String title;
  final double amount;
  final String description;
  final String date;
  final String category;
  final int userId;

  Expense({
    required this.id,
    required this.title,
    required this.amount,
    required this.description,
    required this.date,
    required this.category,
    required this.userId,
  });

  Map<String, dynamic> toJson() => {
    'id': id,
    'title': title,
    'amount': amount,
    'description': description,
    'date': date,
    'category': category,
    'user_id': userId,
  };
}