import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'dart:convert';
import 'dart:math' as math;

void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return const MaterialApp(
      debugShowCheckedModeBanner: false,
      home: MainScreen(),
    );
  }
}

class Account {
  final String id;
  final String name;
  final String iconType; // 'wallet', 'bank', 'savings', 'cash', 'card'

  Account({
    required this.id,
    required this.name,
    this.iconType = 'wallet',
  });

  Map<String, dynamic> toMap() => {
    'id': id,
    'name': name,
    'iconType': iconType,
  };

  factory Account.fromMap(Map<String, dynamic> map) => Account(
    id: map['id'] ?? 'main',
    name: map['name'] ?? 'Principal',
    iconType: map['iconType'] ?? 'wallet',
  );

  IconData get icon {
    switch (iconType) {
      case 'bank':
        return Icons.account_balance;
      case 'savings':
        return Icons.savings;
      case 'cash':
        return Icons.payments;
      case 'card':
        return Icons.credit_card;
      case 'wallet':
      default:
        return Icons.account_balance_wallet;
    }
  }
}

class Transaction {
  final String id;
  final String title;
  final double amount;
  final DateTime date;
  final bool isExpense;
  final String categoryId;
  final String accountId;

  Transaction({
    required this.id,
    required this.title,
    required this.amount,
    required this.date,
    required this.isExpense,
    required this.categoryId,
    this.accountId = 'main',
  });

  Map<String, dynamic> toMap() => {
    'id': id,
    'title': title,
    'amount': amount,
    'date': date.toIso8601String(),
    'isExpense': isExpense,
    'categoryId': categoryId,
    'accountId': accountId,
  };

  factory Transaction.fromMap(Map<String, dynamic> map) => Transaction(
    id: map['id'],
    title: map['title'],
    amount: (map['amount'] as num).toDouble(),
    date: DateTime.parse(map['date']),
    isExpense: map['isExpense'],
    categoryId: map['categoryId'] ?? 'other',
    accountId: map['accountId'] ?? 'main',
  );
}

class PieSectionItem {
  final double value;
  final Color color;
  final String title;

  PieSectionItem({required this.value, required this.color, required this.title});
}

class DonutChartPainter extends CustomPainter {
  final List<PieSectionItem> sections;
  final double strokeWidth;

  DonutChartPainter({required this.sections, this.strokeWidth = 38.0});

  @override
  void paint(Canvas canvas, Size size) {
    final double total = sections.fold(0.0, (sum, s) => sum + s.value);
    if (total <= 0) return;

    final center = Offset(size.width / 2, size.height / 2);
    final radius = (math.min(size.width, size.height) - strokeWidth) / 2;

    double startAngle = -math.pi / 2;

    final paint = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = strokeWidth
      ..strokeCap = StrokeCap.butt;

    for (var section in sections) {
      final sweepAngle = (section.value / total) * 2 * math.pi;
      paint.color = section.color;

      canvas.drawArc(
        Rect.fromCircle(center: center, radius: radius),
        startAngle,
        sweepAngle > 0.05 ? sweepAngle - 0.03 : sweepAngle,
        false,
        paint,
      );

      if (sweepAngle > 0.3) {
        final midAngle = startAngle + sweepAngle / 2;
        final labelOffset = Offset(
          center.dx + radius * math.cos(midAngle),
          center.dy + radius * math.sin(midAngle),
        );

        final textSpan = TextSpan(
          text: section.title,
          style: const TextStyle(
            color: Colors.white,
            fontSize: 12,
            fontWeight: FontWeight.bold,
          ),
        );
        final textPainter = TextPainter(
          text: textSpan,
          textAlign: TextAlign.center,
          textDirection: TextDirection.ltr,
        )..layout();

        textPainter.paint(
          canvas,
          Offset(labelOffset.dx - textPainter.width / 2, labelOffset.dy - textPainter.height / 2),
        );
      }

      startAngle += sweepAngle;
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => true;
}

class InteractiveBackground extends StatefulWidget {
  final bool isDark;
  final Widget child;
  const InteractiveBackground({super.key, required this.isDark, required this.child});

  @override
  State<InteractiveBackground> createState() => _InteractiveBackgroundState();
}

class _InteractiveBackgroundState extends State<InteractiveBackground> with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  double _xOffset = 0.0;
  double _yOffset = 0.0;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(vsync: this, duration: const Duration(seconds: 15))..repeat();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onPanUpdate: (details) => setState(() {
        _yOffset += details.delta.dx / 80;
        _xOffset -= details.delta.dy / 80;
      }),
      child: Stack(
        children: [
          Positioned.fill(
            child: Container(
              color: widget.isDark ? const Color(0xFF121212) : Colors.grey[100],
              child: Center(
                child: AnimatedBuilder(
                  animation: _controller,
                  builder: (context, child) {
                    return Transform(
                      transform: Matrix4.identity()
                        ..setEntry(3, 2, 0.001)
                        ..rotateX(_xOffset)
                        ..rotateY((_controller.value * 2 * math.pi) + _yOffset),
                      alignment: Alignment.center,
                      child: Opacity(
                        opacity: widget.isDark ? 0.22 : 0.28,
                        child: Container(
                          width: 320,
                          height: 320,
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            gradient: const LinearGradient(
                              colors: [Color(0xFFF7931A), Color(0xFFB15F00)],
                              begin: Alignment.topLeft,
                              end: Alignment.bottomRight,
                            ),
                            boxShadow: [
                              BoxShadow(
                                color: Colors.orange.withOpacity(0.5),
                                blurRadius: 50,
                                spreadRadius: 8,
                              )
                            ],
                            border: Border.all(color: const Color(0xFFF7931A), width: 8),
                          ),
                          child: const Center(
                            child: Text(
                              '₿',
                              style: TextStyle(
                                fontSize: 200,
                                color: Colors.white,
                                fontWeight: FontWeight.w900,
                              ),
                            ),
                          ),
                        ),
                      ),
                    );
                  },
                ),
              ),
            ),
          ),
          widget.child,
        ],
      ),
    );
  }
}

