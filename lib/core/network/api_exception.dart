/// Unified DRF error envelope mapping (MOB-C-05): `{detail, code}` plus
/// domain codes the courier flow cares about (atomic claim arbitration).
class ApiException implements Exception {
  ApiException({
    required this.statusCode,
    this.code = 'unknown',
    this.detail = 'Request failed',
    this.fields = const {},
  });

  final int statusCode;
  final String code;
  final String detail;
  final Map<String, List<String>> fields;

  bool get isAuthExpired => statusCode == 401;

  /// `delivery.already_claimed` / `delivery.offer_unavailable` — another
  /// rider won the race. Neutral UX, never red.
  bool get isClaimLost =>
      code == 'delivery.already_claimed' || code == 'delivery.offer_unavailable';

  bool get isNetwork => statusCode == 0;

  factory ApiException.fromDio(Object error) {
    final re = error as dynamic;
    try {
      final response = re.response;
      final data = response?.data;
      if (data is Map) {
        final rawDetail = data['detail'];
        String detail;
        if (rawDetail is String) {
          detail = rawDetail;
        } else if (rawDetail is List) {
          detail = rawDetail.map((e) => e.toString()).join(', ');
        } else {
          detail = data.entries
              .map((e) => '${e.key}: ${(e.value as List?)?.join(", ")}')
              .join('; ');
        }
        return ApiException(
          statusCode: (response?.statusCode ?? 400) as int,
          code: (data['code'] ?? 'unknown') as String,
          detail: detail,
          fields: data is Map<String, dynamic>
              ? data.map((k, v) => MapEntry(
                  k, v is List ? v.map((e) => e.toString()).toList() : [v.toString()]))
              : {},
        );
      }
      return ApiException(
        statusCode: (response?.statusCode ?? 0) as int,
        detail: response?.statusMessage ?? 'Request failed',
      );
    } catch (_) {
      return ApiException(statusCode: 0, code: 'network', detail: 'No connection');
    }
  }

  @override
  String toString() => 'ApiException($statusCode, $code, $detail)';
}
