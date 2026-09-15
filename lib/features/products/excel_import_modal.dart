import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import '../../core/theme.dart';
import '../../core/constants.dart';
import '../../providers/auth_provider.dart';
import '../../providers/catalog_provider.dart';

class ExcelImportModal extends StatefulWidget {
  const ExcelImportModal({super.key});

  static const String sampleCsvTemplate =
      '''design_code,title,fabric,color,size,occasion,festival,set_count,price,cost_price,stock_quantity,stock_status,short_description,image_urls
SR-260915-021,Dola Silk Zari Border Saree,Dola Silk,Emerald Green,Free Size,Festive,Diwali Special,4,950,650,150,available,Heavy weaving work on Dola silk with 4 matching colors.,https://images.unsplash.com/photo-1610030469983-98e550d6193c?w=800|https://images.unsplash.com/photo-1583391733956-3750e0ff4e8b?w=800
SR-260915-022,Pure Georgette Scallop Saree,Georgette,Wine / Purple,Free Size,Party Wear,Navratri & Garba,4,890,580,200,available,60g pure georgette with cutwork scallop border.,https://images.unsplash.com/photo-1583391733956-3750e0ff4e8b?w=800
SR-260915-023,Rayon 14kg Mirror Work Kurti,Rayon 14kg,Pink / Rani,Set of All Sizes (S to XXL),Party Wear,Diwali Special,4,650,420,80,limited,Heavy thread and mirror neckline work.,https://images.unsplash.com/photo-1617627143750-d86bc21e42bb?w=800
SR-260915-024,Jam Cotton Unstitched Suit,Cotton,Mustard Yellow,Unstitched,Daily Wear,Regular / All Season,6,520,340,300,available,Pure Jam cotton top with Nazneen dupatta.,https://images.unsplash.com/photo-1609357605129-26f69add5d6e?w=800
SR-260915-025,Velvet Sequence Bridal Lehenga,Velvet,Royal Blue,Semi-Stitched,Wedding / Bridal,Wedding Season,1,3850,2400,25,available,9000 Micro velvet with 5mm tone-to-tone sequence work.,https://images.unsplash.com/photo-1594633312681-425c7b97ccd1?w=800''';

  @override
  State<ExcelImportModal> createState() => _ExcelImportModalState();
}

class _ExcelImportModalState extends State<ExcelImportModal> {
  final _csvTextController = TextEditingController();
  final _collectionTitleController = TextEditingController(
    text: "Excel Import Drop • ${DateTime.now().day} Sep 2026",
  );

  bool _createDailyDrop = true;
  bool _isProcessing = false;
  List<Map<String, dynamic>> _parsedRows = [];

  @override
  void dispose() {
    _csvTextController.dispose();
    _collectionTitleController.dispose();
    super.dispose();
  }

  void _loadDemoData() {
    setState(() {
      _csvTextController.text = ExcelImportModal.sampleCsvTemplate;
      _parseCsv();
    });
  }

