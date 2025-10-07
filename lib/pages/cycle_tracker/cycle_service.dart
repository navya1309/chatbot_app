import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'cycle_data_model.dart';

class CycleService {
  static final CycleService _instance = CycleService._internal();
  factory CycleService() => _instance;
  CycleService._internal();

  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;

  String get _userId => _auth.currentUser?.uid ?? '';

  // Save period log
  Future<void> savePeriodLog(PeriodLog log) async {
    try {
      if (_userId.isEmpty) {
        print('ERROR: savePeriodLog - User not logged in');
        throw Exception('User not logged in');
      }

      print(
          'DEBUG: Saving period log - Start: ${log.startDate}, End: ${log.endDate}');
      await _firestore
          .collection('users')
          .doc(_userId)
          .collection('period_logs')
          .doc(log.id)
          .set(log.toJson());

      print('DEBUG: Period log saved successfully with ID: ${log.id}');
    } catch (e, stackTrace) {
      print('ERROR: savePeriodLog failed - $e');
      print('STACK TRACE: $stackTrace');
      rethrow;
    }
  }

  // Get all period logs
  Future<List<PeriodLog>> getAllPeriodLogs() async {
    try {
      if (_userId.isEmpty) {
        print('DEBUG: getAllPeriodLogs - User ID is empty');
        return [];
      }

      print('DEBUG: Fetching all period logs for user: $_userId');
      final snapshot = await _firestore
          .collection('users')
          .doc(_userId)
          .collection('period_logs')
          .orderBy('startDate', descending: true)
          .get();

      print('DEBUG: Retrieved ${snapshot.docs.length} period logs');
      return snapshot.docs
          .map((doc) => PeriodLog.fromJson({...doc.data(), 'id': doc.id}))
          .toList();
    } catch (e, stackTrace) {
      print('ERROR: getAllPeriodLogs failed - $e');
      print('STACK TRACE: $stackTrace');
      return [];
    }
  }

  // Get period logs within a date range
  Future<List<PeriodLog>> getPeriodLogsInRange(
      DateTime start, DateTime end) async {
    try {
      if (_userId.isEmpty) {
        print('DEBUG: getPeriodLogsInRange - User ID is empty');
        return [];
      }

      print('DEBUG: Fetching period logs from $start to $end');
      final snapshot = await _firestore
          .collection('users')
          .doc(_userId)
          .collection('period_logs')
          .where('startDate', isGreaterThanOrEqualTo: Timestamp.fromDate(start))
          .where('startDate', isLessThanOrEqualTo: Timestamp.fromDate(end))
          .orderBy('startDate', descending: true)
          .get();

      print('DEBUG: Retrieved ${snapshot.docs.length} period logs in range');
      return snapshot.docs
          .map((doc) => PeriodLog.fromJson({...doc.data(), 'id': doc.id}))
          .toList();
    } catch (e, stackTrace) {
      print('ERROR: getPeriodLogsInRange failed - $e');
      print('STACK TRACE: $stackTrace');
      return [];
    }
  }

  // Calculate average cycle length
  Future<int> getAverageCycleLength() async {
    try {
      print('DEBUG: Calculating average cycle length');
      final logs = await getAllPeriodLogs();
      if (logs.length < 2) {
        print('DEBUG: Not enough data for calculation, using default: 28 days');
        return 28; // Default cycle length
      }

      List<int> cycleLengths = [];
      for (int i = 0; i < logs.length - 1; i++) {
        int days = logs[i].startDate.difference(logs[i + 1].startDate).inDays;
        if (days > 0 && days < 60) {
          // Filter out invalid data
          cycleLengths.add(days);
        }
      }

      if (cycleLengths.isEmpty) {
        print('DEBUG: No valid cycle lengths found, using default: 28 days');
        return 28;
      }

      int sum = cycleLengths.reduce((a, b) => a + b);
      int average = (sum / cycleLengths.length).round();
      print('DEBUG: Average cycle length calculated: $average days');
      return average;
    } catch (e, stackTrace) {
      print('ERROR: getAverageCycleLength failed - $e');
      print('STACK TRACE: $stackTrace');
      return 28;
    }
  }

