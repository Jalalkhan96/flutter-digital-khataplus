import 'package:flutter/material.dart';

import '../models/khata_entry.dart';
import '../state/khata_controller.dart';

/// Adds one page to the book: a new customer with an optional opening
/// balance (the amount they already owed when the shop moved from the
/// paper notebook to KhataPlus).
class AddCustomerScreen extends StatefulWidget {
  const AddCustomerScreen({super.key, required this.controller});

  final KhataController controller;

  @override
  State<AddCustomerScreen> createState() => _AddCustomerScreenState();
}

class _AddCustomerScreenState extends State<AddCustomerScreen> {
  final _formKey = GlobalKey<FormState>();
  final _name = TextEditingController();
  final _phone = TextEditingController();
  final _address = TextEditingController();
  final _opening = TextEditingController();
  bool _saving = false;

  @override
  void dispose() {
    _name.dispose();
    _phone.dispose();
    _address.dispose();
    _opening.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    if (!(_formKey.currentState?.validate() ?? false)) return;
    setState(() => _saving = true);

    final openingText = _opening.text.replaceAll(',', '').trim();
    final opening = openingText.isEmpty
        ? 0.0
        : double.tryParse(openingText) ?? 0.0;

    final customer = await widget.controller.addCustomer(
      name: _name.text,
      phone: _phone.text,
      address: _address.text,
    );
    if (opening > 0) {
      await widget.controller.addEntry(
        customerId: customer.id,
        type: EntryType.credit,
        amount: opening,
        note: 'Opening balance (purana khata)',
      );
    }
    if (mounted) Navigator.of(context).pop();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Add customer')),
      body: Form(
        key: _formKey,
        child: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            TextFormField(
              controller: _name,
              decoration: const InputDecoration(
                labelText: 'Customer name *',
                border: OutlineInputBorder(),
              ),
              textCapitalization: TextCapitalization.words,
              validator: (value) => (value == null || value.trim().isEmpty)
                  ? 'Name is required'
                  : null,
            ),
            const SizedBox(height: 12),
            TextFormField(
              controller: _phone,
              decoration: const InputDecoration(
                labelText: 'Phone (optional)',
                border: OutlineInputBorder(),
              ),
              keyboardType: TextInputType.phone,
            ),
            const SizedBox(height: 12),
            TextFormField(
              controller: _address,
              decoration: const InputDecoration(
                labelText: 'Address / note (optional)',
                border: OutlineInputBorder(),
              ),
              textCapitalization: TextCapitalization.sentences,
            ),
            const SizedBox(height: 12),
            TextFormField(
              controller: _opening,
              decoration: const InputDecoration(
                labelText: 'Opening balance — already due (optional)',
                hintText: 'e.g. 1500',
                border: OutlineInputBorder(),
              ),
              keyboardType: const TextInputType.numberWithOptions(
                decimal: true,
              ),
              validator: (value) {
                final text = (value ?? '').replaceAll(',', '').trim();
                if (text.isEmpty) return null;
                final parsed = double.tryParse(text);
                if (parsed == null || parsed < 0) {
                  return 'Enter a valid amount';
                }
                return null;
              },
            ),
            const SizedBox(height: 20),
            FilledButton.icon(
              onPressed: _saving ? null : _save,
              icon: const Icon(Icons.save),
              label: const Text('Save customer'),
            ),
          ],
        ),
      ),
    );
  }
}
