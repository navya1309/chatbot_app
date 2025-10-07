import 'package:flutter/material.dart';
import 'symptom_emotion_selector.dart';
import 'cycle_service.dart';
import 'cycle_data_model.dart';

class CycleLogForm extends StatefulWidget {
  @override
  _CycleLogFormState createState() => _CycleLogFormState();
}

class _CycleLogFormState extends State<CycleLogForm> {
  final CycleService _cycleService = CycleService();
  DateTime? periodStart;
  DateTime? periodEnd;
  Map<String, bool> loggedSymptoms = {};
  bool _isSaving = false;

  final _symptoms = [
    'Cramps',
    'Bloating',
    'Headaches',
    'Fatigue',
    'Nausea',
    'Breast Tenderness',
    'Irritability',
    'Sadness',
    'Brain Fog',
    'Confidence Dips',
  ];

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Track Your Cycle',
            style: TextStyle(
              fontSize: 24,
              fontWeight: FontWeight.w700,
              color: Colors.black87,
              letterSpacing: -0.5,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Log your period dates and symptoms',
            style: TextStyle(
              fontSize: 15,
              color: Colors.grey[600],
            ),
          ),
          const SizedBox(height: 24),
          Container(
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(16),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.06),
                  blurRadius: 12,
                  offset: const Offset(0, 4),
                ),
              ],
            ),
            child: Column(
              children: [
                _buildDateTile(
                  'Period Start Date',
                  periodStart,
                  Icons.play_circle_outline,
                  const Color(0xFFEF4444),
                  (date) => setState(() => periodStart = date),
                ),
                Divider(height: 1, color: Colors.grey[200]),
                _buildDateTile(
                  'Period End Date',
                  periodEnd,
                  Icons.stop_circle_outlined,
                  const Color(0xFF6366F1),
                  (date) => setState(() => periodEnd = date),
                ),
              ],
            ),
          ),
          const SizedBox(height: 24),
          const Text(
            'Log Symptoms & Emotions',
            style: TextStyle(
              fontWeight: FontWeight.w700,
              fontSize: 18,
              color: Colors.black87,
            ),
          ),
          const SizedBox(height: 12),
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(16),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.06),
                  blurRadius: 12,
                  offset: const Offset(0, 4),
                ),
              ],
            ),
            child: SymptomEmotionSelector(
              symptoms: _symptoms,
              selectedSymptoms: loggedSymptoms,
              onSelectionChanged: (updated) {
                setState(() {
                  loggedSymptoms = updated;
                });
              },
            ),
          ),
          const SizedBox(height: 24),
          SizedBox(
            width: double.infinity,
            height: 56,
            child: ElevatedButton(
              onPressed:
                  _isSaving || periodStart == null ? null : _savePeriodLog,
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF6366F1),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(16),
                ),
                elevation: 0,
              ),
              child: _isSaving
                  ? const SizedBox(
                      width: 20,
                      height: 20,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                      ),
                    )
                  : const Text(
                      'Save Log',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                        color: Colors.white,
                      ),
                    ),
            ),
          ),
          const SizedBox(height: 16),
        ],
      ),
    );
  }

  Future<void> _savePeriodLog() async {
    if (periodStart == null) {
      print('WARNING: CycleLogForm - Period start date not selected');
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please select period start date'),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    setState(() => _isSaving = true);

    try {
      print('DEBUG: CycleLogForm - Saving period log');
      final periodLog = PeriodLog(
        id: DateTime.now().millisecondsSinceEpoch.toString(),
        startDate: periodStart!,
        endDate: periodEnd,
        symptoms: loggedSymptoms,
      );

      print('DEBUG: CycleLogForm - Period log object created: ${periodLog.id}');
      await _cycleService.savePeriodLog(periodLog);
      print('DEBUG: CycleLogForm - Period log saved to Firestore');

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Cycle data saved successfully!'),
            backgroundColor: Color(0xFF10B981),
          ),
        );

        // Reset form
        setState(() {
          periodStart = null;
          periodEnd = null;
          loggedSymptoms = {};
          _isSaving = false;
        });
        print('DEBUG: CycleLogForm - Form reset successfully');
      }
    } catch (e, stackTrace) {
      print('ERROR: CycleLogForm - Failed to save period log: $e');
      print('STACK TRACE: $stackTrace');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error saving data: ${e.toString()}'),
            backgroundColor: Colors.red,
          ),
        );
        setState(() => _isSaving = false);
      }
    }
  }

  Widget _buildDateTile(
    String title,
    DateTime? date,
    IconData icon,
    Color color,
    Function(DateTime) onDateSelected,
  ) {
    return InkWell(
      onTap: () => _pickDate(onDateSelected),
      borderRadius: BorderRadius.circular(16),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Row(
          children: [
            Container(
              width: 48,
              height: 48,
              decoration: BoxDecoration(
                color: color.withOpacity(0.1),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Icon(icon, color: color, size: 24),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: const TextStyle(
                      fontSize: 15,
                      fontWeight: FontWeight.w600,
                      color: Colors.black87,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    date == null
                        ? 'Tap to select date'
                        : date.toLocal().toString().split(' ')[0],
                    style: TextStyle(
                      fontSize: 14,
                      color: date == null ? Colors.grey[500] : color,
                      fontWeight:
                          date == null ? FontWeight.w400 : FontWeight.w600,
                    ),
                  ),
                ],
              ),
            ),
            Icon(Icons.calendar_today, color: Colors.grey[400], size: 20),
          ],
        ),
      ),
    );
  }

  Future<void> _pickDate(Function(DateTime) onDateSelected) async {
    final date = await showDatePicker(
      context: context,
      initialDate: DateTime.now(),
      firstDate: DateTime(2020),
      lastDate: DateTime(DateTime.now().year + 2),
    );
    if (date != null) onDateSelected(date);
  }
}
