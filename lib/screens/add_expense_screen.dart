import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../database_helper.dart';
import '../app_data.dart';

class AddExpenseScreen extends StatefulWidget {
  final Map<String, dynamic>? existing;
  const AddExpenseScreen({super.key, this.existing});

  @override
  State<AddExpenseScreen> createState() => _AddExpenseScreenState();
}

class _AddExpenseScreenState extends State<AddExpenseScreen> {
  final _formKey = GlobalKey<FormState>();
  DateTime _selectedDate = DateTime.now();
  String? _selectedCategory;
  String? _selectedItem;
  final _amountController = TextEditingController();
  final _notesController = TextEditingController();

  @override
  void initState() {
    super.initState();
    if (widget.existing != null) {
      final e = widget.existing!;
      _selectedDate = DateTime.parse(e['date']);
      _selectedCategory = e['category'];
      _selectedItem = e['item'];
      _amountController.text = e['amount'].toString();
      _notesController.text = e['notes'] ?? '';
    }
  }

  List<String> get _items {
    if (_selectedCategory == null) return [];
    return AppData.expenseCategories[_selectedCategory!] ?? [];
  }

  Future<void> _selectDate() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: _selectedDate,
      firstDate: DateTime(2020),
      lastDate: DateTime(2030),
    );
    if (picked != null) setState(() => _selectedDate = picked);
  }

  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) return;

    final row = {
      'date': DateFormat('yyyy-MM-dd').format(_selectedDate),
      'category': _selectedCategory,
      'item': _selectedItem,
      'amount': double.tryParse(_amountController.text) ?? 0,
      'notes': _notesController.text.trim(),
    };

    if (widget.existing != null) {
      row['id'] = widget.existing!['id'];
      await DatabaseHelper.instance.updateExpense(row);
    } else {
      await DatabaseHelper.instance.insertExpense(row);
    }

    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('تم الحفظ ✓'), backgroundColor: Colors.green),
      );
      Navigator.pop(context, true);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.existing != null ? 'تعديل مصروف' : 'إضافة مصروف'),
        backgroundColor: const Color(0xFFE07B39),
      ),
      body: Form(
        key: _formKey,
        child: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            // Date
            GestureDetector(
              onTap: _selectDate,
              child: Container(
                padding: const EdgeInsets.all(14),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(color: Colors.grey.shade300),
                ),
                child: Row(
                  children: [
                    const Icon(Icons.calendar_today, color: Color(0xFFE07B39)),
                    const SizedBox(width: 10),
                    Text(DateFormat('dd/MM/yyyy').format(_selectedDate),
                        style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w500)),
                    const Spacer(),
                    const Text('تغيير', style: TextStyle(color: Color(0xFFE07B39))),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 12),

            // Category
            DropdownButtonFormField<String>(
              value: _selectedCategory,
              decoration: _inputDecoration('الفئة'),
              items: AppData.expenseCategories.keys
                  .map((k) => DropdownMenuItem(value: k, child: Text('${AppData.getCategoryIcon(k)}  $k')))
                  .toList(),
              onChanged: (v) => setState(() {
                _selectedCategory = v;
                _selectedItem = null;
              }),
              validator: (v) => v == null ? 'مطلوب' : null,
            ),
            const SizedBox(height: 12),

            // Item
            if (_selectedCategory != null)
              DropdownButtonFormField<String>(
                value: _selectedItem,
                decoration: _inputDecoration('البند'),
                items: _items.map((i) => DropdownMenuItem(value: i, child: Text(i))).toList(),
                onChanged: (v) => setState(() => _selectedItem = v),
                validator: (v) => v == null ? 'مطلوب' : null,
              ),
            const SizedBox(height: 12),

            // Amount
            TextFormField(
              controller: _amountController,
              keyboardType: TextInputType.number,
              decoration: _inputDecoration('المبلغ (ج.م) *'),
              validator: (v) {
                if (v == null || v.isEmpty) return 'مطلوب';
                if (double.tryParse(v) == null) return 'رقم غير صحيح';
                return null;
              },
            ),
            const SizedBox(height: 12),

            // Notes
            TextFormField(
              controller: _notesController,
              maxLines: 2,
              decoration: _inputDecoration('ملاحظات (اختياري)'),
            ),
            const SizedBox(height: 24),

            ElevatedButton(
              onPressed: _save,
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFFE07B39),
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(vertical: 16),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              ),
              child: const Text('💾  حفظ', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
            ),
          ],
        ),
      ),
    );
  }

  InputDecoration _inputDecoration(String label) {
    return InputDecoration(
      labelText: label,
      filled: true,
      fillColor: Colors.white,
      border: OutlineInputBorder(borderRadius: BorderRadius.circular(10), borderSide: BorderSide(color: Colors.grey.shade300)),
      enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(10), borderSide: BorderSide(color: Colors.grey.shade300)),
    );
  }

  @override
  void dispose() {
    _amountController.dispose();
    _notesController.dispose();
    super.dispose();
  }
}
