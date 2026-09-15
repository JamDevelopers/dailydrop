import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import '../../core/theme.dart';
import '../../core/responsive.dart';
import '../../models/inquiry.dart';
import '../../providers/inquiry_provider.dart';
import '../../services/whatsapp_link_service.dart';
import 'inquiry_detail_screen.dart';
import 'follow_up_modal.dart';

class InquiriesScreen extends StatefulWidget {
  const InquiriesScreen({super.key});

  @override
  State<InquiriesScreen> createState() => _InquiriesScreenState();
}

class _InquiriesScreenState extends State<InquiriesScreen> with SingleTickerProviderStateMixin {
  late final TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final inqProvider = context.watch<InquiryProvider>();
    final inquiries = inqProvider.filteredInquiries;
    final pendingToday = inqProvider.pendingFollowUpsToday;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Buyer Inquiries & CRM Pipeline'),
        bottom: TabBar(
          controller: _tabController,
          indicatorColor: AppTheme.primaryEmerald,
          labelColor: AppTheme.primaryEmerald,
          unselectedLabelColor: AppTheme.textSecondary,
          tabs: const [
            Tab(icon: Icon(Icons.view_kanban_outlined), text: 'Kanban Pipeline'),
            Tab(icon: Icon(Icons.list_alt_rounded), text: 'All Inquiries List'),
          ],
        ),
      ),
      body: TabBarView(
        controller: _tabController,
        children: [
          // Tab 1: Kanban Board View
          _KanbanBoardView(inqProvider: inqProvider, pendingToday: pendingToday),

          // Tab 2: Table/List View
          _InquiryListView(inquiries: inquiries, inqProvider: inqProvider),
        ],
      ),
    );
  }
}

class _KanbanBoardView extends StatelessWidget {
  final InquiryProvider inqProvider;
  final List<Inquiry> pendingToday;

  const _KanbanBoardView({
    required this.inqProvider,
    required this.pendingToday,
  });

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Pending Follow-Ups Today Alert
          if (pendingToday.isNotEmpty)
            Container(
              margin: const EdgeInsets.only(bottom: 16),
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                color: AppTheme.accentGoldLight,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: AppTheme.accentGold.withOpacity(0.4)),
              ),
              child: Row(
                children: [
                  const Icon(Icons.alarm_on, color: AppTheme.accentGold, size: 24),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      '🔔 ${pendingToday.length} follow-up reminder(s) scheduled for today!',
                      style: const TextStyle(
                        fontWeight: FontWeight.w700,
                        color: Colors.brown,
                        fontSize: 14,
                      ),
                    ),
                  ),
                ],
              ),
            ),

          // Horizontal Kanban Stages
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _KanbanColumn(
                  title: 'New Inquiries',
                  color: Colors.blue,
                  inquiries: inqProvider.newInquiries,
                ),
                const SizedBox(width: 16),
                _KanbanColumn(
                  title: 'Contacted / Catalog Sent',
                  color: Colors.purple,
                  inquiries: inqProvider.contactedInquiries,
                ),
                const SizedBox(width: 16),
                _KanbanColumn(
                  title: 'Price Quoted',
                  color: Colors.amber.shade800,
                  inquiries: inqProvider.quotedInquiries,
                ),
                const SizedBox(width: 16),
                _KanbanColumn(
                  title: 'Follow-Up Scheduled',
                  color: Colors.orange,
                  inquiries: inqProvider.followUpInquiries,
                ),
                const SizedBox(width: 16),
                _KanbanColumn(
                  title: 'Ordered / Closed Deals',
                  color: Colors.green,
                  inquiries: inqProvider.orderedInquiries,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _KanbanColumn extends StatelessWidget {
  final String title;
  final Color color;
  final List<Inquiry> inquiries;

  const _KanbanColumn({
    required this.title,
    required this.color,
    required this.inquiries,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 290,
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppTheme.borderColor),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // Column Header
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
            decoration: BoxDecoration(
              color: color.withOpacity(0.08),
              borderRadius: const BorderRadius.vertical(top: Radius.circular(12)),
              border: Border(bottom: BorderSide(color: color.withOpacity(0.2))),
            ),
            child: Row(
              children: [
                Container(
                  width: 8,
                  height: 8,
                  decoration: BoxDecoration(color: color, shape: BoxShape.circle),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    title,
                    style: TextStyle(fontSize: 13, fontWeight: FontWeight.w700, color: color),
                  ),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                  decoration: BoxDecoration(
                    color: color,
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Text(
                    '${inquiries.length}',
                    style: const TextStyle(color: Colors.white, fontSize: 11, fontWeight: FontWeight.w700),
                  ),
                ),
              ],
            ),
          ),

          // Cards List
          Padding(
            padding: const EdgeInsets.all(10),
            child: inquiries.isEmpty
                ? Container(
                    padding: const EdgeInsets.symmetric(vertical: 30),
                    alignment: Alignment.center,
                    child: Text(
                      'No inquiries in this stage',
                      style: TextStyle(fontSize: 12, color: AppTheme.textMuted),
                    ),
                  )
                : ListView.separated(
                    shrinkWrap: true,
                    physics: const NeverScrollableScrollPhysics(),
                    itemCount: inquiries.length,
                    separatorBuilder: (_, __) => const SizedBox(height: 10),
                    itemBuilder: (context, index) {
                      final inquiry = inquiries[index];
                      return _InquiryCard(inquiry: inquiry);
                    },
                  ),
          ),
        ],
      ),
    );
  }
}

