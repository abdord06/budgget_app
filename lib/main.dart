import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:fl_chart/fl_chart.dart';
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

// --- MODEL TRANSACTION ---
class Transaction {
  final String id;
  final String title;
  final double amount;
  final DateTime date;
  final bool isExpense;
  final String categoryId;

  Transaction({
    required this.id,
    required this.title,
    required this.amount,
    required this.date,
    required this.isExpense,
    required this.categoryId,
  });

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'title': title,
      'amount': amount,
      'date': date.toIso8601String(),
      'isExpense': isExpense,
      'categoryId': categoryId,
    };
  }

  factory Transaction.fromMap(Map<String, dynamic> map) {
    return Transaction(
      id: map['id'],
      title: map['title'],
      amount: map['amount'],
      date: DateTime.parse(map['date']),
      isExpense: map['isExpense'],
      categoryId: map['categoryId'] ?? 'other',
    );
  }
}

// --- ₿ WIDGET: 3D BITCOIN BACKGROUND ---
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
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 15), // Dour bchwiya 3la mhlha
    )..repeat();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onPanUpdate: (details) {
        setState(() {
          _yOffset += details.delta.dx / 80;
          _xOffset -= details.delta.dy / 80;
        });
      },
      child: Stack(
        children: [
          // 1. LAYER BITCOIN 3D 🔶
          Positioned.fill(
            child: Container(
              color: widget.isDark ? const Color(0xFF121212) : Colors.grey[100],
              child: Center(
                child: AnimatedBuilder(
                  animation: _controller,
                  builder: (context, child) {
                    final double autoRotate = _controller.value * 2 * math.pi;
                    
                    return Transform(
                      transform: Matrix4.identity()
                        ..setEntry(3, 2, 0.001)
                        ..rotateX(_xOffset)
                        ..rotateY(autoRotate + _yOffset),
                      alignment: Alignment.center,
                      child: Opacity(
                        opacity: widget.isDark ? 0.2 : 0.3, // Zdna l-Wdo7 bach tban mziyan!
                        child: Container(
                          width: 350, // Kbbarna l-7ajm
                          height: 350,
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            gradient: const LinearGradient(
                              colors: [Color(0xFFF7931A), Color(0xFFB15F00)], // Lwan Bitcoin Orignal
                              begin: Alignment.topLeft,
                              end: Alignment.bottomRight,
                            ),
                            boxShadow: [
                              BoxShadow(
                                color: Colors.orange.withOpacity(0.6),
                                blurRadius: 60,
                                spreadRadius: 10,
                              )
                            ],
                            border: Border.all(color: const Color(0xFFF7931A), width: 8), // Bordure dhabiya
                          ),
                          child: const Center(
                            child: Text(
                              '₿', // Ramz Bitcoin
                              style: TextStyle(
                                fontSize: 220,
                                color: Colors.white,
                                fontWeight: FontWeight.w900, // Ghlid bzaf
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
          
          // 2. APP FOREGROUND
          widget.child,
        ],
      ),
    );
  }
}

// --- MAIN SCREEN ---
class MainScreen extends StatefulWidget {
  const MainScreen({super.key});

  @override
  State<MainScreen> createState() => _MainScreenState();
}

class _MainScreenState extends State<MainScreen> {
  List<Transaction> _transactions = [];
  bool _isLoading = true;
  String _selectedLang = 'dr'; 
  bool _isDarkMode = false;
  int _selectedIndex = 0;
  late PageController _pageController;

  final Map<String, IconData> _categoryIcons = {
    'food': Icons.fastfood, 'transport': Icons.directions_car, 'home': Icons.home,
    'fun': Icons.sports_esports, 'clothes': Icons.checkroom, 'other': Icons.shopping_bag,
  };

  final Map<String, Color> _categoryColors = {
    'food': Colors.orange, 'transport': Colors.blue, 'home': Colors.purple,
    'fun': Colors.pink, 'clothes': Colors.teal, 'other': Colors.grey,
  };

  final Map<String, Map<String, String>> _dictionary = {
    'dr': {
      'app_title': 'Masroufi Pro 🇲🇦', 'total_balance': 'Rass l-mal', 'empty_list': 'Yallah bda t-9yyed masrouf!',
      'add_btn': 'Zid 3amaliya', 'title_label': 'Fash? (Titre)', 'amount_loss': 'Ch7al mcha? (DH)',
      'amount_gain': 'Ch7al dkhl? (DH)', 'save': 'Sajal', 'currency': 'DH', 'nav_home': 'Ra2issiya',
      'nav_stats': 'Mibyanat', 'stats_title': 'Fin mchat l-flouss?', 'no_expenses': 'Mazal ma khssrti walo! 🎉',
      'cat_food': 'Mkla', 'cat_transport': 'Transport', 'cat_home': 'Dar/Kira', 'cat_fun': 'L3ib',
      'cat_clothes': '7wayj', 'cat_other': 'Okhrin',
    },
    'en': {
      'app_title': 'My Budget 🇺🇸', 'total_balance': 'Total Balance', 'empty_list': 'No transactions yet!',
      'add_btn': 'Add', 'title_label': 'Title', 'amount_loss': 'Amount Spent', 'amount_gain': 'Amount Earned',
      'save': 'Save', 'currency': '\$', 'nav_home': 'Home', 'nav_stats': 'Stats', 'stats_title': 'Where did money go?',
      'no_expenses': 'No expenses yet! 🎉', 'cat_food': 'Food', 'cat_transport': 'Transport', 'cat_home': 'Rent',
      'cat_fun': 'Fun', 'cat_clothes': 'Clothes', 'cat_other': 'Other',
    },
    'ar': {
      'app_title': 'مصروفي 🇸🇦', 'total_balance': 'الرصيد', 'empty_list': 'لا توجد معاملات', 'add_btn': 'إضافة',
      'title_label': 'العنوان', 'amount_loss': 'كم صرفت؟', 'amount_gain': 'كم ربحت؟', 'save': 'حفظ', 'currency': 'د.م',
      'nav_home': 'الرئيسية', 'nav_stats': 'إحصائيات', 'stats_title': 'أين ذهب المال؟', 'no_expenses': 'لم تصرف شيئاً بعد! 🎉',
      'cat_food': 'أكل', 'cat_transport': 'نقل', 'cat_home': 'منزل', 'cat_fun': 'ترفيه', 'cat_clothes': 'ملابس', 'cat_other': 'أخرى',
    },
  };

  @override
  void initState() {
    super.initState();
    _pageController = PageController();
    _loadData();
  }

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  Future<void> _saveData() async {
    final prefs = await SharedPreferences.getInstance();
    final String encodedData = jsonEncode(_transactions.map((tx) => tx.toMap()).toList());
    await prefs.setString('tx_data', encodedData);
    await prefs.setString('lang', _selectedLang);
    await prefs.setBool('isDark', _isDarkMode);
  }

  Future<void> _loadData() async {
    final prefs = await SharedPreferences.getInstance();
    if (prefs.containsKey('lang')) _selectedLang = prefs.getString('lang') ?? 'dr';
    if (prefs.containsKey('isDark')) _isDarkMode = prefs.getBool('isDark') ?? false;

    final String? encodedData = prefs.getString('tx_data');
    if (encodedData != null) {
      final List<dynamic> decodedList = jsonDecode(encodedData);
      setState(() {
        _transactions = decodedList.map((item) => Transaction.fromMap(item)).toList();
        _isLoading = false;
      });
    } else {
      setState(() => _isLoading = false);
    }
  }

  double get _currentBalance {
    double balance = 0.0;
    for (var tx in _transactions) {
      if (tx.isExpense) balance -= tx.amount; else balance += tx.amount;
    }
    return balance;
  }

  String t(String key) => _dictionary[_selectedLang]![key] ?? key;

  void _addNewTransaction(String txTitle, double txAmount, bool isExpense, String categoryId) {
    final newTx = Transaction(
      title: txTitle, amount: txAmount, date: DateTime.now(), id: DateTime.now().toString(),
      isExpense: isExpense, categoryId: isExpense ? categoryId : 'income',
    );
    setState(() => _transactions.insert(0, newTx));
    _saveData();
  }

  void _deleteTransaction(String id) {
    setState(() => _transactions.removeWhere((tx) => tx.id == id));
    _saveData();
  }

  void _onPageChanged(int index) => setState(() => _selectedIndex = index);
  void _onItemTapped(int index) => _pageController.animateToPage(index, duration: const Duration(milliseconds: 300), curve: Curves.easeInOut);

  void _startAddNewTransaction(BuildContext ctx) {
    String titleInput = ''; String amountInput = ''; bool isExpenseType = true; String selectedCat = 'food';
    showModalBottomSheet(
      context: ctx, isScrollControlled: true,
      backgroundColor: _isDarkMode ? Colors.grey[900] : Colors.white,
      builder: (_) {
        return Directionality(
          textDirection: _selectedLang == 'ar' ? TextDirection.rtl : TextDirection.ltr,
          child: StatefulBuilder(
            builder: (context, setModalState) {
              return Padding(
                padding: EdgeInsets.only(top: 20, left: 20, right: 20, bottom: MediaQuery.of(context).viewInsets.bottom + 20),
                child: Column(
                  mainAxisSize: MainAxisSize.min, crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    TextField(
                      style: TextStyle(color: _isDarkMode ? Colors.white : Colors.black),
                      decoration: InputDecoration(
                        labelText: t('title_label'), labelStyle: TextStyle(color: _isDarkMode ? Colors.white70 : Colors.grey[600]),
                        border: const OutlineInputBorder(),
                      ),
                      onChanged: (val) => titleInput = val,
                    ),
                    const SizedBox(height: 10),
                    TextField(
                      style: TextStyle(color: _isDarkMode ? Colors.white : Colors.black),
                      decoration: InputDecoration(
                        labelText: isExpenseType ? t('amount_loss') : t('amount_gain'),
                        labelStyle: TextStyle(color: _isDarkMode ? Colors.white70 : Colors.grey[600]),
                        border: const OutlineInputBorder(),
                      ),
                      keyboardType: TextInputType.number, onChanged: (val) => amountInput = val,
                    ),
                    const SizedBox(height: 15),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(isExpenseType ? "🔻" : "🟢", style: const TextStyle(fontSize: 20)),
                        Switch(
                          value: isExpenseType, activeColor: Colors.redAccent, inactiveThumbColor: Colors.greenAccent,
                          onChanged: (val) => setModalState(() => isExpenseType = val),
                        ),
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
                                margin: const EdgeInsets.symmetric(horizontal: 5), padding: const EdgeInsets.all(10),
                                decoration: BoxDecoration(
                                  color: isSelected ? (_isDarkMode ? Colors.blue[800] : Colors.blue[100]) : Colors.transparent,
                                  border: Border.all(color: isSelected ? Colors.blue : Colors.grey.withOpacity(0.3)),
                                  borderRadius: BorderRadius.circular(15),
                                ),
                                child: Column(children: [Icon(entry.value, color: isSelected ? Colors.blue : Colors.grey, size: 28), Text(t('cat_${entry.key}'), style: TextStyle(fontSize: 10, color: _isDarkMode ? Colors.white70 : Colors.black87))]),
                              ),
                            );
                          }).toList(),
                        ),
                      ),
                    ],
                    const SizedBox(height: 20),
                    ElevatedButton(
                      onPressed: () {
                        final enteredAmount = double.tryParse(amountInput);
                        if (titleInput.isEmpty || enteredAmount == null || enteredAmount <= 0) return;
                        _addNewTransaction(titleInput, enteredAmount, isExpenseType, selectedCat);
                        Navigator.of(ctx).pop();
                      },
                      style: ElevatedButton.styleFrom(backgroundColor: Colors.blue[800], padding: const EdgeInsets.symmetric(vertical: 15)),
                      child: Text(t('save'), style: const TextStyle(color: Colors.white)),
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

  @override
  Widget build(BuildContext context) {
    return Theme(
      data: _isDarkMode 
        ? ThemeData.dark().copyWith(primaryColor: Colors.blue[900], scaffoldBackgroundColor: Colors.transparent, cardColor: const Color(0xFF1E1E1E))
        : ThemeData.light().copyWith(primaryColor: Colors.blue, scaffoldBackgroundColor: Colors.transparent),
      child: InteractiveBackground(
        isDark: _isDarkMode,
        child: Directionality(
          textDirection: _selectedLang == 'ar' ? TextDirection.rtl : TextDirection.ltr,
          child: Scaffold(
            backgroundColor: Colors.transparent, 
            appBar: AppBar(
              title: Text(t('app_title'), style: const TextStyle(color: Colors.white)),
              centerTitle: true,
              backgroundColor: _isDarkMode ? Colors.black.withOpacity(0.8) : Colors.blue[900]!.withOpacity(0.8),
              elevation: 0,
              actions: [
                IconButton(
                  icon: Icon(_isDarkMode ? Icons.light_mode : Icons.dark_mode, color: Colors.yellowAccent),
                  onPressed: () { setState(() { _isDarkMode = !_isDarkMode; _saveData(); }); },
                ),
                PopupMenuButton<String>(
                  icon: const Icon(Icons.language, color: Colors.white),
                  onSelected: (result) { setState(() { _selectedLang = result; _saveData(); }); },
                  itemBuilder: (context) => const [PopupMenuItem(value: 'dr', child: Text('Darija 🇲🇦')), PopupMenuItem(value: 'en', child: Text('English 🇺🇸')), PopupMenuItem(value: 'ar', child: Text('العربية 🇸🇦'))],
                ),
              ],
            ),
            body: _isLoading 
              ? const Center(child: CircularProgressIndicator()) 
              : PageView(
                  controller: _pageController,
                  onPageChanged: _onPageChanged,
                  children: [_buildHomeTab(), _buildStatsTab()],
                ),
            floatingActionButton: _selectedIndex == 0 
              ? FloatingActionButton(onPressed: () => _startAddNewTransaction(context), backgroundColor: _isDarkMode ? Colors.blue[800] : Colors.blue[900], child: const Icon(Icons.add, color: Colors.white))
              : null,
            bottomNavigationBar: NavigationBar(
              selectedIndex: _selectedIndex, onDestinationSelected: _onItemTapped,
              backgroundColor: _isDarkMode ? Colors.black.withOpacity(0.9) : Colors.white.withOpacity(0.9),
              destinations: [NavigationDestination(icon: const Icon(Icons.list), label: t('nav_home')), NavigationDestination(icon: const Icon(Icons.pie_chart), label: t('nav_stats'))],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildHomeTab() {
    return Column(
      children: [
        Container(
          width: double.infinity, margin: const EdgeInsets.all(20), padding: const EdgeInsets.all(30),
          decoration: BoxDecoration(
            gradient: LinearGradient(colors: _isDarkMode ? [Colors.blue.shade900.withOpacity(0.9), Colors.black.withOpacity(0.9)] : [Colors.blue.shade900.withOpacity(0.9), Colors.blue.shade600.withOpacity(0.9)]),
            borderRadius: BorderRadius.circular(20),
            boxShadow: const [BoxShadow(color: Colors.black26, blurRadius: 10, offset: Offset(0, 5))],
          ),
          child: Column(children: [Text(t('total_balance'), style: const TextStyle(color: Colors.white70, fontSize: 18)), const SizedBox(height: 10), Text('${_currentBalance.toStringAsFixed(2)} ${t('currency')}', style: const TextStyle(color: Colors.white, fontSize: 40, fontWeight: FontWeight.bold), textDirection: TextDirection.ltr)]),
        ),
        Expanded(
          child: _transactions.isEmpty
              ? Center(child: Text(t('empty_list')))
              : ListView.builder(
                  itemCount: _transactions.length,
                  itemBuilder: (ctx, index) {
                    final tx = _transactions[index];
                    return Card(
                      margin: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
                      color: _isDarkMode ? Colors.grey[900]!.withOpacity(0.9) : Colors.white.withOpacity(0.9),
                      elevation: _isDarkMode ? 0 : 2,
                      child: ListTile(
                        leading: CircleAvatar(backgroundColor: tx.isExpense ? Colors.red.withOpacity(0.2) : Colors.green.withOpacity(0.2), child: Icon(tx.isExpense ? (_categoryIcons[tx.categoryId] ?? Icons.category) : Icons.account_balance_wallet, color: tx.isExpense ? Colors.red : Colors.green)),
                        title: Text(tx.title, style: const TextStyle(fontWeight: FontWeight.bold)), subtitle: Text("${tx.date.year}-${tx.date.month}-${tx.date.day}"), trailing: Text('${tx.isExpense ? '-' : '+'} ${tx.amount.toStringAsFixed(2)}', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16, color: tx.isExpense ? Colors.redAccent : Colors.greenAccent), textDirection: TextDirection.ltr),
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
    Map<String, double> catTotals = {}; double totalExpense = 0.0;
    for (var tx in _transactions) { if (tx.isExpense) { catTotals[tx.categoryId] = (catTotals[tx.categoryId] ?? 0) + tx.amount; totalExpense += tx.amount; } }
    if (totalExpense == 0) return Center(child: Text(t('no_expenses'), style: const TextStyle(fontSize: 18)));

    List<PieChartSectionData> sections = catTotals.entries.map((entry) {
      final percentage = (entry.value / totalExpense) * 100;
      return PieChartSectionData(color: _categoryColors[entry.key] ?? Colors.grey, value: entry.value, title: '${percentage.toStringAsFixed(0)}%', radius: 60, titleStyle: const TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: Colors.white));
    }).toList();

    return SingleChildScrollView(
      child: Column(
        children: [
          const SizedBox(height: 20), Text(t('stats_title'), style: const TextStyle(fontSize: 22, fontWeight: FontWeight.bold)), const SizedBox(height: 30),
          SizedBox(height: 250, child: PieChart(PieChartData(sections: sections, centerSpaceRadius: 40, sectionsSpace: 2))),
          const SizedBox(height: 30),
          ...catTotals.entries.map((entry) {
            return Card(
              margin: const EdgeInsets.symmetric(horizontal: 20, vertical: 5), elevation: 0, color: Colors.transparent,
              child: ListTile(leading: Icon(_categoryIcons[entry.key], color: _categoryColors[entry.key]), title: Text(t('cat_${entry.key}'), style: const TextStyle(fontWeight: FontWeight.bold)), trailing: Text('${entry.value.toStringAsFixed(2)} ${t('currency')}', style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16))),
            );
          }),
        ],
      ),
    );
  }
}