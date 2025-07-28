import 'dart:typed_data';
import 'package:excel/excel.dart';
import 'package:twins_meet/model/twins_model.dart';

Future<Uint8List> generateExcelBytes(List<TwinFamily> families) async {
  final Excel excel = Excel.createExcel();
  final Sheet sheet = excel['Twins'];

  // Header row
  sheet.appendRow([
    TextCellValue('Family ID'),
    TextCellValue('Submitted At'),
    TextCellValue('Submitted By'),
    TextCellValue('Total Twins'),
    TextCellValue('Twin Number'),
    TextCellValue('Full Name'),
    TextCellValue('Phone'),
    TextCellValue('House Name'),
    TextCellValue('Post Office'),
    TextCellValue('District'),
    TextCellValue('State'),
    TextCellValue('Country'),
    TextCellValue('Pincode'),
  ]);

  for (final family in families) {
    for (final twin in family.twins) {
      sheet.appendRow([
        TextCellValue(family.id ?? ''),
        TextCellValue(family.submittedAt.toIso8601String()),
        TextCellValue(family.submittedBy ?? ''),
        IntCellValue(family.totalTwins ?? 0),
        IntCellValue(twin.twinNumber ?? 0),
        TextCellValue(twin.fullName ?? ''),
        TextCellValue(twin.phone ?? ''),
        TextCellValue(twin.houseName ?? ''),
        TextCellValue(twin.postOffice ?? ''),
        TextCellValue(twin.district ?? ''),
        TextCellValue(twin.state ?? ''),
        TextCellValue(twin.country ?? ''),
        TextCellValue(twin.pincode ?? ''),
      ]);
    }
  }

  final bytes = excel.encode();
  if (bytes == null) {
    throw Exception('Failed to encode Excel data');
  }

  return Uint8List.fromList(bytes);
}