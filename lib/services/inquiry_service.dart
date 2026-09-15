import '../models/inquiry.dart';
import '../models/contact.dart';
import 'mock_data_service.dart';

class InquiryService {
  final List<Inquiry> _inquiries = List.from(MockDataService.demoInquiries);
  final List<Contact> _contacts = List.from(MockDataService.demoContacts);

  List<Inquiry> getInquiries() => List.unmodifiable(_inquiries);
  List<Contact> getContacts() => List.unmodifiable(_contacts);

  Inquiry createInquiry({
    required int businessId,
    required String contactPhone,
    String? contactName,
    String? contactCompany,
    int? productId,
    String? productCode,
    String? productTitle,
    String? productImage,
    double? productPrice,
    int? collectionId,
    String? collectionName,
    String source = 'catalog',
    String? message,
  }) {
    // Find or create Contact
    Contact? contact;
    final foundContacts = _contacts.where((c) => c.phoneE164 == contactPhone);
    if (foundContacts.isNotEmpty) {
      contact = foundContacts.first;
      final cIdx = _contacts.indexOf(contact);
      _contacts[cIdx] = contact.copyWith(
        name: contactName ?? contact.name,
        companyName: contactCompany ?? contact.companyName,
        totalInquiries: contact.totalInquiries + 1,
      );
    } else {
      final newContactId = _contacts.isEmpty ? 301 : _contacts.map((c) => c.id).reduce((a, b) => a > b ? a : b) + 1;
      contact = Contact(
        id: newContactId,
        businessId: businessId,
        name: contactName,
        phoneE164: contactPhone,
        companyName: contactCompany,
        totalInquiries: 1,
      );
      _contacts.insert(0, contact);
    }

    final newInqId = _inquiries.isEmpty ? 401 : _inquiries.map((i) => i.id).reduce((a, b) => a > b ? a : b) + 1;

    final inquiry = Inquiry(
      id: newInqId,
      businessId: businessId,
      contactId: contact.id,
      contactName: contact.name,
      contactPhone: contactPhone,
      contactCompany: contact.companyName,
      productId: productId,
      productCode: productCode,
      productTitle: productTitle,
      productImage: productImage,
      productPrice: productPrice,
      collectionId: collectionId,
      collectionName: collectionName,
      source: source,
      status: 'new',
      message: message,
      activities: [
        InquiryActivity(
          id: DateTime.now().millisecondsSinceEpoch,
          businessId: businessId,
          inquiryId: newInqId,
          activityType: 'created',
          body: 'Inquiry received for Design $productCode via $source.',
        ),
      ],
    );

    _inquiries.insert(0, inquiry);
    return inquiry;
  }

  void updateInquiryStatus({
    required int inquiryId,
    required String newStatus,
    String? note,
    int? currentUserId,
    String? currentUserName,
  }) {
    final idx = _inquiries.indexWhere((i) => i.id == inquiryId);
    if (idx != -1) {
      final current = _inquiries[idx];
      final newActivities = List<InquiryActivity>.from(current.activities);
      newActivities.insert(
        0,
        InquiryActivity(
          id: DateTime.now().millisecondsSinceEpoch,
          businessId: current.businessId,
          inquiryId: inquiryId,
          userId: currentUserId,
          userName: currentUserName,
          activityType: 'status_changed',
          body: 'Status updated to ${current.statusDisplay}.${note != null && note.isNotEmpty ? " Note: $note" : ""}',
        ),
      );

      _inquiries[idx] = current.copyWith(
        status: newStatus,
        activities: newActivities,
        updatedAt: DateTime.now(),
      );
    }
  }

  void addInquiryActivity({
    required int inquiryId,
    required String activityType,
    required String body,
    int? currentUserId,
    String? currentUserName,
  }) {
    final idx = _inquiries.indexWhere((i) => i.id == inquiryId);
    if (idx != -1) {
      final current = _inquiries[idx];
      final newActivities = List<InquiryActivity>.from(current.activities);
      newActivities.insert(
        0,
        InquiryActivity(
          id: DateTime.now().millisecondsSinceEpoch,
          businessId: current.businessId,
          inquiryId: inquiryId,
          userId: currentUserId,
          userName: currentUserName,
          activityType: activityType,
          body: body,
        ),
      );

      _inquiries[idx] = current.copyWith(
        activities: newActivities,
        updatedAt: DateTime.now(),
      );
    }
  }

  void scheduleFollowUp({
    required int inquiryId,
    required DateTime followUpDate,
    String? note,
    int? currentUserId,
    String? currentUserName,
  }) {
    final idx = _inquiries.indexWhere((i) => i.id == inquiryId);
    if (idx != -1) {
      final current = _inquiries[idx];
      final newActivities = List<InquiryActivity>.from(current.activities);
      newActivities.insert(
        0,
        InquiryActivity(
          id: DateTime.now().millisecondsSinceEpoch,
          businessId: current.businessId,
          inquiryId: inquiryId,
          userId: currentUserId,
          userName: currentUserName,
          activityType: 'follow_up_scheduled',
          body: 'Follow-up scheduled for ${followUpDate.toLocal().toString().split(".")[0]}.${note != null && note.isNotEmpty ? " Note: $note" : ""}',
        ),
      );

      _inquiries[idx] = current.copyWith(
        nextFollowUpAt: followUpDate,
        status: current.status == 'new' ? 'follow_up' : current.status,
        activities: newActivities,
        updatedAt: DateTime.now(),
      );
    }
  }

  void assignInquiry({
    required int inquiryId,
    required int staffUserId,
    required String staffName,
  }) {
    final idx = _inquiries.indexWhere((i) => i.id == inquiryId);
    if (idx != -1) {
      final current = _inquiries[idx];
      final newActivities = List<InquiryActivity>.from(current.activities);
      newActivities.insert(
        0,
        InquiryActivity(
          id: DateTime.now().millisecondsSinceEpoch,
          businessId: current.businessId,
          inquiryId: inquiryId,
          activityType: 'note',
          body: 'Assigned inquiry to $staffName.',
        ),
      );

      _inquiries[idx] = current.copyWith(
        assignedToUserId: staffUserId,
        assignedToUserName: staffName,
        activities: newActivities,
        updatedAt: DateTime.now(),
      );
    }
  }

  // Contacts
  Contact addContact({
    required int businessId,
    required String phoneE164,
    String? name,
    String? companyName,
    String? city,
    String? state,
    String contactType = 'buyer',
    String preferredLanguage = 'hi',
    List<String> tags = const [],
  }) {
    final newId = _contacts.isEmpty ? 301 : _contacts.map((c) => c.id).reduce((a, b) => a > b ? a : b) + 1;
    final contact = Contact(
      id: newId,
      businessId: businessId,
      name: name,
      phoneE164: phoneE164,
      companyName: companyName,
      city: city,
      state: state,
      contactType: contactType,
      preferredLanguage: preferredLanguage,
      tags: tags,
    );
    _contacts.insert(0, contact);
    return contact;
  }

  void updateContact(Contact updated) {
    final idx = _contacts.indexWhere((c) => c.id == updated.id);
    if (idx != -1) {
      _contacts[idx] = updated;
    }
  }

  void deleteContact(int id) {
    _contacts.removeWhere((c) => c.id == id);
  }
}