  // Calculate average period duration
  Future<int> getAveragePeriodDuration() async {
    try {
      print('DEBUG: Calculating average period duration');
      final logs = await getAllPeriodLogs();
      if (logs.isEmpty) {
        print('DEBUG: No logs found, using default duration: 5 days');
        return 5; // Default period duration
      }

      List<int> durations = [];
      for (var log in logs) {
        if (log.endDate != null) {
          int days = log.endDate!.difference(log.startDate).inDays + 1;
          if (days > 0 && days < 15) {
            // Filter out invalid data
            durations.add(days);
          }
        }
      }

      if (durations.isEmpty) {
        print('DEBUG: No valid durations found, using default: 5 days');
        return 5;
      }

      int sum = durations.reduce((a, b) => a + b);
      int average = (sum / durations.length).round();
      print('DEBUG: Average period duration calculated: $average days');
      return average;
    } catch (e, stackTrace) {
      print('ERROR: getAveragePeriodDuration failed - $e');
      print('STACK TRACE: $stackTrace');
      return 5;
    }
  }

  // Predict next period
  Future<PeriodPrediction> predictNextPeriod() async {
    try {
      print('DEBUG: Predicting next period');
      final logs = await getAllPeriodLogs();

      if (logs.isEmpty) {
        print('DEBUG: No period logs found, returning default prediction');
        return PeriodPrediction(
          predictedStartDate: DateTime.now().add(const Duration(days: 28)),
          predictedEndDate: DateTime.now().add(const Duration(days: 33)),
          ovulationDate: DateTime.now().add(const Duration(days: 14)),
          pmsStartDate: DateTime.now().add(const Duration(days: 24)),
          confidence: 0.0,
        );
      }

      int avgCycleLength = await getAverageCycleLength();
      int avgPeriodDuration = await getAveragePeriodDuration();

      print(
          'DEBUG: Using avg cycle length: $avgCycleLength, avg duration: $avgPeriodDuration');

      // Get last period start date
      DateTime lastPeriodStart = logs.first.startDate;

      // Calculate next period
      DateTime nextPeriodStart =
          lastPeriodStart.add(Duration(days: avgCycleLength));
      DateTime nextPeriodEnd =
          nextPeriodStart.add(Duration(days: avgPeriodDuration - 1));

      // Calculate ovulation (typically 14 days before next period)
      DateTime ovulationDate =
          nextPeriodStart.subtract(const Duration(days: 14));

      // Calculate PMS start (typically 5-7 days before period)
      DateTime pmsStartDate = nextPeriodStart.subtract(const Duration(days: 5));

      // Calculate confidence based on cycle regularity
      double confidence = _calculatePredictionConfidence(logs);

      print(
          'DEBUG: Next period predicted - Start: $nextPeriodStart, Confidence: $confidence');
      return PeriodPrediction(
        predictedStartDate: nextPeriodStart,
        predictedEndDate: nextPeriodEnd,
        ovulationDate: ovulationDate,
        pmsStartDate: pmsStartDate,
        confidence: confidence,
      );
    } catch (e, stackTrace) {
      print('ERROR: predictNextPeriod failed - $e');
      print('STACK TRACE: $stackTrace');
      return PeriodPrediction(
        predictedStartDate: DateTime.now().add(const Duration(days: 28)),
        predictedEndDate: DateTime.now().add(const Duration(days: 33)),
        ovulationDate: DateTime.now().add(const Duration(days: 14)),
        pmsStartDate: DateTime.now().add(const Duration(days: 24)),
        confidence: 0.0,
      );
    }
  }

  // Get cycle phase for today
  Future<CyclePhase> getCurrentCyclePhase() async {
    try {
      print('DEBUG: Determining current cycle phase');
      final logs = await getAllPeriodLogs();

      if (logs.isEmpty) {
        print('DEBUG: No logs found, phase unknown');
        return CyclePhase.unknown;
      }

      DateTime today = DateTime.now();
      PeriodLog? currentOrLastPeriod;

      // Check if currently on period
      for (var log in logs) {
        if (log.endDate != null) {
          if (today.isAfter(log.startDate.subtract(const Duration(days: 1))) &&
              today.isBefore(log.endDate!.add(const Duration(days: 1)))) {
            return CyclePhase.menstruation;
          }
        } else if (isSameDay(today, log.startDate)) {
          return CyclePhase.menstruation;
        }
      }

      // Calculate based on last period
      currentOrLastPeriod = logs.first;
      int daysSinceLastPeriod =
          today.difference(currentOrLastPeriod.startDate).inDays;
      int avgCycleLength = await getAverageCycleLength();

      if (daysSinceLastPeriod <= 7) {
        print('DEBUG: Current phase: Menstruation');
        return CyclePhase.menstruation;
      } else if (daysSinceLastPeriod <= 13) {
        print('DEBUG: Current phase: Follicular');
        return CyclePhase.follicular;
      } else if (daysSinceLastPeriod <= 16) {
        print('DEBUG: Current phase: Ovulation');
        return CyclePhase.ovulation;
      } else if (daysSinceLastPeriod <= avgCycleLength - 2) {
        print('DEBUG: Current phase: Luteal');
        return CyclePhase.luteal;
      } else {
        print('DEBUG: Current phase: Premenstrual');
        return CyclePhase.premenstrual;
      }
    } catch (e, stackTrace) {
      print('ERROR: getCurrentCyclePhase failed - $e');
      print('STACK TRACE: $stackTrace');
      return CyclePhase.unknown;
    }
  }

