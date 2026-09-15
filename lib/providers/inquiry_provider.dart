import 'package:flutter/material.dart';
import '../models/inquiry.dart';
import '../services/inquiry_service.dart';

class InquiryProvider extends ChangeNotifier {
  final InquiryService _service = InquiryService();

  List<Inquiry> _inquiries = [];
  String? _selectedStatusFilter;
  String _searchQuery = '';

  InquiryProvider() {
    _loadInitialData();
  }

  void _loadInitialData() {
    _inquiries = _service.getInquiries();
    notifyListeners();
  }

  List<Inquiry> get allInquiries => _inquiries;

  List<Inquiry> get filteredInquiries {
    return _inquiries.where((i) {
      if (_selectedStatusFilter != null && _selectedStatusFilter!.isNotEmpty) {
        if (i.status != _selectedStatusFilter) return false;
      }
      if (_searchQuery.isNotEmpty) {
        final q = _searchQuery.toLowerCase();
        final matchCode = (i.productCode ?? '').toLowerCase().contains(q);
        final matchPhone = i.contactPhone.toLowerCase().contains(q);
        final matchName = (i.contactName ?? '').toLowerCase().contains(q);
        final matchCompany = (i.contactCompany ?? '').toLowerCase().contains(q);
        if (!matchCode && !matchPhone && !matchName && !matchCompany) {
          return false;
        }
      }
      return true;
    }).toList();
  }

  // Kanban Stage Getters
  List<Inquiry> get newInquiries =>
      _inquiries.where((i) => i.status == 'new').toList();

  List<Inquiry> get contactedInquiries =>
      _inquiries.where((i) => i.status == 'contacted' || i.status == 'catalog_sent').toList();

  List<Inquiry> get quotedInquiries =>
      _inquiries.where((i) => i.status == 'quoted').toList();

  List<Inquiry> get followUpInquiries =>
      _inquiries.where((i) => i.status == 'follow_up').toList();

  List<Inquiry> get orderedInquiries =>
      _inquiries.where((i) => i.status == 'ordered').toList();

  List<Inquiry> get pendingFollowUpsToday {
    final now = DateTime.now();
    return _inquiries.where((i) {
      if (i.nextFollowUpAt == null) return false;
      return i.nextFollowUpAt!.year == now.year &&
          i.nextFollowUpAt!.month == now.month &&
          i.nextFollowUpAt!.day == now.day;
    }).toList();
  }

  String? get selectedStatusFilter => _selectedStatusFilter;
  String get searchQuery => _searchQuery;

  void setStatusFilter(String? status) {
    _selectedStatusFilter = status;
    notifyListeners();
  }

  void setSearchQuery(String q) {
    _searchQuery = q;
    notifyListeners();
  }

  // Public Catalog Buyer Inquiry Submission
  Inquiry submitPublicInquiry({
    required int businessId,
    required String buyerPhone,
    String? buyerName,
    String? buyerCompany,
    int? productId,
    String? productCode,
    String? productTitle,
    String? productImage,
    double? productPrice,
    int? collectionId,
    String? collectionName,
    String? message,
  }) {
    final inq = _service.createInquiry(
      businessId: businessId,
      contactPhone: buyerPhone,
      contactName: buyerName,
      contactCompany: buyerCompany,
      productId: productId,
      productCode: productCode,
      productTitle: productTitle,
      productImage: productImage,
      productPrice: productPrice,
      collectionId: collectionId,
      collectionName: collectionName,
      source: 'catalog',
      message: message,
    );
    _inquiries = _service.getInquiries();
    notifyListeners();
    return inq;
  }

  void updateStatus({
    required int inquiryId,
    required String newStatus,
    String? note,
    int? userId,
    String? userName,
  }) {
    _service.updateInquiryStatus(
      inquiryId: inquiryId,
      newStatus: newStatus,
      note: note,
      currentUserId: userId,
      currentUserName: userName,
    );
    _inquiries = _service.getInquiries();
    notifyListeners();
  }

  void addActivity({
    required int inquiryId,
    required String activityType,
    required String body,
    int? userId,
    String? userName,
  }) {
    _service.addInquiryActivity(
      inquiryId: inquiryId,
      activityType: activityType,
      body: body,
      currentUserId: userId,
      currentUserName: userName,
    );
    _inquiries = _service.getInquiries();
    notifyListeners();
  }

  void scheduleFollowUp({
    required int inquiryId,
    required DateTime followUpDate,
    String? note,
    int? userId,
    String? userName,
  }) {
    _service.scheduleFollowUp(
      inquiryId: inquiryId,
      followUpDate: followUpDate,
      note: note,
      currentUserId: userId,
      currentUserName: userName,
    );
    _inquiries = _service.getInquiries();
    notifyListeners();
  }

  void assignInquiry({
    required int inquiryId,
    required int staffUserId,
    required String staffName,
  }) {
    _service.assignInquiry(
      inquiryId: inquiryId,
      staffUserId: staffUserId,
      staffName: staffName,
    );
    _inquiries = _service.getInquiries();
    notifyListeners();
  }
}