class MainScreen extends StatefulWidget {
  const MainScreen({super.key});
  @override
  State<MainScreen> createState() => _MainScreenState();
}

class _MainScreenState extends State<MainScreen> {
  List<Account> _accounts = [
    Account(id: 'main', name: 'Compte Principal', iconType: 'wallet'),
  ];
  String _selectedAccountId = 'all';
  List<Transaction> _transactions = [];
  bool _isLoading = true;
  String _selectedLang = 'dr';
  bool _isDarkMode = false;
  int _selectedIndex = 0;
  late PageController _pageController;
  int _selectedQuarter = 0;

  final Map<String, IconData> _categoryIcons = {
    'food': Icons.fastfood,
    'transport': Icons.directions_car,
    'home': Icons.home,
    'fun': Icons.sports_esports,
    'clothes': Icons.checkroom,
    'other': Icons.shopping_bag,
  };

  final Map<String, Color> _categoryColors = {
    'food': Colors.orange,
    'transport': Colors.blue,
    'home': Colors.purple,
    'fun': Colors.pink,
    'clothes': Colors.teal,
    'other': Colors.grey,
  };

  final Map<String, Map<String, String>> _dictionary = {
    'dr': {
      'app_title': 'Masroufi Pro',
      'total_balance': 'Rass l-mal',
      'empty_list': 'Yallah bda t-9yyed masrouf!',
      'add_btn': 'Zid 3amaliya',
      'title_label': 'Fash? (Titre)',
      'amount_loss': 'Ch7al mcha? (DH)',
      'amount_gain': 'Ch7al dkhl? (DH)',
      'save': 'Sajal',
      'currency': 'DH',
      'nav_home': 'Ra2issiya',
      'nav_stats': 'Mibyanat',
      'stats_title': 'Fin mchat l-flouss?',
      'no_expenses': 'Mazal ma khssrti walo!',
      'cat_food': 'Mkla',
      'cat_transport': 'Transport',
      'cat_home': 'Dar',
      'cat_fun': 'L3ib',
      'cat_clothes': '7wayj',
      'cat_other': 'Okhrin',
      'filter_0': 'Ga3 l-Ayam',
      'filter_1': 'Q1 (Ch-har 1 ➔ 3)',
      'filter_2': 'Q2 (Ch-har 4 ➔ 6)',
      'filter_3': 'Q3 (Ch-har 7 ➔ 9)',
      'filter_4': 'Q4 (Ch-har 10 ➔ 12)',
      'all_accounts': 'Ga3 l-Kontat',
      'manage_accounts': 'Idarat l-Kontat',
      'add_account': 'Zid Kont Jdid',
      'account_name': 'Smit l-Kont',
      'select_account': 'L-Kont',
      'account_created': 'T-zad l-kont b naja7! 🎉',
      'delete_account': 'Mss7 had l-kont?',
      'cant_delete_last': 'Ma ymknsh tmss7 l-kont l-wa7id!',
    },
    'en': {
      'app_title': 'My Budget',
      'total_balance': 'Total Balance',
      'empty_list': 'No transactions yet!',
      'add_btn': 'Add',
      'title_label': 'Title',
      'amount_loss': 'Amount Spent (DH)',
      'amount_gain': 'Amount Earned (DH)',
      'save': 'Save',
      'currency': 'DH',
      'nav_home': 'Home',
      'nav_stats': 'Stats',
      'stats_title': 'Where did money go?',
      'no_expenses': 'No expenses yet!',
      'cat_food': 'Food',
      'cat_transport': 'Transport',
      'cat_home': 'Rent',
      'cat_fun': 'Fun',
      'cat_clothes': 'Clothes',
      'cat_other': 'Other',
      'filter_0': 'All Time',
      'filter_1': 'Q1 (Jan-Mar)',
      'filter_2': 'Q2 (Apr-Jun)',
      'filter_3': 'Q3 (Jul-Sep)',
      'filter_4': 'Q4 (Oct-Dec)',
      'all_accounts': 'All Accounts',
      'manage_accounts': 'Manage Accounts',
      'add_account': 'Add New Account',
      'account_name': 'Account Name',
      'select_account': 'Account',
      'account_created': 'Account added successfully! 🎉',
      'delete_account': 'Delete this account?',
      'cant_delete_last': 'Cannot delete the only account!',
    },
    'ar': {
      'app_title': 'مصروفي',
      'total_balance': 'الرصيد',
      'empty_list': 'لا توجد معاملات',
      'add_btn': 'إضافة',
      'title_label': 'العنوان',
      'amount_loss': 'كم صرفت؟ (د.م)',
      'amount_gain': 'كم ربحت؟ (د.م)',
      'save': 'حفظ',
      'currency': 'د.م',
      'nav_home': 'الرئيسية',
      'nav_stats': 'إحصائيات',
      'stats_title': 'أين ذهب المال؟',
      'no_expenses': 'لم تصرف شيئاً بعد!',
      'cat_food': 'أكل',
      'cat_transport': 'نقل',
      'cat_home': 'منزل',
      'cat_fun': 'ترفيه',
      'cat_clothes': 'ملابس',
      'cat_other': 'أخرى',
      'filter_0': 'كل الأوقات',
      'filter_1': 'الربع الأول (1 ➔ 3)',
      'filter_2': 'الربع الثاني (4 ➔ 6)',
      'filter_3': 'الربع الثالث (7 ➔ 9)',
      'filter_4': 'الربع الرابع (10 ➔ 12)',
      'all_accounts': 'كل الحسابات',
      'manage_accounts': 'إدارة الحسابات',
      'add_account': 'إضافة حساب جديد',
      'account_name': 'اسم الحساب',
      'select_account': 'الحساب',
      'account_created': 'تمت إضافة الحساب بنجاح! 🎉',
      'delete_account': 'حذف هذا الحساب؟',
      'cant_delete_last': 'لا يمكن حذف الحساب الوحيد!',
    },
  };

