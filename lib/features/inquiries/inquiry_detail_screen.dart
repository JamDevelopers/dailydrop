import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import '../../core/theme.dart';
import '../../core/responsive.dart';
import '../../models/inquiry.dart';
import '../../models/collection.dart';
import '../../models/product.dart';
import '../../providers/auth_provider.dart';
import '../../providers/catalog_provider.dart';
import '../../providers/inquiry_provider.dart';
import '../../services/whatsapp_link_service.dart';
import 'follow_up_modal.dart';

class InquiryDetailScreen extends StatefulWidget {
  final Inquiry inquiry;

  const InquiryDetailScreen({super.key, required this.inquiry});

  @override
  State<InquiryDetailScreen> createState() => _InquiryDetailScreenState();
}

class _InquiryDetailScreenState extends State<InquiryDetailScreen> {
  final _activityNoteController = TextEditingController();

  @override
  void dispose() {
    _activityNoteController.dispose();
    super.dispose();
  }

  void _addNote() {
    if (_activityNoteController.text.trim().isEmpty) return;
    final auth = context.read<AuthProvider>();
    final inqProvider = context.read<InquiryProvider>();

    inqProvider.addActivity(
      inquiryId: widget.inquiry.id,
      activityType: 'note',
      body: _activityNoteController.text.trim(),
      userId: auth.currentUser?.id,
      userName: auth.currentUser?.name,
    );

    _activityNoteController.clear();
  }

