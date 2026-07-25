import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../services/local_storage_service.dart';
import '../navigation/seller_navigator.dart';
import '../theme/app_theme.dart';
import '../theme/theme_colors.dart';

class OperationsScreen extends StatefulWidget {
  const OperationsScreen({super.key});

  @override
  State<OperationsScreen> createState() => _OperationsScreenState();
}

class _OperationsScreenState extends State<OperationsScreen> {
  bool _isOpen = true;
  bool _busyMode = false;
  bool _holidayMode = false;
  bool _autoAccept = false;
  bool _orderSound = true;
  bool _orderVibrate = true;
  String _prepTime = '25 min';
  String? _holidayStart;
  String? _holidayEnd;
  bool _loading = true;
  bool _isSaving = false;

  TimeOfDay _defaultOpen = const TimeOfDay(hour: 8, minute: 0);
  TimeOfDay _defaultClose = const TimeOfDay(hour: 22, minute: 0);

  late final Map<int, DaySchedule> _weeklyHours;

  final List<String> _prepOptions = [
    '15 min',
    '20 min',
    '25 min',
    '30 min',
    '45 min',
    '60 min'
  ];

  @override
  void initState() {
    super.initState();
    _weeklyHours = {
      for (var i = 1; i <= 7; i++)
        i: DaySchedule(open: true, start: _defaultOpen, end: _defaultClose)
    };
    _load();
  }

  static const _dayNames = {
    1: 'Monday',
    2: 'Tuesday',
    3: 'Wednesday',
    4: 'Thursday',
    5: 'Friday',
    6: 'Saturday',
    7: 'Sunday',
  };

  Future<void> _load() async {
    final user = Supabase.instance.client.auth.currentUser;
    if (user == null) return;
    final String userId = user.id;
    try {
      final shop = await Supabase.instance.client
          .from('Restaurants')
          .select()
          .eq('owner_id', userId)
          .maybeSingle();
      if (shop != null && mounted) {
        setState(() {
          _isOpen = shop['is_open'] ?? true;
          _prepTime = shop['delivery_time']?.toString() ?? '25 min';
          if (mounted) setState(() => _loading = false);
        });
      } else {
        if (mounted) setState(() => _loading = false);
      }
    } catch (_) {
      if (mounted) setState(() => _loading = false);
    }
  }

