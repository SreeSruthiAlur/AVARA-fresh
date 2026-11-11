import 'package:avara_astrology_trial/models/astrologers_model.dart';
import 'package:avara_astrology_trial/services/avara_api_client.dart';

/// Service for all AVARA Astrologers API calls.
///
/// Endpoint reference (`backend/app/api/v1/astrologers.py`):
/// ```
/// GET  /astrologers                → List<AstrologerResponse>
/// GET  /astrologers/{id}           → AstrologerResponse
/// POST /astrologers/bookings       → BookingResponse (201)
/// GET  /astrologers/bookings/me    → List<BookingResponse>
/// DELETE /astrologers/bookings/{id}
/// ```
class AstrologersService {
  AstrologersService._();
  static final AstrologersService instance = AstrologersService._();

  final AvaraApiClient _client = AvaraApiClient.instance;

  // ---- Directory -----------------------------------------------------------

  /// Returns all astrologers, with optional [language] and [expertise] filters.
  Future<List<Astrologer>> getAstrologers({
    String? language,
    String? expertise,
  }) async {
    final params = <String, String>{
      if (language != null && language.isNotEmpty) 'language': language,
      if (expertise != null && expertise.isNotEmpty) 'expertise': expertise,
    };
    final data = await _client.get(
      '/astrologers',
      queryParams: params.isNotEmpty ? params : null,
    );
    final list = data as List? ?? [];
    return list
        .map((e) => Astrologer.fromJson(e as Map<String, dynamic>))
        .toList(growable: false);
  }

  // ---- Bookings ------------------------------------------------------------

  /// Creates a consultation booking request.
  ///
  /// Returns the persisted [ConsultationBooking] with server-assigned id.
  Future<ConsultationBooking> createBooking(ConsultationBooking booking) async {
    final data = await _client.post(
      '/astrologers/bookings',
      body: booking.toJson(),
    ) as Map<String, dynamic>;
    return ConsultationBooking.fromJson(data);
  }

  /// Returns the authenticated user's consultation booking history.
  Future<List<ConsultationBooking>> getMyBookings() async {
    final data = await _client.get('/astrologers/bookings/me');
    final list = data as List? ?? [];
    return list
        .map((e) => ConsultationBooking.fromJson(e as Map<String, dynamic>))
        .toList(growable: false);
  }

  /// Cancels a booking by [id].
  Future<void> cancelBooking(int id) async {
    await _client.delete('/astrologers/bookings/$id');
  }
}