class _InquiryCard extends StatelessWidget {
  final Inquiry inquiry;

  const _InquiryCard({required this.inquiry});

  @override
  Widget build(BuildContext context) {
    return Card(
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(10),
        side: const BorderSide(color: AppTheme.borderColor),
      ),
      child: InkWell(
        borderRadius: BorderRadius.circular(10),
        onTap: () {
          Navigator.of(context).push(
            MaterialPageRoute(
              builder: (_) => InquiryDetailScreen(inquiry: inquiry),
            ),
          );
        },
        child: Padding(
          padding: const EdgeInsets.all(12),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Buyer & Time
              Row(
                children: [
                  Expanded(
                    child: Text(
                      inquiry.buyerDisplayName,
                      style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 13),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                  Text(
                    DateFormat('dd MMM').format(inquiry.createdAt),
                    style: const TextStyle(fontSize: 11, color: AppTheme.textSecondary),
                  ),
                ],
              ),
              const SizedBox(height: 6),

              // Product Pill
              if (inquiry.productCode != null)
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 3),
                  decoration: BoxDecoration(
                    color: AppTheme.primaryLight,
                    borderRadius: BorderRadius.circular(4),
                  ),
                  child: Text(
                    'DESIGN ${inquiry.productCode}',
                    style: const TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.w700,
                      color: AppTheme.primaryDark,
                    ),
                  ),
                ),
              if (inquiry.message != null && inquiry.message!.isNotEmpty) ...[
                const SizedBox(height: 6),
                Text(
                  inquiry.message!,
                  style: const TextStyle(fontSize: 12, color: AppTheme.textSecondary),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
              ],
              const SizedBox(height: 8),

              // Actions Row
              Row(
                children: [
                  IconButton(
                    icon: const Icon(Icons.chat, color: AppTheme.whatsappGreen, size: 18),
                    tooltip: 'WhatsApp Chat',
                    padding: EdgeInsets.zero,
                    constraints: const BoxConstraints(),
                    onPressed: () {
                      WhatsAppLinkService.openDirectChat(
                        buyerPhone: inquiry.contactPhone,
                        initialText: 'Hello ${inquiry.contactName ?? ""}, regarding Design ${inquiry.productCode ?? ""}',
                      );
                    },
                  ),
                  const SizedBox(width: 12),
                  IconButton(
                    icon: const Icon(Icons.alarm_add, color: AppTheme.accentGold, size: 18),
                    tooltip: 'Schedule Follow-Up',
                    padding: EdgeInsets.zero,
                    constraints: const BoxConstraints(),
                    onPressed: () {
                      showDialog(
                        context: context,
                        builder: (_) => FollowUpModal(inquiry: inquiry),
                      );
                    },
                  ),
                  const Spacer(),
                  if (inquiry.quotedAmount != null)
                    Text(
                      '₹${inquiry.quotedAmount!.toStringAsFixed(0)}',
                      style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 12, color: AppTheme.primaryEmerald),
                    ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _InquiryListView extends StatelessWidget {
  final List<Inquiry> inquiries;
  final InquiryProvider inqProvider;

  const _InquiryListView({
    required this.inquiries,
    required this.inqProvider,
  });

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: MaxWidthContainer(
        maxWidth: 1100,
        child: Column(
          children: [
            // Search & Filter
            TextField(
              decoration: InputDecoration(
                hintText: 'Search inquiries by buyer name, phone, or design code...',
                prefixIcon: const Icon(Icons.search, color: AppTheme.primaryEmerald),
                suffixIcon: inqProvider.searchQuery.isNotEmpty
                    ? IconButton(
                        icon: const Icon(Icons.clear),
                        onPressed: () => inqProvider.setSearchQuery(''),
                      )
                    : null,
              ),
              onChanged: (val) => inqProvider.setSearchQuery(val),
            ),
            const SizedBox(height: 16),

            // Inquiries List
            Card(
              child: inquiries.isEmpty
                  ? const Padding(
                      padding: EdgeInsets.all(40),
                      child: Center(child: Text('No inquiries match your query.')),
                    )
                  : ListView.separated(
                      shrinkWrap: true,
                      physics: const NeverScrollableScrollPhysics(),
                      itemCount: inquiries.length,
                      separatorBuilder: (_, __) => const Divider(height: 1),
                      itemBuilder: (context, index) {
                        final inq = inquiries[index];
                        return ListTile(
                          onTap: () {
                            Navigator.of(context).push(
                              MaterialPageRoute(
                                builder: (_) => InquiryDetailScreen(inquiry: inq),
                              ),
                            );
                          },
                          leading: CircleAvatar(
                            backgroundColor: AppTheme.primaryLight,
                            child: const Icon(Icons.person, color: AppTheme.primaryEmerald),
                          ),
                          title: Text(
                            '${inq.buyerDisplayName} • ${inq.productCode ?? "General Inquiry"}',
                            style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 14),
                          ),
                          subtitle: Text(
                            'Status: ${inq.statusDisplay} • ${DateFormat('dd MMM, hh:mm a').format(inq.createdAt)}',
                            style: const TextStyle(fontSize: 12),
                          ),
                          trailing: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              IconButton(
                                icon: const Icon(Icons.chat_bubble, color: AppTheme.whatsappGreen),
                                onPressed: () {
                                  WhatsAppLinkService.openDirectChat(buyerPhone: inq.contactPhone);
                                },
                              ),
                              const Icon(Icons.chevron_right),
                            ],
                          ),
                        );
                      },
                    ),
            ),
          ],
        ),
      ),
    );
  }
}

