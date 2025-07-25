import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:excel/excel.dart';
import 'package:path_provider/path_provider.dart';
import 'package:permission_handler/permission_handler.dart';
import 'dart:io';

class Twin {
  final int twinNumber;
  final String fullName;
  final String phone;
  final String houseName;
  final String postOffice;
  final String district;
  final String state;
  final String country;
  final String pincode;

  Twin({
    required this.twinNumber,
    required this.fullName,
    required this.phone,
    required this.houseName,
    required this.postOffice,
    required this.district,
    required this.state,
    required this.country,
    required this.pincode,
  });

  factory Twin.fromMap(Map<String, dynamic> map) {
    return Twin(
      twinNumber: map['twinNumber'] ?? 0,
      fullName: map['fullName'] ?? '',
      phone: map['phone'] ?? '',
      houseName: map['houseName'] ?? '',
      postOffice: map['postOffice'] ?? '',
      district: map['district'] ?? '',
      state: map['state'] ?? '',
      country: map['country'] ?? '',
      pincode: map['pincode'] ?? '',
    );
  }
}

class TwinFamily {
  final String id;
  final DateTime submittedAt;
  final String submittedBy;
  final List<Twin> twins;
  final int totalTwins;

  TwinFamily({
    required this.id,
    required this.submittedAt,
    required this.submittedBy,
    required this.twins,
    required this.totalTwins,
  });

  factory TwinFamily.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    final twinsData = List<Map<String, dynamic>>.from(data['twins'] ?? []);
    
    return TwinFamily(
      id: doc.id,
      submittedAt: (data['submittedAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
      submittedBy: data['submittedBy'] ?? 'Unknown',
      totalTwins: data['totalTwins'] ?? 0,
      twins: twinsData.map((twinMap) => Twin.fromMap(twinMap)).toList(),
    );
  }
}

class TwinListPage extends StatefulWidget {
  const TwinListPage({super.key});

  @override
  State<TwinListPage> createState() => _TwinListPageState();
}

class _TwinListPageState extends State<TwinListPage> {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final TextEditingController _searchController = TextEditingController();
  
  String _searchQuery = "";
  bool _isLoading = true;
  bool _isExporting = false;
  List<TwinFamily> _allFamilies = [];
  List<TwinFamily> _filteredFamilies = [];
  List<bool> _expandedStates = [];

