import 'package:flutter/material.dart';

import '../models/khata_entry.dart';
import '../models/ledger.dart';
import '../state/khata_controller.dart';
import '../utils/format.dart';
import 'add_entry_screen.dart';

/// One customer's page of the book: current balance on top, the full
/// ledger below (newest first, with the running balance after each
/// entry), and the two actions a shopkeeper does all day —
/// "Udhaar diya" and "Paise mile".
class CustomerDetailScreen extends StatelessWidget {
  const CustomerDetailScreen({
    super.key,
    required this.controller,
    required this.customerId,
  });

  final KhataController controller;
  final String customerId;

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: controller,
      builder: (context, _) {
        final matches = controller.customers.where((c) => c.id == customerId);
        if (matches.isEmpty) {
          // Customer was deleted from elsewhere — just leave.
          return const Scaffold(body: Center(child: Text('Customer gone')));
        }
        final customer = matches.first;
        final balance = controller.balanceOf(customerId);
        final entries = controller.entriesOf(customerId);
        final balances = runningBalances(customerId, controller.entries);

        return Scaffold(
          appBar: AppBar(
            title: Text(customer.name),
            actions: [
              IconButton(
                icon: const Icon(Icons.delete_outline),
                tooltip: 'Delete customer',
                onPressed: () => _confirmDeleteCustomer(context),
              ),
            ],
          ),
          body: Column(
            children: [
              _BalanceHeader(
                balance: balance,
                phone: customer.phone,
                address: customer.address,
              ),
              Expanded(
                child: entries.isEmpty
                    ? const Center(
                        child: Text('No entries yet for this customer.'),
                      )
                    : ListView.builder(
                        itemCount: entries.length,
                        itemBuilder: (context, index) {
                          final entry = entries[index];
                          final isCredit = entry.type == EntryType.credit;
                          return Card(
                            child: ListTile(
                              leading: Icon(
                                isCredit
                                    ? Icons.arrow_upward
                                    : Icons.arrow_downward,
                                color: isCredit ? Colors.red : Colors.green,
                              ),
                              title: Text(
                                entry.note.isEmpty
                                    ? (isCredit ? 'Udhaar diya' : 'Paise mile')
                                    : entry.note,
                              ),
                              subtitle: Text(
                                '${isCredit ? 'Credit' : 'Payment'} · '
                                '${shortDate(entry.date)}',
                              ),
                              trailing: Column(
                                mainAxisAlignment: MainAxisAlignment.center,
                                crossAxisAlignment: CrossAxisAlignment.end,
                                children: [
                                  Text(
                                    '${isCredit ? '+' : '-'}'
                                    '${rupees(entry.amount)}',
                                    style: TextStyle(
                                      fontWeight: FontWeight.bold,
                                      color: isCredit
                                          ? Colors.red
                                          : Colors.green,
                                    ),
                                  ),
                                  Text(
                                    'Bal ${rupees(balances[index])}',
                                    style: Theme.of(context)
                                        .textTheme
                                        .bodySmall,
                                  ),
                                ],
                              ),
                              onLongPress: () =>
                                  _confirmDeleteEntry(context, entry),
                            ),
                          );
                        },
                      ),
              ),
              SafeArea(
                child: Padding(
                  padding: const EdgeInsets.all(12),
                  child: Row(
                    children: [
                      Expanded(
                        child: FilledButton.icon(
                          style: FilledButton.styleFrom(
                            backgroundColor: Colors.red.shade700,
                          ),
                          onPressed: () => _addEntry(context, EntryType.credit),
                          icon: const Icon(Icons.arrow_upward),
                          label: const Text('Udhaar diya'),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: FilledButton.icon(
                          style: FilledButton.styleFrom(
                            backgroundColor: Colors.green.shade700,
                          ),
                          onPressed: () =>
                              _addEntry(context, EntryType.payment),
                          icon: const Icon(Icons.arrow_downward),
                          label: const Text('Paise mile'),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  void _addEntry(BuildContext context, EntryType type) {
    Navigator.of(context).push(
      MaterialPageRoute<void>(
        builder: (_) => AddEntryScreen(
          controller: controller,
          customerId: customerId,
          type: type,
        ),
      ),
    );
  }

  Future<void> _confirmDeleteEntry(
    BuildContext context,
    KhataEntry entry,
  ) async {
    final ok = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('Delete this entry?'),
        content: Text(
          '${entry.type == EntryType.credit ? 'Credit' : 'Payment'} of '
          '${rupees(entry.amount)} on ${shortDate(entry.date)} will be removed.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(dialogContext).pop(false),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () => Navigator.of(dialogContext).pop(true),
            child: const Text('Delete'),
          ),
        ],
      ),
    );
    if (ok == true) await controller.deleteEntry(entry.id);
  }

  Future<void> _confirmDeleteCustomer(BuildContext context) async {
    final ok = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('Delete this customer?'),
        content: const Text(
          'The customer and their whole ledger will be removed. '
          'This cannot be undone.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(dialogContext).pop(false),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () => Navigator.of(dialogContext).pop(true),
            child: const Text('Delete'),
          ),
        ],
      ),
    );
    if (ok == true) {
      await controller.deleteCustomer(customerId);
      if (context.mounted) Navigator.of(context).pop();
    }
  }
}

class _BalanceHeader extends StatelessWidget {
  const _BalanceHeader({
    required this.balance,
    required this.phone,
    required this.address,
  });

  final double balance;
  final String phone;
  final String address;

  @override
  Widget build(BuildContext context) {
    final String label;
    if (balance > 0) {
      label = '${rupees(balance)} lena hai';
    } else if (balance < 0) {
      label = '${rupees(-balance)} advance jama hai';
    } else {
      label = 'Hisaab barabar — kuch lena nahi';
    }
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      color: Theme.of(context).colorScheme.primaryContainer,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label,
            style: Theme.of(context).textTheme.titleLarge
                ?.copyWith(fontWeight: FontWeight.bold),
          ),
          if (phone.isNotEmpty) Text('Phone: $phone'),
          if (address.isNotEmpty) Text(address),
        ],
      ),
    );
  }
}
