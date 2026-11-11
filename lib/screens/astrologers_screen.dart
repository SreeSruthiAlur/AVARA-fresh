import 'package:avara_astrology_trial/models/astrologers_model.dart';
import 'package:avara_astrology_trial/services/astrologers_service.dart';
import 'package:avara_astrology_trial/services/avara_api_client.dart';
import 'package:avara_astrology_trial/theme/app_colors.dart';
import 'package:avara_astrology_trial/widgets/avara_surface_card.dart';
import 'package:flutter/material.dart';

/// AVARA Astrologers directory screen.
///
/// Shows a searchable [ListView] of astrologer cards — each with the
/// astrologer's name, expertise tags, star rating, availability indicator,
/// and two action buttons ("Chat" / "Video").
///
/// Demo profiles are clearly labelled with an amber pill badge so users
/// understand they are demonstration entries.
///
/// Tapping "Chat" or "Video" shows a booking sheet ([_BookingSheet]) allowing
/// the user to select a date, time slot, and topic before confirming.
class AstrologersScreen extends StatefulWidget {
  const AstrologersScreen({super.key});

  @override
  State<AstrologersScreen> createState() => _AstrologersScreenState();
}

class _AstrologersScreenState extends State<AstrologersScreen> {
  late Future<List<Astrologer>> _listFuture;
  final _searchController = TextEditingController();
  String _searchQuery = '';

  @override
  void initState() {
    super.initState();
    _listFuture = AstrologersService.instance.getAstrologers();
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _refresh() async {
    setState(() => _listFuture =
        AstrologersService.instance.getAstrologers());
    await _listFuture;
  }

  void _showBookingSheet(BuildContext context, Astrologer astrologer,
      {required bool isVideo}) {
    showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => _BookingSheet(
        astrologer: astrologer,
        isVideo: isVideo,
      ),
    );
  }

  // ---------------------------------------------------------------------------
  // Build
  // ---------------------------------------------------------------------------

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: Text('AVARA Astrologers',
            style: Theme.of(context).textTheme.titleLarge),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh_rounded),
            onPressed: _refresh,
            tooltip: 'Refresh',
          ),
        ],
      ),
      body: FutureBuilder<List<Astrologer>>(
        future: _listFuture,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(
                child:
                    CircularProgressIndicator(color: AppColors.violet));
          }
          if (snapshot.hasError) {
            final msg = snapshot.error is AvaraApiException
                ? (snapshot.error as AvaraApiException).message
                : 'Could not load astrologers.';
            return _ErrorView(message: msg, onRetry: _refresh);
          }

          final all = snapshot.data ?? [];
          final filtered = _searchQuery.isEmpty
              ? all
              : all
                  .where((a) =>
                      a.name
                          .toLowerCase()
                          .contains(_searchQuery.toLowerCase()) ||
                      a.areasOfExpertise.any((e) => e
                          .toLowerCase()
                          .contains(_searchQuery.toLowerCase())))
                  .toList(growable: false);

          return RefreshIndicator(
            onRefresh: _refresh,
            color: AppColors.violet,
            child: Column(
              children: [
                Padding(
                  padding: const EdgeInsets.fromLTRB(16, 12, 16, 0),
                  child: TextField(
                    controller: _searchController,
                    onChanged: (v) =>
                        setState(() => _searchQuery = v),
                    decoration: InputDecoration(
                      hintText: 'Search by name or expertise',
                      prefixIcon: const Icon(Icons.search,
                          color: AppColors.secondaryText),
                      suffixIcon: _searchQuery.isNotEmpty
                          ? IconButton(
                              icon: const Icon(Icons.clear,
                                  color: AppColors.secondaryText),
                              onPressed: () {
                                _searchController.clear();
                                setState(() => _searchQuery = '');
                              },
                            )
                          : null,
                    ),
                  ),
                ),
                const SizedBox(height: 8),
                Expanded(
                  child: filtered.isEmpty
                      ? _EmptyResults(query: _searchQuery)
                      : ListView.separated(
                          padding:
                              const EdgeInsets.fromLTRB(16, 8, 16, 40),
                          itemCount: filtered.length,
                          separatorBuilder: (_, _) =>
                              const SizedBox(height: 12),
                          itemBuilder: (context, i) => _AstrologerCard(
                            astrologer: filtered[i],
                            onChat: () => _showBookingSheet(
                              context,
                              filtered[i],
                              isVideo: false,
                            ),
                            onVideo: () => _showBookingSheet(
                              context,
                              filtered[i],
                              isVideo: true,
                            ),
                          ),
                        ),
                ),
              ],
            ),
          );
        },
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// Astrologer card
// ---------------------------------------------------------------------------

