import 'package:flutter/material.dart';
import 'symptom_emotion_selector.dart';

class CycleLogForm extends StatefulWidget {
  @override
  _CycleLogFormState createState() => _CycleLogFormState();
}

class _CycleLogFormState extends State<CycleLogForm> {
  DateTime? periodStart;
  DateTime? periodEnd;
  Map<String, bool> loggedSymptoms = {};

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
      padding: EdgeInsets.all(12),
      child: Column(
        children: [
          ListTile(
            title: Text('Period Start Date'),
            trailing: Text(periodStart == null
                ? 'Select'
                : periodStart!.toLocal().toString().split(' ')[0]),
            onTap: () =>
                _pickDate((date) => setState(() => periodStart = date)),
          ),
          ListTile(
            title: Text('Period End Date'),
            trailing: Text(periodEnd == null
                ? 'Select'
                : periodEnd!.toLocal().toString().split(' ')[0]),
            onTap: () => _pickDate((date) => setState(() => periodEnd = date)),
          ),
          SizedBox(height: 16),
          Text('Log Symptoms & Emotions',
              style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18)),
          SymptomEmotionSelector(
            symptoms: _symptoms,
            selectedSymptoms: loggedSymptoms,
            onSelectionChanged: (updated) {
              setState(() {
                loggedSymptoms = updated;
              });
            },
          ),
          SizedBox(height: 16),
          ElevatedButton(
            onPressed: () {
              // Save logic here (call backend or local storage)
              ScaffoldMessenger.of(context)
                  .showSnackBar(SnackBar(content: Text('Cycle data saved!')));
            },
            child: Text('Save Log'),
          )
        ],
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
