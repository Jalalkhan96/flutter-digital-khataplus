import 'package:flutter/material.dart';

import '../models/khata_entry.dart';
import '../state/khata_controller.dart';
import '../utils/format.dart';

/// Writes one line in the ledger: an amount, an optional note about
/// what it was for, and the date (today by default, changeable for
/// entries the shopkeeper forgot to write down in the evening rush).
class AddEntryScreen extends StatefulWidget {
  const AddEntryScreen({
    super.key,
    required this.controller,
    required this.customerId,
    required this.type,
  });

  final KhataController controller;
  final String customerId;
  final EntryType type;

  @override
  State<AddEntryScreen> createState() => _AddEntryScreenState();
}

class _AddEntryScreenState extends State<AddEntryScreen> {
  final _formKey = GlobalKey<FormState>();
  final _amount = TextEditingController();
  final _note = TextEditingController();
  DateTime _date = DateTime.now();
  bool _saving = false;

  bool get _isCredit => widget.type == EntryType.credit;

  @override
  void dispose() {
    _amount.dispose();
    _note.dispose();
    super.dispose();
  }

  Future<void> _pickDate() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: _date,
      firstDate: DateTime(2000),
      lastDate: DateTime.now(),
    );
    if (picked != null) setState(() => _date = picked);
  }

  Future<void> _save() async {
    if (!(_formKey.currentState?.validate() ?? false)) return;
    setState(() => _saving = true);
    await widget.controller.addEntry(
      customerId: widget.customerId,
      type: widget.type,
      amount: parseAmount(_amount.text)!,
      note: _note.text,
      date: _date,
    );
    if (mounted) Navigator.of(context).pop();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text(_isCredit ? 'Udhaar diya' : 'Paise mile')),
      body: Form(
        key: _formKey,
        child: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            TextFormField(
              controller: _amount,
              autofocus: true,
              decoration: const InputDecoration(
                labelText: 'Amount (Rs) *',
                hintText: 'e.g. 500',
                border: OutlineInputBorder(),
              ),
              keyboardType: const TextInputType.numberWithOptions(
                decimal: true,
              ),
              validator: (value) => parseAmount(value ?? '') == null
                  ? 'Enter a valid amount'
                  : null,
            ),
            const SizedBox(height: 12),
            TextFormField(
              controller: _note,
              decoration: InputDecoration(
                labelText: _isCredit
                    ? 'What was given? (optional)'
                    : 'Note (optional)',
                hintText: _isCredit ? 'e.g. 2 kg cheeni, 1 litre doodh' : null,
                border: const OutlineInputBorder(),
              ),
              textCapitalization: TextCapitalization.sentences,
            ),
            const SizedBox(height: 12),
            OutlinedButton.icon(
              onPressed: _pickDate,
              icon: const Icon(Icons.calendar_today),
              label: Text('Date: ${shortDate(_date)}'),
            ),
            const SizedBox(height: 20),
            FilledButton.icon(
              style: FilledButton.styleFrom(
                backgroundColor: _isCredit
                    ? Colors.red.shade700
                    : Colors.green.shade700,
              ),
              onPressed: _saving ? null : _save,
              icon: const Icon(Icons.save),
              label: Text(_isCredit ? 'Save credit' : 'Save payment'),
            ),
          ],
        ),
      ),
    );
  }
}
