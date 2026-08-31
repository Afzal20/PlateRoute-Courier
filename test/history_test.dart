import 'package:flutter_test/flutter_test.dart';
import 'package:courier/features/history/data/ticket_model.dart';

void main() {
  test('Ticket fromJson handles terminal states', () {
    final t1 = Ticket.fromJson({
      'uuid': '123',
      'state': 'dropped',
      'created_at': '2025-01-01T10:00:00Z',
    });
    
    expect(t1.state, TicketState.dropped);
    expect(t1.state.isTerminal, true);

    final t2 = Ticket.fromJson({
      'uuid': '456',
      'state': 'claimed',
      'created_at': '2025-01-01T10:00:00Z',
    });

    expect(t2.state.isTerminal, false);
  });
}
