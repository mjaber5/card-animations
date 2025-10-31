import 'package:flutter/material.dart';
import 'features/card_wallet/models/credit_card.dart';
import 'features/card_wallet/widgets/card_list_screen.dart';

void main() => runApp(const CardWalletApp());

class CardWalletApp extends StatelessWidget {
  const CardWalletApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Card Wallet',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        useMaterial3: true,
        scaffoldBackgroundColor: const Color(0xFFF5F5F5),
        fontFamily: 'SF Pro',
      ),
      home: CardListScreen(
        cards: _sampleCards,
        transactions: _sampleTransactions,
      ),
    );
  }
}

// Sample data
final List<CreditCard> _sampleCards = const [
  CreditCard(
    id: '1',
    name: 'TRAVEL CARD',
    balance: '453',
    color: Color(0xFF2D2D2D),
  ),
  CreditCard(
    id: '2',
    name: 'MUJEER WALYT',
    balance: '999',
    color: Color.fromARGB(255, 0, 85, 159),
  ),
  CreditCard(
    id: '3',
    name: 'FOOD CARD',
    balance: '127',
    color: Color(0xFF090915),
  ),
  CreditCard(
    id: '4',
    name: 'GIFT CARD',
    balance: '745',
    color: Color.fromARGB(255, 20, 0, 92),
    hasSpendingAnalytics: true,
  ),
];

final List<Transaction> _sampleTransactions = const [
  Transaction(
    title: 'Spent at Kayak',
    date: '19 October, 1:32 PM',
    amount: -120,
    type: TransactionType.debit,
  ),
  Transaction(
    title: 'Cashback Received',
    date: '28 August, 7:13 AM',
    amount: 7,
    type: TransactionType.credit,
  ),
  Transaction(
    title: 'Money Added',
    date: '19 October, 1:32 PM',
    amount: 120,
    type: TransactionType.credit,
  ),
  Transaction(
    title: 'Cashback Received',
    date: '28 August, 7:13 AM',
    amount: 7,
    type: TransactionType.credit,
  ),
  Transaction(
    title: 'Paid for order #11538',
    date: '27 August, 11:35 AM',
    amount: -60,
    type: TransactionType.debit,
  ),
  Transaction(
    title: 'Paid at Tesco',
    date: '19 October, 1:45 PM',
    amount: -80,
    type: TransactionType.debit,
  ),
];
