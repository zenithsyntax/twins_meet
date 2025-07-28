import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:twins_meet/model/twins_model.dart';
import 'package:twins_meet/pages/list_page.dart';
import 'package:twins_meet/services/url_launcher.dart';
import 'dart:io';


class TwinWidgets {
  static Widget buildSearchBar({
    required TextEditingController controller,
    required Function(String) onChanged,
    required String searchQuery,
    required VoidCallback onClear,
  }) {
    return Container(
      margin: EdgeInsets.all(20.w),
      child: TextField(
        controller: controller,
        onChanged: onChanged,
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
          suffixIcon: searchQuery.isNotEmpty
              ? IconButton(
                  onPressed: onClear,
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
            borderSide: BorderSide(color: Color(0xFF6E6588), width: 2),
          ),
        ),
      ),
    );
  }

  static Widget buildExportButton({
    required bool isExporting,
    required VoidCallback onPressed,
  }) {
    return Container(
      margin: EdgeInsets.symmetric(horizontal: 20.w, vertical: 10.h),
      child: ElevatedButton.icon(
        onPressed: isExporting ? null : onPressed,
        icon: isExporting
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
          isExporting ? 'Exporting...' : 'Export to Excel',
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

  static Widget buildLoadingWidget() {
    return Center(
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
    );
  }

  static Widget buildEmptyState({required String searchQuery}) {
    return Center(
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
            searchQuery.isEmpty
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
            searchQuery.isEmpty
                ? 'Families will appear here once submitted'
                : 'Try adjusting your search terms',
            style: TextStyle(
              fontSize: 14.sp,
              color: Color(0xFF9CA3AF),
            ),
          ),
        ],
      ),
    );
  }
}

class FamilyCard extends StatelessWidget {
  final TwinFamily family;
  final bool isExpanded;
  final VoidCallback onToggleExpanded;
  final VoidCallback onUpdate;
  final VoidCallback onDelete;
  final bool showSharedAddress;
  final String Function(DateTime) formatDate;

  const FamilyCard({
    super.key,
    required this.family,
    required this.isExpanded,
    required this.onToggleExpanded,
    required this.onUpdate,
    required this.onDelete,
    required this.showSharedAddress,
    required this.formatDate,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: EdgeInsets.symmetric(horizontal: 20.w, vertical: 8.h),
      child: Card(
        elevation: 2,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16.r),
        ),
        child: Column(
          children: [
            _buildFamilyHeader(),
            if (isExpanded) _buildFamilyDetails(),
          ],
        ),
      ),
    );
  }

  Widget _buildFamilyHeader() {
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
                  color: Color(0xFF6E6588),
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
                onPressed: onToggleExpanded,
                icon: Icon(
                  isExpanded ? Icons.expand_less : Icons.expand_more,
                  size: 24.w,
                  color: Color(0xFF6B7280),
                ),
              ),
            ],
          ),
          // SizedBox(height: 12.h),
          // Row(
          //   children: [
          //     Icon(
          //       Icons.access_time,
          //       size: 16.w,
          //       color: Color(0xFF9CA3AF),
          //     ),
          //     SizedBox(width: 8.w),
          //     Text(
          //       'Submitted: ${formatDate(family.submittedAt)}',
          //       style: TextStyle(
          //         fontSize: 12.sp,
          //         color: Color(0xFF9CA3AF),
          //       ),
          //     ),
          //   ],
          // ),
        ],
      ),
    );
  }

  Widget _buildFamilyDetails() {
    return Container(
      padding: EdgeInsets.fromLTRB(20.w, 0, 20.w, 20.w),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Divider(color: Color(0xFFE5E7EB)),
          SizedBox(height: 16.h),
          
          // Twins Details
          for (int i = 0; i < family.twins.length; i++)
            TwinDetailsWidget(
              twin: family.twins[i],
              showAddress: !showSharedAddress,
            ),
          
          // Shared Address
          if (showSharedAddress) 
            SharedAddressWidget(twin: family.twins.first),
          
          SizedBox(height: 20.h),
          
          // Action Buttons
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            children: [
              Expanded(
                child: OutlinedButton.icon(
                  onPressed: onUpdate,
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
                  onPressed: onDelete,
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
}

class TwinDetailsWidget extends StatelessWidget {
  final Twin twin;
  final bool showAddress;

  const TwinDetailsWidget({
    super.key,
    required this.twin,
    required this.showAddress,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: EdgeInsets.only(bottom: 16.h),
      padding: EdgeInsets.all(16.w),
      decoration: BoxDecoration(
        color: Color(0xFFF9FAFB),
        borderRadius: BorderRadius.circular(12.r),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: EdgeInsets.symmetric(horizontal: 8.w, vertical: 4.h),
                decoration: BoxDecoration(
                  color: Color(0xFF6E6588),
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
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Expanded(
                child: ContactButton(
                  icon: Icons.call,
                  label: 'Call',
                  color: Color(0xFF10B981),
                  onPressed: () => UrlLauncherService().launchPhone(twin.phone),
                ),
              ),
              SizedBox(width: 8.w),
              Expanded(
                child: ContactButton(
                  icon: Icons.sms,
                  label: 'message',
                  color: Color(0xFF3B82F6),
                  onPressed: () => UrlLauncherService().launchSMS(twin.phone),
                ),
              ),
              // SizedBox(width: 8.w),
              // Expanded(
              //   child: ContactButton(
              //     icon: Icons.message,
              //     label: 'WhatsApp\t',
              //     color: Color(0xFF059669),
              //     onPressed: () => UrlLauncherService().launchWhatsApp(twin.phone),
              //   ),
              // ),
            ],
          ),
          
          // Individual Address (if not shared)
          if (showAddress) ...[
            SizedBox(height: 12.h),
            AddressInfoWidget(twin: twin),
          ],
        ],
      ),
    );
  }
}

class ContactButton extends StatelessWidget {
  final IconData icon;
  final String label;
  final Color color;
  final VoidCallback onPressed;

  const ContactButton({
    super.key,
    required this.icon,
    required this.label,
    required this.color,
    required this.onPressed,
  });

  @override
  Widget build(BuildContext context) {
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
}

class SharedAddressWidget extends StatelessWidget {
  final Twin twin;

  const SharedAddressWidget({
    super.key,
    required this.twin,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: EdgeInsets.only(top: 8.h, bottom: 8.h),
      padding: EdgeInsets.all(16.w),
      decoration: BoxDecoration(
        color: Color(0xFFF0F9FF),
        borderRadius: BorderRadius.circular(12.r),
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
          AddressInfoWidget(twin: twin),
        ],
      ),
    );
  }
}

class AddressInfoWidget extends StatelessWidget {
  final Twin twin;

  const AddressInfoWidget({
    super.key,
    required this.twin,
  });

  @override
  Widget build(BuildContext context) {
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
}