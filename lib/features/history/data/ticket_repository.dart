import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../state/app_providers.dart';
import 'ticket_model.dart';

class TicketRepository {
  const TicketRepository(this._dio);
  final Dio _dio;

  Future<PaginatedTickets> fetchTickets({int page = 1}) async {
    final resp = await _dio.get('/tickets/', queryParameters: {'page': page});
    return PaginatedTickets.fromJson(resp.data as Map<String, dynamic>);
  }

  Future<Ticket> fetchTicketDetails(String uuid) async {
    final resp = await _dio.get('/tickets/$uuid/');
    return Ticket.fromJson(resp.data as Map<String, dynamic>);
  }
}

final ticketRepositoryProvider = Provider<TicketRepository>((ref) {
  final api = ref.watch(apiClientProvider);
  return TicketRepository(api.dio);
});
