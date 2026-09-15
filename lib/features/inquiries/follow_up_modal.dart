import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import '../../core/theme.dart';
import '../../models/inquiry.dart';
import '../../providers/auth_provider.dart';
import '../../providers/inquiry_provider.dart';

class FollowUpModal extends StatefulWidget {
  final Inquiry inquiry;

  const FollowUpModal({super.key, required this.inquiry});

  @override
  State<FollowUpModal> createState() => _FollowUpModalState();
}

class _FollowUpModalState extends State<FollowUpModal> {
  final _noteController = TextEditingController();
  DateTime _selectedDate = DateTime.now().add(const Duration(days: 1));
  TimeOfDay _selectedTime = const TimeOfDay(hour: 11, minute: 0);

  @override
  void dispose() {
    _noteController.dispose();
    super.dispose();
  }

  void _saveFollowUp() {
    final auth = context.read<AuthProvider>();
    final inqProvider = context.read<InquiryProvider>();

    final scheduled = DateTime(
      _selectedDate.year,
      _selectedDate.month,
      _selectedDate.day,
      _selectedTime.hour,
      _selectedTime.minute,
    );

    inqProvider.scheduleFollowUp(
      inquiryId: widget.inquiry.id,
      followUpDate: scheduled,
      note: _noteController.text.trim(),
      userId: auth.currentUser?.id,
      userName: auth.currentUser?.name,
    );

    Navigator.of(context).pop();

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          'Follow-up scheduled for ${DateFormat('dd MMM, hh:mm a').format(scheduled)}',
        ),
        backgroundColor: AppTheme.primaryDark,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 450),
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: AppTheme.primaryLight,
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: const Icon(Icons.alarm_add_rounded, color: AppTheme.primaryEmerald),
                  ),
                  const SizedBox(width: 12),
                  const Expanded(
                    child: Text(
                      'Schedule Follow-Up',
                      style: TextStyle(fontSize: 18, fontWeight: FontWeight.w700),
                    ),
                  ),
                  IconButton(
                    icon: const Icon(Icons.close),
                    onPressed: () => Navigator.of(context).pop(),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              Text(
                'Buyer: ${widget.inquiry.buyerDisplayName} (${widget.inquiry.contactPhone})',
                style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 13),
              ),
              if (widget.inquiry.productCode != null) ...[
                const SizedBox(height: 2),
                Text(
                  'Design: ${widget.inquiry.productCode}',
                  style: const TextStyle(color: AppTheme.primaryEmerald, fontSize: 13, fontWeight: FontWeight.w600),
                ),
              ],
              const SizedBox(height: 16),

              // Date Selector
              ListTile(
                contentPadding: EdgeInsets.zero,
                leading: const Icon(Icons.calendar_today, color: AppTheme.primaryEmerald),
                title: const Text('Follow-Up Date', style: TextStyle(fontSize: 13, color: AppTheme.textSecondary)),
                subtitle: Text(
                  DateFormat('EEE, dd MMM yyyy').format(_selectedDate),
                  style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 14, color: AppTheme.textPrimary),
                ),
                trailing: TextButton(
                  onPressed: () async {
                    final picked = await showDatePicker(
                      context: context,
                      initialDate: _selectedDate,
                      firstDate: DateTime.now(),
                      lastDate: DateTime.now().add(const Duration(days: 365)),
                    );
                    if (picked != null) setState(() => _selectedDate = picked);
                  },
                  child: const Text('Change Date'),
                ),
              ),

              // Time Selector
              ListTile(
                contentPadding: EdgeInsets.zero,
                leading: const Icon(Icons.access_time, color: AppTheme.primaryEmerald),
                title: const Text('Time', style: TextStyle(fontSize: 13, color: AppTheme.textSecondary)),
                subtitle: Text(
                  _selectedTime.format(context),
                  style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 14, color: AppTheme.textPrimary),
                ),
                trailing: TextButton(
                  onPressed: () async {
                    final picked = await showTimePicker(
                      context: context,
                      initialTime: _selectedTime,
                    );
                    if (picked != null) setState(() => _selectedTime = picked);
                  },
                  child: const Text('Change Time'),
                ),
              ),
              const SizedBox(height: 12),

              // Note
              TextField(
                controller: _noteController,
                maxLines: 2,
                decoration: const InputDecoration(
                  labelText: 'Follow-up Note (e.g. Call for rate confirmation)',
                ),
              ),
              const SizedBox(height: 24),

              ElevatedButton(
                onPressed: _saveFollowUp,
                child: const Text('Set Reminder & Save'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

