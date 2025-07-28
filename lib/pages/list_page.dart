import 'dart:typed_data';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:device_info_plus/device_info_plus.dart';
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:share_plus/share_plus.dart';
import 'package:twins_meet/model/twins_model.dart';
import 'package:twins_meet/pages/form_page.dart';
import 'package:twins_meet/pages/update_data_page.dart';
import 'package:twins_meet/services/excel_download.dart';
import 'package:twins_meet/services/twins_services.dart';
import 'package:twins_meet/utils/dilouge_utils.dart';
import 'package:twins_meet/utils/snackbar.dart';
import 'package:twins_meet/widgets/twin_widget.dart';
import 'package:path_provider/path_provider.dart';
import 'dart:io';

class TwinListPage extends StatefulWidget {
  const TwinListPage({super.key});

  @override
  State<TwinListPage> createState() => _TwinListPageState();
}

class _TwinListPageState extends State<TwinListPage> {
  final TwinService _twinService = TwinService();
  final TextEditingController _searchController = TextEditingController();
  final ScrollController _scrollController = ScrollController();

  String _searchQuery = "";
  bool _isLoading = true;
  bool _isLoadingMore = false;
  bool _isExporting = false;
  bool _hasDownloadPermission = false;
  bool _hasMoreData = true;
  
  List<TwinFamily> _allFamilies = [];
  List<TwinFamily> _filteredFamilies = [];
  List<bool> _expandedStates = [];
  DocumentSnapshot? _lastDocument;
  
  // Search mode
  bool _isSearchMode = false;

  @override
  void initState() {
    super.initState();
    _checkDownloadPermission();
    _loadInitialFamilies();
    _setupScrollController();
  }

