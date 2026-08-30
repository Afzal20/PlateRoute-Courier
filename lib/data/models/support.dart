/// Support ticket list row (`GET /support/tickets/`).
class Ticket {
  const Ticket({
    required this.uuid,
    required this.subject,
    required this.category,
    required this.priority,
    required this.status,
    required this.createdAt,
    this.orderUuid,
  });

  final String uuid;
  final String subject;
  final String category;
  final String priority;
  final String status;
  final DateTime createdAt;
  final String? orderUuid;

  factory Ticket.fromJson(Map<String, Object?> json) => Ticket(
        uuid: json['uuid'] as String,
        subject: (json['subject'] as String?) ?? 'Support',
        category: (json['category'] as String?) ?? 'other',
        priority: (json['priority'] as String?) ?? 'normal',
        status: (json['status'] as String?) ?? 'open',
        orderUuid: json['order'] as String?,
        createdAt: DateTime.tryParse((json['created_at'] ?? '') as String) ??
            DateTime.now(),
      );
}

/// Support ticket thread (`GET /support/tickets/{uuid}/`).
class TicketThread {
  const TicketThread({
    required this.uuid,
    required this.status,
    required this.priority,
    required this.messages,
  });

  final String uuid;
  final String status;
  final String priority;
  final List<TicketMessage> messages;

  factory TicketThread.fromJson(Map<String, Object?> json) => TicketThread(
        uuid: json['uuid'] as String,
        status: json['status'] as String,
        priority: json['priority'] as String,
        messages: [
          for (final m in ((json['messages'] as List?) ?? []))
            TicketMessage.fromJson((m as Map).cast<String, Object?>())
        ],
      );
}

class TicketMessage {
  const TicketMessage({
    required this.sender,
    required this.body,
    required this.internal,
    required this.createdAt,
  });

  final String sender;
  final String body;
  final bool internal;
  final DateTime createdAt;

  factory TicketMessage.fromJson(Map<String, Object?> json) => TicketMessage(
        sender: (json['sender'] as String?) ?? '',
        body: (json['body'] as String?) ?? '',
        internal: json['internal'] == true,
        createdAt: DateTime.tryParse((json['created_at'] ?? '') as String) ??
            DateTime.now(),
      );
}