  @override
  void initState() {
    super.initState();
    _pageController = PageController();
    _selectedQuarter = (DateTime.now().month - 1) ~/ 3 + 1;
    _loadData();
  }

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  Future<void> _exportData() async {
    final prefs = await SharedPreferences.getInstance();
    final exportMap = {
      'accounts': _accounts.map((a) => a.toMap()).toList(),
      'transactions': _transactions.map((t) => t.toMap()).toList(),
    };
    final String encodedData = jsonEncode(exportMap);
    await Clipboard.setData(ClipboardData(text: encodedData));
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('T-copia l-historique mzyan! 📋 Daba mss7 l-app', style: TextStyle(color: Colors.white)),
        backgroundColor: Colors.green,
      ),
    );
  }

  Future<void> _importData() async {
    ClipboardData? clipboardData = await Clipboard.getData('text/plain');
    if (clipboardData != null && clipboardData.text != null && clipboardData.text!.isNotEmpty) {
      try {
        final String encodedData = clipboardData.text!;
        final dynamic decoded = jsonDecode(encodedData);
        if (decoded is Map<String, dynamic> && decoded.containsKey('accounts')) {
          final List<dynamic> accList = decoded['accounts'];
          final List<dynamic> txList = decoded['transactions'];
          setState(() {
            _accounts = accList.map((item) => Account.fromMap(item)).toList();
            _transactions = txList.map((item) => Transaction.fromMap(item)).toList();
          });
        } else if (decoded is List) {
          setState(() {
            _transactions = decoded.map((item) => Transaction.fromMap(item)).toList();
          });
        }
        _saveData();
        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Rje3 l-historique! 🎉', style: TextStyle(color: Colors.white)), backgroundColor: Colors.green),
        );
      } catch (e) {
        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Ghalat f l-code dyal l-historique! ❌'), backgroundColor: Colors.red),
        );
      }
    }
  }

  Future<void> _saveData() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('accounts_data', jsonEncode(_accounts.map((a) => a.toMap()).toList()));
    await prefs.setString('tx_data', jsonEncode(_transactions.map((tx) => tx.toMap()).toList()));
    await prefs.setString('selected_account_id', _selectedAccountId);
    await prefs.setString('lang', _selectedLang);
    await prefs.setBool('isDark', _isDarkMode);
  }

  Future<void> _loadData() async {
    final prefs = await SharedPreferences.getInstance();
    if (prefs.containsKey('lang')) _selectedLang = prefs.getString('lang') ?? 'dr';
    if (prefs.containsKey('isDark')) _isDarkMode = prefs.getBool('isDark') ?? false;
    if (prefs.containsKey('selected_account_id')) {
      _selectedAccountId = prefs.getString('selected_account_id') ?? 'all';
    }

    final String? accData = prefs.getString('accounts_data');
    if (accData != null) {
      try {
        final List<dynamic> list = jsonDecode(accData);
        if (list.isNotEmpty) {
          _accounts = list.map((a) => Account.fromMap(a)).toList();
        }
      } catch (_) {}
    }

    final String? encodedData = prefs.getString('tx_data');
    if (encodedData != null) {
      try {
        final List<dynamic> list = jsonDecode(encodedData);
        _transactions = list.map((item) => Transaction.fromMap(item)).toList();
      } catch (_) {}
    }

    setState(() {
      _isLoading = false;
    });
  }

  List<Transaction> get _filteredTransactions {
    if (_selectedAccountId == 'all') {
      return _transactions;
    }
    return _transactions.where((tx) => tx.accountId == _selectedAccountId).toList();
  }

  double _calculateBalance(String accountId) {
    double balance = 0.0;
    for (var tx in _transactions) {
      if (accountId == 'all' || tx.accountId == accountId) {
        if (tx.isExpense) {
          balance -= tx.amount;
        } else {
          balance += tx.amount;
        }
      }
    }
    return balance;
  }

  double get _currentBalance => _calculateBalance(_selectedAccountId);

  String t(String key) => _dictionary[_selectedLang]?[key] ?? key;

  Account _getAccount(String id) {
    return _accounts.firstOrNullWhere((a) => a.id == id) ??
        Account(id: 'main', name: 'Compte Principal', iconType: 'wallet');
  }

  String get _currentAccountName {
    if (_selectedAccountId == 'all') return t('all_accounts');
    return _getAccount(_selectedAccountId).name;
  }

  void _addNewTransaction(String txTitle, double txAmount, bool isExpense, String categoryId, String accountId) {
    setState(() {
      _transactions.insert(
        0,
        Transaction(
          id: DateTime.now().millisecondsSinceEpoch.toString(),
          title: txTitle,
          amount: txAmount,
          date: DateTime.now(),
          isExpense: isExpense,
          categoryId: isExpense ? categoryId : 'income',
          accountId: accountId,
        ),
      );
    });
    _saveData();
  }

  void _deleteTransaction(String id) {
    setState(() => _transactions.removeWhere((tx) => tx.id == id));
    _saveData();
  }

  void _addNewAccount(String name, String iconType) {
    final newAcc = Account(
      id: DateTime.now().millisecondsSinceEpoch.toString(),
      name: name,
      iconType: iconType,
    );
    setState(() {
      _accounts.add(newAcc);
      _selectedAccountId = newAcc.id;
    });
    _saveData();
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(t('account_created')), backgroundColor: Colors.green),
    );
  }

  void _deleteAccount(String accountId) {
    if (_accounts.length <= 1) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(t('cant_delete_last')), backgroundColor: Colors.red),
      );
      return;
    }
    setState(() {
      _accounts.removeWhere((a) => a.id == accountId);
      if (_selectedAccountId == accountId) {
        _selectedAccountId = 'all';
      }
    });
    _saveData();
  }

  void _showAccountsSheet(BuildContext ctx) {
    showModalBottomSheet(
      context: ctx,
      backgroundColor: _isDarkMode ? const Color(0xFF1E1E1E) : Colors.white,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
      isScrollControlled: true,
      builder: (_) {
        return Directionality(
          textDirection: _selectedLang == 'ar' ? TextDirection.rtl : TextDirection.ltr,
          child: StatefulBuilder(
            builder: (context, setModalState) {
              return Container(
                padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 20),
                height: MediaQuery.of(context).size.height * 0.7,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          t('manage_accounts'),
                          style: TextStyle(
                            fontSize: 20,
                            fontWeight: FontWeight.bold,
                            color: _isDarkMode ? Colors.white : Colors.black,
                          ),
                        ),
                        IconButton(
                          icon: const Icon(Icons.add_circle, color: Colors.blueAccent, size: 28),
                          onPressed: () {
                            Navigator.pop(context);
                            _showCreateAccountDialog(ctx);
                          },
                        ),
                      ],
                    ),
                    const Divider(height: 25),
                    ListTile(
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                      tileColor: _selectedAccountId == 'all'
                          ? (_isDarkMode ? Colors.blue.withOpacity(0.3) : Colors.blue.withOpacity(0.15))
                          : Colors.transparent,
                      leading: CircleAvatar(
                        backgroundColor: Colors.blue.withOpacity(0.2),
                        child: const Icon(Icons.dashboard, color: Colors.blue),
                      ),
                      title: Text(
                        t('all_accounts'),
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          color: _isDarkMode ? Colors.white : Colors.black,
                        ),
                      ),
                      trailing: Text(
                        '${_calculateBalance('all').toStringAsFixed(2)} ${t('currency')}',
                        style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15),
                        textDirection: TextDirection.ltr,
                      ),
                      onTap: () {
                        setState(() => _selectedAccountId = 'all');
                        _saveData();
                        Navigator.pop(context);
                      },
                    ),
                    const SizedBox(height: 8),
                    Expanded(
                      child: ListView.builder(
                        itemCount: _accounts.length,
                        itemBuilder: (ctx, index) {
                          final acc = _accounts[index];
                          final isSelected = _selectedAccountId == acc.id;
                          final accBalance = _calculateBalance(acc.id);

                          return Container(
                            margin: const EdgeInsets.symmetric(vertical: 4),
                            decoration: BoxDecoration(
                              color: isSelected
                                  ? (_isDarkMode ? Colors.blue.withOpacity(0.3) : Colors.blue.withOpacity(0.15))
                                  : (_isDarkMode ? Colors.grey[900] : Colors.grey[100]),
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: ListTile(
                              leading: CircleAvatar(
                                backgroundColor: Colors.amber.withOpacity(0.2),
                                child: Icon(acc.icon, color: Colors.amber[800]),
                              ),
                              title: Text(
                                acc.name,
                                style: TextStyle(
                                  fontWeight: FontWeight.bold,
                                  color: _isDarkMode ? Colors.white : Colors.black,
                                ),
                                overflow: TextOverflow.ellipsis,
                              ),
                              subtitle: Text(
                                '${_transactions.where((t) => t.accountId == acc.id).length} txs',
                                style: TextStyle(color: _isDarkMode ? Colors.grey[400] : Colors.grey[600]),
                              ),
                              trailing: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Text(
                                    '${accBalance.toStringAsFixed(2)} ${t('currency')}',
                                    style: TextStyle(
                                      fontWeight: FontWeight.bold,
                                      fontSize: 14,
                                      color: accBalance >= 0 ? Colors.green : Colors.redAccent,
                                    ),
                                    textDirection: TextDirection.ltr,
                                  ),
                                  if (_accounts.length > 1) ...[
                                    const SizedBox(width: 4),
                                    IconButton(
                                      padding: EdgeInsets.zero,
                                      constraints: const BoxConstraints(),
                                      icon: const Icon(Icons.delete_outline, color: Colors.redAccent, size: 20),
                                      onPressed: () {
                                        _deleteAccount(acc.id);
                                        setModalState(() {});
                                      },
                                    ),
                                  ],
                                ],
                              ),
                              onTap: () {
                                setState(() => _selectedAccountId = acc.id);
                                _saveData();
                                Navigator.pop(context);
                              },
                            ),
                          );
                        },
                      ),
                    ),
                  ],
                ),
              );
            },
          ),
        );
      },
    );
  }

  void _showCreateAccountDialog(BuildContext ctx) {
    String accName = '';
    String selectedIcon = 'wallet';

    final iconOptions = [
      {'type': 'wallet', 'icon': Icons.account_balance_wallet},
      {'type': 'bank', 'icon': Icons.account_balance},
      {'type': 'savings', 'icon': Icons.savings},
      {'type': 'cash', 'icon': Icons.payments},
      {'type': 'card', 'icon': Icons.credit_card},
    ];

    showDialog(
      context: ctx,
      builder: (_) {
        return Directionality(
          textDirection: _selectedLang == 'ar' ? TextDirection.rtl : TextDirection.ltr,
          child: StatefulBuilder(
            builder: (context, setDialogState) {
              return AlertDialog(
                backgroundColor: _isDarkMode ? const Color(0xFF1E1E1E) : Colors.white,
                title: Text(t('add_account'), style: TextStyle(color: _isDarkMode ? Colors.white : Colors.black)),
                content: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    TextField(
                      autofocus: true,
                      style: TextStyle(color: _isDarkMode ? Colors.white : Colors.black),
                      decoration: InputDecoration(
                        labelText: t('account_name'),
                        hintText: 'CIH, Jib, Tawfir...',
                        border: const OutlineInputBorder(),
                      ),
                      onChanged: (val) => accName = val,
                    ),
                    const SizedBox(height: 16),
                    SingleChildScrollView(
                      scrollDirection: Axis.horizontal,
                      child: Row(
                        children: iconOptions.map((opt) {
                          final isSel = selectedIcon == opt['type'];
                          return GestureDetector(
                            onTap: () => setDialogState(() => selectedIcon = opt['type'] as String),
                            child: Container(
                              margin: const EdgeInsets.symmetric(horizontal: 4),
                              padding: const EdgeInsets.all(10),
                              decoration: BoxDecoration(
                                color: isSel ? Colors.blue.withOpacity(0.2) : Colors.transparent,
                                border: Border.all(color: isSel ? Colors.blue : Colors.grey.withOpacity(0.3)),
                                borderRadius: BorderRadius.circular(10),
                              ),
                              child: Icon(opt['icon'] as IconData, color: isSel ? Colors.blue : Colors.grey),
                            ),
                          );
                        }).toList(),
                      ),
                    ),
                  ],
                ),
                actions: [
                  TextButton(
                    onPressed: () => Navigator.pop(context),
                    child: Text(_selectedLang == 'dr' ? 'Ilghe' : 'Cancel'),
                  ),
                  ElevatedButton(
                    onPressed: () {
                      if (accName.trim().isNotEmpty) {
                        _addNewAccount(accName.trim(), selectedIcon);
                        Navigator.pop(context);
                      }
                    },
                    style: ElevatedButton.styleFrom(backgroundColor: Colors.blue[900]),
                    child: Text(t('save'), style: const TextStyle(color: Colors.white)),
                  ),
                ],
              );
            },
          ),
        );
      },
    );
  }

  void _startAddNewTransaction(BuildContext ctx) {
    String titleInput = '';
    String amountInput = '';
    bool isExpenseType = true;
    String selectedCat = 'food';
    String txAccountId = _selectedAccountId == 'all' ? (_accounts.first.id) : _selectedAccountId;

    showModalBottomSheet(
      context: ctx,
      isScrollControlled: true,
      backgroundColor: _isDarkMode ? const Color(0xFF1E1E1E) : Colors.white,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
      builder: (_) {
        return Directionality(
          textDirection: _selectedLang == 'ar' ? TextDirection.rtl : TextDirection.ltr,
          child: StatefulBuilder(
            builder: (context, setModalState) {
              return SingleChildScrollView(
                child: Padding(
                  padding: EdgeInsets.only(
                    top: 20,
                    left: 20,
                    right: 20,
                    bottom: MediaQuery.of(context).viewInsets.bottom + 20,
                  ),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      TextField(
                        style: TextStyle(color: _isDarkMode ? Colors.white : Colors.black),
                        decoration: InputDecoration(
                          labelText: t('title_label'),
                          labelStyle: TextStyle(color: _isDarkMode ? Colors.white70 : Colors.grey[600]),
                          border: const OutlineInputBorder(),
                        ),
                        onChanged: (val) => titleInput = val,
                      ),
                      const SizedBox(height: 12),
                      TextField(
                        style: TextStyle(color: _isDarkMode ? Colors.white : Colors.black),
                        decoration: InputDecoration(
                          labelText: isExpenseType ? t('amount_loss') : t('amount_gain'),
                          labelStyle: TextStyle(color: _isDarkMode ? Colors.white70 : Colors.grey[600]),
                          border: const OutlineInputBorder(),
                        ),
                        keyboardType: const TextInputType.numberWithOptions(decimal: true),
                        onChanged: (val) => amountInput = val,
                      ),
                      const SizedBox(height: 12),
                      Row(
                        children: [
                          Icon(Icons.account_balance_wallet, color: Colors.blue[800], size: 20),
                          const SizedBox(width: 8),
                          Text(
                            '${t('select_account')}: ',
                            style: TextStyle(fontWeight: FontWeight.bold, color: _isDarkMode ? Colors.white70 : Colors.black87),
                          ),
                          const SizedBox(width: 8),
                          Expanded(
                            child: DropdownButtonHideUnderline(
                              child: DropdownButton<String>(
                                isExpanded: true,
                                value: txAccountId,
                                dropdownColor: _isDarkMode ? Colors.grey[900] : Colors.white,
                                style: TextStyle(
                                  color: _isDarkMode ? Colors.white : Colors.black,
                                  fontWeight: FontWeight.bold,
                                ),
                                items: _accounts.map((a) {
                                  return DropdownMenuItem<String>(
                                    value: a.id,
                                    child: Row(
                                      children: [
                                        Icon(a.icon, size: 18, color: Colors.amber[800]),
                                        const SizedBox(width: 8),
                                        Expanded(child: Text(a.name, overflow: TextOverflow.ellipsis)),
                                      ],
                                    ),
                                  );
                                }).toList(),
                                onChanged: (val) {
                                  if (val != null) {
                                    setModalState(() => txAccountId = val);
                                  }
                                },
                              ),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 12),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Expanded(
                            child: Text(
                              isExpenseType ? "🔻 ${t('amount_loss')}" : "🟢 ${t('amount_gain')}",
                              style: TextStyle(
                                fontSize: 15,
                                fontWeight: FontWeight.bold,
                                color: isExpenseType ? Colors.redAccent : Colors.greenAccent,
                              ),
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                          Switch(
                            value: isExpenseType,
                            activeColor: Colors.redAccent,
                            inactiveThumbColor: Colors.greenAccent,
                            onChanged: (val) => setModalState(() => isExpenseType = val),
                          )
                        ],
                      ),
                      if (isExpenseType) ...[
                        const SizedBox(height: 15),
                        SingleChildScrollView(
                          scrollDirection: Axis.horizontal,
                          child: Row(
                            children: _categoryIcons.entries.map((entry) {
                              final isSelected = selectedCat == entry.key;
                              return GestureDetector(
                                onTap: () => setModalState(() => selectedCat = entry.key),
                                child: Container(
                                  margin: const EdgeInsets.symmetric(horizontal: 5),
                                  padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                                  decoration: BoxDecoration(
                                    color: isSelected
                                        ? (_isDarkMode ? Colors.blue[900] : Colors.blue[100])
                                        : Colors.transparent,
                                    border: Border.all(
                                      color: isSelected ? Colors.blue : Colors.grey.withOpacity(0.3),
                                    ),
                                    borderRadius: BorderRadius.circular(15),
                                  ),
                                  child: Column(
                                    children: [
                                      Icon(entry.value, color: isSelected ? Colors.blue : Colors.grey, size: 28),
                                      const SizedBox(height: 4),
                                      Text(
                                        t('cat_${entry.key}'),
                                        style: TextStyle(
                                          fontSize: 11,
                                          color: _isDarkMode ? Colors.white70 : Colors.black87,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              );
                            }).toList(),
                          ),
                        )
                      ],
                      const SizedBox(height: 20),
                      ElevatedButton(
                        onPressed: () {
                          final enteredAmount = double.tryParse(amountInput);
                          if (titleInput.trim().isEmpty || enteredAmount == null || enteredAmount <= 0) return;
                          _addNewTransaction(titleInput.trim(), enteredAmount, isExpenseType, selectedCat, txAccountId);
                          Navigator.of(ctx).pop();
                        },
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.blue[900],
                          padding: const EdgeInsets.symmetric(vertical: 15),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                        ),
                        child: Text(
                          t('save'),
                          style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 16),
                        ),
                      ),
                    ],
                  ),
                ),
              );
            },
          ),
        );
      },
    );
  }

  void _showCategoryDetails(BuildContext context, String categoryId, List<Transaction> categoryTransactions) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: _isDarkMode ? const Color(0xFF1E1E1E) : Colors.white,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
      builder: (_) {
        return Directionality(
          textDirection: _selectedLang == 'ar' ? TextDirection.rtl : TextDirection.ltr,
          child: Container(
            padding: const EdgeInsets.all(20),
            height: MediaQuery.of(context).size.height * 0.6,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    CircleAvatar(
                      backgroundColor: _categoryColors[categoryId]?.withOpacity(0.2),
                      child: Icon(_categoryIcons[categoryId], color: _categoryColors[categoryId]),
                    ),
                    const SizedBox(width: 15),
                    Expanded(
                      child: Text(
                        t('cat_$categoryId'),
                        style: TextStyle(
                          fontSize: 22,
                          fontWeight: FontWeight.bold,
                          color: _isDarkMode ? Colors.white : Colors.black,
                        ),
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                  ],
                ),
                const Divider(height: 30),
                Expanded(
                  child: categoryTransactions.isEmpty
                      ? const Center(child: Text("Makayn walo hna!"))
                      : ListView.builder(
                          itemCount: categoryTransactions.length,
                          itemBuilder: (ctx, i) {
                            final tx = categoryTransactions[i];
                            final acc = _getAccount(tx.accountId);
                            return ListTile(
                              contentPadding: EdgeInsets.zero,
                              title: Text(
                                tx.title,
                                style: TextStyle(
                                  fontWeight: FontWeight.bold,
                                  color: _isDarkMode ? Colors.white : Colors.black,
                                ),
                              ),
                              subtitle: Row(
                                children: [
                                  Text(
                                    "${tx.date.year}-${tx.date.month.toString().padLeft(2, '0')}-${tx.date.day.toString().padLeft(2, '0')}",
                                    style: TextStyle(color: _isDarkMode ? Colors.grey[400] : Colors.grey[600]),
                                  ),
                                  const SizedBox(width: 8),
                                  Flexible(
                                    child: Container(
                                      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 1),
                                      decoration: BoxDecoration(
                                        color: Colors.blue.withOpacity(0.15),
                                        borderRadius: BorderRadius.circular(6),
                                      ),
                                      child: Text(
                                        acc.name,
                                        style: const TextStyle(fontSize: 10, color: Colors.blue),
                                        overflow: TextOverflow.ellipsis,
                                      ),
                                    ),
                                  )
                                ],
                              ),
                              trailing: Text(
                                '- ${tx.amount.toStringAsFixed(2)} ${t('currency')}',
                                style: const TextStyle(
                                  color: Colors.redAccent,
                                  fontWeight: FontWeight.bold,
                                  fontSize: 16,
                                ),
                                textDirection: TextDirection.ltr,
                              ),
                            );
                          },
                        ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Theme(
      data: _isDarkMode
          ? ThemeData.dark().copyWith(
              primaryColor: Colors.blue[900],
              scaffoldBackgroundColor: Colors.transparent,
              cardColor: const Color(0xFF1E1E1E),
            )
          : ThemeData.light().copyWith(
              primaryColor: Colors.blue[900],
              scaffoldBackgroundColor: Colors.transparent,
            ),
      child: InteractiveBackground(
        isDark: _isDarkMode,
        child: Directionality(
          textDirection: _selectedLang == 'ar' ? TextDirection.rtl : TextDirection.ltr,
          child: Scaffold(
            backgroundColor: Colors.transparent,
            appBar: AppBar(
              title: Text(
                t('app_title'),
                style: const TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold),
              ),
              centerTitle: true,
              backgroundColor: _isDarkMode ? Colors.black.withOpacity(0.85) : Colors.blue[900]!.withOpacity(0.85),
              elevation: 0,
              actions: [
                PopupMenuButton<String>(
                  icon: const Icon(Icons.save_alt, color: Colors.greenAccent),
                  onSelected: (result) {
                    if (result == 'export') _exportData();
                    if (result == 'import') _importData();
                  },
                  itemBuilder: (context) => const [
                    PopupMenuItem(value: 'export', child: Text('Copier l-Historique 📋')),
                    PopupMenuItem(value: 'import', child: Text('Coller l-Historique 📥')),
                  ],
                ),
                IconButton(
                  icon: Icon(_isDarkMode ? Icons.light_mode : Icons.dark_mode, color: Colors.yellowAccent),
                  onPressed: () {
                    setState(() {
                      _isDarkMode = !_isDarkMode;
                      _saveData();
                    });
                  },
                ),
                PopupMenuButton<String>(
                  icon: const Icon(Icons.language, color: Colors.white),
                  onSelected: (result) {
                    setState(() {
                      _selectedLang = result;
                      _saveData();
                    });
                  },
                  itemBuilder: (context) => const [
                    PopupMenuItem(value: 'dr', child: Text('Darija 🇲🇦')),
                    PopupMenuItem(value: 'en', child: Text('English 🇺🇸')),
                    PopupMenuItem(value: 'ar', child: Text('العربية 🇸🇦')),
                  ],
                ),
              ],
            ),
            body: _isLoading
                ? const Center(child: CircularProgressIndicator())
                : PageView(
                    controller: _pageController,
                    onPageChanged: (index) => setState(() => _selectedIndex = index),
                    children: [_buildHomeTab(), _buildStatsTab()],
                  ),
            floatingActionButton: _selectedIndex == 0
                ? FloatingActionButton(
                    onPressed: () => _startAddNewTransaction(context),
                    backgroundColor: _isDarkMode ? Colors.blue[800] : Colors.blue[900],
                    child: const Icon(Icons.add, color: Colors.white),
                  )
                : null,
            bottomNavigationBar: NavigationBar(
              selectedIndex: _selectedIndex,
              onDestinationSelected: (index) => _pageController.animateToPage(
                index,
                duration: const Duration(milliseconds: 300),
                curve: Curves.easeInOut,
              ),
              backgroundColor: _isDarkMode ? Colors.black.withOpacity(0.9) : Colors.white.withOpacity(0.9),
              destinations: [
                NavigationDestination(icon: const Icon(Icons.list), label: t('nav_home')),
                NavigationDestination(icon: const Icon(Icons.pie_chart), label: t('nav_stats')),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildHomeTab() {
    final filtered = _filteredTransactions;

    return Column(
      children: [
        // Account Selector Bar
        GestureDetector(
          onTap: () => _showAccountsSheet(context),
          child: Container(
            margin: const EdgeInsets.only(top: 12, left: 20, right: 20),
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
            decoration: BoxDecoration(
              color: _isDarkMode ? Colors.grey[900]!.withOpacity(0.85) : Colors.white.withOpacity(0.85),
              borderRadius: BorderRadius.circular(30),
              border: Border.all(color: Colors.blue.withOpacity(0.4)),
              boxShadow: const [BoxShadow(color: Colors.black12, blurRadius: 6)],
            ),
            child: Row(
              children: [
                Expanded(
                  child: Row(
                    children: [
                      Icon(
                        _selectedAccountId == 'all' ? Icons.dashboard : _getAccount(_selectedAccountId).icon,
                        color: Colors.blueAccent,
                        size: 20,
                      ),
                      const SizedBox(width: 8),
                      Flexible(
                        child: Text(
                          _currentAccountName,
                          style: TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: 15,
                            color: _isDarkMode ? Colors.white : Colors.black87,
                          ),
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 8),
                Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      '(${_accounts.length} kontat)',
                      style: TextStyle(fontSize: 12, color: _isDarkMode ? Colors.grey[400] : Colors.grey[600]),
                    ),
                    const SizedBox(width: 4),
                    const Icon(Icons.keyboard_arrow_down, color: Colors.blueAccent),
                  ],
                ),
              ],
            ),
          ),
        ),

        // Total Balance Card
        Container(
          width: double.infinity,
          margin: const EdgeInsets.all(20),
          padding: const EdgeInsets.all(24),
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: _isDarkMode
                  ? [Colors.blue.shade900.withOpacity(0.9), Colors.black.withOpacity(0.9)]
                  : [Colors.blue.shade900.withOpacity(0.9), Colors.blue.shade600.withOpacity(0.9)],
            ),
            borderRadius: BorderRadius.circular(20),
            boxShadow: const [BoxShadow(color: Colors.black26, blurRadius: 10, offset: Offset(0, 5))],
          ),
          child: Column(
            children: [
              Text(
                '${t('total_balance')} ($_currentAccountName)',
                style: const TextStyle(color: Colors.white70, fontSize: 16),
                overflow: TextOverflow.ellipsis,
              ),
              const SizedBox(height: 8),
              FittedBox(
                fit: BoxFit.scaleDown,
                child: Text(
                  '${_currentBalance.toStringAsFixed(2)} ${t('currency')}',
                  style: const TextStyle(color: Colors.white, fontSize: 38, fontWeight: FontWeight.bold),
                  textDirection: TextDirection.ltr,
                ),
              ),
            ],
          ),
        ),

        // Transactions List
        Expanded(
          child: filtered.isEmpty
              ? Center(child: Text(t('empty_list'), style: const TextStyle(fontSize: 16)))
              : ListView.builder(
                  itemCount: filtered.length,
                  itemBuilder: (ctx, index) {
                    final tx = filtered[index];
                    final acc = _getAccount(tx.accountId);

                    return Card(
                      margin: const EdgeInsets.symmetric(horizontal: 20, vertical: 6),
                      color: _isDarkMode ? Colors.grey[900]!.withOpacity(0.9) : Colors.white.withOpacity(0.9),
                      elevation: _isDarkMode ? 0 : 2,
                      child: ListTile(
                        leading: CircleAvatar(
                          backgroundColor: tx.isExpense ? Colors.red.withOpacity(0.2) : Colors.green.withOpacity(0.2),
                          child: Icon(
                            tx.isExpense ? (_categoryIcons[tx.categoryId] ?? Icons.category) : Icons.account_balance_wallet,
                            color: tx.isExpense ? Colors.red : Colors.green,
                          ),
                        ),
                        title: Text(
                          tx.title,
                          style: const TextStyle(fontWeight: FontWeight.bold),
                          overflow: TextOverflow.ellipsis,
                        ),
                        subtitle: Row(
                          children: [
                            Text(
                              "${tx.date.year}-${tx.date.month.toString().padLeft(2, '0')}-${tx.date.day.toString().padLeft(2, '0')}",
                              style: TextStyle(fontSize: 12, color: _isDarkMode ? Colors.grey[400] : Colors.grey[600]),
                            ),
                            const SizedBox(width: 6),
                            Flexible(
                              child: Container(
                                padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 1),
                                decoration: BoxDecoration(
                                  color: Colors.blue.withOpacity(0.12),
                                  borderRadius: BorderRadius.circular(6),
                                ),
                                child: Row(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    Icon(acc.icon, size: 10, color: Colors.blue),
                                    const SizedBox(width: 3),
                                    Flexible(
                                      child: Text(
                                        acc.name,
                                        style: const TextStyle(fontSize: 10, color: Colors.blue, fontWeight: FontWeight.bold),
                                        overflow: TextOverflow.ellipsis,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ),
                          ],
                        ),
                        trailing: Text(
                          '${tx.isExpense ? '-' : '+'} ${tx.amount.toStringAsFixed(2)} ${t('currency')}',
                          style: TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: 15,
                            color: tx.isExpense ? Colors.redAccent : Colors.greenAccent,
                          ),
                          textDirection: TextDirection.ltr,
                        ),
                        onLongPress: () => _deleteTransaction(tx.id),
                      ),
                    );
                  },
                ),
        ),
      ],
    );
  }

  Widget _buildStatsTab() {
    Map<String, List<Transaction>> catTransactions = {};
    double totalExpense = 0.0;
    int currentYear = DateTime.now().year;

    final filtered = _filteredTransactions;

    for (var tx in filtered) {
      if (tx.isExpense) {
        int txQuarter = (tx.date.month - 1) ~/ 3 + 1;
        bool matchQuarter = _selectedQuarter == 0 || (txQuarter == _selectedQuarter && tx.date.year == currentYear);
        if (matchQuarter) {
          if (!catTransactions.containsKey(tx.categoryId)) {
            catTransactions[tx.categoryId] = [];
          }
          catTransactions[tx.categoryId]!.add(tx);
          totalExpense += tx.amount;
        }
      }
    }

    return Column(
      children: [
        const SizedBox(height: 16),
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
              decoration: BoxDecoration(
                color: _isDarkMode ? Colors.grey[800] : Colors.white,
                borderRadius: BorderRadius.circular(15),
                boxShadow: const [BoxShadow(color: Colors.black12, blurRadius: 5)],
              ),
              child: DropdownButtonHideUnderline(
                child: DropdownButton<int>(
                  value: _selectedQuarter,
                  dropdownColor: _isDarkMode ? Colors.grey[800] : Colors.white,
                  icon: Icon(Icons.filter_alt, color: _isDarkMode ? Colors.white : Colors.blue[900]),
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 15,
                    color: _isDarkMode ? Colors.white : Colors.black,
                  ),
                  items: [
                    DropdownMenuItem(value: 0, child: Text(t('filter_0'))),
                    DropdownMenuItem(value: 1, child: Text(t('filter_1'))),
                    DropdownMenuItem(value: 2, child: Text(t('filter_2'))),
                    DropdownMenuItem(value: 3, child: Text(t('filter_3'))),
                    DropdownMenuItem(value: 4, child: Text(t('filter_4'))),
                  ],
                  onChanged: (val) {
                    setState(() {
                      _selectedQuarter = val!;
                    });
                  },
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 16),
        Expanded(
          child: totalExpense == 0
              ? Center(child: Text(t('no_expenses'), style: const TextStyle(fontSize: 18)))
              : SingleChildScrollView(
                  child: Column(
                    children: [
                      Text(t('stats_title'), style: const TextStyle(fontSize: 22, fontWeight: FontWeight.bold)),
                      const SizedBox(height: 24),
                      SizedBox(
                        width: 220,
                        height: 220,
                        child: CustomPaint(
                          painter: DonutChartPainter(
                            sections: catTransactions.entries.map((entry) {
                              double catTotal = entry.value.fold(0.0, (sum, item) => sum + item.amount);
                              final percentage = (catTotal / totalExpense) * 100;
                              return PieSectionItem(
                                color: _categoryColors[entry.key] ?? Colors.grey,
                                value: catTotal,
                                title: '${percentage.toStringAsFixed(0)}%',
                              );
                            }).toList(),
                          ),
                        ),
                      ),
                      const SizedBox(height: 24),
                      ...catTransactions.entries.map((entry) {
                        double catTotal = entry.value.fold(0.0, (sum, item) => sum + item.amount);
                        return Card(
                          margin: const EdgeInsets.symmetric(horizontal: 20, vertical: 5),
                          elevation: 0,
                          color: Colors.transparent,
                          child: ListTile(
                            onTap: () => _showCategoryDetails(context, entry.key, entry.value),
                            leading: Icon(_categoryIcons[entry.key], color: _categoryColors[entry.key]),
                            title: Text(t('cat_${entry.key}'), style: const TextStyle(fontWeight: FontWeight.bold)),
                            trailing: Text(
                              '${catTotal.toStringAsFixed(2)} ${t('currency')}',
                              style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                            ),
                          ),
                        );
                      }),
                    ],
                  ),
                ),
        ),
      ],
    );
  }
}

extension IterableExtension<T> on Iterable<T> {
  T? firstOrNullWhere(bool Function(T element) test) {
    for (var element in this) {
      if (test(element)) return element;
    }
    return null;
  }
}