  @override
  void initState() {
    super.initState();
    _loadFamiliesFromFirebase();
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _loadFamiliesFromFirebase() async {
    try {
      setState(() {
        _isLoading = true;
      });

      final QuerySnapshot snapshot = await _firestore
          .collection('twins_submissions')
          .orderBy('submittedAt', descending: true)
          .get();

      final families = snapshot.docs
          .map((doc) => TwinFamily.fromFirestore(doc))
          .toList();

      setState(() {
        _allFamilies = families;
        _filteredFamilies = families;
        _expandedStates = List.generate(families.length, (_) => false);
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _isLoading = false;
      });
      _showErrorSnackBar('Error loading data: $e');
    }
  }

  Future<void> _exportToExcel() async {
    if (_allFamilies.isEmpty) {
      _showErrorSnackBar('No data to export');
      return;
    }

    setState(() {
      _isExporting = true;
    });

    try {
      // Request storage permission
      final status = await Permission.storage.request();
      if (!status.isGranted) {
        _showErrorSnackBar('Storage permission denied');
        setState(() {
          _isExporting = false;
        });
        return;
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
      CellStyle headerStyle = CellStyle(
        bold: true,

      );

      // Add headers to first row
      for (int i = 0; i < headers.length; i++) {
        var cell = sheetObject.cell(CellIndex.indexByColumnRow(columnIndex: i, rowIndex: 0));
        cell.value = TextCellValue(headers[i]);
        cell.cellStyle = headerStyle;
      }

      // Add data rows
      int rowIndex = 1;
      for (TwinFamily family in _allFamilies) {
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

        setState(() {
          _isExporting = false;
        });

        _showSuccessSnackBar('Excel file exported successfully to Downloads folder');
        
        // Show dialog with file path
        _showExportSuccessDialog(filePath, fileName);
      } else {
        throw Exception('Failed to generate Excel file');
      }
    } catch (e) {
      setState(() {
        _isExporting = false;
      });
      _showErrorSnackBar('Error exporting to Excel: $e');
    }
  }

  void _showExportSuccessDialog(String filePath, String fileName) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16.r),
          ),
          title: Row(
            children: [
              Container(
                padding: EdgeInsets.all(8.w),
                decoration: BoxDecoration(
                  color: Color(0xFF10B981).withOpacity(0.1),
                  borderRadius: BorderRadius.circular(8.r),
                ),
                child: Icon(
                  Icons.check_circle_outline,
                  color: Color(0xFF10B981),
                  size: 24.w,
                ),
              ),
              SizedBox(width: 12.w),
              Text(
                'Export Successful',
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
              Text(
                'Excel file has been saved successfully!',
                style: TextStyle(
                  fontSize: 14.sp,
                  color: Color(0xFF374151),
                ),
              ),
              SizedBox(height: 12.h),
              Container(
                padding: EdgeInsets.all(12.w),
                decoration: BoxDecoration(
                  color: Color(0xFFF3F4F6),
                  borderRadius: BorderRadius.circular(8.r),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'File Name:',
                      style: TextStyle(
                        fontSize: 12.sp,
                        fontWeight: FontWeight.w600,
                        color: Color(0xFF6B7280),
                      ),
                    ),
                    Text(
                      fileName,
                      style: TextStyle(
                        fontSize: 12.sp,
                        color: Color(0xFF374151),
                      ),
                    ),
                    SizedBox(height: 8.h),
                    Text(
                      'Location:',
                      style: TextStyle(
                        fontSize: 12.sp,
                        fontWeight: FontWeight.w600,
                        color: Color(0xFF6B7280),
                      ),
                    ),
                    Text(
                      Platform.isAndroid ? 'Downloads folder' : 'Documents folder',
                      style: TextStyle(
                        fontSize: 12.sp,
                        color: Color(0xFF374151),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: Text(
                'OK',
                style: TextStyle(
                  fontSize: 14.sp,
                  color: Color(0xFF3B82F6),
                ),
              ),
            ),
          ],
        );
      },
    );
  }

  String _formatDateForExcel(DateTime date) {
    return '${date.day}/${date.month}/${date.year} ${date.hour.toString().padLeft(2, '0')}:${date.minute.toString().padLeft(2, '0')}';
  }

  void _filterFamilies(String query) {
    setState(() {
      _searchQuery = query;
      if (query.isEmpty) {
        _filteredFamilies = _allFamilies;
      } else {
        _filteredFamilies = _allFamilies.where((family) {
          return family.twins.any((twin) =>
              twin.fullName.toLowerCase().contains(query.toLowerCase()) ||
              twin.phone.contains(query) ||
              twin.district.toLowerCase().contains(query.toLowerCase()));
        }).toList();
      }
      _expandedStates = List.generate(_filteredFamilies.length, (_) => false);
    });
  }

