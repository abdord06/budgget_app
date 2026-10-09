import 'package:flutter/material.dart';
import 'package:flutter/services.dart'; // 🆕 ZDNA HADI DYAL COPY/PASTE
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

class Transaction {
  final String id;
  final String title;
  final double amount;
  final DateTime date;
  final bool isExpense;
  final String categoryId;

  Transaction({required this.id, required this.title, required this.amount, required this.date, required this.isExpense, required this.categoryId});

  Map<String, dynamic> toMap() => {'id': id, 'title': title, 'amount': amount, 'date': date.toIso8601String(), 'isExpense': isExpense, 'categoryId': categoryId};
  
  factory Transaction.fromMap(Map<String, dynamic> map) => Transaction(id: map['id'], title: map['title'], amount: map['amount'], date: DateTime.parse(map['date']), isExpense: map['isExpense'], categoryId: map['categoryId'] ?? 'other');
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
  void dispose() { _controller.dispose(); super.dispose(); }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onPanUpdate: (details) => setState(() { _yOffset += details.delta.dx / 80; _xOffset -= details.delta.dy / 80; }),
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
                      transform: Matrix4.identity()..setEntry(3, 2, 0.001)..rotateX(_xOffset)..rotateY((_controller.value * 2 * math.pi) + _yOffset),
                      alignment: Alignment.center,
                      child: Opacity(
                        opacity: widget.isDark ? 0.2 : 0.3,
                        child: Container(
                          width: 350, height: 350,
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            gradient: const LinearGradient(colors: [Color(0xFFF7931A), Color(0xFFB15F00)], begin: Alignment.topLeft, end: Alignment.bottomRight),
                            boxShadow: [BoxShadow(color: Colors.orange.withOpacity(0.6), blurRadius: 60, spreadRadius: 10)],
                            border: Border.all(color: const Color(0xFFF7931A), width: 8),
                          ),
                          child: const Center(child: Text('₿', style: TextStyle(fontSize: 220, color: Colors.white, fontWeight: FontWeight.w900))),
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
  List<Transaction> _transactions = [];
  bool _isLoading = true;
  String _selectedLang = 'dr'; 
  bool _isDarkMode = false;
  int _selectedIndex = 0;
  late PageController _pageController;
  int _selectedQuarter = 0; 

  final Map<String, IconData> _categoryIcons = {'food': Icons.fastfood, 'transport': Icons.directions_car, 'home': Icons.home, 'fun': Icons.sports_esports, 'clothes': Icons.checkroom, 'other': Icons.shopping_bag};
  final Map<String, Color> _categoryColors = {'food': Colors.orange, 'transport': Colors.blue, 'home': Colors.purple, 'fun': Colors.pink, 'clothes': Colors.teal, 'other': Colors.grey};
  final Map<String, Map<String, String>> _dictionary = {
    'dr': { 'app_title': 'Masroufi Pro', 'total_balance': 'Rass l-mal', 'empty_list': 'Yallah bda t-9yyed masrouf!', 'add_btn': 'Zid 3amaliya', 'title_label': 'Fash? (Titre)', 'amount_loss': 'Ch7al mcha? (DH)', 'amount_gain': 'Ch7al dkhl? (DH)', 'save': 'Sajal', 'currency': 'DH', 'nav_home': 'Ra2issiya', 'nav_stats': 'Mibyanat', 'stats_title': 'Fin mchat l-flouss?', 'no_expenses': 'Mazal ma khssrti walo!', 'cat_food': 'Mkla', 'cat_transport': 'Transport', 'cat_home': 'Dar', 'cat_fun': 'L3ib', 'cat_clothes': '7wayj', 'cat_other': 'Okhrin', 'filter_0': 'Ga3 l-Ayam', 'filter_1': 'Q1 (Ch-har 1 ➔ 3)', 'filter_2': 'Q2 (Ch-har 4 ➔ 6)', 'filter_3': 'Q3 (Ch-har 7 ➔ 9)', 'filter_4': 'Q4 (Ch-har 10 ➔ 12)' },
    'en': { 'app_title': 'My Budget', 'total_balance': 'Total Balance', 'empty_list': 'No transactions yet!', 'add_btn': 'Add', 'title_label': 'Title', 'amount_loss': 'Amount Spent', 'amount_gain': 'Amount Earned', 'save': 'Save', 'currency': '\$', 'nav_home': 'Home', 'nav_stats': 'Stats', 'stats_title': 'Where did money go?', 'no_expenses': 'No expenses yet!', 'cat_food': 'Food', 'cat_transport': 'Transport', 'cat_home': 'Rent', 'cat_fun': 'Fun', 'cat_clothes': 'Clothes', 'cat_other': 'Other', 'filter_0': 'All Time', 'filter_1': 'Q1 (Jan-Mar)', 'filter_2': 'Q2 (Apr-Jun)', 'filter_3': 'Q3 (Jul-Sep)', 'filter_4': 'Q4 (Oct-Dec)' },
    'ar': { 'app_title': 'مصروفي', 'total_balance': 'الرصيد', 'empty_list': 'لا توجد معاملات', 'add_btn': 'إضافة', 'title_label': 'العنوان', 'amount_loss': 'كم صرفت؟', 'amount_gain': 'كم ربحت؟', 'save': 'حفظ', 'currency': 'د.م', 'nav_home': 'الرئيسية', 'nav_stats': 'إحصائيات', 'stats_title': 'أين ذهب المال؟', 'no_expenses': 'لم تصرف شيئاً بعد!', 'cat_food': 'أكل', 'cat_transport': 'نقل', 'cat_home': 'منزل', 'cat_fun': 'ترفيه', 'cat_clothes': 'ملابس', 'cat_other': 'أخرى', 'filter_0': 'كل الأوقات', 'filter_1': 'الربع الأول (1 ➔ 3)', 'filter_2': 'الربع الثاني (4 ➔ 6)', 'filter_3': 'الربع الثالث (7 ➔ 9)', 'filter_4': 'الربع الرابع (10 ➔ 12)' },
  };

  @override
  void initState() {
    super.initState();
    _pageController = PageController();
    _selectedQuarter = (DateTime.now().month - 1) ~/ 3 + 1;
    _loadData();
  }

  @override
  void dispose() { _pageController.dispose(); super.dispose(); }

  // 🆕 FONCTION: Copier l-historique l-clavier
  Future<void> _exportData() async {
    final prefs = await SharedPreferences.getInstance();
    final String? encodedData = prefs.getString('tx_data');
    if (encodedData != null) {
      await Clipboard.setData(ClipboardData(text: encodedData));
      if(!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('T-copia l-historique mzyan! 📋 Daba mss7 l-app', style: TextStyle(color: Colors.white)), backgroundColor: Colors.green));
    } else {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Makayn walo ma yt-copia!'), backgroundColor: Colors.red));
    }
  }

