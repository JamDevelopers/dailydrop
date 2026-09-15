import 'package:intl/intl.dart';

class ProductCodeService {
  static String generateDesignCode({
    String prefix = 'SR',
    DateTime? date,
    int sequenceNumber = 1,
  }) {
    final effectiveDate = date ?? DateTime.now();
    final dateStr = DateFormat('yyMMdd').format(effectiveDate);
    final seqStr = sequenceNumber.toString().padLeft(3, '0');
    return '$prefix-$dateStr-$seqStr';
  }

  static List<String> generateBatchDesignCodes({
    String prefix = 'SR',
    DateTime? date,
    int startSequence = 1,
    required int count,
    List<String> existingCodes = const [],
  }) {
    final effectiveDate = date ?? DateTime.now();
    final dateStr = DateFormat('yyMMdd').format(effectiveDate);
    final codes = <String>[];
    int currentSeq = startSequence;

    while (codes.length < count) {
      final code = '$prefix-$dateStr-${currentSeq.toString().padLeft(3, '0')}';
      if (!existingCodes.contains(code)) {
        codes.add(code);
      }
      currentSeq++;
    }

    return codes;
  }

  static int getNextSequenceNumber({
    String prefix = 'SR',
    DateTime? date,
    required List<String> existingCodes,
  }) {
    final effectiveDate = date ?? DateTime.now();
    final dateStr = DateFormat('yyMMdd').format(effectiveDate);
    final searchPrefix = '$prefix-$dateStr-';

    int maxSeq = 0;
    for (final code in existingCodes) {
      if (code.startsWith(searchPrefix)) {
        final seqPart = code.substring(searchPrefix.length);
        final num = int.tryParse(seqPart);
        if (num != null && num > maxSeq) {
          maxSeq = num;
        }
      }
    }

    return maxSeq + 1;
  }
}