  double _calculatePredictionConfidence(List<PeriodLog> logs) {
    if (logs.length < 2) return 0.3;
    if (logs.length < 3) return 0.5;

    // Calculate cycle length variations
    List<int> cycleLengths = [];
    for (int i = 0; i < logs.length - 1 && i < 6; i++) {
      int days = logs[i].startDate.difference(logs[i + 1].startDate).inDays;
      if (days > 0 && days < 60) {
        cycleLengths.add(days);
      }
    }

    if (cycleLengths.isEmpty) return 0.3;

    // Calculate standard deviation
    double mean = cycleLengths.reduce((a, b) => a + b) / cycleLengths.length;
    double variance = cycleLengths
            .map((x) => (x - mean) * (x - mean))
            .reduce((a, b) => a + b) /
        cycleLengths.length;
    double stdDev = variance < 0 ? 0 : variance;

    // Lower standard deviation = higher confidence
    if (stdDev <= 2) return 0.9;
    if (stdDev <= 4) return 0.8;
    if (stdDev <= 6) return 0.7;
    if (stdDev <= 8) return 0.6;
    return 0.5;
  }

  bool isSameDay(DateTime date1, DateTime date2) {
    return date1.year == date2.year &&
        date1.month == date2.month &&
        date1.day == date2.day;
  }

  // Get days for calendar display
  Future<Map<String, List<DateTime>>> getCalendarDays(DateTime month) async {
    try {
      print('DEBUG: Getting calendar days for ${month.month}/${month.year}');
      final prediction = await predictNextPeriod();
      final logs = await getPeriodLogsInRange(
        DateTime(month.year, month.month, 1),
        DateTime(month.year, month.month + 1, 0),
      );

      List<DateTime> periodDays = [];
      List<DateTime> predictedPeriodDays = [];
      List<DateTime> ovulationDays = [];
      List<DateTime> pmsDays = [];

      // Add logged period days
      for (var log in logs) {
        DateTime current = log.startDate;
        DateTime end =
            log.endDate ?? log.startDate.add(const Duration(days: 5));

        while (current.isBefore(end.add(const Duration(days: 1)))) {
          if (current.month == month.month && current.year == month.year) {
            periodDays.add(current);
          }
          current = current.add(const Duration(days: 1));
        }
      }

      // Add predicted period days
      if (prediction.predictedStartDate.month == month.month &&
          prediction.predictedStartDate.year == month.year) {
        DateTime current = prediction.predictedStartDate;
        while (current.isBefore(
            prediction.predictedEndDate.add(const Duration(days: 1)))) {
          predictedPeriodDays.add(current);
          current = current.add(const Duration(days: 1));
        }
      }

      // Add ovulation window (3 days around ovulation)
      if (prediction.ovulationDate.month == month.month &&
          prediction.ovulationDate.year == month.year) {
        for (int i = -1; i <= 1; i++) {
          ovulationDays.add(prediction.ovulationDate.add(Duration(days: i)));
        }
      }

      // Add PMS days (5 days before period)
      if (prediction.pmsStartDate.month == month.month &&
          prediction.pmsStartDate.year == month.year) {
        DateTime current = prediction.pmsStartDate;
        while (current.isBefore(prediction.predictedStartDate)) {
          pmsDays.add(current);
          current = current.add(const Duration(days: 1));
        }
      }

      print(
          'DEBUG: Calendar data prepared - Period: ${periodDays.length}, Predicted: ${predictedPeriodDays.length}, Ovulation: ${ovulationDays.length}, PMS: ${pmsDays.length}');
      return {
        'period': periodDays,
        'predicted': predictedPeriodDays,
        'ovulation': ovulationDays,
        'pms': pmsDays,
      };
    } catch (e, stackTrace) {
      print('ERROR: getCalendarDays failed - $e');
      print('STACK TRACE: $stackTrace');
      return {
        'period': <DateTime>[],
        'predicted': <DateTime>[],
        'ovulation': <DateTime>[],
        'pms': <DateTime>[],
      };
    }
  }
}

enum CyclePhase {
  menstruation,
  follicular,
  ovulation,
  luteal,
  premenstrual,
  unknown,
}
