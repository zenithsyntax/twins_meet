import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:excel/excel.dart';
import 'package:path_provider/path_provider.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:twins_meet/model/twins_model.dart';
import 'dart:io';

class PaginatedResult {
  final List<TwinFamily> families;
  final DocumentSnapshot? lastDocument;
  final bool hasMore;

  PaginatedResult({
    required this.families,
    this.lastDocument,
    required this.hasMore,
  });
}

class TwinService {
  static final TwinService _instance = TwinService._internal();
  factory TwinService() => _instance;
  TwinService._internal();

  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  
  // Pagination settings
  static const int pageSize = 6; // Adjust based on your needs

  /// Load families with pagination
  Future<PaginatedResult> loadFamiliesFromFirebase({
    DocumentSnapshot? lastDocument,
    int limit = pageSize,
  }) async {
    try {
      Query query = _firestore
          .collection('twins_submissions')
          .orderBy('submittedAt', descending: true)
          .limit(limit);

      // If we have a last document, start after it
      if (lastDocument != null) {
        query = query.startAfterDocument(lastDocument);
      }

      final QuerySnapshot snapshot = await query.get();
      
      final families = snapshot.docs
          .map((doc) => TwinFamily.fromFirestore(doc))
          .toList();

      // Check if there are more documents
      final hasMore = snapshot.docs.length == limit;
      final lastDoc = snapshot.docs.isNotEmpty ? snapshot.docs.last : null;

      return PaginatedResult(
        families: families,
        lastDocument: lastDoc,
        hasMore: hasMore,
      );
    } catch (e) {
      throw Exception('Error loading data: $e');
    }
  }

  /// Load all families (for export functionality)
  Future<List<TwinFamily>> loadAllFamiliesForExport() async {
    try {
      final QuerySnapshot snapshot = await _firestore
          .collection('twins_submissions')
          .orderBy('submittedAt', descending: true)
          .get();

      return snapshot.docs
          .map((doc) => TwinFamily.fromFirestore(doc))
          .toList();
    } catch (e) {
      throw Exception('Error loading data: $e');
    }
  }

  /// Search families with pagination
  Future<List<TwinFamily>> searchFamilies(String query) async {
    try {
      // For search, we might need to load more data or implement server-side search
      // This is a simple client-side search implementation
      final allFamilies = await loadAllFamiliesForExport();
      return filterFamilies(allFamilies, query);
    } catch (e) {
      throw Exception('Error searching families: $e');
    }
  }

  /// Delete a family by ID
  Future<void> deleteFamily(String familyId) async {
    try {
      await _firestore.collection('twins_submissions').doc(familyId).delete();
    } catch (e) {
      throw Exception('Error deleting family: $e');
    }
  }

  /// Update a family
  Future<void> updateFamily(String familyId, TwinFamily family) async {
    try {
      await _firestore
          .collection('twins_submissions')
          .doc(familyId)
          .update(family.toMap());
    } catch (e) {
      throw Exception('Error updating family: $e');
    }
  }

  /// Filter families based on search query
  List<TwinFamily> filterFamilies(List<TwinFamily> families, String query) {
    if (query.isEmpty) return families;

    return families.where((family) {
      return family.twins.any((twin) =>
          twin.fullName.toLowerCase().contains(query.toLowerCase()) ||
          twin.phone.contains(query) ||
          twin.district.toLowerCase().contains(query.toLowerCase()));
    }).toList();
  }

  /// Check if all twins in a family have the same address
  bool hasSameAddress(List<Twin> twins) {
    if (twins.length < 2) return true;
    final first = twins.first;
    return twins.every((t) =>
        t.houseName == first.houseName &&
        t.postOffice == first.postOffice &&
        t.district == first.district &&
        t.state == first.state &&
        t.country == first.country &&
        t.pincode == first.pincode);
  }

  /// Export families data to Excel (loads all data)
  Future<String> exportToExcel(List<TwinFamily> families) async {
    if (families.isEmpty) {
      throw Exception('No data to export');
    }

    // Request storage permission
    final status = await Permission.storage.request();
    if (!status.isGranted) {
      throw Exception('Storage permission denied');
    }

    // Create Excel workbook
    var excel = Excel.createExcel();
    Sheet sheetObject = excel['Twins Data'];

    // Add headers
    List<String> headers = [
      'Family ID',
      'Submitted Date',
      'Submitted By',
      'Total Twins',
      'Twin Number',
      'Full Name',
      'Phone',
      'House Name',
      'Post Office',
      'District',
      'State',
      'Country',
      'Pincode'
    ];

    // Style for headers
    CellStyle headerStyle = CellStyle(bold: true);

    // Add headers to first row
    for (int i = 0; i < headers.length; i++) {
      var cell = sheetObject.cell(CellIndex.indexByColumnRow(columnIndex: i, rowIndex: 0));
      cell.value = TextCellValue(headers[i]);
      cell.cellStyle = headerStyle;
    }

    // Add data rows
    int rowIndex = 1;
    for (TwinFamily family in families) {
      for (Twin twin in family.twins) {
        List<dynamic> rowData = [
          family.id,
          _formatDateForExcel(family.submittedAt),
          family.submittedBy,
          family.totalTwins,
          twin.twinNumber,
          twin.fullName,
          twin.phone,
          twin.houseName,
          twin.postOffice,
          twin.district,
          twin.state,
          twin.country,
          twin.pincode,
        ];

        for (int i = 0; i < rowData.length; i++) {
          var cell = sheetObject.cell(CellIndex.indexByColumnRow(columnIndex: i, rowIndex: rowIndex));
          var value = rowData[i];
          
          // Convert data to appropriate CellValue type
          if (value is String) {
            cell.value = TextCellValue(value);
          } else if (value is int) {
            cell.value = IntCellValue(value);
          } else if (value is double) {
            cell.value = DoubleCellValue(value);
          } else {
            cell.value = TextCellValue(value.toString());
          }
        }
        rowIndex++;
      }
    }

    // Auto-fit columns
    for (int i = 0; i < headers.length; i++) {
      sheetObject.setColumnAutoFit(i);
    }

    // Get the Downloads directory
    Directory? directory;
    if (Platform.isAndroid) {
      directory = Directory('/storage/emulated/0/Download');
      if (!directory.existsSync()) {
        directory = await getExternalStorageDirectory();
      }
    } else {
      directory = await getApplicationDocumentsDirectory();
    }

    if (directory == null) {
      throw Exception('Could not access storage directory');
    }

    // Create filename with timestamp
    String timestamp = DateTime.now().millisecondsSinceEpoch.toString();
    String fileName = 'twins_data_$timestamp.xlsx';
    String filePath = '${directory.path}/$fileName';

    // Save file
    List<int>? fileBytes = excel.save();
    if (fileBytes != null) {
      File file = File(filePath);
      await file.writeAsBytes(fileBytes);
      return fileName;
    } else {
      throw Exception('Failed to generate Excel file');
    }
  }

  /// Format date for Excel export
  String _formatDateForExcel(DateTime date) {
    return '${date.day}/${date.month}/${date.year} ${date.hour.toString().padLeft(2, '0')}:${date.minute.toString().padLeft(2, '0')}';
  }

  /// Format date for display
  String formatDate(DateTime date) {
    return '${date.day}/${date.month}/${date.year} at ${date.hour.toString().padLeft(2, '0')}:${date.minute.toString().padLeft(2, '0')}';
  }
}