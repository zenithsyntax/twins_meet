import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:twins_meet/model/twins_model.dart';

class UpdateTwinFormData {
  TextEditingController fullNameController = TextEditingController();
  TextEditingController houseNameController = TextEditingController();
  TextEditingController postOfficeController = TextEditingController();
  TextEditingController districtController = TextEditingController();
  TextEditingController stateController = TextEditingController();
  TextEditingController countryController = TextEditingController();
  TextEditingController pincodeController = TextEditingController();
  TextEditingController phoneController = TextEditingController();

  void dispose() {
    fullNameController.dispose();
    houseNameController.dispose();
    postOfficeController.dispose();
    districtController.dispose();
    stateController.dispose();
    countryController.dispose();
    pincodeController.dispose();
    phoneController.dispose();
  }

  void populateFromTwin(Twin twin) {
    fullNameController.text = twin.fullName;
    houseNameController.text = twin.houseName;
    postOfficeController.text = twin.postOffice;
    districtController.text = twin.district;
    stateController.text = twin.state;
    countryController.text = twin.country;
    pincodeController.text = twin.pincode;
    phoneController.text = twin.phone;
  }
}

class UpdateTwinsDataPage extends StatefulWidget {
  final TwinFamily family;

  const UpdateTwinsDataPage({
    super.key,
    required this.family,
  });

  @override
  _UpdateTwinsDataPageState createState() => _UpdateTwinsDataPageState();
}

class _UpdateTwinsDataPageState extends State<UpdateTwinsDataPage> {
  List<UpdateTwinFormData> twins = [];
  final GlobalKey<FormState> _formKey = GlobalKey<FormState>();
  bool _isLoading = false;
  bool _isUpdating = false;

  // Firebase Firestore instance
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  @override
  void initState() {
    super.initState();
    _populateExistingData();
  }

  void _populateExistingData() {
    for (Twin twin in widget.family.twins) {
      UpdateTwinFormData formData = UpdateTwinFormData();
      formData.populateFromTwin(twin);
      twins.add(formData);
    }
  }

  @override
  void dispose() {
    for (var twin in twins) {
      twin.dispose();
    }
    super.dispose();
  }

  void _addTwin(int previousIndex) {
    setState(() {
      UpdateTwinFormData newTwin = UpdateTwinFormData();
      
      if (previousIndex < twins.length) {
        UpdateTwinFormData previousTwin = twins[previousIndex];
        newTwin.houseNameController.text = previousTwin.houseNameController.text;
        newTwin.postOfficeController.text = previousTwin.postOfficeController.text;
        newTwin.districtController.text = previousTwin.districtController.text;
        newTwin.stateController.text = previousTwin.stateController.text;
        newTwin.countryController.text = previousTwin.countryController.text;
        newTwin.pincodeController.text = previousTwin.pincodeController.text;
      }
      
      twins.add(newTwin);
    });
  }

  void _removeTwin(int index) {
    if (twins.length > 1) {
      setState(() {
        twins[index].dispose();
        twins.removeAt(index);
      });
    }
  }