  bool _hasSameAddress(List<Twin> twins) {
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

  Future<void> _launchPhone(String phone) async {
    final Uri url = Uri.parse('tel:$phone');
    if (await canLaunchUrl(url)) {
      await launchUrl(url);
    }
  }

  Future<void> _launchSMS(String phone) async {
    final Uri url = Uri.parse('sms:$phone');
    if (await canLaunchUrl(url)) {
      await launchUrl(url);
    }
  }

  Future<void> _launchWhatsApp(String phone) async {
    final Uri url = Uri.parse('https://wa.me/$phone');
    if (await canLaunchUrl(url)) {
      await launchUrl(url, mode: LaunchMode.externalApplication);
    }
  }

  Future<void> _deleteFamily(String familyId, int index) async {
    try {
      await _firestore.collection('twins_submissions').doc(familyId).delete();
      setState(() {
        _allFamilies.removeWhere((family) => family.id == familyId);
        _filterFamilies(_searchQuery);
      });
      _showSuccessSnackBar('Family data deleted successfully');
    } catch (e) {
      _showErrorSnackBar('Error deleting family: $e');
    }
  }

  Future<void> _showDeleteConfirmation(String familyId, int index) async {
    final bool? confirm = await showDialog<bool>(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16.r),
          ),
          title: Row(
            children: [
              Container(
                padding: EdgeInsets.all(8.w),
                decoration: BoxDecoration(
                  color: Color(0xFFEF4444).withOpacity(0.1),
                  borderRadius: BorderRadius.circular(8.r),
                ),
                child: Icon(
                  Icons.warning_outlined,
                  color: Color(0xFFEF4444),
                  size: 24.w,
                ),
              ),
              SizedBox(width: 12.w),
              Text(
                'Confirm Delete',
                style: TextStyle(
                  fontSize: 18.sp,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
          content: Text(
            'Are you sure you want to delete this family data? This action cannot be undone.',
            style: TextStyle(
              fontSize: 14.sp,
              color: Color(0xFF6B7280),
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(false),
              child: Text(
                'Cancel',
                style: TextStyle(
                  fontSize: 14.sp,
                  color: Color(0xFF6B7280),
                ),
              ),
            ),
            ElevatedButton(
              onPressed: () => Navigator.of(context).pop(true),
              style: ElevatedButton.styleFrom(
                backgroundColor: Color(0xFFEF4444),
                foregroundColor: Colors.white,
              ),
              child: Text('Delete'),
            ),
          ],
        );
      },
    );

    if (confirm == true) {
      await _deleteFamily(familyId, index);
    }
  }

  void _showSuccessSnackBar(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: Color(0xFF10B981),
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(8.r),
        ),
      ),
    );
  }

  void _showErrorSnackBar(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: Color(0xFFEF4444),
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(8.r),
        ),
      ),
    );
  }

  Widget _buildSearchBar() {
    return Container(
      margin: EdgeInsets.all(20.w),
      child: TextField(
        controller: _searchController,
        onChanged: _filterFamilies,
        style: TextStyle(fontSize: 14.sp),
        decoration: InputDecoration(
          hintText: 'Search by name, phone, or district...',
          hintStyle: TextStyle(
            fontSize: 14.sp,
            color: Color(0xFF9CA3AF),
          ),
          prefixIcon: Icon(
            Icons.search,
            size: 20.w,
            color: Color(0xFF6B7280),
          ),
          suffixIcon: _searchQuery.isNotEmpty
              ? IconButton(
                  onPressed: () {
                    _searchController.clear();
                    _filterFamilies('');
                  },
                  icon: Icon(
                    Icons.clear,
                    size: 20.w,
                    color: Color(0xFF6B7280),
                  ),
                )
              : null,
          filled: true,
          fillColor: Color(0xFFF9FAFB),
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12.r),
            borderSide: BorderSide(color: Color(0xFFE5E7EB)),
          ),
          enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12.r),
            borderSide: BorderSide(color: Color(0xFFE5E7EB)),
          ),
          focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12.r),
            borderSide: BorderSide(color: Color(0xFF3B82F6), width: 2),
          ),
        ),
      ),
    );
  }

  Widget _buildExportButton() {
    return Container(
      margin: EdgeInsets.symmetric(horizontal: 20.w, vertical: 10.h),
      child: ElevatedButton.icon(
        onPressed: _isExporting ? null : _exportToExcel,
        icon: _isExporting
            ? SizedBox(
                width: 20.w,
                height: 20.h,
                child: CircularProgressIndicator(
                  strokeWidth: 2,
                  valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                ),
              )
            : Icon(
                Icons.file_download_outlined,
                size: 20.w,
                color: Colors.white,
              ),
        label: Text(
          _isExporting ? 'Exporting...' : 'Export to Excel',
          style: TextStyle(
            fontSize: 14.sp,
            fontWeight: FontWeight.w600,
            color: Colors.white,
          ),
        ),
        style: ElevatedButton.styleFrom(
          backgroundColor: Color(0xFF059669),
          padding: EdgeInsets.symmetric(vertical: 12.h, horizontal: 20.w),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(8.r),
          ),
          elevation: 2,
        ),
      ),
    );
  }

  Widget _buildFamilyCard(TwinFamily family, int index) {
    final bool isExpanded = _expandedStates[index];
    final bool showSharedAddress = _hasSameAddress(family.twins);

    return Container(
      margin: EdgeInsets.symmetric(horizontal: 20.w, vertical: 8.h),
      child: Card(
        elevation: 2,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16.r),
        ),
        child: Column(
          children: [
            _buildFamilyHeader(family, index, isExpanded),
            if (isExpanded) _buildFamilyDetails(family, showSharedAddress),
          ],
        ),
      ),
    );
  }

  Widget _buildFamilyHeader(TwinFamily family, int index, bool isExpanded) {
    return Container(
      padding: EdgeInsets.all(20.w),
      child: Column(
        children: [
          Row(
            children: [
              Container(
                padding: EdgeInsets.all(12.w),
                decoration: BoxDecoration(
                  color: Color(0xFF3B82F6).withOpacity(0.1),
                  borderRadius: BorderRadius.circular(12.r),
                ),
                child: Icon(
                  Icons.family_restroom,
                  color: Color(0xFF3B82F6),
                  size: 24.w,
                ),
              ),
              SizedBox(width: 16.w),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      '${family.totalTwins} Twins Family',
                      style: TextStyle(
                        fontSize: 16.sp,
                        fontWeight: FontWeight.w600,
                        color: Color(0xFF111827),
                      ),
                    ),
                    SizedBox(height: 4.h),
                    Text(
                      family.twins.map((t) => t.fullName).join(', '),
                      style: TextStyle(
                        fontSize: 14.sp,
                        color: Color(0xFF6B7280),
                      ),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                ),
              ),
              IconButton(
                onPressed: () {
                  setState(() {
                    _expandedStates[index] = !_expandedStates[index];
                  });
                },
                icon: Icon(
                  isExpanded ? Icons.expand_less : Icons.expand_more,
                  size: 24.w,
                  color: Color(0xFF6B7280),
                ),
              ),
            ],
          ),
          SizedBox(height: 12.h),
          Row(
            children: [
              Icon(
                Icons.access_time,
                size: 16.w,
                color: Color(0xFF9CA3AF),
              ),
              SizedBox(width: 8.w),
              Text(
                'Submitted: ${_formatDate(family.submittedAt)}',
                style: TextStyle(
                  fontSize: 12.sp,
                  color: Color(0xFF9CA3AF),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildFamilyDetails(TwinFamily family, bool showSharedAddress) {
    return Container(
      padding: EdgeInsets.fromLTRB(20.w, 0, 20.w, 20.w),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Divider(color: Color(0xFFE5E7EB)),
          SizedBox(height: 16.h),
          
          // Twins Details
          for (int i = 0; i < family.twins.length; i++)
            _buildTwinDetails(family.twins[i], showSharedAddress),
          
          // Shared Address
          if (showSharedAddress) _buildSharedAddress(family.twins.first),
          
          SizedBox(height: 20.h),
          
          // Action Buttons
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            children: [
              Expanded(
                child: OutlinedButton.icon(
                  onPressed: () => _showUpdateDialog(family),
                  icon: Icon(Icons.edit_outlined, size: 18.w),
                  label: Text('Update'),
                  style: OutlinedButton.styleFrom(
                    foregroundColor: Color(0xFF3B82F6),
                    side: BorderSide(color: Color(0xFF3B82F6)),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(8.r),
                    ),
                    padding: EdgeInsets.symmetric(vertical: 12.h),
                  ),
                ),
              ),
              SizedBox(width: 12.w),
              Expanded(
                child: OutlinedButton.icon(
                  onPressed: () => _showDeleteConfirmation(
                    family.id,
                    _filteredFamilies.indexOf(family),
                  ),
                  icon: Icon(Icons.delete_outline, size: 18.w),
                  label: Text('Delete'),
                  style: OutlinedButton.styleFrom(
                    foregroundColor: Color(0xFFEF4444),
                    side: BorderSide(color: Color(0xFFEF4444)),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(8.r),
                    ),
                    padding: EdgeInsets.symmetric(vertical: 12.h),
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildTwinDetails(Twin twin, bool showSharedAddress) {
    return Container(
      margin: EdgeInsets.only(bottom: 16.h),
      padding: EdgeInsets.all(16.w),
      decoration: BoxDecoration(
        color: Color(0xFFF9FAFB),
        borderRadius: BorderRadius.circular(12.r),
        // border: Border.all(color: Color(0xFFE5E7EB)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: EdgeInsets.symmetric(horizontal: 8.w, vertical: 4.h),
                decoration: BoxDecoration(
                  color: Color(0xFF3B82F6),
                  borderRadius: BorderRadius.circular(12.r),
                ),
                child: Text(
                  'Twin ${twin.twinNumber}',
                  style: TextStyle(
                    fontSize: 12.sp,
                    fontWeight: FontWeight.w600,
                    color: Colors.white,
                  ),
                ),
              ),
              SizedBox(width: 12.w),
              Expanded(
                child: Text(
                  twin.fullName,
                  style: TextStyle(
                    fontSize: 16.sp,
                    fontWeight: FontWeight.w600,
                    color: Color(0xFF111827),
                  ),
                ),
              ),
            ],
          ),
          SizedBox(height: 12.h),
          
          Row(
            children: [
              Icon(Icons.phone_outlined, size: 16.w, color: Color(0xFF6B7280)),
              SizedBox(width: 8.w),
              Text(
                twin.phone,
                style: TextStyle(
                  fontSize: 14.sp,
                  color: Color(0xFF374151),
                ),
              ),
            ],
          ),
          SizedBox(height: 12.h),
          
          // Contact Buttons
          Row(
            children: [
              Expanded(
                child: _buildContactButton(
                  icon: Icons.call,
                  label: 'Call',
                  color: Color(0xFF10B981),
                  onPressed: () => _launchPhone(twin.phone),
                ),
              ),
              SizedBox(width: 8.w),
              Expanded(
                child: _buildContactButton(
                  icon: Icons.sms,
                  label: 'SMS',
                  color: Color(0xFF3B82F6),
                  onPressed: () => _launchSMS(twin.phone),
                ),
              ),
              SizedBox(width: 8.w),
              Expanded(
                child: _buildContactButton(
                  icon: Icons.message,
                  label: 'WhatsApp',
                  color: Color(0xFF059669),
                  onPressed: () => _launchWhatsApp(twin.phone),
                ),
              ),
            ],
          ),
          
          // Individual Address (if not shared)
          if (!showSharedAddress) ...[
            SizedBox(height: 12.h),
            _buildAddressInfo(twin),
          ],
        ],
      ),
    );
  }

  Widget _buildContactButton({
    required IconData icon,
    required String label,
    required Color color,
    required VoidCallback onPressed,
  }) {
    return ElevatedButton.icon(
      onPressed: onPressed,
      icon: Icon(icon, size: 14.w),
      label: Text(
        label,
        style: TextStyle(fontSize: 12.sp),
      ),
      style: ElevatedButton.styleFrom(
        backgroundColor: color,
        foregroundColor: Colors.white,
        padding: EdgeInsets.symmetric(vertical: 8.h),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(6.r),
        ),
        elevation: 0,
      ),
    );
  }

  Widget _buildSharedAddress(Twin twin) {
    return Container(
      margin: EdgeInsets.only(top: 8.h, bottom: 8.h),
      padding: EdgeInsets.all(16.w),
      decoration: BoxDecoration(
        color: Color(0xFFF0F9FF),
        borderRadius: BorderRadius.circular(12.r),
        // border: Border.all(color: Color(0xFFBAE6FD)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(
                Icons.home_outlined,
                size: 16.w,
                color: Color(0xFF0284C7),
              ),
              SizedBox(width: 8.w),
              Text(
                'Shared Address',
                style: TextStyle(
                  fontSize: 14.sp,
                  fontWeight: FontWeight.w600,
                  color: Color(0xFF0284C7),
                ),
              ),
            ],
          ),
          SizedBox(height: 8.h),
          _buildAddressInfo(twin),
        ],
      ),
    );
  }

  Widget _buildAddressInfo(Twin twin) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildInfoRow('House', twin.houseName),
        _buildInfoRow('Post Office', twin.postOffice),
        _buildInfoRow('District', twin.district),
        _buildInfoRow('State', twin.state),
        _buildInfoRow('Country', twin.country),
        _buildInfoRow('Pincode', twin.pincode),
      ],
    );
  }

  Widget _buildInfoRow(String label, String value) {
    return Padding(
      padding: EdgeInsets.only(bottom: 4.h),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 80.w,
            child: Text(
              '$label:',
              style: TextStyle(
                fontSize: 12.sp,
                color: Color(0xFF6B7280),
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
          Expanded(
            child: Text(
              value,
              style: TextStyle(
                fontSize: 12.sp,
                color: Color(0xFF374151),
              ),
            ),
          ),
        ],
      ),
    );
  }

  void _showUpdateDialog(TwinFamily family) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16.r),
        ),
        title: Text(
          'Update Family',
          style: TextStyle(
            fontSize: 18.sp,
            fontWeight: FontWeight.w600,
          ),
        ),
        content: Text(
          'Update functionality can be implemented here. You would typically navigate to an edit form.',
          style: TextStyle(
            fontSize: 14.sp,
            color: Color(0xFF6B7280),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(context);
              // Navigate to update form or implement update logic
            },
            child: Text('Update'),
          ),
        ],
      ),
    );
  }

  String _formatDate(DateTime date) {
    return '${date.day}/${date.month}/${date.year} at ${date.hour.toString().padLeft(2, '0')}:${date.minute.toString().padLeft(2, '0')}';
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Color(0xFFF9FAFB),
      appBar: AppBar(
        title: Text(
          'Twins Families',
          style: TextStyle(
            fontSize: 20.sp,
            fontWeight: FontWeight.w600,
            color: Colors.white,
          ),
        ),
        backgroundColor: Color(0xFF1E40AF),
        elevation: 0,
        centerTitle: true,
        actions: [
          IconButton(
            onPressed: _loadFamiliesFromFirebase,
            icon: Icon(Icons.refresh, color: Colors.white),
            tooltip: 'Refresh',
          ),
        ],
      ),
      body: Column(
        children: [
          _buildSearchBar(),
          
          // Export Button
          _buildExportButton(),
          
          // Results Summary
          Container(
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
              ],
            ),
          ),
          
          Expanded(
            child: _isLoading
                ? Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        CircularProgressIndicator(
                          valueColor: AlwaysStoppedAnimation<Color>(
                            Color(0xFF3B82F6),
                          ),
                        ),
                        SizedBox(height: 16.h),
                        Text(
                          'Loading families...',
                          style: TextStyle(
                            fontSize: 14.sp,
                            color: Color(0xFF6B7280),
                          ),
                        ),
                      ],
                    ),
                  )
                : _filteredFamilies.isEmpty
                    ? Center(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(
                              Icons.family_restroom,
                              size: 64.w,
                              color: Color(0xFFD1D5DB),
                            ),
                            SizedBox(height: 16.h),
                            Text(
                              _searchQuery.isEmpty
                                  ? 'No families found'
                                  : 'No families match your search',
                              style: TextStyle(
                                fontSize: 16.sp,
                                fontWeight: FontWeight.w500,
                                color: Color(0xFF6B7280),
                              ),
                            ),
                            SizedBox(height: 8.h),
                            Text(
                              _searchQuery.isEmpty
                                  ? 'Families will appear here once submitted'
                                  : 'Try adjusting your search terms',
                              style: TextStyle(
                                fontSize: 14.sp,
                                color: Color(0xFF9CA3AF),
                              ),
                            ),
                          ],
                        ),
                      )
                    : RefreshIndicator(
                        onRefresh: _loadFamiliesFromFirebase,
                        color: Color(0xFF3B82F6),
                        child: ListView.builder(
                          padding: EdgeInsets.only(bottom: 20.h),
                          itemCount: _filteredFamilies.length,
                          itemBuilder: (context, index) {
                            return _buildFamilyCard(_filteredFamilies[index], index);
                          },
                        ),
                      ),
          ),
        ],
      ),
    );
  }
}