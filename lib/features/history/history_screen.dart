import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import 'data/ticket_model.dart';
import 'data/ticket_repository.dart';

final historyTicketsProvider = FutureProvider<List<Ticket>>((ref) async {
  final repo = ref.watch(ticketRepositoryProvider);
  final paginated = await repo.fetchTickets(page: 1);
  return paginated.results;
});

class HistoryScreen extends ConsumerWidget {
  const HistoryScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final ticketsAsync = ref.watch(historyTicketsProvider);

    return Scaffold(
      appBar: AppBar(title: const Text('History')),
      body: ticketsAsync.when(
        data: (tickets) {
          if (tickets.isEmpty) {
            return const Center(child: Text('No history found.'));
          }
          return RefreshIndicator(
            onRefresh: () => ref.refresh(historyTicketsProvider.future),
            child: ListView.builder(
              itemCount: tickets.length,
              itemBuilder: (context, index) {
                final ticket = tickets[index];
                return ListTile(
                  title: Text('Order #${ticket.uuid.substring(0, 6).toUpperCase()}'),
                  subtitle: Text(ticket.state.name.toUpperCase()),
                  trailing: Text('৳${ticket.courierFeeMinor / 100}'),
                  onTap: () => context.push('/history/ticket/${ticket.uuid}'),
                );
              },
            ),
          );
        },
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, st) => Center(child: Text('Failed to load history')),
      ),
    );
  }
}