  Widget _buildTwinForm(int index) {
    UpdateTwinFormData twin = twins[index];
    
    return Container(
      margin: EdgeInsets.symmetric(horizontal: 20.w, vertical: 8.h),
      child: Card(
        child: Padding(
          padding: EdgeInsets.all(24.w),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _buildTwinHeader(index),
              SizedBox(height: 24.h),
              
              _buildTextField(
                controller: twin.fullNameController,
                label: 'Full Name',
                icon: Icons.person_outline,
                required: true,
              ),
              SizedBox(height: 20.h),
              
              _buildTextField(
                controller: twin.houseNameController,
                label: 'House Name',
                icon: Icons.home_outlined,
                required: true,
              ),
              SizedBox(height: 20.h),
              
              _buildTextField(
                controller: twin.postOfficeController,
                label: 'Post Office',
                icon: Icons.local_post_office_outlined,
                required: true,
              ),
              SizedBox(height: 20.h),
              
              _buildTextField(
                controller: twin.districtController,
                label: 'District',
                icon: Icons.location_city_outlined,
                required: true,
              ),
              SizedBox(height: 20.h),
              
              Row(
                children: [
                  Expanded(
                    child: _buildTextField(
                      controller: twin.stateController,
                      label: 'State',
                      icon: Icons.map_outlined,
                      required: true,
                    ),
                  ),
                  SizedBox(width: 16.w),
                  Expanded(
                    child: _buildTextField(
                      controller: twin.countryController,
                      label: 'Country',
                      icon: Icons.public_outlined,
                      required: true,
                    ),
                  ),
                ],
              ),
              SizedBox(height: 20.h),
              
              Row(
                children: [
                  Expanded(
                    child: _buildTextField(
                      controller: twin.pincodeController,
                      label: 'Pincode',
                      icon: Icons.pin_drop_outlined,
                      keyboardType: TextInputType.number,
                      required: true,
                    ),
                  ),
                  SizedBox(width: 16.w),
                  Expanded(
                    child: _buildTextField(
                      controller: twin.phoneController,
                      label: 'Phone Number',
                      icon: Icons.phone_outlined,
                      keyboardType: TextInputType.phone,
                      required: true,
                    ),
                  ),
                ],
              ),
              SizedBox(height: 32.h),
              
              Center(
                child: _buildAddTwinButton(index),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildTwinHeader(int index) {
    return Row(
      children: [
        Container(
          padding: EdgeInsets.symmetric(horizontal: 12.w, vertical: 6.h),
          decoration: BoxDecoration(
            color: Color(0xFF3B82F6).withOpacity(0.1),
            borderRadius: BorderRadius.circular(20.r),
          ),
          child: Text(
            'Twin ${index + 1}',
            style: TextStyle(
              fontSize: 14.sp,
              fontWeight: FontWeight.w600,
              color: Color(0xFF6E6588)
            ),
          ),
        ),
        Spacer(),
        if (twins.length > 1)
          IconButton(
            onPressed: () => _removeTwin(index),
            icon: Icon(Icons.delete_outline, size: 20.w),
            style: IconButton.styleFrom(
              backgroundColor: Color(0xFFFEF2F2),
              foregroundColor: Color(0xFFEF4444),
              padding: EdgeInsets.all(8.w),
            ),
            tooltip: 'Remove Twin',
          ),
      ],
    );
  }

  Widget _buildTextField({
    required TextEditingController controller,
    required String label,
    required IconData icon,
    TextInputType? keyboardType,
    bool required = false,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label + (required ? ' *' : ''),
          style: TextStyle(
            fontSize: 14.sp,
            fontWeight: FontWeight.w500,
            color: Color(0xFF374151),
          ),
        ),
        SizedBox(height: 8.h),
        TextFormField(
          controller: controller,
          keyboardType: keyboardType,
          style: TextStyle(fontSize: 14.sp),
          decoration: InputDecoration(
            prefixIcon: Icon(icon, size: 20.w, color: Color(0xFF6B7280)),
            hintText: 'Enter $label',
            hintStyle: TextStyle(
              fontSize: 14.sp,
              color: Color(0xFF9CA3AF),
            ),
          ),
          validator: required
              ? (value) {
                  if (value == null || value.trim().isEmpty) {
                    return '$label is required';
                  }
                  if (label == 'Phone Number' && value.length < 10) {
                    return 'Please enter a valid phone number';
                  }
                  if (label == 'Pincode' && value.length != 6) {
                    return 'Please enter a valid pincode';
                  }
                  return null;
                }
              : null,
        ),
      ],
    );
  }

  Widget _buildAddTwinButton(int index) {
    return Container(
      width: double.infinity,
      child: ElevatedButton.icon(
        onPressed: () => _addTwin(index),
        icon: Icon(Icons.add, size: 18.w),
        label: Text('Add Another Twin'),
        style: ElevatedButton.styleFrom(
          backgroundColor: Color(0xFF416587),
          foregroundColor: Colors.white,
          shadowColor: Color(0xFF416587).withOpacity(0.3),
          elevation: 2,
        ),
      ),
    );
  }

  Widget _buildActionButtons() {
    return Container(
      width: double.infinity,
      padding: EdgeInsets.all(24.w),
      decoration: BoxDecoration(
        color: Colors.white,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10,
            offset: Offset(0, -5),
          ),
        ],
      ),
      child: Row(
        children: [
          Expanded(
            child: OutlinedButton(
              onPressed: _isUpdating ? null : () => Navigator.of(context).pop(),
              child: Text('Cancel'),
              style: OutlinedButton.styleFrom(
                foregroundColor: Color(0xFF6B7280),
                side: BorderSide(color: Color(0xFFD1D5DB)),
                padding: EdgeInsets.symmetric(vertical: 16.h),
                textStyle: TextStyle(
                  fontSize: 16.sp,
                  fontWeight: FontWeight.w600,
                ),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8.r),
                ),
              ),
            ),
          ),
          SizedBox(width: 16.w),
          Expanded(
            flex: 2,
            child: ElevatedButton(
              onPressed: _isUpdating ? null : _updateForm,
              child: _isUpdating
                  ? SizedBox(
                      height: 20.h,
                      width: 20.w,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                      ),
                    )
                  : Text('Update Data'),
              style: ElevatedButton.styleFrom(
                backgroundColor: Color(0xFF6E6588),
                foregroundColor: Colors.white,
                padding: EdgeInsets.symmetric(vertical: 16.h),
                textStyle: TextStyle(
                  fontSize: 16.sp,
                  fontWeight: FontWeight.w600,
                ),
                shadowColor: Color(0xFF1E40AF).withOpacity(0.3),
                elevation: 3,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8.r),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _updateForm() async {
    if (_formKey.currentState!.validate()) {
      setState(() {
        _isUpdating = true;
      });

      try {
        // Prepare updated data for Firebase
        List<Map<String, dynamic>> twinsData = [];
        
        for (int i = 0; i < twins.length; i++) {
          UpdateTwinFormData twin = twins[i];
          twinsData.add({
            'fullName': twin.fullNameController.text.trim(),
            'houseName': twin.houseNameController.text.trim(),
            'postOffice': twin.postOfficeController.text.trim(),
            'district': twin.districtController.text.trim(),
            'state': twin.stateController.text.trim(),
            'country': twin.countryController.text.trim(),
            'pincode': twin.pincodeController.text.trim(),
            'phone': twin.phoneController.text.trim(),
            'twinNumber': i + 1,
          });
        }

        // Update document data
        Map<String, dynamic> updatedData = {
          'twins': twinsData,
          'totalTwins': twins.length,
          'lastUpdatedAt': FieldValue.serverTimestamp(),
          'submittedAt': widget.family.submittedAt, // Keep original submission time
          'submittedBy': widget.family.submittedBy, // Keep original submitter
        };

        // Update in Firebase Firestore
        await _firestore
            .collection('twins_submissions')
            .doc(widget.family.id)
            .update(updatedData);

        print('Data updated successfully for document ID: ${widget.family.id}');
        print('Updated Twins Data: $twinsData');

        setState(() {
          _isUpdating = false;
        });

        // Show success dialog
        _showSuccessDialog();

      } catch (error) {
        setState(() {
          _isUpdating = false;
        });
        
        // Show error dialog
        _showErrorDialog(error.toString());
        print('Error updating data: $error');
      }
    }
  }

  void _showSuccessDialog() {
    showDialog(
      context: context,
      barrierDismissible: false,
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
                'Updated Successfully!',
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
                'Data for ${twins.length} twin(s) has been successfully updated in Firebase.',
                style: TextStyle(
                  fontSize: 14.sp,
                  color: Color(0xFF6B7280),
                ),
              ),
              SizedBox(height: 8.h),
              Text(
                'Document ID: ${widget.family.id}',
                style: TextStyle(
                  fontSize: 12.sp,
                  color: Color(0xFF9CA3AF),
                  fontFamily: 'monospace',
                ),
              ),
            ],
          ),
          actions: [
            ElevatedButton(
              onPressed: () {
                Navigator.of(context).pop(); // Close dialog
                Navigator.of(context).pop(true); // Return to previous page with success flag
              },
              child: Text('Done'),
              style: ElevatedButton.styleFrom(
                backgroundColor: Color(0xFF10B981),
                foregroundColor: Colors.white,
                padding: EdgeInsets.symmetric(horizontal: 24.w, vertical: 12.h),
              ),
            ),
          ],
        );
      },
    );
  }

  void _showErrorDialog(String error) {
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
                  color: Color(0xFFEF4444).withOpacity(0.1),
                  borderRadius: BorderRadius.circular(8.r),
                ),
                child: Icon(
                  Icons.error_outline,
                  color: Color(0xFFEF4444),
                  size: 24.w,
                ),
              ),
              SizedBox(width: 12.w),
              Text(
                'Update Failed',
                style: TextStyle(
                  fontSize: 18.sp,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
          content: Text(
            'Failed to update data in Firebase:\n$error',
            style: TextStyle(
              fontSize: 14.sp,
              color: Color(0xFF6B7280),
            ),
          ),
          actions: [
            ElevatedButton(
              onPressed: () {
                Navigator.of(context).pop();
              },
              child: Text('OK'),
              style: ElevatedButton.styleFrom(
                backgroundColor: Color(0xFFEF4444),
                foregroundColor: Colors.white,
                padding: EdgeInsets.symmetric(horizontal: 24.w, vertical: 12.h),
              ),
            ),
          ],
        );
      },
    );
  }

  Widget _buildInfoHeader() {
    return Container(
      width: double.infinity,
      padding: EdgeInsets.all(20.w),
      color: Color(0xFFF8FAFC),
      child: Column(
        children: [
          Row(
            children: [
              Container(
                padding: EdgeInsets.all(8.w),
                decoration: BoxDecoration(
                  color: Color(0xFF3B82F6).withOpacity(0.1),
                  borderRadius: BorderRadius.circular(8.r),
                ),
                child: Icon(
                  Icons.edit_outlined,
                  color: Color(0xFF6E6588),
                  size: 20.w,
                ),
              ),
              SizedBox(width: 12.w),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Updating ${twins.length} twin(s) data',
                      style: TextStyle(
                        fontSize: 16.sp,
                        fontWeight: FontWeight.w600,
                        color: Color(0xFF374151),
                      ),
                    ),
                    Text(
                      'Originally submitted: ${_formatDate(widget.family.submittedAt)}',
                      style: TextStyle(
                        fontSize: 12.sp,
                        color: Color(0xFF6B7280),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          SizedBox(height: 12.h),
          LinearProgressIndicator(
            value: twins.length / 10, // Adjust max as needed
            backgroundColor: Color(0xFFE5E7EB),
            valueColor: AlwaysStoppedAnimation<Color>(Color(0xFF6E6588)),
          ),
        ],
      ),
    );
  }

  String _formatDate(DateTime date) {
    return '${date.day}/${date.month}/${date.year}';
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Update Twins Data'),
        centerTitle: true,
        backgroundColor: Colors.white,
        foregroundColor: Color(0xFF374151),
        elevation: 0,
        bottom: PreferredSize(
          preferredSize: Size.fromHeight(1.0),
          child: Container(
            color: Color(0xFFE5E7EB),
            height: 1.0,
          ),
        ),
      ),
      body: Form(
        key: _formKey,
        child: Column(
          children: [
            _buildInfoHeader(),
            Expanded(
              child: ListView.builder(
                padding: EdgeInsets.only(top: 16.h, bottom: 16.h),
                itemCount: twins.length,
                itemBuilder: (context, index) => _buildTwinForm(index),
              ),
            ),
            _buildActionButtons(),
          ],
        ),
      ),
    );
  }
}