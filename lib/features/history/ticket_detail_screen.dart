import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'data/ticket_model.dart';
import 'data/ticket_repository.dart';

final ticketDetailProvider = FutureProvider.family<Ticket, String>((ref, uuid) async {
  final repo = ref.watch(ticketRepositoryProvider);
  return repo.fetchTicketDetails(uuid);
});

class TicketDetailScreen extends ConsumerWidget {
  const TicketDetailScreen({super.key, required this.uuid});
  final String uuid;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final ticketAsync = ref.watch(ticketDetailProvider(uuid));

    return Scaffold(
      appBar: AppBar(title: const Text('Ticket Details')),
      body: ticketAsync.when(
        data: (ticket) {
          return ListView(
            padding: const EdgeInsets.all(16.0),
            children: [
              Text('Order #${ticket.uuid.substring(0, 6).toUpperCase()}', style: Theme.of(context).textTheme.titleLarge),
              const SizedBox(height: 8),
              Text('State: ${ticket.state.name.toUpperCase()}'),
              Text('Courier Fee: ৳${ticket.courierFeeMinor / 100}'),
              const Divider(),
              const Text('Pickup', style: TextStyle(fontWeight: FontWeight.bold)),
              Text(ticket.pickupAddress),
              if (ticket.pickedAt != null) Text('Picked at: ${ticket.pickedAt}'),
              const SizedBox(height: 16),
              const Text('Dropoff', style: TextStyle(fontWeight: FontWeight.bold)),
              Text(ticket.dropoffAddress),
              if (ticket.droppedAt != null) Text('Dropped at: ${ticket.droppedAt}'),
            ],
          );
        },
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, st) => const Center(child: Text('Failed to load details')),
      ),
    );
  }
}
