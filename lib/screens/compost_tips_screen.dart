import 'package:flutter/material.dart';

class CompostTipsScreen extends StatelessWidget {
  const CompostTipsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("Composting Tips and News")),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              "Learn how to improve your composting practices",
              style: TextStyle(fontSize: 16),
            ),
            const SizedBox(height: 20),
            Expanded(
              child: ListView(
                children: const [
                  TipCard(
                    title: "Use balanced green and brown waste",
                    content: "Mix food scraps (green) and dry leaves (brown) to speed up composting.",
                  ),
                  TipCard(
                    title: "Turn your compost regularly",
                    content: "Aerate your compost pile every 1–2 weeks to prevent odor and speed decomposition.",
                  ),
                  TipCard(
                    title: "Keep compost moist, not wet",
                    content: "Moisture should feel like a wrung-out sponge — not too dry, not soggy.",
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class TipCard extends StatelessWidget {
  final String title;
  final String content;

  const TipCard({super.key, required this.title, required this.content});

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.symmetric(vertical: 8),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(title, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
            const SizedBox(height: 8),
            Text(content),
          ],
        ),
      ),
    );
  }
}