  // 🆕 FONCTION: Coller l-historique mn l-clavier
  Future<void> _importData() async {
    ClipboardData? clipboardData = await Clipboard.getData('text/plain');
    if (clipboardData != null && clipboardData.text != null && clipboardData.text!.isNotEmpty) {
      try {
        final String encodedData = clipboardData.text!;
        final List<dynamic> decodedList = jsonDecode(encodedData);
        setState(() {
          _transactions = decodedList.map((item) => Transaction.fromMap(item)).toList();
        });
        _saveData();
        if(!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Rje3 l-historique! 🎉', style: TextStyle(color: Colors.white)), backgroundColor: Colors.green));
      } catch (e) {
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Ghalat f l-code dyal l-historique! ❌'), backgroundColor: Colors.red));
      }
    }
  }

  Future<void> _saveData() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('tx_data', jsonEncode(_transactions.map((tx) => tx.toMap()).toList()));
    await prefs.setString('lang', _selectedLang);
    await prefs.setBool('isDark', _isDarkMode);
  }

  Future<void> _loadData() async {
    final prefs = await SharedPreferences.getInstance();
    if (prefs.containsKey('lang')) _selectedLang = prefs.getString('lang') ?? 'dr';
    if (prefs.containsKey('isDark')) _isDarkMode = prefs.getBool('isDark') ?? false;
    final String? encodedData = prefs.getString('tx_data');
    if (encodedData != null) setState(() { _transactions = (jsonDecode(encodedData) as List).map((item) => Transaction.fromMap(item)).toList(); _isLoading = false; });
    else setState(() => _isLoading = false);
  }

  double get _currentBalance {
    double balance = 0.0;
    for (var tx in _transactions) { if (tx.isExpense) balance -= tx.amount; else balance += tx.amount; }
    return balance;
  }

  String t(String key) => _dictionary[_selectedLang]![key] ?? key;

