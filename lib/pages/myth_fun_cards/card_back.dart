import 'package:flutter/material.dart';

class CardBack extends StatelessWidget {
  final dynamic card;
  final bool isMyth;
  CardBack({required this.card, required this.isMyth});

  @override
  Widget build(BuildContext context) {
    String mainText = isMyth ? card.truth : card.fact;

    return Container(
      key: ValueKey('back'),
      padding: EdgeInsets.all(24),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(16),
        color: Colors.green[50],
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            mainText,
            style: TextStyle(fontSize: 18),
            textAlign: TextAlign.center,
          ),
          SizedBox(height: 20),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              IconButton(
                  icon: Text('😲', style: TextStyle(fontSize: 24)),
                  onPressed: () {}),
              IconButton(
                  icon: Text('😡', style: TextStyle(fontSize: 24)),
                  onPressed: () {}),
              IconButton(
                  icon: Text('💡', style: TextStyle(fontSize: 24)),
                  onPressed: () {}),
            ],
          ),
          SizedBox(height: 10),
          if (isMyth)
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text("Did you believe this before? "),
                Switch(value: false, onChanged: (val) {}),
              ],
            )
          else
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text("Whoa!", style: TextStyle(fontWeight: FontWeight.bold)),
                ElevatedButton(onPressed: () {}, child: Text("Tell me more")),
              ],
            ),
        ],
      ),
    );
  }
}
