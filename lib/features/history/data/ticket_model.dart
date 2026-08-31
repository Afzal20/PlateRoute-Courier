import 'package:equatable/equatable.dart';

enum TicketState {
  created, offering, claimed, atVendor, picked, arrived, dropped, cancelled, expiredNoCourier;

  static TicketState fromString(String s) {
    switch (s) {
      case 'created': return TicketState.created;
      case 'offering': return TicketState.offering;
      case 'claimed': return TicketState.claimed;
      case 'at_vendor': return TicketState.atVendor;
      case 'picked': return TicketState.picked;
      case 'arrived': return TicketState.arrived;
      case 'dropped': return TicketState.dropped;
      case 'cancelled': return TicketState.cancelled;
      case 'expired_no_courier': return TicketState.expiredNoCourier;
      default: return TicketState.created;
    }
  }

  bool get isTerminal => switch (this) {
    TicketState.dropped || TicketState.cancelled || TicketState.expiredNoCourier => true,
    _ => false,
  };
}

class Ticket extends Equatable {
  const Ticket({
    required this.uuid,
    required this.orderUuid,
    required this.state,
    required this.courierFeeMinor,
    required this.createdAt,
    this.claimedAt,
    this.pickedAt,
    this.droppedAt,
    required this.pickupAddress,
    required this.dropoffAddress,
  });

  final String uuid;
  final String orderUuid;
  final TicketState state;
  final int courierFeeMinor;
  final DateTime createdAt;
  final DateTime? claimedAt;
  final DateTime? pickedAt;
  final DateTime? droppedAt;
  final String pickupAddress;
  final String dropoffAddress;

  factory Ticket.fromJson(Map<String, dynamic> json) => Ticket(
    uuid: json['uuid'] as String,
    orderUuid: json['order_uuid'] as String? ?? '',
    state: TicketState.fromString(json['state'] as String? ?? 'created'),
    courierFeeMinor: (json['courier_fee_minor'] as num?)?.toInt() ?? 0,
    createdAt: DateTime.parse(json['created_at'] as String),
    claimedAt: json['claimed_at'] != null ? DateTime.tryParse(json['claimed_at'] as String) : null,
    pickedAt: json['picked_at'] != null ? DateTime.tryParse(json['picked_at'] as String) : null,
    droppedAt: json['dropped_at'] != null ? DateTime.tryParse(json['dropped_at'] as String) : null,
    pickupAddress: json['pickup_address'] as String? ?? 'Unknown Pickup',
    dropoffAddress: json['dropoff_address'] as String? ?? 'Unknown Dropoff',
  );

  @override
  List<Object?> get props => [uuid, state];
}

class PaginatedTickets {
  const PaginatedTickets({
    required this.results,
    required this.nextUrl,
  });

  final List<Ticket> results;
  final String? nextUrl;

  factory PaginatedTickets.fromJson(Map<String, dynamic> json) => PaginatedTickets(
    results: (json['results'] as List<dynamic>?)
        ?.map((j) => Ticket.fromJson(j as Map<String, dynamic>))
        .toList() ?? [],
    nextUrl: json['next'] as String?,
  );
}
