import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../database_helper.dart';
import '../app_data.dart';

class AddPurchaseScreen extends StatefulWidget {
  final Map<String, dynamic>? existing;
  const AddPurchaseScreen({super.key, this.existing});

  @override
  State<AddPurchaseScreen> createState() => _AddPurchaseScreenState();
}

class _AddPurchaseScreenState extends State<AddPurchaseScreen> {
  final _formKey = GlobalKey<FormState>();
  DateTime _selectedDate = DateTime.now();
  String? _selectedCategory;
  String? _selectedItem;
  String _unit = '';
  final _qtyController = TextEditingController();
  final _priceController = TextEditingController();
  final _totalController = TextEditingController();
  final _notesController = TextEditingController();
  bool _manualTotal = false;

  @override
  void initState() {
    super.initState();
    if (widget.existing != null) {
      final e = widget.existing!;
      _selectedDate = DateTime.parse(e['date']);
      _selectedCategory = e['category'];
      _selectedItem = e['item'];
      _unit = e['unit'] ?? '';
      _qtyController.text = e['quantity']?.toString() ?? '';
      _priceController.text = e['unit_price']?.toString() ?? '';
      _totalController.text = e['total'].toString();
      _notesController.text = e['notes'] ?? '';
    }
    _qtyController.addListener(_calcTotal);
    _priceController.addListener(_calcTotal);
  }

  void _calcTotal() {
    if (_manualTotal) return;
    final qty = double.tryParse(_qtyController.text) ?? 0;
    final price = double.tryParse(_priceController.text) ?? 0;
    if (qty > 0 && price > 0) {
      _totalController.text = (qty * price).toStringAsFixed(0);
    }
  }

  List<Map<String, String>> get _items {
    if (_selectedCategory == null) return [];
    return AppData.purchaseCategories[_selectedCategory!] ?? [];
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
    final total = double.tryParse(_totalController.text) ?? 0;
    if (total <= 0) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('الرجاء إدخال الإجمالي'), backgroundColor: Colors.red),
      );
      return;
    }

    final row = {
      'date': DateFormat('yyyy-MM-dd').format(_selectedDate),
      'category': _selectedCategory,
      'item': _selectedItem,
      'unit': _unit,
      'quantity': double.tryParse(_qtyController.text),
      'unit_price': double.tryParse(_priceController.text),
      'total': total,
      'notes': _notesController.text.trim(),
    };

    if (widget.existing != null) {
      row['id'] = widget.existing!['id'];
      await DatabaseHelper.instance.updatePurchase(row);
    } else {
      await DatabaseHelper.instance.insertPurchase(row);
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
        title: Text(widget.existing != null ? 'تعديل مشتريات' : 'إضافة مشتريات'),
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
                    const Icon(Icons.calendar_today, color: Color(0xFF1E6F9F)),
                    const SizedBox(width: 10),
                    Text(
                      DateFormat('dd/MM/yyyy').format(_selectedDate),
                      style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w500),
                    ),
                    const Spacer(),
                    const Text('تغيير', style: TextStyle(color: Color(0xFF1E6F9F))),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 12),

            // Category
            _buildDropdown<String>(
              label: 'الفئة',
              value: _selectedCategory,
              items: AppData.purchaseCategories.keys.toList(),
              display: (s) => '${AppData.getCategoryIcon(s)}  $s',
              onChanged: (v) => setState(() {
                _selectedCategory = v;
                _selectedItem = null;
                _unit = '';
              }),
            ),
            const SizedBox(height: 12),

            // Item
            if (_selectedCategory != null)
              _buildDropdown<String>(
                label: 'الصنف',
                value: _selectedItem,
                items: _items.map((i) => i['name']!).toList(),
                display: (s) => s,
                onChanged: (v) {
                  setState(() {
                    _selectedItem = v;
                    _unit = _items.firstWhere((i) => i['name'] == v, orElse: () => {'unit': ''})['unit'] ?? '';
                  });
                },
              ),
            const SizedBox(height: 12),

            // Unit
            if (_unit.isNotEmpty)
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                decoration: BoxDecoration(
                  color: const Color(0xFF1E6F9F).withOpacity(0.08),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Text('الوحدة: $_unit', style: const TextStyle(color: Color(0xFF1E6F9F), fontWeight: FontWeight.w500)),
              ),
            const SizedBox(height: 12),

            // Qty & Price
            Row(
              children: [
                Expanded(child: _buildField(_qtyController, 'الكمية', isNumber: true)),
                const SizedBox(width: 12),
                Expanded(child: _buildField(_priceController, 'سعر الوحدة', isNumber: true)),
              ],
            ),
            const SizedBox(height: 12),

            // Total
            _buildField(
              _totalController,
              'الإجمالي *',
              isNumber: true,
              onTap: () => setState(() => _manualTotal = true),
              required: true,
            ),
            const SizedBox(height: 12),

            // Notes
            _buildField(_notesController, 'ملاحظات (اختياري)', maxLines: 2),
            const SizedBox(height: 24),

            ElevatedButton(
              onPressed: _save,
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF1E6F9F),
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

  Widget _buildDropdown<T>({
    required String label,
    required T? value,
    required List<T> items,
    required String Function(T) display,
    required void Function(T?) onChanged,
  }) {
    return DropdownButtonFormField<T>(
      value: value,
      decoration: InputDecoration(
        labelText: label,
        filled: true,
        fillColor: Colors.white,
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(10), borderSide: BorderSide(color: Colors.grey.shade300)),
        enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(10), borderSide: BorderSide(color: Colors.grey.shade300)),
      ),
      items: items.map((i) => DropdownMenuItem(value: i, child: Text(display(i)))).toList(),
      onChanged: onChanged,
      validator: (v) => v == null ? 'مطلوب' : null,
    );
  }

  Widget _buildField(TextEditingController ctrl, String label,
      {bool isNumber = false, bool required = false, int maxLines = 1, VoidCallback? onTap}) {
    return TextFormField(
      controller: ctrl,
      keyboardType: isNumber ? TextInputType.number : TextInputType.text,
      maxLines: maxLines,
      onTap: onTap,
      decoration: InputDecoration(
        labelText: label,
        filled: true,
        fillColor: Colors.white,
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(10), borderSide: BorderSide(color: Colors.grey.shade300)),
        enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(10), borderSide: BorderSide(color: Colors.grey.shade300)),
      ),
      validator: required ? (v) => (v == null || v.isEmpty) ? 'مطلوب' : null : null,
    );
  }

  @override
  void dispose() {
    _qtyController.dispose();
    _priceController.dispose();
    _totalController.dispose();
    _notesController.dispose();
    super.dispose();
  }
}
