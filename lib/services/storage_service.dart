import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/transaction.dart';

class StorageService {
  static const String _transactionsKey = 'transactions';

  Future<void> saveTransactions(List<Transaction> transactions) async {
    final preferences = await SharedPreferences.getInstance();

    final data = transactions
        .map((transaction) => transaction.toMap())
        .toList();

    final jsonString = jsonEncode(data);

    await preferences.setString(_transactionsKey, jsonString);
  }

  Future<List<Transaction>> loadTransactions() async {
    final preferences = await SharedPreferences.getInstance();

    final jsonString = preferences.getString(_transactionsKey);

    if (jsonString == null) {
      return [];
    }

    final List<dynamic> data = jsonDecode(jsonString);

    return data
        .map((item) => Transaction.fromMap(Map<String, dynamic>.from(item)))
        .toList();
  }
}