class _AstrologerCard extends StatelessWidget {
  const _AstrologerCard({
    required this.astrologer,
    required this.onChat,
    required this.onVideo,
  });

  final Astrologer astrologer;
  final VoidCallback onChat;
  final VoidCallback onVideo;

  @override
  Widget build(BuildContext context) {
    return AvaraSurfaceCard(
      backgroundColor: AppColors.white,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header row
          Row(
            children: [
              // Initials avatar
              CircleAvatar(
                radius: 26,
                backgroundColor: AppColors.lavender,
                child: Text(
                  astrologer.name.isNotEmpty
                      ? astrologer.name[0].toUpperCase()
                      : '?',
                  style: const TextStyle(
                    fontSize: 22,
                    fontWeight: FontWeight.w700,
                    color: AppColors.deepNavy,
                  ),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Expanded(
                          child: Text(
                            astrologer.name,
                            style: Theme.of(context).textTheme.titleMedium,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                        if (astrologer.isDemo)
                          _Pill(
                              label: 'Demo',
                              bg: AppColors.lightOrange,
                              fg: AppColors.orange),
                      ],
                    ),
                    Text(
                      astrologer.title,
                      style: Theme.of(context)
                          .textTheme
                          .bodySmall
                          ?.copyWith(color: AppColors.secondaryText),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          // Expertise tags
          Wrap(
            spacing: 6,
            runSpacing: 4,
            children: astrologer.areasOfExpertise
                .take(3)
                .map((e) => _Pill(
                    label: e,
                    bg: AppColors.lightPink,
                    fg: AppColors.violet))
                .toList(),
          ),
          const SizedBox(height: 10),
          // Stats row
          Row(
            children: [
              const Icon(Icons.star_rounded,
                  size: 16, color: AppColors.orange),
              const SizedBox(width: 4),
              Text(
                astrologer.rating.toStringAsFixed(1),
                style: Theme.of(context)
                    .textTheme
                    .labelMedium
                    ?.copyWith(fontWeight: FontWeight.w700),
              ),
              const SizedBox(width: 12),
              const Icon(Icons.work_outline,
                  size: 14, color: AppColors.secondaryText),
              const SizedBox(width: 4),
              Text('${astrologer.experienceYears}y exp',
                  style: Theme.of(context).textTheme.bodySmall),
              const SizedBox(width: 12),
              const Icon(Icons.currency_rupee,
                  size: 14, color: AppColors.secondaryText),
              Text(astrologer.consultationFee.toStringAsFixed(0),
                  style: Theme.of(context).textTheme.bodySmall),
              const Spacer(),
              // Availability dot
              Container(
                width: 8,
                height: 8,
                decoration: const BoxDecoration(
                  shape: BoxShape.circle,
                  color: AppColors.green,
                ),
              ),
              const SizedBox(width: 4),
              Text('Available',
                  style: Theme.of(context)
                      .textTheme
                      .labelSmall
                      ?.copyWith(color: AppColors.green)),
            ],
          ),
          const SizedBox(height: 14),
          // Action buttons
          Row(
            children: [
              Expanded(
                child: OutlinedButton.icon(
                  onPressed: onChat,
                  icon: const Icon(Icons.chat_bubble_outline, size: 16),
                  label: const Text('Chat'),
                  style: OutlinedButton.styleFrom(
                    foregroundColor: AppColors.deepNavy,
                    side: const BorderSide(color: AppColors.border),
                  ),
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: ElevatedButton.icon(
                  onPressed: onVideo,
                  icon: const Icon(Icons.videocam_outlined, size: 16),
                  label: const Text('Video'),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// Booking bottom sheet
// ---------------------------------------------------------------------------

class _BookingSheet extends StatefulWidget {
  const _BookingSheet({required this.astrologer, required this.isVideo});
  final Astrologer astrologer;
  final bool isVideo;

  @override
  State<_BookingSheet> createState() => _BookingSheetState();
}

class _BookingSheetState extends State<_BookingSheet> {
  final _topicController = TextEditingController();
  final _notesController = TextEditingController();
  String? _selectedSlot;
  DateTime _selectedDate = DateTime.now();
  bool _isLoading = false;

  @override
  void dispose() {
    _topicController.dispose();
    _notesController.dispose();
    super.dispose();
  }

  String get _formattedDate =>
      '${_selectedDate.year}-'
      '${_selectedDate.month.toString().padLeft(2, '0')}-'
      '${_selectedDate.day.toString().padLeft(2, '0')}';

  Future<void> _pickDate() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: _selectedDate.isBefore(DateTime.now())
          ? DateTime.now()
          : _selectedDate,
      firstDate: DateTime.now(),
      lastDate: DateTime.now().add(const Duration(days: 60)),
    );
    if (picked != null) setState(() => _selectedDate = picked);
  }

  Future<void> _confirm() async {
    if (_selectedSlot == null ||
        _topicController.text.trim().length < 3) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
        content:
            Text('Please select a time slot and describe your topic.'),
        behavior: SnackBarBehavior.floating,
      ));
      return;
    }

    setState(() => _isLoading = true);
    try {
      final booking = ConsultationBooking(
        id: 0, // placeholder; server assigns
        astrologerId: widget.astrologer.id,
        bookingDate: _formattedDate,
        timeSlot: _selectedSlot!,
        consultationTopic: _topicController.text.trim(),
        status: 'requested',
        notes: _notesController.text.trim().isNotEmpty
            ? _notesController.text.trim()
            : null,
      );
      await AstrologersService.instance.createBooking(booking);
      if (!mounted) return;
      Navigator.of(context).pop();
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
        content: const Text('Booking request submitted!'),
        backgroundColor: AppColors.green,
        behavior: SnackBarBehavior.floating,
        shape:
            RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
      ));
    } on AvaraApiException catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
        content: Text(e.message),
        backgroundColor: const Color(0xFFD32F2F),
        behavior: SnackBarBehavior.floating,
      ));
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(top: 60),
      decoration: const BoxDecoration(
        color: AppColors.background,
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      child: SafeArea(
        child: Padding(
          padding: EdgeInsets.only(
            left: 20,
            right: 20,
            top: 20,
            bottom: MediaQuery.of(context).viewInsets.bottom + 20,
          ),
          child: SingleChildScrollView(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              mainAxisSize: MainAxisSize.min,
              children: [
                // Handle bar
                Center(
                  child: Container(
                    width: 40,
                    height: 4,
                    decoration: BoxDecoration(
                      color: AppColors.border,
                      borderRadius: BorderRadius.circular(2),
                    ),
                  ),
                ),
                const SizedBox(height: 16),
                Text(
                  '${widget.isVideo ? 'Video' : 'Chat'} with ${widget.astrologer.name}',
                  style: Theme.of(context).textTheme.titleLarge,
                ),
                const SizedBox(height: 4),
                Text(
                  '₹${widget.astrologer.consultationFee.toStringAsFixed(0)} per session',
                  style: Theme.of(context)
                      .textTheme
                      .bodySmall
                      ?.copyWith(color: AppColors.secondaryText),
                ),
                const SizedBox(height: 20),
                // Date
                InkWell(
                  onTap: _pickDate,
                  borderRadius: BorderRadius.circular(12),
                  child: InputDecorator(
                    decoration: const InputDecoration(
                      labelText: 'Date',
                      prefixIcon: Icon(Icons.calendar_today_outlined,
                          color: AppColors.secondaryText),
                    ),
                    child: Text(_formattedDate,
                        style: Theme.of(context).textTheme.bodyMedium),
                  ),
                ),
                const SizedBox(height: 16),
                // Time slots
                Text('Select a Time',
                    style: Theme.of(context)
                        .textTheme
                        .labelLarge
                        ?.copyWith(color: AppColors.deepNavy)),
                const SizedBox(height: 10),
                Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: widget.astrologer.availableSlots
                      .map(
                        (slot) => ChoiceChip(
                          label: Text(slot),
                          selected: _selectedSlot == slot,
                          selectedColor: AppColors.lavender,
                          onSelected: (_) =>
                              setState(() => _selectedSlot = slot),
                          labelStyle: TextStyle(
                            color: _selectedSlot == slot
                                ? AppColors.deepNavy
                                : AppColors.secondaryText,
                            fontWeight: _selectedSlot == slot
                                ? FontWeight.w700
                                : FontWeight.w500,
                          ),
                        ),
                      )
                      .toList(),
                ),
                const SizedBox(height: 16),
                // Topic
                TextField(
                  controller: _topicController,
                  decoration: const InputDecoration(
                    labelText: 'Consultation Topic',
                    hintText: 'e.g. Career guidance, relationship clarity',
                    prefixIcon: Icon(Icons.help_outline,
                        color: AppColors.secondaryText),
                  ),
                ),
                const SizedBox(height: 12),
                // Notes
                TextField(
                  controller: _notesController,
                  maxLines: 2,
                  decoration: const InputDecoration(
                    labelText: 'Additional Notes (optional)',
                    prefixIcon: Icon(Icons.notes_outlined,
                        color: AppColors.secondaryText),
                  ),
                ),
                const SizedBox(height: 24),
                ElevatedButton(
                  onPressed: _isLoading ? null : _confirm,
                  child: _isLoading
                      ? const SizedBox(
                          width: 22,
                          height: 22,
                          child: CircularProgressIndicator(
                              color: Colors.white, strokeWidth: 2.5))
                      : const Text('Book Consultation →'),
                ),
                if (widget.astrologer.isDemo) ...[
                  const SizedBox(height: 12),
                  Text(
                    'This is a demonstration profile. '
                    'Your booking is private and confidential.',
                    style: Theme.of(context)
                        .textTheme
                        .bodySmall
                        ?.copyWith(color: AppColors.secondaryText),
                    textAlign: TextAlign.center,
                  ),
                ],
              ],
            ),
          ),
        ),
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// Small pill badge
// ---------------------------------------------------------------------------

class _Pill extends StatelessWidget {
  const _Pill({required this.label, required this.bg, required this.fg});
  final String label;
  final Color bg;
  final Color fg;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(20),
      ),
      child: Text(label,
          style: Theme.of(context)
              .textTheme
              .labelSmall
              ?.copyWith(color: fg, fontWeight: FontWeight.w600)),
    );
  }
}

// ---------------------------------------------------------------------------
// Empty / error states
// ---------------------------------------------------------------------------

class _EmptyResults extends StatelessWidget {
  const _EmptyResults({required this.query});
  final String query;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.search_off, size: 56, color: AppColors.border),
            const SizedBox(height: 16),
            Text(
              query.isNotEmpty
                  ? 'No results for "$query"'
                  : 'No astrologers available',
              style: Theme.of(context)
                  .textTheme
                  .bodyMedium
                  ?.copyWith(color: AppColors.secondaryText),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }
}

class _ErrorView extends StatelessWidget {
  const _ErrorView({required this.message, required this.onRetry});
  final String message;
  final VoidCallback onRetry;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.cloud_off_outlined,
                size: 56, color: AppColors.border),
            const SizedBox(height: 16),
            Text(message,
                textAlign: TextAlign.center,
                style: Theme.of(context)
                    .textTheme
                    .bodyMedium
                    ?.copyWith(color: AppColors.secondaryText)),
            const SizedBox(height: 20),
            OutlinedButton.icon(
              onPressed: onRetry,
              icon: const Icon(Icons.refresh_rounded),
              label: const Text('Retry'),
            ),
          ],
        ),
      ),
    );
  }
}