  @override
  Widget build(BuildContext context) {
    final auth = context.watch<AuthProvider>();
    final inqProvider = context.watch<InquiryProvider>();

    final currentInquiry = inqProvider.allInquiries.firstWhere(
      (i) => i.id == widget.inquiry.id,
      orElse: () => widget.inquiry,
    );

    return Scaffold(
      appBar: AppBar(
        title: Text(
          'Inquiry #${currentInquiry.id} • ${currentInquiry.buyerDisplayName}',
        ),
        actions: [
          ElevatedButton.icon(
            icon: const Icon(Icons.alarm_add, size: 16, color: Colors.white),
            label: const Text('Follow-Up'),
            style: ElevatedButton.styleFrom(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
              textStyle: const TextStyle(fontSize: 12),
            ),
            onPressed: () {
              showDialog(
                context: context,
                builder: (_) => FollowUpModal(inquiry: currentInquiry),
              );
            },
          ),
          const SizedBox(width: 12),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: MaxWidthContainer(
          maxWidth: 1000,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // Buyer Contact & Quick Actions Card
              Card(
                child: Padding(
                  padding: const EdgeInsets.all(20),
                  child: Row(
                    children: [
                      Container(
                        width: 52,
                        height: 52,
                        decoration: BoxDecoration(
                          color: AppTheme.primaryLight,
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: const Icon(
                          Icons.person,
                          color: AppTheme.primaryEmerald,
                          size: 28,
                        ),
                      ),
                      const SizedBox(width: 16),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              currentInquiry.buyerDisplayName,
                              style: const TextStyle(
                                fontSize: 18,
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                            const SizedBox(height: 2),
                            Text(
                              'Phone: ${currentInquiry.contactPhone}',
                              style: const TextStyle(
                                fontSize: 13,
                                color: AppTheme.textSecondary,
                              ),
                            ),
                            if (currentInquiry.nextFollowUpAt != null) ...[
                              const SizedBox(height: 4),
                              Row(
                                children: [
                                  const Icon(
                                    Icons.alarm,
                                    size: 14,
                                    color: AppTheme.accentGold,
                                  ),
                                  const SizedBox(width: 4),
                                  Text(
                                    'Follow-up: ${DateFormat('dd MMM, hh:mm a').format(currentInquiry.nextFollowUpAt!)}',
                                    style: const TextStyle(
                                      fontSize: 12,
                                      fontWeight: FontWeight.w700,
                                      color: AppTheme.accentGold,
                                    ),
                                  ),
                                ],
                              ),
                            ],
                          ],
                        ),
                      ),
                      // 1-Tap WhatsApp Action
                      ElevatedButton.icon(
                        icon: const Icon(
                          Icons.chat_bubble,
                          size: 16,
                          color: Colors.white,
                        ),
                        label: const Text('Open WhatsApp'),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: AppTheme.whatsappGreen,
                          padding: const EdgeInsets.symmetric(
                            horizontal: 16,
                            vertical: 12,
                          ),
                        ),
                        onPressed: () {
                          final msg =
                              'Hello ${currentInquiry.contactName ?? ""}, regarding your inquiry for Design ${currentInquiry.productCode ?? ""} from Surat Silk Mills.';
                          WhatsAppLinkService.openDirectChat(
                            buyerPhone: currentInquiry.contactPhone,
                            initialText: msg,
                          );
                        },
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 16),

              // Linked Product Card
              if (currentInquiry.productCode != null)
                Card(
                  child: Padding(
                    padding: const EdgeInsets.all(16),
                    child: Row(
                      children: [
                        if (currentInquiry.productImage != null)
                          ClipRRect(
                            borderRadius: BorderRadius.circular(8),
                            child: Image.network(
                              currentInquiry.productImage!,
                              width: 64,
                              height: 64,
                              fit: BoxFit.cover,
                            ),
                          ),
                        const SizedBox(width: 14),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Container(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 6,
                                  vertical: 2,
                                ),
                                decoration: BoxDecoration(
                                  color: AppTheme.primaryLight,
                                  borderRadius: BorderRadius.circular(4),
                                ),
                                child: Text(
                                  'DESIGN ${currentInquiry.productCode}',
                                  style: const TextStyle(
                                    fontSize: 12,
                                    fontWeight: FontWeight.w700,
                                    color: AppTheme.primaryDark,
                                  ),
                                ),
                              ),
                              const SizedBox(height: 4),
                              Text(
                                currentInquiry.productTitle ??
                                    'Surat Wholesale Design',
                                style: const TextStyle(
                                  fontSize: 14,
                                  fontWeight: FontWeight.w600,
                                ),
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                              ),
                              if (currentInquiry.collectionName != null)
                                Text(
                                  'From: ${currentInquiry.collectionName}',
                                  style: const TextStyle(
                                    fontSize: 12,
                                    color: AppTheme.textSecondary,
                                  ),
                                ),
                            ],
                          ),
                        ),
                        if (currentInquiry.productPrice != null)
                          Text(
                            '₹${currentInquiry.productPrice!.toStringAsFixed(0)}',
                            style: const TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.w800,
                              color: AppTheme.primaryEmerald,
                            ),
                          ),
                      ],
                    ),
                  ),
                ),
              const SizedBox(height: 16),

              // Expiry & Limited-Time Link Follow-Up Card
              Builder(
                builder: (context) {
                  final catalog = context.watch<CatalogProvider>();
                  final linkedCollection = catalog.collections.where((c) {
                    if (currentInquiry.collectionId != null &&
                        c.id == currentInquiry.collectionId)
                      return true;
                    if (currentInquiry.collectionName != null &&
                        c.name == currentInquiry.collectionName)
                      return true;
                    return false;
                  }).firstOrNull;

                  final linkedProduct = catalog.allProducts.where((p) {
                    if (currentInquiry.productId != null &&
                        p.id == currentInquiry.productId)
                      return true;
                    if (currentInquiry.productCode != null &&
                        p.productCode == currentInquiry.productCode)
                      return true;
                    return false;
                  }).firstOrNull;

                  final hasExpiry =
                      linkedCollection?.expiresAt != null ||
                      linkedProduct?.expiresAt != null;
                  final isExpired =
                      linkedCollection?.isExpired ??
                      linkedProduct?.isExpired ??
                      false;
                  final remainingTime =
                      linkedCollection?.remainingTimeFormatted ??
                      linkedProduct?.remainingTimeFormatted ??
                      'No Expiry';

                  return Card(
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                      side: BorderSide(
                        color: hasExpiry
                            ? (isExpired
                                  ? Colors.red.shade300
                                  : Colors.amber.shade300)
                            : AppTheme.borderColor,
                      ),
                    ),
                    child: Padding(
                      padding: const EdgeInsets.all(20),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              Icon(
                                hasExpiry
                                    ? (isExpired
                                          ? Icons.history_toggle_off
                                          : Icons.timer_outlined)
                                    : Icons.link,
                                color: hasExpiry
                                    ? (isExpired
                                          ? Colors.red
                                          : Colors.amber.shade800)
                                    : AppTheme.primaryEmerald,
                                size: 22,
                              ),
                              const SizedBox(width: 10),
                              const Text(
                                'Time-Limited Catalog & Expiry Follow-Up',
                                style: TextStyle(
                                  fontSize: 16,
                                  fontWeight: FontWeight.w700,
                                ),
                              ),
                              const Spacer(),
                              Container(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 8,
                                  vertical: 4,
                                ),
                                decoration: BoxDecoration(
                                  color: hasExpiry
                                      ? (isExpired
                                            ? Colors.red.shade50
                                            : Colors.amber.shade50)
                                      : Colors.green.shade50,
                                  borderRadius: BorderRadius.circular(6),
                                  border: Border.all(
                                    color: hasExpiry
                                        ? (isExpired
                                              ? Colors.red
                                              : Colors.amber.shade700)
                                        : Colors.green,
                                  ),
                                ),
                                child: Text(
                                  hasExpiry
                                      ? (isExpired
                                            ? '⏰ Expired'
                                            : '⏳ $remainingTime')
                                      : '∞ Active Permanent Link',
                                  style: TextStyle(
                                    color: hasExpiry
                                        ? (isExpired
                                              ? Colors.red.shade700
                                              : Colors.amber.shade900)
                                        : Colors.green.shade700,
                                    fontWeight: FontWeight.w700,
                                    fontSize: 11,
                                  ),
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 8),
                          Text(
                            linkedCollection != null
                                ? 'Linked Collection: ${linkedCollection.name}'
                                : 'Linked Design: ${currentInquiry.productCode ?? "Custom Inquiry"}',
                            style: const TextStyle(
                              fontSize: 13,
                              color: AppTheme.textSecondary,
                            ),
                          ),
                          const SizedBox(height: 14),
                          Wrap(
                            spacing: 10,
                            runSpacing: 8,
                            children: [
                              // 1-Click WhatsApp Expiry Reminder
                              ElevatedButton.icon(
                                icon: const Icon(
                                  Icons.send_rounded,
                                  size: 16,
                                  color: Colors.white,
                                ),
                                label: const Text('WhatsApp Expiry Reminder'),
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: AppTheme.whatsappGreen,
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 14,
                                    vertical: 8,
                                  ),
                                  textStyle: const TextStyle(
                                    fontSize: 12,
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                                onPressed: () {
                                  final msg =
                                      'Hello ${currentInquiry.buyerDisplayName}, quick reminder from Surat Silk Mills! Your wholesale catalog selection for ${currentInquiry.productCode ?? currentInquiry.collectionName ?? "exclusive designs"} is time-limited (${hasExpiry ? remainingTime : "limited stock"}). Please let us know if you would like to book lots before rates close!';
                                  WhatsAppLinkService.openDirectChat(
                                    buyerPhone: currentInquiry.contactPhone,
                                    initialText: msg,
                                  );
                                  inqProvider.addActivity(
                                    inquiryId: currentInquiry.id,
                                    activityType: 'quote_sent',
                                    body:
                                        'Sent WhatsApp Expiry & Rate Reminder to buyer',
                                    userId: auth.currentUser?.id,
                                    userName: auth.currentUser?.name,
                                  );
                                },
                              ),
                              // 1-Click Extend Expiry (+24 Hours)
                              if (linkedCollection != null)
                                OutlinedButton.icon(
                                  icon: const Icon(
                                    Icons.update,
                                    size: 16,
                                    color: AppTheme.primaryEmerald,
                                  ),
                                  label: const Text(
                                    'Extend Expiry (+24h)',
                                    style: TextStyle(
                                      color: AppTheme.primaryEmerald,
                                    ),
                                  ),
                                  style: OutlinedButton.styleFrom(
                                    side: const BorderSide(
                                      color: AppTheme.primaryEmerald,
                                    ),
                                    padding: const EdgeInsets.symmetric(
                                      horizontal: 14,
                                      vertical: 8,
                                    ),
                                    textStyle: const TextStyle(
                                      fontSize: 12,
                                      fontWeight: FontWeight.w600,
                                    ),
                                  ),
                                  onPressed: () {
                                    final currentExp =
                                        linkedCollection.expiresAt ??
                                        DateTime.now();
                                    final newExp =
                                        (currentExp.isBefore(DateTime.now())
                                                ? DateTime.now()
                                                : currentExp)
                                            .add(const Duration(hours: 24));
                                    catalog.updateCollection(
                                      linkedCollection.copyWith(
                                        expiresAt: newExp,
                                      ),
                                    );
                                    inqProvider.addActivity(
                                      inquiryId: currentInquiry.id,
                                      activityType: 'follow_up_scheduled',
                                      body:
                                          'Extended catalog "${linkedCollection.name}" expiry by +24 hours (New expiry: ${DateFormat("dd MMM, hh:mm a").format(newExp)})',
                                      userId: auth.currentUser?.id,
                                      userName: auth.currentUser?.name,
                                    );
                                    ScaffoldMessenger.of(context).showSnackBar(
                                      SnackBar(
                                        content: Text(
                                          '✅ Expiry extended by +24 hours for ${linkedCollection.name}',
                                        ),
                                        backgroundColor: AppTheme.primaryDark,
                                      ),
                                    );
                                  },
                                ),
                            ],
                          ),
                        ],
                      ),
                    ),
                  );
                },
              ),
              const SizedBox(height: 16),

              // Status Pipeline Updater
              Card(
                child: Padding(
                  padding: const EdgeInsets.all(20),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'Update Inquiry Stage in Sales Pipeline',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                      const SizedBox(height: 12),
                      SingleChildScrollView(
                        scrollDirection: Axis.horizontal,
                        child: Row(
                          children: [
                            _StageChip(
                              label: 'New Inquiry',
                              status: 'new',
                              currentStatus: currentInquiry.status,
                              color: Colors.blue,
                              onTap: () => inqProvider.updateStatus(
                                inquiryId: currentInquiry.id,
                                newStatus: 'new',
                                userId: auth.currentUser?.id,
                                userName: auth.currentUser?.name,
                              ),
                            ),
                            const SizedBox(width: 8),
                            _StageChip(
                              label: 'Contacted',
                              status: 'contacted',
                              currentStatus: currentInquiry.status,
                              color: Colors.purple,
                              onTap: () => inqProvider.updateStatus(
                                inquiryId: currentInquiry.id,
                                newStatus: 'contacted',
                                userId: auth.currentUser?.id,
                                userName: auth.currentUser?.name,
                              ),
                            ),
                            const SizedBox(width: 8),
                            _StageChip(
                              label: 'Price Quoted',
                              status: 'quoted',
                              currentStatus: currentInquiry.status,
                              color: Colors.amber.shade800,
                              onTap: () => inqProvider.updateStatus(
                                inquiryId: currentInquiry.id,
                                newStatus: 'quoted',
                                userId: auth.currentUser?.id,
                                userName: auth.currentUser?.name,
                              ),
                            ),
                            const SizedBox(width: 8),
                            _StageChip(
                              label: 'Follow-Up',
                              status: 'follow_up',
                              currentStatus: currentInquiry.status,
                              color: Colors.orange,
                              onTap: () => inqProvider.updateStatus(
                                inquiryId: currentInquiry.id,
                                newStatus: 'follow_up',
                                userId: auth.currentUser?.id,
                                userName: auth.currentUser?.name,
                              ),
                            ),
                            const SizedBox(width: 8),
                            _StageChip(
                              label: 'Ordered / Closed',
                              status: 'ordered',
                              currentStatus: currentInquiry.status,
                              color: Colors.green,
                              onTap: () => inqProvider.updateStatus(
                                inquiryId: currentInquiry.id,
                                newStatus: 'ordered',
                                userId: auth.currentUser?.id,
                                userName: auth.currentUser?.name,
                              ),
                            ),
                            const SizedBox(width: 8),
                            _StageChip(
                              label: 'Lost',
                              status: 'lost',
                              currentStatus: currentInquiry.status,
                              color: Colors.red,
                              onTap: () => inqProvider.updateStatus(
                                inquiryId: currentInquiry.id,
                                newStatus: 'lost',
                                userId: auth.currentUser?.id,
                                userName: auth.currentUser?.name,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 16),

              // Activity Timeline Card
              Card(
                child: Padding(
                  padding: const EdgeInsets.all(20),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'Inquiry Activity & Notes Timeline',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                      const SizedBox(height: 14),

                      // Add Note Row
                      Row(
                        children: [
                          Expanded(
                            child: TextField(
                              controller: _activityNoteController,
                              decoration: const InputDecoration(
                                hintText:
                                    'Log customer call note or quotation details...',
                                contentPadding: EdgeInsets.symmetric(
                                  horizontal: 14,
                                  vertical: 12,
                                ),
                              ),
                            ),
                          ),
                          const SizedBox(width: 10),
                          ElevatedButton.icon(
                            icon: const Icon(Icons.add_comment, size: 16),
                            label: const Text('Add Note'),
                            onPressed: _addNote,
                          ),
                        ],
                      ),
                      const SizedBox(height: 20),

                      // Activities List
                      if (currentInquiry.activities.isEmpty)
                        const Padding(
                          padding: EdgeInsets.symmetric(vertical: 20),
                          child: Center(
                            child: Text(
                              'No activity logs yet.',
                              style: TextStyle(color: AppTheme.textSecondary),
                            ),
                          ),
                        )
                      else
                        ListView.separated(
                          shrinkWrap: true,
                          physics: const NeverScrollableScrollPhysics(),
                          itemCount: currentInquiry.activities.length,
                          separatorBuilder: (_, __) =>
                              const Divider(height: 24),
                          itemBuilder: (context, index) {
                            final act = currentInquiry.activities[index];
                            final timeStr = DateFormat(
                              'dd MMM, hh:mm a',
                            ).format(act.createdAt);

                            IconData iconData = Icons.notes_rounded;
                            Color iconColor = AppTheme.textSecondary;
                            if (act.activityType == 'created') {
                              iconData = Icons.fiber_new;
                              iconColor = Colors.blue;
                            } else if (act.activityType == 'status_changed') {
                              iconData = Icons.alt_route;
                              iconColor = Colors.purple;
                            } else if (act.activityType == 'quote_sent') {
                              iconData = Icons.request_quote;
                              iconColor = Colors.amber.shade800;
                            } else if (act.activityType ==
                                'follow_up_scheduled') {
                              iconData = Icons.alarm;
                              iconColor = Colors.orange;
                            }

                            return Row(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Container(
                                  padding: const EdgeInsets.all(6),
                                  decoration: BoxDecoration(
                                    color: iconColor.withOpacity(0.12),
                                    borderRadius: BorderRadius.circular(6),
                                  ),
                                  child: Icon(
                                    iconData,
                                    color: iconColor,
                                    size: 16,
                                  ),
                                ),
                                const SizedBox(width: 12),
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        act.body ?? '',
                                        style: const TextStyle(
                                          fontSize: 13,
                                          fontWeight: FontWeight.w600,
                                          color: AppTheme.textPrimary,
                                        ),
                                      ),
                                      const SizedBox(height: 2),
                                      Text(
                                        'By ${act.userName ?? "System"} • $timeStr',
                                        style: const TextStyle(
                                          fontSize: 11,
                                          color: AppTheme.textSecondary,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ],
                            );
                          },
                        ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _StageChip extends StatelessWidget {
  final String label;
  final String status;
  final String currentStatus;
  final Color color;
  final VoidCallback onTap;

  const _StageChip({
    required this.label,
    required this.status,
    required this.currentStatus,
    required this.color,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final isSelected = currentStatus == status;

    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(8),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
        decoration: BoxDecoration(
          color: isSelected ? color : color.withOpacity(0.08),
          borderRadius: BorderRadius.circular(8),
          border: Border.all(color: color.withOpacity(isSelected ? 1.0 : 0.3)),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            if (isSelected) ...[
              const Icon(Icons.check, size: 14, color: Colors.white),
              const SizedBox(width: 6),
            ],
            Text(
              label,
              style: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w700,
                color: isSelected ? Colors.white : color,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
