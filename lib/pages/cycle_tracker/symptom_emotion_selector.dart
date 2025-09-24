import 'package:flutter/material.dart';

class SymptomEmotionSelector extends StatelessWidget {
  final List<String> symptoms;
  final Map<String, bool> selectedSymptoms;
  final ValueChanged<Map<String, bool>> onSelectionChanged;

  SymptomEmotionSelector({
    required this.symptoms,
    required this.selectedSymptoms,
    required this.onSelectionChanged,
  });

  @override
  Widget build(BuildContext context) {
    return Wrap(
      spacing: 8,
      children: symptoms.map((symptom) {
        final selected = selectedSymptoms[symptom] ?? false;
        return FilterChip(
          label: Text(symptom),
          selected: selected,
          onSelected: (val) {
            final newSelected = Map<String, bool>.from(selectedSymptoms);
            if (val)
              newSelected[symptom] = true;
            else
              newSelected.remove(symptom);
            onSelectionChanged(newSelected);
          },
        );
      }).toList(),
    );
  }
}
