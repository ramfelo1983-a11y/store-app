import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../database_helper.dart';
import 'add_purchase_screen.dart';
import 'add_expense_screen.dart';
import 'purchases_list_screen.dart';
import 'expenses_list_screen.dart';
import 'summary_screen.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  double _totalPurchases = 0;
  double _totalExpenses = 0;
  String _currentMonth = DateFormat('yyyy-MM').format(DateTime.now());
  String _currentMonthAr = '';
  int _selectedIndex = 0;

  @override
  void initState() {
    super.initState();
    _currentMonthAr = _getArabicMonth(DateTime.now());
    _loadTotals();
  }

  String _getArabicMonth(DateTime date) {
    const months = [
      'يناير', 'فبراير', 'مارس', 'إبريل', 'مايو', 'يونيو',
      'يوليو', 'أغسطس', 'سبتمبر', 'أكتوبر', 'نوفمبر', 'ديسمبر'
    ];
    return '${months[date.month - 1]} ${date.year}';
  }

  Future<void> _loadTotals() async {
    final p = await DatabaseHelper.instance.getTotalPurchases(month: _currentMonth);
    final e = await DatabaseHelper.instance.getTotalExpenses(month: _currentMonth);
    setState(() {
      _totalPurchases = p;
      _totalExpenses = e;
    });
  }

  String _formatCurrency(double amount) {
    return NumberFormat('#,##0', 'ar').format(amount) + ' ج.م';
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF5F7FA),
      appBar: AppBar(
        title: const Text('سجل المشتريات والمصروفات',
            style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18)),
        actions: [
          IconButton(
            icon: const Icon(Icons.bar_chart_rounded),
            onPressed: () => Navigator.push(
              context,
              MaterialPageRoute(builder: (_) => const SummaryScreen()),
            ).then((_) => _loadTotals()),
          )
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Month header
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
              decoration: BoxDecoration(
                color: const Color(0xFF1E6F9F).withOpacity(0.1),
                borderRadius: BorderRadius.circular(10),
              ),
              child: Row(
                children: [
                  const Icon(Icons.calendar_month, color: Color(0xFF1E6F9F)),
                  const SizedBox(width: 8),
                  Text(
                    'شهر $_currentMonthAr',
                    style: const TextStyle(
                      color: Color(0xFF1E6F9F),
                      fontWeight: FontWeight.bold,
                      fontSize: 16,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),

            // Summary cards
            Row(
              children: [
                Expanded(
                  child: _SummaryCard(
                    title: 'المشتريات',
                    amount: _formatCurrency(_totalPurchases),
                    icon: Icons.shopping_cart_rounded,
                    color: const Color(0xFF1E6F9F),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: _SummaryCard(
                    title: 'المصروفات',
                    amount: _formatCurrency(_totalExpenses),
                    icon: Icons.payments_rounded,
                    color: const Color(0xFFE07B39),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),

            // Grand total
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                gradient: const LinearGradient(
                  colors: [Color(0xFF1E6F9F), Color(0xFF0D4F7C)],
                ),
                borderRadius: BorderRadius.circular(12),
                boxShadow: [
                  BoxShadow(
                    color: const Color(0xFF1E6F9F).withOpacity(0.3),
                    blurRadius: 8,
                    offset: const Offset(0, 4),
                  )
                ],
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text(
                    '🔢 الإجمالي العام',
                    style: TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.bold),
                  ),
                  Text(
                    _formatCurrency(_totalPurchases + _totalExpenses),
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 24),

            // Quick actions
            const Text('إضافة سريعة',
                style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Color(0xFF333333))),
            const SizedBox(height: 12),
            Row(
              children: [
                Expanded(
                  child: _ActionButton(
                    label: 'إضافة مشتريات',
                    icon: Icons.add_shopping_cart_rounded,
                    color: const Color(0xFF1E6F9F),
                    onTap: () => Navigator.push(
                      context,
                      MaterialPageRoute(builder: (_) => const AddPurchaseScreen()),
                    ).then((_) => _loadTotals()),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: _ActionButton(
                    label: 'إضافة مصروف',
                    icon: Icons.add_card_rounded,
                    color: const Color(0xFFE07B39),
                    onTap: () => Navigator.push(
                      context,
                      MaterialPageRoute(builder: (_) => const AddExpenseScreen()),
                    ).then((_) => _loadTotals()),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 24),

            // Lists
            const Text('عرض السجلات',
                style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Color(0xFF333333))),
            const SizedBox(height: 12),
            _ListTileCard(
              icon: Icons.receipt_long_rounded,
              title: 'سجل المشتريات',
              subtitle: 'عرض وتعديل جميع المشتريات',
              color: const Color(0xFF1E6F9F),
              onTap: () => Navigator.push(
                context,
                MaterialPageRoute(builder: (_) => const PurchasesListScreen()),
              ).then((_) => _loadTotals()),
            ),
            const SizedBox(height: 8),
            _ListTileCard(
              icon: Icons.money_off_rounded,
              title: 'سجل المصروفات',
              subtitle: 'عرض وتعديل جميع المصروفات',
              color: const Color(0xFFE07B39),
              onTap: () => Navigator.push(
                context,
                MaterialPageRoute(builder: (_) => const ExpensesListScreen()),
              ).then((_) => _loadTotals()),
            ),
            const SizedBox(height: 8),
            _ListTileCard(
              icon: Icons.pie_chart_rounded,
              title: 'الملخص والإحصائيات',
              subtitle: 'تقارير شاملة لكل الفئات',
              color: const Color(0xFF27AE60),
              onTap: () => Navigator.push(
                context,
                MaterialPageRoute(builder: (_) => const SummaryScreen()),
              ).then((_) => _loadTotals()),
            ),
          ],
        ),
      ),
    );
  }
}

class _SummaryCard extends StatelessWidget {
  final String title, amount;
  final IconData icon;
  final Color color;

  const _SummaryCard({required this.title, required this.amount, required this.icon, required this.color});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.07), blurRadius: 8, offset: const Offset(0, 2))],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(icon, color: color, size: 20),
              const SizedBox(width: 6),
              Text(title, style: TextStyle(color: color, fontWeight: FontWeight.bold, fontSize: 14)),
            ],
          ),
          const SizedBox(height: 8),
          Text(amount, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16, color: Color(0xFF222222))),
        ],
      ),
    );
  }
}

class _ActionButton extends StatelessWidget {
  final String label;
  final IconData icon;
  final Color color;
  final VoidCallback onTap;

  const _ActionButton({required this.label, required this.icon, required this.color, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 16),
        decoration: BoxDecoration(
          color: color,
          borderRadius: BorderRadius.circular(12),
        ),
        child: Column(
          children: [
            Icon(icon, color: Colors.white, size: 28),
            const SizedBox(height: 6),
            Text(label, style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
          ],
        ),
      ),
    );
  }
}

class _ListTileCard extends StatelessWidget {
  final IconData icon;
  final String title, subtitle;
  final Color color;
  final VoidCallback onTap;

  const _ListTileCard({required this.icon, required this.title, required this.subtitle, required this.color, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(12),
          boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.06), blurRadius: 6, offset: const Offset(0, 2))],
        ),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(color: color.withOpacity(0.1), borderRadius: BorderRadius.circular(10)),
              child: Icon(icon, color: color, size: 22),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(title, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15)),
                  Text(subtitle, style: TextStyle(color: Colors.grey[600], fontSize: 12)),
                ],
              ),
            ),
            Icon(Icons.arrow_back_ios_rounded, color: Colors.grey[400], size: 16),
          ],
        ),
      ),
    );
  }
}
