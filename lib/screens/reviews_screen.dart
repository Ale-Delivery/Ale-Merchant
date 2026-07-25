import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../services/local_storage_service.dart';
import '../theme/app_theme.dart';

class ReviewsScreen extends StatefulWidget {
  const ReviewsScreen({super.key});

  @override
  State<ReviewsScreen> createState() => _ReviewsScreenState();
}

class _ReviewsScreenState extends State<ReviewsScreen> {
  List<Map<String, dynamic>> _reviews = [];
  bool _loading = true;
  int _ratingFilter = 0;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    final userId = await LocalStorageService.getUserId();
    if (userId == null) return;
    try {
      final shop = await Supabase.instance.client
          .from('Restaurants')
          .select('id')
          .eq('owner_id', userId)
          .maybeSingle();
      if (shop != null) {
        final data = await Supabase.instance.client
            .from('Reviews')
            .select('rating, comment, created_at')
            .eq('restaurant_id', shop['id'])
            .order('created_at', ascending: false);
        if (mounted)
          setState(() {
            _reviews = List<Map<String, dynamic>>.from(data);
            _loading = false;
          });
      } else if (mounted) setState(() => _loading = false);
    } catch (_) {
      if (mounted) setState(() => _loading = false);
    }
  }

  double get _avgRating => _reviews.isEmpty
      ? 0
      : _reviews.fold<double>(
              0, (s, r) => s + ((r['rating'] as num?)?.toDouble() ?? 0)) /
          _reviews.length;

  List<Map<String, dynamic>> get _filtered => _ratingFilter == 0
      ? _reviews
      : _reviews
          .where((r) => (r['rating'] as num?)?.toInt() == _ratingFilter)
          .toList();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF8F9FA),
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        scrolledUnderElevation: 0.5,
        title: const Text('Customer Reviews',
            style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.w800,
                color: Colors.black87)),
        leading: IconButton(
            icon: Icon(Icons.arrow_back_ios_new_rounded,
                color: Colors.black87, size: 20),
            onPressed: () => Navigator.pop(context)),
      ),
      body: _loading
          ? const Center(
              child: CircularProgressIndicator(
                  color: AppColors.orange, strokeWidth: 2.5))
          : Column(children: [
              if (_reviews.isNotEmpty)
                Container(
                  padding: const EdgeInsets.all(16),
                  margin: const EdgeInsets.fromLTRB(16, 12, 16, 0),
                  decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(16),
                      boxShadow: [
                        BoxShadow(
                            color: Colors.black.withValues(alpha: 0.04),
                            blurRadius: 8,
                            offset: const Offset(0, 2))
                      ]),
                  child: Row(children: [
                    Container(
                        width: 52,
                        height: 52,
                        decoration: BoxDecoration(
                            color:
                                const Color(0xFFF59E0B).withValues(alpha: 0.1),
                            borderRadius: BorderRadius.circular(14)),
                        child: const Icon(Icons.star_rounded,
                            color: Color(0xFFF59E0B), size: 28)),
                    const SizedBox(width: 14),
                    Expanded(
                        child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                          Text(_avgRating.toStringAsFixed(1),
                              style: const TextStyle(
                                  fontSize: 24,
                                  fontWeight: FontWeight.w900,
                                  color: Colors.black87)),
                          Text('${_reviews.length} reviews',
                              style: const TextStyle(color: AppColors.muted)),
                        ])),
                    Row(
                        mainAxisSize: MainAxisSize.min,
                        children: List.generate(
                            5,
                            (i) => Icon(
                                i < _avgRating.round()
                                    ? Icons.star_rounded
                                    : Icons.star_outline_rounded,
                                color: i < _avgRating.round()
                                    ? const Color(0xFFF59E0B)
                                    : const Color(0xFFD1D5DB),
                                size: 20))),
                  ]),
                ),
              const SizedBox(height: 12),
              SizedBox(
                height: 36,
                child: ListView(
                    scrollDirection: Axis.horizontal,
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    children: [
                      _starChip('All', 0),
                      _starChip('★★★★★', 5),
                      _starChip('★★★★☆', 4),
                      _starChip('★★★☆☆', 3),
                      _starChip('★★☆☆☆', 2),
                      _starChip('★☆☆☆☆', 1),
                    ]),
              ),
              Expanded(
                child: _filtered.isEmpty
                    ? Center(
                        child:
                            Column(mainAxisSize: MainAxisSize.min, children: [
                        Icon(Icons.rate_review_rounded,
                            size: 56, color: AppColors.muted),
                        const SizedBox(height: 12),
                        Text(
                            _reviews.isEmpty
                                ? 'No reviews yet'
                                : 'No reviews with this rating',
                            style: TextStyle(color: AppColors.muted))
                      ]))
                    : RefreshIndicator(
                        onRefresh: _load,
                        child: ListView.builder(
                            padding: const EdgeInsets.fromLTRB(16, 8, 16, 100),
                            itemCount: _filtered.length,
                            itemBuilder: (_, i) {
                              final r = _filtered[i];
                              final rating =
                                  (r['rating'] as num?)?.toDouble() ?? 0;
                              final comment = r['comment'] ?? '';
                              final date = r['created_at'] != null
                                  ? DateFormat('MMM d, yyyy')
                                      .format(DateTime.parse(r['created_at']))
                                  : '';
                              return Container(
                                margin: const EdgeInsets.only(bottom: 10),
                                padding: const EdgeInsets.all(14),
                                decoration: BoxDecoration(
                                    color: Colors.white,
                                    borderRadius: BorderRadius.circular(14),
                                    boxShadow: [
                                      BoxShadow(
                                          color: Colors.black
                                              .withValues(alpha: 0.03),
                                          blurRadius: 6,
                                          offset: const Offset(0, 1))
                                    ]),
                                child: Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      Row(children: [
                                        ...List.generate(
                                            5,
                                            (j) => Icon(
                                                j < rating
                                                    ? Icons.star_rounded
                                                    : Icons
                                                        .star_outline_rounded,
                                                color: j < rating
                                                    ? const Color(0xFFF59E0B)
                                                    : const Color(0xFFD1D5DB),
                                                size: 16)),
                                        const SizedBox(width: 8),
                                        Text(date,
                                            style: const TextStyle(
                                                fontSize: 11,
                                                color: AppColors.muted)),
                                      ]),
                                      if (comment.toString().isNotEmpty) ...[
                                        const SizedBox(height: 6),
                                        Text(comment.toString(),
                                            style: const TextStyle(
                                                fontSize: 13,
                                                color: Colors.black87,
                                                height: 1.4))
                                      ],
                                    ]),
                              );
                            }),
                      ),
              ),
            ]),
    );
  }

  Widget _starChip(String label, int value) {
    final selected = _ratingFilter == value;
    return Padding(
      padding: const EdgeInsets.only(right: 8),
      child: GestureDetector(
        onTap: () {
          _ratingFilter = value;
          setState(() {});
        },
        child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
            decoration: BoxDecoration(
                color: selected ? AppColors.orange : const Color(0xFFF3F4F6),
                borderRadius: BorderRadius.circular(20)),
            child: Text(label,
                style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                    color: selected ? Colors.white : Colors.black87))),
      ),
    );
  }
}
