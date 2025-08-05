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
  
  // Cache to prevent duplicate loading - IMPROVED
  final Set<String> _loadedDocumentIds = {};

  /// Reset cache when refreshing data - FIXED
  void resetCache() {
    _loadedDocumentIds.clear();
    print('TwinService: Cache reset - loaded IDs cleared');
  }

  /// Load families with pagination - FIXED duplicate prevention
  Future<PaginatedResult> loadFamiliesFromFirebase({
    DocumentSnapshot? lastDocument,
    int limit = pageSize,
  }) async {
    try {
      print('TwinService: Loading families - lastDocument: ${lastDocument?.id}, limit: $limit');
      
      Query query = _firestore
          .collection('twins_submissions')
          .orderBy('submittedAt', descending: true)
          .limit(limit);

      // If we have a last document, start after it
      if (lastDocument != null) {
        query = query.startAfterDocument(lastDocument);
      }

      final QuerySnapshot snapshot = await query.get();
      print('TwinService: Fetched ${snapshot.docs.length} documents from Firestore');
      
      // Convert all documents to families first (don't filter by cache here for pagination)
      final families = snapshot.docs
          .map((doc) => TwinFamily.fromFirestore(doc))
          .toList();

      // Check if there are more documents
      final hasMore = snapshot.docs.length == limit;
      final lastDoc = snapshot.docs.isNotEmpty ? snapshot.docs.last : null;

      print('TwinService: Returning ${families.length} families, hasMore: $hasMore');

      return PaginatedResult(
        families: families,
        lastDocument: lastDoc,
        hasMore: hasMore,
      );
    } catch (e) {
      print('TwinService: Error loading families: $e');
      throw Exception('Error loading data: $e');
    }
  }

  /// Load all families (for export functionality) with duplicate prevention
  Future<List<TwinFamily>> loadAllFamiliesForExport() async {
    try {
      print('TwinService: Loading all families for export');
      
      final QuerySnapshot snapshot = await _firestore
          .collection('twins_submissions')
          .orderBy('submittedAt', descending: true)
          .get();

      print('TwinService: Fetched ${snapshot.docs.length} documents for export');

      // Use a Map to ensure uniqueness by document ID
      final Map<String, TwinFamily> uniqueFamilies = {};
      
      for (final doc in snapshot.docs) {
        if (!uniqueFamilies.containsKey(doc.id)) {
          uniqueFamilies[doc.id] = TwinFamily.fromFirestore(doc);
        }
      }

      print('TwinService: Returning ${uniqueFamilies.length} unique families for export');
      return uniqueFamilies.values.toList();
    } catch (e) {
      print('TwinService: Error loading all families: $e');
      throw Exception('Error loading data: $e');
    }
  }

  /// Search families with pagination and duplicate prevention
  Future<List<TwinFamily>> searchFamilies(String query) async {
    try {
      print('TwinService: Searching families with query: "$query"');
      
      // For search, load all data and filter - ensure no duplicates
      final allFamilies = await loadAllFamiliesForExport();
      final filteredFamilies = filterFamilies(allFamilies, query);
      
      print('TwinService: Search returned ${filteredFamilies.length} results');
      return filteredFamilies;
    } catch (e) {
      print('TwinService: Error searching families: $e');
      throw Exception('Error searching families: $e');
    }
  }

  /// Delete a family by ID - IMPROVED
  Future<void> deleteFamily(String familyId) async {
    try {
      print('TwinService: Deleting family with ID: $familyId');
      
      await _firestore.collection('twins_submissions').doc(familyId).delete();
      
      // Remove from cache if it exists
      _loadedDocumentIds.remove(familyId);
      
      print('TwinService: Successfully deleted family $familyId');
    } catch (e) {
      print('TwinService: Error deleting family: $e');
      throw Exception('Error deleting family: $e');
    }
  }

  /// Update a family - IMPROVED
  Future<void> updateFamily(String familyId, TwinFamily family) async {
    try {
      print('TwinService: Updating family with ID: $familyId');
      
      await _firestore
          .collection('twins_submissions')
          .doc(familyId)
          .update(family.toMap());
          
      print('TwinService: Successfully updated family $familyId');
    } catch (e) {
      print('TwinService: Error updating family: $e');
      throw Exception('Error updating family: $e');
    }
  }

  /// Add a new family - NEW METHOD
  Future<String> addFamily(TwinFamily family) async {
    try {
      print('TwinService: Adding new family');
      
      final docRef = await _firestore
          .collection('twins_submissions')
          .add(family.toMap());
      
      print('TwinService: Successfully added family with ID: ${docRef.id}');
      
      // Reset cache to ensure new data appears
      resetCache();
      
      return docRef.id;
    } catch (e) {
      print('TwinService: Error adding family: $e');
      throw Exception('Error adding family: $e');
    }
  }

  /// Filter families based on search query with improved matching
  List<TwinFamily> filterFamilies(List<TwinFamily> families, String query) {
    if (query.isEmpty) return families;

    final lowercaseQuery = query.toLowerCase();
    
    return families.where((family) {
      return family.twins.any((twin) =>
          twin.fullName.toLowerCase().contains(lowercaseQuery) ||
          twin.phone.contains(query) ||
          twin.district.toLowerCase().contains(lowercaseQuery) ||
          twin.postOffice.toLowerCase().contains(lowercaseQuery) ||
          twin.houseName.toLowerCase().contains(lowercaseQuery) ||
          twin.state.toLowerCase().contains(lowercaseQuery));
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

  /// Export families data to Excel (loads all data) with duplicate prevention
  Future<String> exportToExcel(List<TwinFamily> families) async {
    if (families.isEmpty) {
      throw Exception('No data to export');
    }

    // Request storage permission
    final status = await Permission.storage.request();
    if (!status.isGranted) {
      throw Exception('Storage permission denied');
    }

    // Remove duplicates before export using family ID
    final Map<String, TwinFamily> uniqueFamilies = {};
    for (final family in families) {
      uniqueFamilies[family.id] = family;
    }
    final uniqueFamiliesList = uniqueFamilies.values.toList();

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
    for (TwinFamily family in uniqueFamiliesList) {
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