  void _addNewTransaction(String txTitle, double txAmount, bool isExpense, String categoryId) {
    setState(() => _transactions.insert(0, Transaction(title: txTitle, amount: txAmount, date: DateTime.now(), id: DateTime.now().toString(), isExpense: isExpense, categoryId: isExpense ? categoryId : 'income')));
    _saveData();
  }

  void _deleteTransaction(String id) { setState(() => _transactions.removeWhere((tx) => tx.id == id)); _saveData(); }

  void _startAddNewTransaction(BuildContext ctx) {
    String titleInput = ''; String amountInput = ''; bool isExpenseType = true; String selectedCat = 'food';
    showModalBottomSheet(
      context: ctx, isScrollControlled: true, backgroundColor: _isDarkMode ? Colors.grey[900] : Colors.white,
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
                    TextField(style: TextStyle(color: _isDarkMode ? Colors.white : Colors.black), decoration: InputDecoration(labelText: t('title_label'), labelStyle: TextStyle(color: _isDarkMode ? Colors.white70 : Colors.grey[600]), border: const OutlineInputBorder()), onChanged: (val) => titleInput = val),
                    const SizedBox(height: 10),
                    TextField(style: TextStyle(color: _isDarkMode ? Colors.white : Colors.black), decoration: InputDecoration(labelText: isExpenseType ? t('amount_loss') : t('amount_gain'), labelStyle: TextStyle(color: _isDarkMode ? Colors.white70 : Colors.grey[600]), border: const OutlineInputBorder()), keyboardType: TextInputType.number, onChanged: (val) => amountInput = val),
                    const SizedBox(height: 15),
                    Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [Text(isExpenseType ? "🔻" : "🟢", style: const TextStyle(fontSize: 20)), Switch(value: isExpenseType, activeColor: Colors.redAccent, inactiveThumbColor: Colors.greenAccent, onChanged: (val) => setModalState(() => isExpenseType = val))]),
                    if (isExpenseType) ...[const SizedBox(height: 15), SingleChildScrollView(scrollDirection: Axis.horizontal, child: Row(children: _categoryIcons.entries.map((entry) { final isSelected = selectedCat == entry.key; return GestureDetector(onTap: () => setModalState(() => selectedCat = entry.key), child: Container(margin: const EdgeInsets.symmetric(horizontal: 5), padding: const EdgeInsets.all(10), decoration: BoxDecoration(color: isSelected ? (_isDarkMode ? Colors.blue[800] : Colors.blue[100]) : Colors.transparent, border: Border.all(color: isSelected ? Colors.blue : Colors.grey.withOpacity(0.3)), borderRadius: BorderRadius.circular(15)), child: Column(children: [Icon(entry.value, color: isSelected ? Colors.blue : Colors.grey, size: 28), Text(t('cat_${entry.key}'), style: TextStyle(fontSize: 10, color: _isDarkMode ? Colors.white70 : Colors.black87))]))); }).toList()))],
                    const SizedBox(height: 20),
                    ElevatedButton(onPressed: () { final enteredAmount = double.tryParse(amountInput); if (titleInput.isEmpty || enteredAmount == null || enteredAmount <= 0) return; _addNewTransaction(titleInput, enteredAmount, isExpenseType, selectedCat); Navigator.of(ctx).pop(); }, style: ElevatedButton.styleFrom(backgroundColor: Colors.blue[800], padding: const EdgeInsets.symmetric(vertical: 15)), child: Text(t('save'), style: const TextStyle(color: Colors.white))),
                  ],
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
      context: context, isScrollControlled: true, backgroundColor: _isDarkMode ? Colors.grey[900] : Colors.white, shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
      builder: (_) {
        return Directionality(
          textDirection: _selectedLang == 'ar' ? TextDirection.rtl : TextDirection.ltr,
          child: Container(
            padding: const EdgeInsets.all(20), height: MediaQuery.of(context).size.height * 0.6,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(children: [CircleAvatar(backgroundColor: _categoryColors[categoryId]?.withOpacity(0.2), child: Icon(_categoryIcons[categoryId], color: _categoryColors[categoryId])), const SizedBox(width: 15), Text(t('cat_$categoryId'), style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold, color: _isDarkMode ? Colors.white : Colors.black))]),
                const Divider(height: 30),
                Expanded(child: categoryTransactions.isEmpty ? const Center(child: Text("Makayn walo hna!")) : ListView.builder(itemCount: categoryTransactions.length, itemBuilder: (ctx, i) { final tx = categoryTransactions[i]; return ListTile(contentPadding: EdgeInsets.zero, title: Text(tx.title, style: TextStyle(fontWeight: FontWeight.bold, color: _isDarkMode ? Colors.white : Colors.black)), subtitle: Text("${tx.date.year}-${tx.date.month}-${tx.date.day}", style: TextStyle(color: _isDarkMode ? Colors.grey[400] : Colors.grey[600])), trailing: Text('- ${tx.amount.toStringAsFixed(2)} ${t('currency')}', style: const TextStyle(color: Colors.redAccent, fontWeight: FontWeight.bold, fontSize: 16), textDirection: TextDirection.ltr)); })),
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
      data: _isDarkMode ? ThemeData.dark().copyWith(primaryColor: Colors.blue[900], scaffoldBackgroundColor: Colors.transparent, cardColor: const Color(0xFF1E1E1E)) : ThemeData.light().copyWith(primaryColor: Colors.blue, scaffoldBackgroundColor: Colors.transparent),
      child: InteractiveBackground(
        isDark: _isDarkMode,
        child: Directionality(
          textDirection: _selectedLang == 'ar' ? TextDirection.rtl : TextDirection.ltr,
          child: Scaffold(
            backgroundColor: Colors.transparent,
            appBar: AppBar(
              title: Text(t('app_title'), style: const TextStyle(color: Colors.white, fontSize: 18)), centerTitle: true, backgroundColor: _isDarkMode ? Colors.black.withOpacity(0.8) : Colors.blue[900]!.withOpacity(0.8), elevation: 0,
              actions: [
                // 🆕 BOUTON DYAL EXPORT/IMPORT
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
                IconButton(icon: Icon(_isDarkMode ? Icons.light_mode : Icons.dark_mode, color: Colors.yellowAccent), onPressed: () { setState(() { _isDarkMode = !_isDarkMode; _saveData(); }); }),
                PopupMenuButton<String>(icon: const Icon(Icons.language, color: Colors.white), onSelected: (result) { setState(() { _selectedLang = result; _saveData(); }); }, itemBuilder: (context) => const [PopupMenuItem(value: 'dr', child: Text('Darija 🇲🇦')), PopupMenuItem(value: 'en', child: Text('English 🇺🇸')), PopupMenuItem(value: 'ar', child: Text('العربية 🇸🇦'))]),
              ],
            ),
            body: _isLoading ? const Center(child: CircularProgressIndicator()) : PageView(controller: _pageController, onPageChanged: (index) => setState(() => _selectedIndex = index), children: [_buildHomeTab(), _buildStatsTab()]),
            floatingActionButton: _selectedIndex == 0 ? FloatingActionButton(onPressed: () => _startAddNewTransaction(context), backgroundColor: _isDarkMode ? Colors.blue[800] : Colors.blue[900], child: const Icon(Icons.add, color: Colors.white)) : null,
            bottomNavigationBar: NavigationBar(selectedIndex: _selectedIndex, onDestinationSelected: (index) => _pageController.animateToPage(index, duration: const Duration(milliseconds: 300), curve: Curves.easeInOut), backgroundColor: _isDarkMode ? Colors.black.withOpacity(0.9) : Colors.white.withOpacity(0.9), destinations: [NavigationDestination(icon: const Icon(Icons.list), label: t('nav_home')), NavigationDestination(icon: const Icon(Icons.pie_chart), label: t('nav_stats'))]),
          ),
        ),
      ),
    );
  }

