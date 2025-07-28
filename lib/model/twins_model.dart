import 'package:cloud_firestore/cloud_firestore.dart';

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

  Map<String, dynamic> toMap() {
    return {
      'twinNumber': twinNumber,
      'fullName': fullName,
      'phone': phone,
      'houseName': houseName,
      'postOffice': postOffice,
      'district': district,
      'state': state,
      'country': country,
      'pincode': pincode,
    };
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

  Map<String, dynamic> toMap() {
    return {
      'submittedAt': Timestamp.fromDate(submittedAt),
      'submittedBy': submittedBy,
      'totalTwins': totalTwins,
      'twins': twins.map((twin) => twin.toMap()).toList(),
    };
  }
}