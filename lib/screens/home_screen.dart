import 'package:flutter/material.dart';

import '../models/ledger.dart';
import '../state/khata_controller.dart';
import '../utils/format.dart';
import 'add_customer_screen.dart';
import 'customer_detail_screen.dart';

/// The shop's whole book at a glance: today's totals on top, then
/// every customer with the amount they still owe, searchable.
class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key, required this.controller});

  final KhataController controller;

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  String _query = '';

  KhataController get _c => widget.controller;

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _c,
      builder: (context, _) {
        if (!_c.isLoaded) {
          return const Scaffold(
            body: Center(child: CircularProgressIndicator()),
          );
        }
        final visible =
            _c.customers
                .where((cust) => customerMatches(cust.name, cust.phone, _query))
                .toList()
              ..sort(
                (a, b) => _c.balanceOf(b.id).compareTo(_c.balanceOf(a.id)),
              );

        return Scaffold(
          appBar: AppBar(
            title: const Text('KhataPlus'),
            actions: [
              Center(
                child: Padding(
                  padding: const EdgeInsets.only(right: 16),
                  child: Text(
                    '${_c.customersWithDue} due',
                    style: const TextStyle(fontSize: 14),
                  ),
                ),
              ),
            ],
          ),
          body: Column(
            children: [
              _SummaryStrip(controller: _c),
              Padding(
                padding: const EdgeInsets.fromLTRB(12, 10, 12, 4),
                child: TextField(
                  decoration: const InputDecoration(
                    prefixIcon: Icon(Icons.search),
                    hintText: 'Search customer or phone…',
                    border: OutlineInputBorder(),
                    isDense: true,
                  ),
                  onChanged: (value) => setState(() => _query = value),
                ),
              ),
              Expanded(
                child: visible.isEmpty
                    ? _EmptyState(hasCustomers: _c.customers.isNotEmpty)
                    : ListView.builder(
                        itemCount: visible.length,
                        itemBuilder: (context, index) {
                          final customer = visible[index];
                          final balance = _c.balanceOf(customer.id);
                          return Card(
                            child: ListTile(
                              leading: CircleAvatar(
                                child: Text(
                                  customer.name.trim().isEmpty
                                      ? '?'
                                      : customer.name.trim()[0].toUpperCase(),
                                ),
                              ),
                              title: Text(customer.name),
                              subtitle: Text(
                                customer.phone.isEmpty
                                    ? 'No phone saved'
                                    : customer.phone,
                              ),
                              trailing: _BalanceLabel(balance: balance),
                              onTap: () => Navigator.of(context).push(
                                MaterialPageRoute<void>(
                                  builder: (_) => CustomerDetailScreen(
                                    controller: _c,
                                    customerId: customer.id,
                                  ),
                                ),
                              ),
                            ),
                          );
                        },
                      ),
              ),
            ],
          ),
          floatingActionButton: FloatingActionButton.extended(
            onPressed: () => Navigator.of(context).push(
              MaterialPageRoute<void>(
                builder: (_) => AddCustomerScreen(controller: _c),
              ),
            ),
            icon: const Icon(Icons.person_add),
            label: const Text('Add customer'),
          ),
        );
      },
    );
  }
}

/// Top strip: total still to receive, today's credit, today's payments.
class _SummaryStrip extends StatelessWidget {
  const _SummaryStrip({required this.controller});

  final KhataController controller;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Container(
      width: double.infinity,
      color: scheme.primaryContainer,
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Total to receive',
            style: TextStyle(color: scheme.onPrimaryContainer),
          ),
          Text(
            rupees(controller.totalReceivable),
            style: Theme.of(context).textTheme.headlineMedium?.copyWith(
              fontWeight: FontWeight.bold,
              color: scheme.onPrimaryContainer,
            ),
          ),
          const SizedBox(height: 8),
          Row(
            children: [
              Expanded(
                child: Text(
                  'Today credit: ${rupees(controller.todayCredit)}',
                  style: TextStyle(color: scheme.onPrimaryContainer),
                ),
              ),
              Expanded(
                child: Text(
                  'Today received: ${rupees(controller.todayPayments)}',
                  style: TextStyle(color: scheme.onPrimaryContainer),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _BalanceLabel extends StatelessWidget {
  const _BalanceLabel({required this.balance});

  final double balance;

  @override
  Widget build(BuildContext context) {
    if (balance == 0) {
      return const Text('Settled', style: TextStyle(color: Colors.grey));
    }
    if (balance > 0) {
      return Text(
        rupees(balance),
        style: const TextStyle(color: Colors.red, fontWeight: FontWeight.bold),
      );
    }
    return Text(
      '${rupees(-balance)} advance',
      style: const TextStyle(color: Colors.green, fontWeight: FontWeight.bold),
    );
  }
}

class _EmptyState extends StatelessWidget {
  const _EmptyState({required this.hasCustomers});

  final bool hasCustomers;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Text(
          hasCustomers ? 'No customer matches your search.' : 'Your khata is empty.\nTap "Add customer" to write your first page.',
          textAlign: TextAlign.center,
          style: Theme.of(context).textTheme.titleMedium,
        ),
      ),
    );
  }
}