  Widget _buildHomeTab() {
    return Column(children: [Container(width: double.infinity, margin: const EdgeInsets.all(20), padding: const EdgeInsets.all(30), decoration: BoxDecoration(gradient: LinearGradient(colors: _isDarkMode ? [Colors.blue.shade900.withOpacity(0.9), Colors.black.withOpacity(0.9)] : [Colors.blue.shade900.withOpacity(0.9), Colors.blue.shade600.withOpacity(0.9)]), borderRadius: BorderRadius.circular(20), boxShadow: const [BoxShadow(color: Colors.black26, blurRadius: 10, offset: Offset(0, 5))]), child: Column(children: [Text(t('total_balance'), style: const TextStyle(color: Colors.white70, fontSize: 18)), const SizedBox(height: 10), Text('${_currentBalance.toStringAsFixed(2)} ${t('currency')}', style: const TextStyle(color: Colors.white, fontSize: 40, fontWeight: FontWeight.bold), textDirection: TextDirection.ltr)])), Expanded(child: _transactions.isEmpty ? Center(child: Text(t('empty_list'))) : ListView.builder(itemCount: _transactions.length, itemBuilder: (ctx, index) { final tx = _transactions[index]; return Card(margin: const EdgeInsets.symmetric(horizontal: 20, vertical: 8), color: _isDarkMode ? Colors.grey[900]!.withOpacity(0.9) : Colors.white.withOpacity(0.9), elevation: _isDarkMode ? 0 : 2, child: ListTile(leading: CircleAvatar(backgroundColor: tx.isExpense ? Colors.red.withOpacity(0.2) : Colors.green.withOpacity(0.2), child: Icon(tx.isExpense ? (_categoryIcons[tx.categoryId] ?? Icons.category) : Icons.account_balance_wallet, color: tx.isExpense ? Colors.red : Colors.green)), title: Text(tx.title, style: const TextStyle(fontWeight: FontWeight.bold)), subtitle: Text("${tx.date.year}-${tx.date.month}-${tx.date.day}"), trailing: Text('${tx.isExpense ? '-' : '+'} ${tx.amount.toStringAsFixed(2)}', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16, color: tx.isExpense ? Colors.redAccent : Colors.greenAccent), textDirection: TextDirection.ltr), onLongPress: () => _deleteTransaction(tx.id))); }))]);
  }

  Widget _buildStatsTab() {
    Map<String, List<Transaction>> catTransactions = {}; 
    double totalExpense = 0.0;
    int currentYear = DateTime.now().year; 
    
    for (var tx in _transactions) { 
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
        const SizedBox(height: 20),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 5),
          decoration: BoxDecoration(color: _isDarkMode ? Colors.grey[800] : Colors.white, borderRadius: BorderRadius.circular(15), boxShadow: const [BoxShadow(color: Colors.black12, blurRadius: 5)]),
          child: DropdownButtonHideUnderline(
            child: DropdownButton<int>(
              value: _selectedQuarter, dropdownColor: _isDarkMode ? Colors.grey[800] : Colors.white, icon: Icon(Icons.filter_alt, color: _isDarkMode ? Colors.white : Colors.blue[900]), style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16, color: _isDarkMode ? Colors.white : Colors.black),
              items: [DropdownMenuItem(value: 0, child: Text(t('filter_0'))), DropdownMenuItem(value: 1, child: Text(t('filter_1'))), DropdownMenuItem(value: 2, child: Text(t('filter_2'))), DropdownMenuItem(value: 3, child: Text(t('filter_3'))), DropdownMenuItem(value: 4, child: Text(t('filter_4')))],
              onChanged: (val) { setState(() { _selectedQuarter = val!; }); },
            ),
          ),
        ),
        const SizedBox(height: 20),
        Expanded(
          child: totalExpense == 0 
            ? Center(child: Text(t('no_expenses'), style: const TextStyle(fontSize: 18)))
            : SingleChildScrollView(
                child: Column(
                  children: [
                    Text(t('stats_title'), style: const TextStyle(fontSize: 22, fontWeight: FontWeight.bold)), const SizedBox(height: 30), 
                    SizedBox(height: 250, child: PieChart(PieChartData(sections: catTransactions.entries.map((entry) { double catTotal = entry.value.fold(0.0, (sum, item) => sum + item.amount); final percentage = (catTotal / totalExpense) * 100; return PieChartSectionData(color: _categoryColors[entry.key] ?? Colors.grey, value: catTotal, title: '${percentage.toStringAsFixed(0)}%', radius: 60, titleStyle: const TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: Colors.white)); }).toList(), centerSpaceRadius: 40, sectionsSpace: 2))), 
                    const SizedBox(height: 30), 
                    ...catTransactions.entries.map((entry) { double catTotal = entry.value.fold(0.0, (sum, item) => sum + item.amount); return Card(margin: const EdgeInsets.symmetric(horizontal: 20, vertical: 5), elevation: 0, color: Colors.transparent, child: ListTile(onTap: () => _showCategoryDetails(context, entry.key, entry.value), leading: Icon(_categoryIcons[entry.key], color: _categoryColors[entry.key]), title: Text(t('cat_${entry.key}'), style: const TextStyle(fontWeight: FontWeight.bold)), trailing: Text('${catTotal.toStringAsFixed(2)} ${t('currency')}', style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16)))); })
                  ]
                )
              ),
        ),
      ],
    );
  }
}