  void _copyTemplateToClipboard() {
    Clipboard.setData(
      const ClipboardData(text: ExcelImportModal.sampleCsvTemplate),
    );
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text(
          '✅ Sample Excel/CSV template copied to clipboard! Paste into Excel, Google Sheets, or here.',
        ),
        backgroundColor: AppTheme.primaryDark,
      ),
    );
  }

  void _parseCsv() {
    final text = _csvTextController.text.trim();
    if (text.isEmpty) {
      setState(() => _parsedRows = []);
      return;
    }

    final lines = text.split(RegExp(r'\r?\n'));
    if (lines.length < 2) {
      setState(() => _parsedRows = []);
      return;
    }

    final headerLine = lines.first;
    final headers = headerLine
        .split(',')
        .map((h) => h.trim().toLowerCase())
        .toList();

    final rows = <Map<String, dynamic>>[];

    for (int i = 1; i < lines.length; i++) {
      final line = lines[i].trim();
      if (line.isEmpty) continue;

      // Handle simple CSV splitting
      final cols = line.split(',');
      final rowMap = <String, dynamic>{};

      for (int h = 0; h < headers.length; h++) {
        final key = headers[h];
        final val = h < cols.length ? cols[h].trim() : '';
        rowMap[key] = val;
      }

      // Validate row
      final code =
          rowMap['design_code'] ??
          rowMap['product_code'] ??
          'SR-${DateTime.now().millisecondsSinceEpoch % 1000}';
      final title = rowMap['title'] ?? 'Design $code';
      final fabric = rowMap['fabric'] ?? 'Dola Silk';
      final color = rowMap['color'] ?? 'Multi Color';
      final size = rowMap['size'] ?? 'Free Size';
      final occasion = rowMap['occasion'] ?? 'Festive';
      final festival = rowMap['festival'] ?? 'Diwali Special';
      final setCount =
          int.tryParse(rowMap['set_count']?.toString() ?? '4') ?? 4;
      final price =
          double.tryParse(rowMap['price']?.toString() ?? '950') ?? 950.0;
      final costPrice =
          double.tryParse(rowMap['cost_price']?.toString() ?? '650') ?? 650.0;
      final stockQty =
          int.tryParse(rowMap['stock_quantity']?.toString() ?? '100') ?? 100;
      final stockStatus = rowMap['stock_status'] ?? 'available';
      final desc =
          rowMap['short_description'] ?? 'Wholesale textile collection.';

      final rawImages = rowMap['image_urls']?.toString() ?? '';
      final images = rawImages
          .split(RegExp(r'[|;]'))
          .map((s) => s.trim())
          .where((s) => s.isNotEmpty)
          .toList();
      if (images.isEmpty) {
        images.add(
          'https://images.unsplash.com/photo-1610030469983-98e550d6193c?w=800&auto=format&fit=crop&q=80',
        );
      }

      rows.add({
        'product_code': code,
        'title': title,
        'fabric': fabric,
        'color': color,
        'size': size,
        'occasion': occasion,
        'festival': festival,
        'set_count': setCount,
        'price': price,
        'cost_price': costPrice,
        'stock_quantity': stockQty,
        'stock_status': stockStatus,
        'short_description': desc,
        'image_urls': images,
        'is_valid': code.isNotEmpty && title.isNotEmpty,
      });
    }

    setState(() => _parsedRows = rows);
  }

  void _executeImport() async {
    if (_parsedRows.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text(
            'Please paste or load valid CSV data before importing.',
          ),
        ),
      );
      return;
    }

    setState(() => _isProcessing = true);

    final auth = context.read<AuthProvider>();
    final catalog = context.read<CatalogProvider>();

    final createdProducts = <int>[];

    for (final row in _parsedRows) {
      final p = catalog.addProduct(
        businessId: auth.business.id,
        productCode: row['product_code'],
        title: row['title'],
        fabric: row['fabric'],
        color: row['color'],
        size: row['size'],
        occasion: row['occasion'],
        festival: row['festival'],
        setCount: row['set_count'],
        setLabel: 'Set of ${row['set_count']}',
        price: row['price'],
        priceLabel:
            '₹${(row['price'] as double).toStringAsFixed(0)} / Pc (Set of ${row['set_count']})',
        costPrice: row['cost_price'],
        stockQuantity: row['stock_quantity'],
        stockStatus: row['stock_status'],
        shortDescription: row['short_description'],
        imageUrls: List<String>.from(row['image_urls']),
      );
      createdProducts.add(p.id);
    }

    // Optionally create Daily Drop collection
    if (_createDailyDrop && createdProducts.isNotEmpty) {
      catalog.createCollection(
        businessId: auth.business.id,
        name: _collectionTitleController.text.trim(),
        description:
            'Imported collection of ${_parsedRows.length} designs via Excel / CSV.',
        visibility: 'public',
        priceVisibility: 'show',
        expiresAt: DateTime.now().add(const Duration(hours: 24)),
        productIds: createdProducts,
      );
    }

    setState(() => _isProcessing = false);

    if (!mounted) return;

    Navigator.of(context).pop();

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          '🎉 Successfully imported ${_parsedRows.length} designs into your catalog!',
        ),
        backgroundColor: AppTheme.primaryDark,
        duration: const Duration(seconds: 3),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 820),
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // Header
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: AppTheme.primaryLight,
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: const Icon(
                      Icons.table_view_rounded,
                      color: AppTheme.primaryEmerald,
                    ),
                  ),
                  const SizedBox(width: 12),
                  const Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Excel & CSV Product Data Import',
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.w700,
                            color: AppTheme.textPrimary,
                          ),
                        ),
                        Text(
                          'Easily insert 10 to 500 textile products in 1 click from spreadsheet or CSV',
                          style: TextStyle(
                            fontSize: 12,
                            color: AppTheme.textSecondary,
                          ),
                        ),
                      ],
                    ),
                  ),
                  IconButton(
                    icon: const Icon(Icons.close),
                    onPressed: () => Navigator.of(context).pop(),
                  ),
                ],
              ),
              const SizedBox(height: 16),

              // Action Bar (Download Demo Template & Load Demo Data)
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: AppTheme.backgroundLight,
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(color: AppTheme.borderColor),
                ),
                child: Row(
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text(
                            'Standard Surat Textile Format',
                            style: TextStyle(
                              fontWeight: FontWeight.w700,
                              fontSize: 13,
                            ),
                          ),
                          Text(
                            'Columns: design_code, title, fabric, color, size, occasion, festival, set_count, price, image_urls',
                            style: TextStyle(
                              fontSize: 11,
                              color: Colors.grey.shade600,
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(width: 8),
                    OutlinedButton.icon(
                      icon: const Icon(
                        Icons.download_for_offline_outlined,
                        size: 16,
                      ),
                      label: const Text('Download / Copy Template'),
                      style: OutlinedButton.styleFrom(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 10,
                          vertical: 8,
                        ),
                        textStyle: const TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      onPressed: _copyTemplateToClipboard,
                    ),
                    const SizedBox(width: 8),
                    ElevatedButton.icon(
                      icon: const Icon(
                        Icons.auto_fix_high,
                        size: 16,
                        color: Colors.white,
                      ),
                      label: const Text('Load Demo Data'),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppTheme.primaryEmerald,
                        padding: const EdgeInsets.symmetric(
                          horizontal: 12,
                          vertical: 8,
                        ),
                        textStyle: const TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      onPressed: _loadDemoData,
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 16),

              // CSV Text Field
              TextFormField(
                controller: _csvTextController,
                maxLines: 7,
                style: const TextStyle(fontFamily: 'monospace', fontSize: 12),
                decoration: InputDecoration(
                  labelText: 'Paste CSV / Excel Data Here *',
                  hintText:
                      'Paste comma-separated rows or click "Load Demo Data" above...',
                  alignLabelWithHint: true,
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(10),
                  ),
                  filled: true,
                  fillColor: Colors.white,
                ),
                onChanged: (_) => _parseCsv(),
              ),
              const SizedBox(height: 16),

              // Parsed Preview Table
              if (_parsedRows.isNotEmpty) ...[
                Row(
                  children: [
                    Text(
                      'Preview Parsed Designs (${_parsedRows.length} Ready)',
                      style: const TextStyle(
                        fontWeight: FontWeight.w700,
                        fontSize: 14,
                      ),
                    ),
                    const Spacer(),
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 8,
                        vertical: 3,
                      ),
                      decoration: BoxDecoration(
                        color: Colors.green.shade50,
                        borderRadius: BorderRadius.circular(6),
                        border: Border.all(color: Colors.green.shade200),
                      ),
                      child: Text(
                        '✓ ${_parsedRows.length} Valid Rows',
                        style: TextStyle(
                          color: Colors.green.shade800,
                          fontSize: 11,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                Container(
                  height: 160,
                  decoration: BoxDecoration(
                    border: Border.all(color: AppTheme.borderColor),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: ListView.separated(
                    itemCount: _parsedRows.length,
                    separatorBuilder: (_, __) => const Divider(height: 1),
                    itemBuilder: (context, idx) {
                      final r = _parsedRows[idx];
                      return ListTile(
                        dense: true,
                        leading: ClipRRect(
                          borderRadius: BorderRadius.circular(4),
                          child: Image.network(
                            (r['image_urls'] as List).first,
                            width: 36,
                            height: 36,
                            fit: BoxFit.cover,
                          ),
                        ),
                        title: Text(
                          '${r['product_code']} • ${r['title']}',
                          style: const TextStyle(
                            fontWeight: FontWeight.w600,
                            fontSize: 13,
                          ),
                        ),
                        subtitle: Text(
                          '${r['fabric']} • ${r['color']} • ${r['festival']} • ₹${r['price']} (Set of ${r['set_count']})',
                          style: const TextStyle(
                            fontSize: 11,
                            color: AppTheme.textSecondary,
                          ),
                        ),
                        trailing: const Icon(
                          Icons.check_circle,
                          color: AppTheme.primaryEmerald,
                          size: 18,
                        ),
                      );
                    },
                  ),
                ),
                const SizedBox(height: 16),

                // Bundle into Daily Drop option
                Card(
                  child: Padding(
                    padding: const EdgeInsets.all(16),
                    child: Column(
                      children: [
                        SwitchListTile(
                          contentPadding: EdgeInsets.zero,
                          title: const Text(
                            'Bundle into a New Daily Drop Collection',
                            style: TextStyle(
                              fontWeight: FontWeight.w600,
                              fontSize: 14,
                            ),
                          ),
                          subtitle: const Text(
                            'Immediately creates a live WhatsApp shareable drop link with 24h countdown for these imported products',
                          ),
                          value: _createDailyDrop,
                          activeColor: AppTheme.primaryEmerald,
                          onChanged: (val) =>
                              setState(() => _createDailyDrop = val),
                        ),
                        if (_createDailyDrop) ...[
                          const SizedBox(height: 8),
                          TextFormField(
                            controller: _collectionTitleController,
                            decoration: const InputDecoration(
                              labelText: 'Daily Drop Title',
                              prefixIcon: Icon(
                                Icons.collections_bookmark_outlined,
                              ),
                            ),
                          ),
                        ],
                      ],
                    ),
                  ),
                ),
              ],
              const SizedBox(height: 20),

              // Submit Action
              ElevatedButton.icon(
                icon: _isProcessing
                    ? const SizedBox(
                        width: 18,
                        height: 18,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          color: Colors.white,
                        ),
                      )
                    : const Icon(
                        Icons.file_upload_outlined,
                        color: Colors.white,
                      ),
                label: Text(
                  _isProcessing
                      ? 'Importing Products...'
                      : (_parsedRows.isNotEmpty
                            ? 'Import ${_parsedRows.length} Products into Catalog'
                            : 'Paste Data & Click Import'),
                  style: const TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppTheme.primaryEmerald,
                  padding: const EdgeInsets.symmetric(vertical: 14),
                ),
                onPressed: _isProcessing || _parsedRows.isEmpty
                    ? null
                    : _executeImport,
              ),
            ],
          ),
        ),
      ),
    );
  }
}
