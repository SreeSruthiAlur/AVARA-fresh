/// Data models for the AVARA Astrologers module.
///
/// Field names mirror the JSON keys returned by the backend
/// (`backend/app/schemas/astrologer.py`).
library;

// ---------------------------------------------------------------------------
// Astrologer
// ---------------------------------------------------------------------------

/// A verified astrologer available for consultation.
///
/// Maps to `AstrologerResponse` in the backend schema.
/// [isDemo] is `true` for the seed profiles — callers should display a
/// visible label so users know these are demonstration entries.
class Astrologer {
  const Astrologer({
    required this.id,
    required this.name,
    required this.title,
    required this.bio,
    required this.areasOfExpertise,
    required this.languages,
    required this.experienceYears,
    required this.consultationFee,
    required this.rating,
    required this.isDemo,
    required this.availableSlots,
  });

  final int id;
  final String name;
  final String title;
  final String bio;

  /// E.g. ["Vedic Astrology", "Career Guidance"].
  final List<String> areasOfExpertise;

  /// E.g. ["Telugu", "English"].
  final List<String> languages;

  final int experienceYears;

  /// Consultation fee in ₹.
  final double consultationFee;

  /// Rating out of 5.0.
  final double rating;

  /// Whether this is a demonstration / seed profile.
  final bool isDemo;

  /// Human-readable time strings, e.g. "10:00 AM".
  final List<String> availableSlots;

  factory Astrologer.fromJson(Map<String, dynamic> json) {
    List<String> toStringList(dynamic raw) => raw is List
        ? raw.map((e) => e?.toString() ?? '').toList(growable: false)
        : const [];

    return Astrologer(
      id: (json['id'] as num).toInt(),
      name: json['name']?.toString() ?? '',
      title: json['title']?.toString() ?? '',
      bio: json['bio']?.toString() ?? '',
      areasOfExpertise: toStringList(json['areas_of_expertise']),
      languages: toStringList(json['languages']),
      experienceYears: (json['experience_years'] as num?)?.toInt() ?? 0,
      consultationFee: (json['consultation_fee'] as num?)?.toDouble() ?? 0.0,
      rating: (json['rating'] as num?)?.toDouble() ?? 0.0,
      isDemo: json['is_demo'] as bool? ?? true,
      availableSlots: toStringList(json['available_slots']),
    );
  }
}

// ---------------------------------------------------------------------------
// ConsultationBooking
// ---------------------------------------------------------------------------

/// A consultation booking placed by the user.
///
/// Maps to `BookingResponse` in the backend schema.
class ConsultationBooking {
  const ConsultationBooking({
    required this.id,
    required this.astrologerId,
    this.astrologerName,
    required this.bookingDate,
    required this.timeSlot,
    required this.consultationTopic,
    required this.status,
    this.notes,
    this.isDemo = true,
  });

  final int id;
  final int astrologerId;
  final String? astrologerName;

  /// Date of the booking in `YYYY-MM-DD` format.
  final String bookingDate;

  /// Human-readable time string, e.g. "10:00 AM".
  final String timeSlot;
  final String consultationTopic;

  /// One of: `requested`, `confirmed`, `cancelled`.
  final String status;
  final String? notes;
  final bool isDemo;

  factory ConsultationBooking.fromJson(Map<String, dynamic> json) {
    return ConsultationBooking(
      id: (json['id'] as num).toInt(),
      astrologerId: (json['astrologer_id'] as num).toInt(),
      astrologerName: json['astrologer_name']?.toString(),
      bookingDate: json['booking_date']?.toString() ?? '',
      timeSlot: json['time_slot']?.toString() ?? '',
      consultationTopic: json['consultation_topic']?.toString() ?? '',
      status: json['status']?.toString() ?? 'requested',
      notes: json['notes']?.toString(),
      isDemo: json['is_demo'] as bool? ?? true,
    );
  }

  Map<String, dynamic> toJson() => {
        'astrologer_id': astrologerId,
        'booking_date': bookingDate,
        'time_slot': timeSlot,
        'consultation_topic': consultationTopic,
        if (notes != null && notes!.isNotEmpty) 'notes': notes,
      };
}
