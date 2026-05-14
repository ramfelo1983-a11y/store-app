import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../database_helper.dart';

class SummaryScreen extends StatefulWidget {
  const SummaryScreen({super.key});

  @override
  State<SummaryScreen> createState() => _SummaryScreenState();
}

class _SummaryScreenState extends State<SummaryScreen> with SingleTickerProviderStateMixin {
  late TabController _tabController;
  Map<String, double> _purchaseSummary = {};
  Map<String, double> _expenseSummary = {};
  double _totalPurchases = 0;
  double _totalExpenses = 0;
  String? _selectedMonth;
  List<String> _months = [];
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    _loadMonths();
  }

  Future<void> _loadMonths() async {
    final months = await DatabaseHelper.instance.getAvailableMonths();
    setState(() {
      _months = months.map((m) => m['month'] as String).toList();
      if (_months.isNotEmpty) _selectedMonth = _months.first;
    });
    _loadData();
  }

  Future<void> _loadData() async {
    setState(() => _loading = true);
    final ps = await DatabaseHelper.instance.getPurchaseSummaryByCategory(month: _selectedMonth);
    final es = await DatabaseHelper.instance.getExpenseSummaryByCategory(month: _selectedMonth);
    final tp = await DatabaseHelper.instance.getTotalPurchases(month: _selectedMonth);
    final te = await DatabaseHelper.instance.getTotalExpenses(month: _selectedMonth);
    setState(() {
      _purchaseSummary = ps;
      _expenseSummary = es;
      _totalPurchases = tp;
      _totalExpenses = te;
      _loading = false;
    });
  }

  String _fmt(double v) => NumberFormat('#,##0', 'ar').format(v) + ' ج.م';

  String _fmtMonth(String m) {
    final parts = m.split('-');
    const months = ['يناير','فبراير','مارس','إبريل','مايو','يونيو','يوليو','أغسطس','سبتمبر','أكتوبر','نوفمبر','ديسمبر'];
    final idx = int.parse(parts[1]) - 1;
    return '${months[idx]} ${parts[0]}';
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('الملخص والإحصائيات'),
        bottom: TabBar(
          controller: _tabController,
          indicatorColor: Colors.white,
          labelColor: Colors.white,
          unselectedLabelColor: Colors.white70,
          tabs: const [Tab(text: 'المشتريات'), Tab(text: 'المصروفات')],
        ),
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : Column(
              children: [
                // Month filter
                if (_months.isNotEmpty)
                  Container(
                    color: Colors.white,
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                    child: Row(
                      children: [
                        const Text('الشهر:', style: TextStyle(fontWeight: FontWeight.bold)),
                        const SizedBox(width: 12),
                        Expanded(
                          child: DropdownButton<String>(
                            value: _selectedMonth,
                            isExpanded: true,
                            underline: const SizedBox(),
                            items: _months.map((m) => DropdownMenuItem(value: m, child: Text(_fmtMonth(m)))).toList(),
                            onChanged: (v) {
                              setState(() => _selectedMonth = v);
                              _loadData();
                            },
                          ),
                        ),
                      ],
                    ),
                  ),

                // Grand total bar
                Container(
                  padding: const EdgeInsets.all(12),
                  color: const Color(0xFF1E6F9F),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceAround,
                    children: [
                      _TotalChip(label: 'مشتريات', value: _fmt(_totalPurchases), color: Colors.white),
                      Container(width: 1, height: 30, color: Colors.white54),
                      _TotalChip(label: 'مصروفات', value: _fmt(_totalExpenses), color: Colors.white),
                      Container(width: 1, height: 30, color: Colors.white54),
                      _TotalChip(label: 'الإجمالي', value: _fmt(_totalPurchases + _totalExpenses), color: Colors.yellow),
                    ],
                  ),
                ),

                Expanded(
                  child: TabBarView(
                    controller: _tabController,
                    children: [
                      _buildSummaryList(_purchaseSummary, _totalPurchases, const Color(0xFF1E6F9F)),
                      _buildSummaryList(_expenseSummary, _totalExpenses, const Color(0xFFE07B39)),
                    ],
                  ),
                ),
              ],
            ),
    );
  }

  Widget _buildSummaryList(Map<String, double> data, double total, Color color) {
    if (data.isEmpty) {
      return const Center(child: Text('لا توجد بيانات', style: TextStyle(color: Colors.grey)));
    }
    final sorted = data.entries.toList()..sort((a, b) => b.value.compareTo(a.value));
    return ListView.builder(
      padding: const EdgeInsets.all(12),
      itemCount: sorted.length + 1,
      itemBuilder: (_, i) {
        if (i == sorted.length) {
          return Container(
            margin: const EdgeInsets.only(top: 8),
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              color: color,
              borderRadius: BorderRadius.circular(12),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text('✅ الإجمالي', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 16)),
                Text(_fmt(total), style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 16)),
              ],
            ),
          );
        }
        final entry = sorted[i];
        final pct = total > 0 ? entry.value / total : 0.0;
        return Container(
          margin: const EdgeInsets.only(bottom: 8),
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(10),
            boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 4)],
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(entry.key, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
                  Text(_fmt(entry.value), style: TextStyle(color: color, fontWeight: FontWeight.bold)),
                ],
              ),
              const SizedBox(height: 6),
              Row(
                children: [
                  Expanded(
                    child: ClipRRect(
                      borderRadius: BorderRadius.circular(4),
                      child: LinearProgressIndicator(
                        value: pct,
                        backgroundColor: color.withOpacity(0.1),
                        valueColor: AlwaysStoppedAnimation<Color>(color),
                        minHeight: 6,
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Text('${(pct * 100).toStringAsFixed(1)}%',
                      style: TextStyle(color: Colors.grey[600], fontSize: 12)),
                ],
              ),
            ],
          ),
        );
      },
    );
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }
}

class _TotalChip extends StatelessWidget {
  final String label, value;
  final Color color;
  const _TotalChip({required this.label, required this.value, required this.color});

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Text(label, style: TextStyle(color: color.withOpacity(0.8), fontSize: 11)),
        Text(value, style: TextStyle(color: color, fontWeight: FontWeight.bold, fontSize: 13)),
      ],
    );
  }
}
