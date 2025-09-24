import 'package:flutter/material.dart';

class SelfCareToolkitPage extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return ListView(
      padding: EdgeInsets.all(12),
      children: [
        ListTile(
          leading: Icon(Icons.thermostat),
          title: Text("Heat Pad Therapy"),
          subtitle: Text("Place it on your lower belly for 15-20 minutes."),
        ),
        ListTile(
          leading: Icon(Icons.self_improvement),
          title: Text("Gentle Stretching"),
          subtitle: Text("Child’s pose, cat-cow stretch, supine twist."),
        ),
        ListTile(
          leading: Icon(Icons.local_drink),
          title: Text("Hydrate"),
          subtitle: Text("Drink plenty of water to reduce bloating."),
        ),
        // Add more suggestions and audio/meditation links here
      ],
    );
  }
}
