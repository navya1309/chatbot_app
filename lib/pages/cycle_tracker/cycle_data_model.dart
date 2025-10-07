import 'package:cloud_firestore/cloud_firestore.dart';

class PeriodLog {
  final String id;
  final DateTime startDate;
  final DateTime? endDate;
  final Map<String, bool> symptoms;
  final int? flow; // 1-5 scale
  final String? notes;

  PeriodLog({
    required this.id,
    required this.startDate,
    this.endDate,
    this.symptoms = const {},
    this.flow,
    this.notes,
  });

  Map<String, dynamic> toJson() {
    return {
      'startDate': Timestamp.fromDate(startDate),
      'endDate': endDate != null ? Timestamp.fromDate(endDate!) : null,
      'symptoms': symptoms,
      'flow': flow,
      'notes': notes,
    };
  }

  factory PeriodLog.fromJson(Map<String, dynamic> json) {
    return PeriodLog(
      id: json['id'] ?? '',
      startDate: (json['startDate'] as Timestamp).toDate(),
      endDate: json['endDate'] != null
          ? (json['endDate'] as Timestamp).toDate()
          : null,
      symptoms: Map<String, bool>.from(json['symptoms'] ?? {}),
      flow: json['flow'],
      notes: json['notes'],
    );
  }
}

class PeriodPrediction {
  final DateTime predictedStartDate;
  final DateTime predictedEndDate;
  final DateTime ovulationDate;
  final DateTime pmsStartDate;
  final double confidence; // 0.0 to 1.0

  PeriodPrediction({
    required this.predictedStartDate,
    required this.predictedEndDate,
    required this.ovulationDate,
    required this.pmsStartDate,
    required this.confidence,
  });
}
