import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../database_helper.dart';
import 'add_purchase_screen.dart';

class PurchasesListScreen extends StatefulWidget {
  const PurchasesListScreen({super.key});

  @override
  State<PurchasesListScreen> createState() => _PurchasesListScreenState();
}

class _PurchasesListScreenState extends State<PurchasesListScreen> {
  List<Map<String, dynamic>> _items = [];
  String _filter = '';
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    setState(() => _loading = true);
    final data = await DatabaseHelper.instance.getPurchases();
    setState(() {
      _items = data;
      _loading = false;
    });
  }

  List<Map<String, dynamic>> get _filtered {
    if (_filter.isEmpty) return _items;
    return _items.where((i) =>
      i['item'].toString().contains(_filter) ||
      i['category'].toString().contains(_filter)
    ).toList();
  }

  String _fmt(double v) => NumberFormat('#,##0', 'ar').format(v) + ' ج.م';

  Future<void> _delete(int id) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('حذف السجل'),
        content: const Text('هل تريد حذف هذا السجل نهائياً؟'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context, false), child: const Text('إلغاء')),
          TextButton(onPressed: () => Navigator.pop(context, true),
              child: const Text('حذف', style: TextStyle(color: Colors.red))),
        ],
      ),
    );
    if (confirm == true) {
      await DatabaseHelper.instance.deletePurchase(id);
      _load();
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('سجل المشتريات')),
      floatingActionButton: FloatingActionButton(
        onPressed: () => Navigator.push(
          context,
          MaterialPageRoute(builder: (_) => const AddPurchaseScreen()),
        ).then((_) => _load()),
        backgroundColor: const Color(0xFF1E6F9F),
        child: const Icon(Icons.add, color: Colors.white),
      ),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(12),
            child: TextField(
              decoration: InputDecoration(
                hintText: 'بحث...',
                prefixIcon: const Icon(Icons.search),
                filled: true,
                fillColor: Colors.white,
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(10), borderSide: BorderSide.none),
              ),
              onChanged: (v) => setState(() => _filter = v),
            ),
          ),
          Expanded(
            child: _loading
                ? const Center(child: CircularProgressIndicator())
                : _filtered.isEmpty
                    ? const Center(child: Text('لا توجد سجلات', style: TextStyle(color: Colors.grey)))
                    : ListView.builder(
                        padding: const EdgeInsets.symmetric(horizontal: 12),
                        itemCount: _filtered.length,
                        itemBuilder: (_, i) {
                          final item = _filtered[i];
                          return Card(
                            margin: const EdgeInsets.only(bottom: 8),
                            child: ListTile(
                              contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 4),
                              title: Text(item['item'] ?? '', style: const TextStyle(fontWeight: FontWeight.bold)),
                              subtitle: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text('${item['category']} • ${item['date']}',
                                      style: TextStyle(color: Colors.grey[600], fontSize: 12)),
                                  if (item['notes'] != null && item['notes'].toString().isNotEmpty)
                                    Text(item['notes'], style: TextStyle(color: Colors.grey[500], fontSize: 11)),
                                ],
                              ),
                              trailing: Column(
                                mainAxisAlignment: MainAxisAlignment.center,
                                crossAxisAlignment: CrossAxisAlignment.end,
                                children: [
                                  Text(_fmt((item['total'] as num).toDouble()),
                                      style: const TextStyle(color: Color(0xFF1E6F9F), fontWeight: FontWeight.bold)),
                                  if (item['quantity'] != null)
                                    Text('كمية: ${item['quantity']}', style: TextStyle(color: Colors.grey[500], fontSize: 11)),
                                ],
                              ),
                              onTap: () => Navigator.push(
                                context,
                                MaterialPageRoute(builder: (_) => AddPurchaseScreen(existing: item)),
                              ).then((_) => _load()),
                              onLongPress: () => _delete(item['id'] as int),
                            ),
                          );
                        },
                      ),
          ),
        ],
      ),
    );
  }
}