  @override
  void dispose() {
    _searchController.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  void _setupScrollController() {
    _scrollController.addListener(() {
      if (_scrollController.position.pixels >= 
          _scrollController.position.maxScrollExtent - 200) {
        if (!_isLoadingMore && _hasMoreData && !_isSearchMode) {
          _loadMoreFamilies();
        }
      }
    });
  }

  // Load initial families with pagination
  Future<void> _loadInitialFamilies() async {
    try {
      setState(() {
        _isLoading = true;
        _hasMoreData = true;
        _lastDocument = null;
      });

      final result = await _twinService.loadFamiliesFromFirebase();

      setState(() {
        _allFamilies = result.families;
        _filteredFamilies = result.families;
        _expandedStates = List.generate(result.families.length, (_) => false);
        _lastDocument = result.lastDocument;
        _hasMoreData = result.hasMore;
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _isLoading = false;
      });
      if (mounted) {
        SnackBarUtils.showError(context, 'Error loading data: ${e.toString()}');
      }
    }
  }

  // Load more families (pagination)
  Future<void> _loadMoreFamilies() async {
    if (_isLoadingMore || !_hasMoreData || _isSearchMode) return;

    try {
      setState(() {
        _isLoadingMore = true;
      });

      final result = await _twinService.loadFamiliesFromFirebase(
        lastDocument: _lastDocument,
      );

      setState(() {
        _allFamilies.addAll(result.families);
        if (_searchQuery.isEmpty) {
          _filteredFamilies.addAll(result.families);
          _expandedStates.addAll(
            List.generate(result.families.length, (_) => false)
          );
        }
        _lastDocument = result.lastDocument;
        _hasMoreData = result.hasMore;
        _isLoadingMore = false;
      });
    } catch (e) {
      setState(() {
        _isLoadingMore = false;
      });
      if (mounted) {
        SnackBarUtils.showError(
          context, 
          'Error loading more data: ${e.toString()}'
        );
      }
    }
  }

  // Handle search with debouncing
  void _filterFamilies(String query) async {
    setState(() {
      _searchQuery = query;
      _isSearchMode = query.isNotEmpty;
    });

    if (query.isEmpty) {
      // Return to paginated view
      setState(() {
        _filteredFamilies = _allFamilies;
        _expandedStates = List.generate(_allFamilies.length, (_) => false);
        _isSearchMode = false;
      });
    } else {
      // Search mode - load all data and filter
      try {
        setState(() {
          _isLoading = true;
        });

        final searchResults = await _twinService.searchFamilies(query);
        
        setState(() {
          _filteredFamilies = searchResults;
          _expandedStates = List.generate(searchResults.length, (_) => false);
          _isLoading = false;
        });
      } catch (e) {
        setState(() {
          _isLoading = false;
        });
        if (mounted) {
          SnackBarUtils.showError(
            context, 
            'Error searching: ${e.toString()}'
          );
        }
      }
    }
  }

  // Export all families (loads all data)
  Future<void> _downloadExcel() async {
    try {
      setState(() {
        _isExporting = true;
      });

      // Load all families for export
      final allFamiliesForExport = await _twinService.loadAllFamiliesForExport();
      
      if (allFamiliesForExport.isEmpty) {
        SnackBarUtils.showError(context, 'No data to export');
        return;
      }

      // Check permission
      if (!_hasDownloadPermission) {
        await _checkDownloadPermission();
        if (!_hasDownloadPermission) {
          SnackBarUtils.showError(context, 'Download permission is required');
          return;
        }
      }

      // Generate Excel file
      final Uint8List excelBytes = await generateExcelBytes(allFamiliesForExport);
      final timestamp = DateTime.now().toIso8601String().split('T')[0];
      final fileName = 'twins_families_$timestamp.xlsx';
      final filePath = await saveExcel(excelBytes, fileName);

      setState(() {
        _isExporting = false;
      });

      if (mounted) {
        SnackBarUtils.showSuccess(context, 'Excel file downloaded successfully');
        _showDownloadSuccessDialog(fileName, filePath);
      }
    } catch (e) {
      _handleExportError(e);
    }
  }

  // Rest of your existing methods remain the same...
  Future<void> _checkDownloadPermission() async {
    try {
      PermissionStatus status;

      if (Platform.isAndroid) {
        final androidInfo = await DeviceInfoPlugin().androidInfo;

        if (androidInfo.version.sdkInt >= 30) {
          status = await Permission.manageExternalStorage.status;
          if (!status.isGranted) {
            status = await Permission.manageExternalStorage.request();
          }
        } else {
          status = await Permission.storage.status;
          if (!status.isGranted) {
            status = await Permission.storage.request();
          }
        }
      } else {
        status = PermissionStatus.granted;
      }

      setState(() {
        _hasDownloadPermission = status == PermissionStatus.granted;
      });

      if (status == PermissionStatus.permanentlyDenied) {
        _showPermissionDialog();
      }
    } catch (e) {
      debugPrint('Error checking permission: $e');
      setState(() {
        _hasDownloadPermission = false;
      });
    }
  }

  void _showPermissionDialog() {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (BuildContext context) {
        return AlertDialog(
          title: Text(
            'Download Permission Required',
            style: TextStyle(
              fontSize: 18.sp,
              fontWeight: FontWeight.w600,
            ),
          ),
          content: Text(
            'To download Excel files, please enable storage permission in app settings.',
            style: TextStyle(fontSize: 14.sp),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: Text('Later'),
            ),
            ElevatedButton(
              onPressed: () {
                Navigator.of(context).pop();
                openAppSettings();
              },
              child: Text('Open Settings'),
            ),
          ],
        );
      },
    );
  }

  void _showExportOptionsDialog() {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: Text(
            'Export Options',
            style: TextStyle(
              fontSize: 18.sp,
              fontWeight: FontWeight.w600,
            ),
          ),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                'Choose how you want to export the Excel file:',
                style: TextStyle(fontSize: 14.sp),
              ),
              SizedBox(height: 16.h),
              Row(
                children: [
                  Expanded(
                    child: ElevatedButton.icon(
                      onPressed: () {
                        Navigator.of(context).pop();
                        _downloadExcel();
                      },
                      icon: Icon(Icons.download, size: 20.sp),
                      label: Text('Download', style: TextStyle(fontSize: 14.sp)),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Color(0xFF3B82F6),
                        foregroundColor: Colors.white,
                        padding: EdgeInsets.symmetric(vertical: 12.h),
                      ),
                    ),
                  ),
                  SizedBox(width: 8.w),
                  Expanded(
                    child: ElevatedButton.icon(
                      onPressed: () {
                        Navigator.of(context).pop();
                        _shareExcel();
                      },
                      icon: Icon(Icons.share, size: 20.sp),
                      label: Text('Share', style: TextStyle(fontSize: 14.sp)),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Color(0xFF10B981),
                        foregroundColor: Colors.white,
                        padding: EdgeInsets.symmetric(vertical: 12.h),
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: Text('Cancel'),
            ),
          ],
        );
      },
    );
  }

  Future<void> _shareExcel() async {
    try {
      setState(() {
        _isExporting = true;
      });

      final allFamiliesForExport = await _twinService.loadAllFamiliesForExport();
      
      if (allFamiliesForExport.isEmpty) {
        SnackBarUtils.showError(context, 'No data to export');
        return;
      }

      final Uint8List excelBytes = await generateExcelBytes(allFamiliesForExport);
      final timestamp = DateTime.now().toIso8601String().split('T')[0];
      final fileName = 'twins_families_$timestamp.xlsx';

      final tempDir = await getTemporaryDirectory();
      final tempFile = File('${tempDir.path}/$fileName');
      await tempFile.writeAsBytes(excelBytes);

      setState(() {
        _isExporting = false;
      });

      await Share.shareXFiles(
        [XFile(tempFile.path)],
        text: 'Twins Directory Data - Generated on ${DateTime.now().toLocal().toString().split(' ')[0]}',
        subject: 'Twins Directory Excel Report',
      );

      if (mounted) {
        SnackBarUtils.showSuccess(context, 'Excel file shared successfully');
      }
    } catch (e) {
      _handleExportError(e);
    }
  }

  void _handleExportError(dynamic e) {
    setState(() {
      _isExporting = false;
    });

    if (mounted) {
      String errorMessage = 'Failed to export Excel file';

      if (e.toString().contains('permission') || e.toString().contains('denied')) {
        errorMessage = 'Permission denied. Please allow storage access.';
        _checkDownloadPermission();
      } else if (e.toString().contains('space')) {
        errorMessage = 'Not enough storage space.';
      } else if (e.toString().contains('directory')) {
        errorMessage = 'Cannot access storage directory.';
      } else {
        errorMessage = 'Export failed: ${e.toString()}';
      }

      SnackBarUtils.showError(context, errorMessage);
    }
  }

  void _showDownloadSuccessDialog(String fileName, String filePath) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: Row(
            children: [
              Icon(Icons.check_circle, color: Colors.green, size: 24.sp),
              SizedBox(width: 8.w),
              Text(
                'Download Complete',
                style: TextStyle(
                  fontSize: 18.sp,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('File saved successfully:', style: TextStyle(fontSize: 14.sp)),
              SizedBox(height: 8.h),
              Container(
                padding: EdgeInsets.all(8.w),
                decoration: BoxDecoration(
                  color: Colors.grey.shade100,
                  borderRadius: BorderRadius.circular(6.r),
                ),
                child: Text(
                  fileName,
                  style: TextStyle(
                    fontSize: 13.sp,
                    fontWeight: FontWeight.w500,
                    color: Color(0xFF3B82F6),
                  ),
                ),
              ),
              SizedBox(height: 8.h),
              Text(
                'Location: Downloads folder',
                style: TextStyle(fontSize: 12.sp, color: Colors.grey.shade600),
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: Text('OK'),
            ),
            ElevatedButton.icon(
              onPressed: () {
                Navigator.of(context).pop();
                _shareExcelFromPath(filePath);
              },
              icon: Icon(Icons.share, size: 16.sp),
              label: Text('Share File'),
              style: ElevatedButton.styleFrom(
                backgroundColor: Color(0xFF10B981),
                foregroundColor: Colors.white,
              ),
            ),
          ],
        );
      },
    );
  }

  Future<void> _shareExcelFromPath(String filePath) async {
    try {
      await Share.shareXFiles(
        [XFile(filePath)],
        text: 'Twins Directory Data - Generated on ${DateTime.now().toLocal().toString().split(' ')[0]}',
        subject: 'Twins Directory Excel Report',
      );
    } catch (e) {
      if (mounted) {
        SnackBarUtils.showError(context, 'Failed to share file: ${e.toString()}');
      }
    }
  }

  Future<String> saveExcel(Uint8List bytes, String fileName) async {
    try {
      String filePath;

      if (Platform.isAndroid) {
        Directory? downloadsDirectory;

        try {
          downloadsDirectory = Directory('/storage/emulated/0/Download');
          if (!await downloadsDirectory.exists()) {
            throw Exception('Downloads directory not accessible');
          }
        } catch (e) {
          final externalDir = await getExternalStorageDirectory();
          if (externalDir != null) {
            downloadsDirectory = Directory('${externalDir.path}/Download');
            if (!await downloadsDirectory.exists()) {
              await downloadsDirectory.create(recursive: true);
            }
          } else {
            throw Exception('No external storage available');
          }
        }

        filePath = '${downloadsDirectory!.path}/$fileName';
      } else {
        final directory = await getApplicationDocumentsDirectory();
        filePath = '${directory.path}/$fileName';
      }

      final file = File(filePath);
      await file.writeAsBytes(bytes);

      return filePath;
    } catch (e) {
      debugPrint('Error saving Excel file: $e');
      rethrow;
    }
  }

  Future<void> _deleteFamily(String familyId, int index) async {
    try {
      await _twinService.deleteFamily(familyId);
      setState(() {
        _allFamilies.removeWhere((family) => family.id == familyId);
        _filteredFamilies.removeWhere((family) => family.id == familyId);
        if (index < _expandedStates.length) {
          _expandedStates.removeAt(index);
        }
      });
      if (mounted) {
        SnackBarUtils.showSuccess(context, 'Family data deleted successfully');
      }
    } catch (e) {
      if (mounted) {
        SnackBarUtils.showError(context, 'Error deleting family: ${e.toString()}');
      }
    }
  }

  Future<void> _showDeleteConfirmation(String familyId, int index) async {
    final bool? confirm = await DialogUtils.showDeleteConfirmation(context);
    if (confirm == true) {
      await _deleteFamily(familyId, index);
    }
  }

  Widget _buildResultsSummary() {
    return Container(
      margin: EdgeInsets.symmetric(horizontal: 20.w),
      padding: EdgeInsets.symmetric(vertical: 8.h),
      child: Row(
        children: [
          Text(
            'Found ${_filteredFamilies.length} families',
            style: TextStyle(
              fontSize: 14.sp,
              color: Color(0xFF6B7280),
              fontWeight: FontWeight.w500,
            ),
          ),
          if (_searchQuery.isNotEmpty) ...[
            Text(
              ' for "$_searchQuery"',
              style: TextStyle(
                fontSize: 14.sp,
                color: Color(0xFF3B82F6),
                fontWeight: FontWeight.w500,
              ),
            ),
          ],
          if (!_isSearchMode && _hasMoreData) ...[
            Spacer(),
            Text(
              'Loading more...',
              style: TextStyle(
                fontSize: 12.sp,
                color: Color(0xFF9CA3AF),
                fontStyle: FontStyle.italic,
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildPermissionInfo() {
    if (_hasDownloadPermission) return SizedBox.shrink();

    return Container(
      margin: EdgeInsets.symmetric(horizontal: 20.w, vertical: 8.h),
      padding: EdgeInsets.all(12.w),
      decoration: BoxDecoration(
        color: Colors.blue.shade50,
        border: Border.all(color: Colors.blue.shade200),
        borderRadius: BorderRadius.circular(8.r),
      ),
      child: Row(
        children: [
          Icon(Icons.info_outline, color: Colors.blue.shade600, size: 20.sp),
          SizedBox(width: 8.w),
          Expanded(
            child: Text(
              'Allow storage access to download Excel files',
              style: TextStyle(
                fontSize: 13.sp,
                color: Colors.blue.shade800,
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
          TextButton(
            onPressed: _checkDownloadPermission,
            child: Text(
              'Allow',
              style: TextStyle(
                fontSize: 13.sp,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildFamilyList() {
    return RefreshIndicator(
      onRefresh: _loadInitialFamilies,
      color: Color(0xFF6E6588),
      child: ListView.builder(
        controller: _scrollController,
        padding: EdgeInsets.only(bottom: 80.h), // Space for FAB
        itemCount: _filteredFamilies.length + (_isLoadingMore ? 1 : 0),
        itemBuilder: (context, index) {
          // Show loading indicator at the end
          if (index == _filteredFamilies.length) {
            return Container(
              padding: EdgeInsets.all(20.w),
              child: Center(
                child: CircularProgressIndicator(
                  valueColor: AlwaysStoppedAnimation<Color>(Color(0xFF6E6588)),
                ),
              ),
            );
          }

          final family = _filteredFamilies[index];
          return FamilyCard(
            family: family,
            isExpanded: index < _expandedStates.length ? _expandedStates[index] : false,
            onToggleExpanded: () {
              if (index < _expandedStates.length) {
                setState(() {
                  _expandedStates[index] = !_expandedStates[index];
                });
              }
            },
            onUpdate: () async {
              final result = await Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => UpdateTwinsDataPage(family: family),
                ),
              );
              if (result == true) {
                _checkDownloadPermission();
                _loadInitialFamilies();
              }
            },
            onDelete: () => _showDeleteConfirmation(
              family.id,
              index,
            ),
            showSharedAddress: _twinService.hasSameAddress(family.twins),
            formatDate: _twinService.formatDate,
          );
        },
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Color(0xFFF9FAFB),
      appBar: AppBar(
        title: Text(
          'Twins Directory',
          style: TextStyle(
            fontSize: 20.sp,
            fontWeight: FontWeight.w600,
            color: Colors.white,
          ),
        ),
        backgroundColor: Color(0xFF6E6588),
        elevation: 0,
        centerTitle: true,
        actions: [
          IconButton(
            onPressed: _isExporting ? null : _showExportOptionsDialog,
            icon: Icon(Icons.download, color: Colors.white),
            tooltip: 'Download to excel',
          ),
        ],
      ),
      body: Column(
        children: [
          // Search Bar
          TwinWidgets.buildSearchBar(
            controller: _searchController,
            onChanged: _filterFamilies,
            searchQuery: _searchQuery,
            onClear: () {
              _searchController.clear();
              _filterFamilies('');
            },
          ),

          // Permission Info (only shown if needed)
          _buildPermissionInfo(),

          // Results Summary
          _buildResultsSummary(),

          // Main Content
          Expanded(
            child: _isLoading
                ? TwinWidgets.buildLoadingWidget()
                : _filteredFamilies.isEmpty
                    ? TwinWidgets.buildEmptyState(searchQuery: _searchQuery)
                    : _buildFamilyList(),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () {
          Navigator.push(
            context,
            MaterialPageRoute(builder: (context) => TwinsDataForm()),
          );
        },
        child: Container(
          width: 56.w,
          height: 56.w,
          decoration: BoxDecoration(
            color: const Color(0xFF416587),
            shape: BoxShape.circle,
            boxShadow: [
              BoxShadow(
                color: const Color(0xFF416587).withOpacity(0.3),
                blurRadius: 12,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          child: const Icon(
            Icons.add,
            color: Colors.white,
          ),
        ),
      ),
    );
  }
}