  Future<void> _save() async {
    setState(() => _isSaving = true);
    try {
      final user = Supabase.instance.client.auth.currentUser;
      if (user == null) return;
      final String userId = user.id;
      final shop = await Supabase.instance.client
          .from('Restaurants')
          .select('id')
          .eq('owner_id', userId)
          .maybeSingle();
      if (shop != null) {
        await Supabase.instance.client
            .from('Restaurants')
            .update({'is_open': _isOpen, 'delivery_time': _prepTime}).eq(
                'id', shop['id']);
      }
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
              content: Text('Operations updated'),
              backgroundColor: AppColors.green,
              behavior: SnackBarBehavior.floating),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
              content: Text('Error: $e'),
              backgroundColor: AppColors.red,
              behavior: SnackBarBehavior.floating),
        );
      }
    } finally {
      if (mounted) setState(() => _isSaving = false);
    }
  }

  Future<void> _changeStatus(String status) async {
    if (status == 'closed') {
      final confirm = await showDialog<bool>(
        context: context,
        builder: (ctx) => AlertDialog(
          shape:
              RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
          title: const Text('Close store?',
              style: TextStyle(fontWeight: FontWeight.w700)),
          content: const Text(
              'Your store will stop accepting new orders. Existing orders remain active.'),
          actions: [
            TextButton(
                onPressed: () => Navigator.pop(ctx, false),
                child: const Text('Cancel')),
            TextButton(
                onPressed: () => Navigator.pop(ctx, true),
                child: const Text('Close',
                    style: TextStyle(color: AppColors.red))),
          ],
        ),
      );
      if (confirm != true) return;
    }
    setState(() {
      _isOpen = status != 'closed';
      _busyMode = status == 'busy';
    });
    _save();
  }

  String get _storeStatus {
    if (_holidayMode) return 'holiday';
    if (!_isOpen) return 'closed';
    if (_busyMode) return 'busy';
    return 'open';
  }

  @override
  Widget build(BuildContext context) {
    if (_loading) {
      return Scaffold(
        backgroundColor: const Color(0xFFF8F9FA),
        appBar: AppBar(
            backgroundColor: Colors.white,
            elevation: 0,
            title: const Text('Operations',
                style: TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.w800,
                    color: Colors.black87))),
        body: const Center(
            child: CircularProgressIndicator(
                color: AppColors.orange, strokeWidth: 2.5)),
      );
    }

    return Scaffold(
      backgroundColor: const Color(0xFFF8F9FA),
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        scrolledUnderElevation: 0.5,
        title: const Text('Operations',
            style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.w800,
                color: Colors.black87)),
        leading: IconButton(
            icon: Icon(Icons.arrow_back_ios_new_rounded,
                color: context.textPrimary, size: 20),
            onPressed: () => Navigator.pop(context)),
        actions: [
          IconButton(
              icon: const Icon(Icons.save_rounded, color: AppColors.orange),
              onPressed: _isSaving ? null : _save)
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.fromLTRB(16, 16, 16, 100),
        child: Column(
          children: [
            _buildStatusSelector(),
            const SizedBox(height: 20),
            if (_busyMode) _buildBusyBanner(),
            if (_holidayMode) _buildHolidayBanner(),
            const SizedBox(height: 20),
            _sectionCard('Preparation Time', [
              _buildPrepTimeSelector(),
            ]),
            const SizedBox(height: 16),
            _sectionCard('Weekly Schedule', [
              ..._buildScheduleEditor(),
            ]),
            const SizedBox(height: 16),
            _sectionCard('Holiday Mode', [
              _buildSwitchRow(
                  Icons.beach_access_rounded,
                  'Holiday Mode',
                  _holidayMode ? 'Store is on holiday' : 'Operating normally',
                  _holidayMode, (v) {
                if (v)
                  _showHolidayPicker();
                else
                  setState(() {
                    _holidayMode = false;
                    _holidayStart = null;
                    _holidayEnd = null;
                  });
              }),
            ]),
            const SizedBox(height: 16),
            _sectionCard('Order Handling', [
              _buildSwitchRow(
                  Icons.autorenew_rounded,
                  'Auto Accept Orders',
                  'New orders are accepted automatically',
                  _autoAccept,
                  (v) => setState(() => _autoAccept = v)),
              const Divider(height: 1),
              _buildSwitchRow(
                  Icons.notifications_rounded,
                  'Order Sound',
                  'Play sound for new orders',
                  _orderSound,
                  (v) => setState(() => _orderSound = v)),
              const Divider(height: 1),
              _buildSwitchRow(
                  Icons.vibration_rounded,
                  'Vibrate',
                  'Vibrate on new orders',
                  _orderVibrate,
                  (v) => setState(() => _orderVibrate = v)),
            ]),
          ],
        ),
      ),
    );
  }

  Widget _buildStatusSelector() {
    final status = _storeStatus;
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(20),
          boxShadow: [
            BoxShadow(
                color: Colors.black.withValues(alpha: 0.04),
                blurRadius: 12,
                offset: const Offset(0, 2))
          ]),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text('Store Status',
              style: TextStyle(
                  fontSize: 17,
                  fontWeight: FontWeight.w800,
                  color: Colors.black87)),
          const SizedBox(height: 16),
          Row(
            children: [
              _statusOption('Open', Icons.check_circle_rounded, AppColors.green,
                  status == 'open', () => _changeStatus('open')),
              const SizedBox(width: 10),
              _statusOption(
                  'Busy',
                  Icons.speed_rounded,
                  const Color(0xFFF59E0B),
                  status == 'busy',
                  () => _changeStatus('busy')),
              const SizedBox(width: 10),
              _statusOption('Closed', Icons.cancel_rounded, AppColors.red,
                  status == 'closed', () => _changeStatus('closed')),
            ],
          ),
        ],
      ),
    );
  }

  Widget _statusOption(String label, IconData icon, Color color, bool selected,
      VoidCallback onTap) {
    return Expanded(
      child: GestureDetector(
        onTap: onTap,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          padding: const EdgeInsets.symmetric(vertical: 14),
          decoration: BoxDecoration(
            color: selected
                ? color.withValues(alpha: 0.1)
                : const Color(0xFFF3F4F6),
            borderRadius: BorderRadius.circular(14),
            border: Border.all(
                color: selected ? color : Colors.transparent, width: 1.5),
          ),
          child: Column(
            children: [
              Icon(icon, color: selected ? color : AppColors.muted, size: 28),
              const SizedBox(height: 6),
              Text(label,
                  style: TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w700,
                      color: selected ? color : AppColors.muted)),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildBusyBanner() {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: const Color(0xFFF59E0B).withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(14),
        border:
            Border.all(color: const Color(0xFFF59E0B).withValues(alpha: 0.3)),
      ),
      child: Row(
        children: [
          const Icon(Icons.info_outline, color: Color(0xFFF59E0B), size: 20),
          const SizedBox(width: 10),
          Expanded(
              child: Text('Customers will see longer preparation times.',
                  style: const TextStyle(
                      fontSize: 13,
                      color: Color(0xFF92400E),
                      fontWeight: FontWeight.w500))),
        ],
      ),
    );
  }

  Widget _buildHolidayBanner() {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: const Color(0xFF3B82F6).withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(14),
        border:
            Border.all(color: const Color(0xFF3B82F6).withValues(alpha: 0.3)),
      ),
      child: Row(
        children: [
          const Icon(Icons.beach_access_rounded,
              color: Color(0xFF3B82F6), size: 20),
          const SizedBox(width: 10),
          Expanded(
            child:
                Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              const Text('Holiday Mode Active',
                  style: TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w700,
                      color: Color(0xFF1E40AF))),
              if (_holidayStart != null)
                Text('Until $_holidayEnd',
                    style: const TextStyle(
                        fontSize: 12, color: Color(0xFF3B82F6))),
            ]),
          ),
        ],
      ),
    );
  }

  Widget _buildPrepTimeSelector() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Container(
              width: 40,
              height: 40,
              decoration: BoxDecoration(
                  color: AppColors.orange.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(10)),
              child: const Icon(Icons.timer_rounded,
                  color: AppColors.orange, size: 20),
            ),
            const SizedBox(width: 14),
            const Expanded(
                child: Text('Estimated Preparation Time',
                    style: TextStyle(
                        fontSize: 15,
                        fontWeight: FontWeight.w600,
                        color: Colors.black87))),
          ],
        ),
        const SizedBox(height: 14),
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: _prepOptions.map((opt) {
            final selected = opt == _prepTime;
            return GestureDetector(
              onTap: () => setState(() => _prepTime = opt),
              child: Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                decoration: BoxDecoration(
                  color: selected ? AppColors.orange : const Color(0xFFF3F4F6),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Text(opt,
                    style: TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.w700,
                        color: selected ? Colors.white : Colors.black87)),
              ),
            );
          }).toList(),
        ),
      ],
    );
  }

  List<Widget> _buildScheduleEditor() {
    return _dayNames.entries.map((entry) {
      final day = entry.key;
      final schedule = _weeklyHours[day]!;
      return Column(
        children: [
          Row(
            children: [
              SizedBox(
                  width: 100,
                  child: Text(entry.value,
                      style: const TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w600,
                          color: Colors.black87))),
              Switch(
                  value: schedule.open,
                  activeColor: AppColors.green,
                  onChanged: (v) => setState(() => schedule.open = v)),
              if (schedule.open) ...[
                _timeChip(
                    schedule.start, (t) => setState(() => schedule.start = t)),
                const Padding(
                  padding: EdgeInsets.symmetric(horizontal: 4),
                  child: Text('-',
                      style: TextStyle(fontSize: 13, color: AppColors.muted)),
                ),
                _timeChip(
                    schedule.end, (t) => setState(() => schedule.end = t)),
              ] else
                const Text('Closed',
                    style: TextStyle(fontSize: 13, color: AppColors.muted)),
            ],
          ),
          if (day != 7) const Divider(height: 1),
        ],
      );
    }).toList();
  }

  Widget _timeChip(TimeOfDay time, ValueChanged<TimeOfDay> onChanged) {
    return GestureDetector(
      onTap: () async {
        final picked = await showTimePicker(
          context: context,
          initialTime: time,
          builder: (context, child) => Theme(
            data: Theme.of(context).copyWith(
                colorScheme: const ColorScheme.light(
                    primary: AppColors.orange, onPrimary: Colors.white)),
            child: child!,
          ),
        );
        if (picked != null) onChanged(picked);
      },
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
        decoration: BoxDecoration(
            color: const Color(0xFFF3F4F6),
            borderRadius: BorderRadius.circular(8)),
        child: Text(time.format(context),
            style: const TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w600,
                color: Colors.black87)),
      ),
    );
  }

  Future<void> _showHolidayPicker() async {
    final initialRange = _holidayStart != null && _holidayEnd != null
        ? DateTimeRange(
            start: DateTime.parse(_holidayStart!),
            end: DateTime.parse(_holidayEnd!),
          )
        : DateTimeRange(
            start: DateTime.now(),
            end: DateTime.now().add(const Duration(days: 3)),
          );

    final picked = await showDateRangePicker(
      context: context,
      firstDate: DateTime.now(),
      lastDate: DateTime.now().add(const Duration(days: 365)),
      initialDateRange: initialRange,
      builder: (context, child) => Theme(
        data: Theme.of(context).copyWith(
            colorScheme: const ColorScheme.light(
                primary: AppColors.orange, onPrimary: Colors.white)),
        child: child!,
      ),
    );

    if (picked != null) {
      setState(() {
        _holidayMode = true;
        _holidayStart = picked.start.toIso8601String().split('T')[0];
        _holidayEnd = picked.end.toIso8601String().split('T')[0];
      });
    }
  }

  Widget _sectionCard(String title, List<Widget> children) {
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(20),
          boxShadow: [
            BoxShadow(
                color: Colors.black.withValues(alpha: 0.04),
                blurRadius: 12,
                offset: const Offset(0, 2))
          ]),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Text(title,
            style: const TextStyle(
                fontSize: 17,
                fontWeight: FontWeight.w800,
                color: Colors.black87)),
        const SizedBox(height: 14),
        ...children,
      ]),
    );
  }

  Widget _buildSwitchRow(IconData icon, String title, String subtitle,
      bool value, ValueChanged<bool> onChanged) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(children: [
        Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
                color: value
                    ? AppColors.green.withValues(alpha: 0.1)
                    : AppColors.muted.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(10)),
            child: Icon(icon,
                color: value ? AppColors.green : AppColors.muted, size: 20)),
        const SizedBox(width: 14),
        Expanded(
            child:
                Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Text(title,
              style: const TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                  color: Colors.black87)),
          Text(subtitle,
              style: const TextStyle(fontSize: 11, color: AppColors.muted)),
        ])),
        Switch(
            value: value, activeColor: AppColors.green, onChanged: onChanged),
      ]),
    );
  }
}

class DaySchedule {
  bool open;
  TimeOfDay start;
  TimeOfDay end;
  DaySchedule({required this.open, required this.start, required this.end});
}
