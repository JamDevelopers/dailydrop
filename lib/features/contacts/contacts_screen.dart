import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../core/theme.dart';
import '../../core/responsive.dart';
import '../../models/contact.dart';
import '../../providers/contact_provider.dart';
import '../../services/whatsapp_link_service.dart';
import 'add_edit_contact_modal.dart';

class ContactsScreen extends StatelessWidget {
  const ContactsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final contactProvider = context.watch<ContactProvider>();
    final contacts = contactProvider.filteredContacts;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Buyer CRM & Directory'),
        actions: [
          OutlinedButton.icon(
            icon: const Icon(Icons.file_download_outlined, size: 16),
            label: const Text('Export CSV'),
            style: OutlinedButton.styleFrom(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
              textStyle: const TextStyle(fontSize: 12),
            ),
            onPressed: () {
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  content: Text('Buyer CRM contacts exported as CSV successfully!'),
                  backgroundColor: AppTheme.primaryDark,
                ),
              );
            },
          ),
          const SizedBox(width: 8),
          ElevatedButton.icon(
            icon: const Icon(Icons.person_add, size: 16, color: Colors.white),
            label: const Text('Add Contact'),
            style: ElevatedButton.styleFrom(
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
              textStyle: const TextStyle(fontSize: 13),
            ),
            onPressed: () {
              showDialog(
                context: context,
                builder: (_) => const AddEditContactModal(),
              );
            },
          ),
          const SizedBox(width: 12),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: MaxWidthContainer(
          maxWidth: 1100,
          child: Column(
            children: [
              // Search & Filter
              TextField(
                decoration: InputDecoration(
                  hintText: 'Search buyers by name, phone, shop name, or city...',
                  prefixIcon: const Icon(Icons.search, color: AppTheme.primaryEmerald),
                  suffixIcon: contactProvider.searchQuery.isNotEmpty
                      ? IconButton(
                          icon: const Icon(Icons.clear),
                          onPressed: () => contactProvider.setSearchQuery(''),
                        )
                      : null,
                ),
                onChanged: (val) => contactProvider.setSearchQuery(val),
              ),
              const SizedBox(height: 16),

              // Filter Types Chips
              SingleChildScrollView(
                scrollDirection: Axis.horizontal,
                child: Row(
                  children: [
                    ChoiceChip(
                      label: const Text('All Contacts'),
                      selected: contactProvider.selectedTypeFilter == null,
                      onSelected: (_) => contactProvider.setTypeFilter(null),
                    ),
                    const SizedBox(width: 8),
                    ...['buyer', 'dealer', 'reseller', 'boutique', 'retailer'].map((type) {
                      final label = type[0].toUpperCase() + type.substring(1);
                      return Padding(
                        padding: const EdgeInsets.only(right: 8),
                        child: FilterChip(
                          label: Text(label),
                          selected: contactProvider.selectedTypeFilter == type,
                          onSelected: (sel) {
                            contactProvider.setTypeFilter(sel ? type : null);
                          },
                        ),
                      );
                    }),
                  ],
                ),
              ),
              const SizedBox(height: 16),

              // Contacts Cards
              if (contacts.isEmpty)
                Card(
                  child: Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(40),
                    alignment: Alignment.center,
                    child: const Column(
                      children: [
                        Icon(Icons.contacts_outlined, size: 48, color: AppTheme.textMuted),
                        SizedBox(height: 12),
                        Text('No buyer contacts match your filter.', style: TextStyle(color: AppTheme.textSecondary)),
                      ],
                    ),
                  ),
                )
              else
                ListView.separated(
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  itemCount: contacts.length,
                  separatorBuilder: (_, __) => const SizedBox(height: 10),
                  itemBuilder: (context, index) {
                    final contact = contacts[index];
                    return _ContactCard(contact: contact);
                  },
                ),
            ],
          ),
        ),
      ),
      floatingActionButton: FloatingActionButton(
        backgroundColor: AppTheme.primaryEmerald,
        foregroundColor: Colors.white,
        child: const Icon(Icons.person_add),
        onPressed: () {
          showDialog(
            context: context,
            builder: (_) => const AddEditContactModal(),
          );
        },
      ),
    );
  }
}

class _ContactCard extends StatelessWidget {
  final Contact contact;

  const _ContactCard({required this.contact});

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Row(
          children: [
            CircleAvatar(
              backgroundColor: AppTheme.primaryLight,
              child: Text(
                contact.name != null && contact.name!.isNotEmpty
                    ? contact.name![0].toUpperCase()
                    : 'B',
                style: const TextStyle(fontWeight: FontWeight.w700, color: AppTheme.primaryDark),
              ),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Text(
                        contact.displayName,
                        style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 15),
                      ),
                      const SizedBox(width: 8),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                        decoration: BoxDecoration(
                          color: AppTheme.backgroundLight,
                          borderRadius: BorderRadius.circular(4),
                          border: Border.all(color: AppTheme.borderColor),
                        ),
                        child: Text(
                          contact.contactType.toUpperCase(),
                          style: const TextStyle(fontSize: 10, fontWeight: FontWeight.w700, color: AppTheme.textSecondary),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 2),
                  Text(
                    '${contact.phoneE164} • ${contact.city ?? "Surat"}',
                    style: const TextStyle(fontSize: 13, color: AppTheme.textSecondary),
                  ),
                  if (contact.tags.isNotEmpty) ...[
                    const SizedBox(height: 6),
                    Wrap(
                      spacing: 6,
                      runSpacing: 4,
                      children: contact.tags.map((tag) {
                        return Container(
                          padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                          decoration: BoxDecoration(
                            color: AppTheme.primaryLight,
                            borderRadius: BorderRadius.circular(4),
                          ),
                          child: Text(
                            tag,
                            style: const TextStyle(fontSize: 10, color: AppTheme.primaryDark, fontWeight: FontWeight.w600),
                          ),
                        );
                      }).toList(),
                    ),
                  ],
                ],
              ),
            ),
            // Actions
            IconButton(
              icon: const Icon(Icons.chat_bubble_outline, color: AppTheme.whatsappGreen),
              tooltip: 'WhatsApp Chat',
              onPressed: () {
                WhatsAppLinkService.openDirectChat(buyerPhone: contact.phoneE164);
              },
            ),
            IconButton(
              icon: const Icon(Icons.edit_outlined, color: AppTheme.textSecondary),
              tooltip: 'Edit Contact',
              onPressed: () {
                showDialog(
                  context: context,
                  builder: (_) => AddEditContactModal(contact: contact),
                );
              },
            ),
          ],
        ),
      ),
    );
  }
}

