import 'package:flutter/material.dart';

class CompostTipsScreen extends StatelessWidget {
  const CompostTipsScreen({super.key});

  final List<Map<String, String>> tips = const [
    {
      'title': 'Tip 1: Balance Greens & Browns',
      'description': 'Learn how to maintain a healthy carbon-nitrogen ratio in your compost pile.',
      'image': 'https://via.placeholder.com/400x200.png?text=Tip+1'
    },
    {
      'title': 'Tip 2: What NOT to Compost',
      'description': 'Avoid meat, dairy, and oily foods to keep your compost safe and clean.',
      'image': 'https://via.placeholder.com/400x200.png?text=Tip+2'
    },
    {
      'title': 'Tip 3: Keep It Moist',
      'description': 'Ensure your compost stays damp like a wrung-out sponge for effective breakdown.',
      'image': 'https://via.placeholder.com/400x200.png?text=Tip+3'
    },
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Composting Tips and News')),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Learn how to improve your composting practices',
              style: TextStyle(fontSize: 16, color: Colors.black87),
            ),
            const SizedBox(height: 16),
            Expanded(
              child: ListView.builder(
                itemCount: tips.length,
                itemBuilder: (context, index) {
                  final tip = tips[index];
                  return Container(
                    margin: const EdgeInsets.only(bottom: 16),
                    decoration: BoxDecoration(
                      border: Border.all(color: Colors.grey.shade300),
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        ClipRRect(
                          borderRadius: const BorderRadius.vertical(top: Radius.circular(12)),
                          child: Image.network(tip['image']!, height: 180, width: double.infinity, fit: BoxFit.cover),
                        ),
                        Padding(
                          padding: const EdgeInsets.all(12),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(tip['title']!, style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                              const SizedBox(height: 8),
                              Text(tip['description']!, style: const TextStyle(fontSize: 14)),
                              const SizedBox(height: 8),
                              Align(
                                alignment: Alignment.centerRight,
                                child: TextButton(
                                  onPressed: () {
                                    // TODO: Navigate to full article screen
                                  },
                                  child: const Text('Read More'),
                                ),
                              ),
                            ],
                          ),
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
    );
  }
}
