import 'package:flutter/material.dart';

class CreditCard {
  final String id;
  final String name;
  final String balance;
  final Color color;
  final bool hasTransactions;
  final bool hasSpendingAnalytics;

  const CreditCard({
    required this.id,
    required this.name,
    required this.balance,
    required this.color,
    this.hasTransactions = true,
    this.hasSpendingAnalytics = false,
  });
}

class Transaction {
  final String title;
  final String date;
  final double amount;
  final TransactionType type;

  const Transaction({
    required this.title,
    required this.date,
    required this.amount,
    required this.type,
  });
}

enum TransactionType { debit, credit }

enum CardViewState {
  collapsed,
  expanded,
  detail,
}
