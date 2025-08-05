import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class TwinFormData {
  TextEditingController fullNameController = TextEditingController();
  TextEditingController houseNameController = TextEditingController();
  TextEditingController postOfficeController = TextEditingController();
  TextEditingController districtController = TextEditingController();
  TextEditingController stateController = TextEditingController(text: 'Kerala');
  TextEditingController countryController = TextEditingController(text: 'India');
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
}

class ExistingTwinData {
  final String documentId;
  final String fullName;
  final String houseName;
  final String pincode;
  final String phone;
  final DateTime submittedAt;

  ExistingTwinData({
    required this.documentId,
    required this.fullName,
    required this.houseName,
    required this.pincode,
    required this.phone,
    required this.submittedAt,
  });
}

class TwinsDataForm extends StatefulWidget {
  const TwinsDataForm({super.key});

  @override
  _TwinsDataFormState createState() => _TwinsDataFormState();
}

class _TwinsDataFormState extends State<TwinsDataForm> {
  List<TwinFormData> twins = [];
  final GlobalKey<FormState> _formKey = GlobalKey<FormState>();
  bool _isLoading = false;
  bool _isCheckingDuplicates = false;

  // Firebase Firestore instance
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  @override
  void initState() {
    super.initState();
    twins.add(TwinFormData());
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
      TwinFormData newTwin = TwinFormData();
      
      if (previousIndex < twins.length) {
        TwinFormData previousTwin = twins[previousIndex];
        newTwin.houseNameController.text = previousTwin.houseNameController.text;
        newTwin.postOfficeController.text = previousTwin.postOfficeController.text;
        newTwin.districtController.text = previousTwin.districtController.text;
        newTwin.stateController.text = previousTwin.stateController.text;
        newTwin.countryController.text = previousTwin.countryController.text;
        newTwin.pincodeController.text = previousTwin.pincodeController.text;
        newTwin.phoneController.text = previousTwin.phoneController.text;
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

  // Check for existing data in Firebase
  Future<List<ExistingTwinData>> _checkForExistingData() async {
    List<ExistingTwinData> existingData = [];
    
    try {
      for (TwinFormData twin in twins) {
        String houseName = twin.houseNameController.text.trim().toLowerCase();
        String pincode = twin.pincodeController.text.trim();
        String phone = twin.phoneController.text.trim();

        // Query Firebase for existing data with same house name, pincode, and phone
        QuerySnapshot querySnapshot = await _firestore
            .collection('twins_submissions')
            .get();

        for (QueryDocumentSnapshot doc in querySnapshot.docs) {
          Map<String, dynamic> data = doc.data() as Map<String, dynamic>;
          
          if (data['twins'] != null) {
            List<dynamic> twinsInDoc = data['twins'];
            
            for (var existingTwin in twinsInDoc) {
              String existingHouseName = (existingTwin['houseName'] ?? '').toString().toLowerCase();
              String existingPincode = (existingTwin['pincode'] ?? '').toString();
              String existingPhone = (existingTwin['phone'] ?? '').toString();
              
              // Check if house name, pincode, and phone match
              if (existingHouseName == houseName && 
                  existingPincode == pincode && 
                  existingPhone == phone) {
                
                DateTime submittedAt = DateTime.now();
                if (data['submittedAt'] != null) {
                  submittedAt = (data['submittedAt'] as Timestamp).toDate();
                }
                
                existingData.add(ExistingTwinData(
                  documentId: doc.id,
                  fullName: existingTwin['fullName'] ?? '',
                  houseName: existingTwin['houseName'] ?? '',
                  pincode: existingPincode,
                  phone: existingPhone,
                  submittedAt: submittedAt,
                ));
              }
            }
          }
        }
      }
    } catch (e) {
      print('Error checking for existing data: $e');
    }
    
    return existingData;
  }

  // Show existing data popup
  void _showExistingDataDialog(List<ExistingTwinData> existingData) {
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
                  color: const Color(0xFFEAB308).withOpacity(0.1),
                  borderRadius: BorderRadius.circular(8.r),
                ),
                child: Icon(
                  Icons.warning_outlined,
                  color: const Color(0xFFEAB308),
                  size: 24.w,
                ),
              ),
              SizedBox(width: 12.w),
              Expanded(
                child: Text(
                  'Duplicate Data Found',
                  style: TextStyle(
                    fontSize: 18.sp,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ],
          ),
          content: Container(
            width: double.maxFinite,
            constraints: BoxConstraints(maxHeight: 400.h),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Text(
                //   'Found ${existingData.length} existing record(s) with similar data:',
                //   style: TextStyle(
                //     fontSize: 14.sp,
                //     color: const Color(0xFF6B7280),
                //   ),
                // ),
                SizedBox(height: 16.h),
                Flexible(
                  child: ListView.builder(
                    shrinkWrap: true,
                    itemCount: existingData.length,
                    itemBuilder: (context, index) {
                      ExistingTwinData data = existingData[index];
                      return Container(
                        margin: EdgeInsets.only(bottom: 12.h),
                        padding: EdgeInsets.all(12.w),
                        decoration: BoxDecoration(
                          border: Border.all(color: const Color(0xFFE5E7EB)),
                          borderRadius: BorderRadius.circular(8.r),
                          color: const Color(0xFFF9FAFB),
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              children: [
                                Icon(Icons.person, size: 16.w, color: const Color(0xFF6B7280)),
                                SizedBox(width: 8.w),
                                Expanded(
                                  child: Text(
                                    data.fullName,
                                    style: TextStyle(
                                      fontSize: 14.sp,
                                      fontWeight: FontWeight.w600,
                                      color: const Color(0xFF374151),
                                    ),
                                  ),
                                ),
                              ],
                            ),
                            SizedBox(height: 8.h),
                            Row(
                              children: [
                                Icon(Icons.home, size: 16.w, color: const Color(0xFF6B7280)),
                                SizedBox(width: 8.w),
                                Expanded(
                                  child: Text(
                                    data.houseName,
                                    style: TextStyle(
                                      fontSize: 12.sp,
                                      color: const Color(0xFF6B7280),
                                    ),
                                  ),
                                ),
                              ],
                            ),
                            SizedBox(height: 4.h),
                            Row(
                              children: [
                                Icon(Icons.pin_drop, size: 16.w, color: const Color(0xFF6B7280)),
                                SizedBox(width: 8.w),
                                Text(
                                  data.pincode,
                                  style: TextStyle(
                                    fontSize: 12.sp,
                                    color: const Color(0xFF6B7280),
                                  ),
                                ),
                                SizedBox(width: 16.w),
                                Icon(Icons.phone, size: 16.w, color: const Color(0xFF6B7280)),
                                SizedBox(width: 8.w),
                                Text(
                                  data.phone,
                                  style: TextStyle(
                                    fontSize: 12.sp,
                                    color: const Color(0xFF6B7280),
                                  ),
                                ),
                              ],
                            ),
                            SizedBox(height: 4.h),
                            Row(
                              children: [
                                Icon(Icons.access_time, size: 16.w, color: const Color(0xFF6B7280)),
                                SizedBox(width: 8.w),
                                Text(
                                  'Submitted: ${_formatDate(data.submittedAt)}',
                                  style: TextStyle(
                                    fontSize: 11.sp,
                                    color: const Color(0xFF9CA3AF),
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ),
                      );
                    },
                  ),
                ),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.of(context).pop();
              },
              child: Text(
                'Cancel',
                style: TextStyle(
                  fontSize: 14.sp,
                  fontWeight: FontWeight.w500,
                  color: const Color(0xFF6B7280),
                ),
              ),
            ),
            ElevatedButton(
              onPressed: () {
                Navigator.of(context).pop();
                _proceedWithSubmission();
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFFEAB308),
                foregroundColor: Colors.white,
                padding: EdgeInsets.symmetric(horizontal: 24.w, vertical: 12.h),
              ),
              child: Text('Submit Anyway'),
            ),
          ],
        );
      },
    );
  }

  String _formatDate(DateTime date) {
    return '${date.day}/${date.month}/${date.year} ${date.hour}:${date.minute.toString().padLeft(2, '0')}';
  }

  Future<void> _proceedWithSubmission() async {
    setState(() {
      _isLoading = true;
    });

    try {
      // Prepare data for Firebase
      List<Map<String, dynamic>> twinsData = [];
      
      for (int i = 0; i < twins.length; i++) {
        TwinFormData twin = twins[i];
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

      // Create a document with timestamp and twins data
      Map<String, dynamic> submissionData = {
        'twins': twinsData,
        'totalTwins': twins.length,
        'submittedAt': FieldValue.serverTimestamp(),
        'submittedBy': 'user_id', // Replace with actual user ID if you have authentication
      };

      // Save to Firebase Firestore
      DocumentReference docRef = await _firestore
          .collection('twins_submissions')
          .add(submissionData);

      print('Data saved with ID: ${docRef.id}');
      print('Twins Data: $twinsData');

      setState(() {
        _isLoading = false;
      });

      // Show success dialog
      _showSuccessDialog(docRef.id);

    } catch (error) {
      setState(() {
        _isLoading = false;
      });
      
      // Show error dialog
      _showErrorDialog(error.toString());
      print('Error saving data: $error');
    }
  }

  Future<void> _submitForm() async {
    if (_formKey.currentState!.validate()) {
      setState(() {
        _isCheckingDuplicates = true;
      });

      // Check for existing data first
      List<ExistingTwinData> existingData = await _checkForExistingData();
      
      setState(() {
        _isCheckingDuplicates = false;
      });

      if (existingData.isNotEmpty) {
        // Show duplicate data dialog
        _showExistingDataDialog(existingData);
      } else {
        // No duplicates found, proceed with submission
        _proceedWithSubmission();
      }
    }
  }

  Widget _buildTwinForm(int index) {
    TwinFormData twin = twins[index];
    
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
            color: const Color(0xFF3B82F6).withOpacity(0.1),
            borderRadius: BorderRadius.circular(20.r),
          ),
          child: Text(
            'Twin ${index + 1}',
            style: TextStyle(
              fontSize: 14.sp,
              fontWeight: FontWeight.w600,
              color: const Color(0xFF6E6588),
            ),
          ),
        ),
        const Spacer(),
        if (twins.length > 1)
          IconButton(
            onPressed: () => _removeTwin(index),
            icon: Icon(Icons.delete_outline, size: 20.w),
            style: IconButton.styleFrom(
              backgroundColor: const Color(0xFFFEF2F2),
              foregroundColor: const Color(0xFFEF4444),
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
            color: const Color(0xFF374151),
          ),
        ),
        SizedBox(height: 8.h),
        TextFormField(
          controller: controller,
          keyboardType: keyboardType,
          style: TextStyle(fontSize: 14.sp),
          decoration: InputDecoration(
            prefixIcon: Icon(icon, size: 20.w, color: const Color(0xFF6B7280)),
            hintText: 'Enter $label',
            hintStyle: TextStyle(
              fontSize: 14.sp,
              color: const Color(0xFF9CA3AF),
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
    return SizedBox(
      width: double.infinity,
      child: ElevatedButton.icon(
        onPressed: () => _addTwin(index),
        icon: Icon(Icons.add, size: 18.w),
        label: const Text('Add Another Twin'),
        style: ElevatedButton.styleFrom(
          backgroundColor: const Color(0xFF416587),
          foregroundColor: Colors.white,
          shadowColor: const Color(0xFF10B981).withOpacity(0.3),
          elevation: 2,
        ),
      ),
    );
  }

  Widget _buildSubmitButton() {
    return Container(
      width: double.infinity,
      padding: EdgeInsets.all(24.w),
      decoration: BoxDecoration(
        color: Colors.white,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10,
            offset: const Offset(0, -5),
          ),
        ],
      ),
      child: ElevatedButton(
        onPressed: (_isLoading || _isCheckingDuplicates) ? null : _submitForm,
        style: ElevatedButton.styleFrom(
          backgroundColor: const Color(0xFF6E6588),
          foregroundColor: Colors.white,
          padding: EdgeInsets.symmetric(vertical: 16.h),
          textStyle: TextStyle(
            fontSize: 16.sp,
            fontWeight: FontWeight.w600,
          ),
          shadowColor: const Color(0xFF1E40AF).withOpacity(0.3),
          elevation: 3,
        ),
        child: (_isLoading || _isCheckingDuplicates)
            ? SizedBox(
                height: 20.h,
                width: 20.w,
                child: CircularProgressIndicator(
                  strokeWidth: 2,
                  valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                ),
              )
            : Text(_isCheckingDuplicates ? 'Checking for duplicates...' : 'Submit All Data'),
      ),
    );
  }

  void _showSuccessDialog(String documentId) {
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
                  color: const Color(0xFF10B981).withOpacity(0.1),
                  borderRadius: BorderRadius.circular(8.r),
                ),
                child: Icon(
                  Icons.check_circle_outline,
                  color: const Color(0xFF10B981),
                  size: 24.w,
                ),
              ),
              SizedBox(width: 12.w),
              Text(
                'Success!',
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
                'Data for ${twins.length} twin(s) has been successfully saved to Firebase.',
                style: TextStyle(
                  fontSize: 14.sp,
                  color: const Color(0xFF6B7280),
                ),
              ),
              SizedBox(height: 8.h),
              Text(
                'Document ID: $documentId',
                style: TextStyle(
                  fontSize: 12.sp,
                  color: const Color(0xFF9CA3AF),
                  fontFamily: 'monospace',
                ),
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.of(context).pop();
                // Reset form
                setState(() {
                  for (var twin in twins) {
                    twin.dispose();
                  }
                  twins.clear();
                  twins.add(TwinFormData());
                });
              },
              child: Text(
                'Add More',
                style: TextStyle(
                  fontSize: 14.sp,
                  fontWeight: FontWeight.w500,
                  color: const Color(0xFF6B7280),
                ),
              ),
            ),
            ElevatedButton(
              onPressed: () {
                Navigator.pop(context);
                Navigator.of(context).pop(true);
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF10B981),
                foregroundColor: Colors.white,
                padding: EdgeInsets.symmetric(horizontal: 24.w, vertical: 12.h),
              ),
              child: Text('Done'),
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
                  color: const Color(0xFFEF4444).withOpacity(0.1),
                  borderRadius: BorderRadius.circular(8.r),
                ),
                child: Icon(
                  Icons.error_outline,
                  color: const Color(0xFFEF4444),
                  size: 24.w,
                ),
              ),
              SizedBox(width: 12.w),
              Text(
                'Error',
                style: TextStyle(
                  fontSize: 18.sp,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
          content: Text(
            'Failed to save data to Firebase:\n$error',
            style: TextStyle(
              fontSize: 14.sp,
              color: const Color(0xFF6B7280),
            ),
          ),
          actions: [
            ElevatedButton(
              onPressed: () {
                Navigator.of(context).pop();
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFFEF4444),
                foregroundColor: Colors.white,
                padding: EdgeInsets.symmetric(horizontal: 24.w, vertical: 12.h),
              ),
              child: Text('OK'),
            ),
          ],
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Twins Data'),
        centerTitle: true,
        backgroundColor: const Color(0xFF6E6588),
      ),
      body: Form(
        key: _formKey,
        child: Column(
          children: [
            Container(
              width: double.infinity,
              padding: EdgeInsets.all(20.w),
              color: Colors.white,
              child: Column(
                children: [
                  Text(
                    'Collecting data for ${twins.length} twin(s)',
                    style: TextStyle(
                      fontSize: 16.sp,
                      fontWeight: FontWeight.w500,
                      color: const Color(0xFF374151),
                    ),
                  ),
                  SizedBox(height: 8.h),
                  LinearProgressIndicator(
                    value: twins.length / 5, 
                    backgroundColor: const Color(0xFFE5E7EB),
                    valueColor: const AlwaysStoppedAnimation<Color>(Color(0xFF6E6588)),
                  ),
                ],
              ),
            ),
            Expanded(
              child: ListView.builder(
                padding: EdgeInsets.only(top: 16.h, bottom: 16.h),
                itemCount: twins.length,
                itemBuilder: (context, index) => _buildTwinForm(index),
              ),
            ),
            _buildSubmitButton(),
          ],
        ),
      ),
    );
  }
}