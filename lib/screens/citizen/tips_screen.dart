import 'package:flutter/material.dart';

class CitizenTipsScreen extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Waste Management Tips',
            style: Theme.of(context).textTheme.headlineMedium,
          ),
          const SizedBox(height: 24),
          _buildTipCard(
            context,
            title: 'Reduce',
            tips: [
              'Buy products with minimal packaging',
              'Use reusable bags, containers, and water bottles',
              'Plan meals to avoid food waste',
              'Choose durable products over disposable ones',
            ],
            icon: Icons.remove_circle_outline,
          ),
          const SizedBox(height: 16),
          _buildTipCard(
            context,
            title: 'Reuse',
            tips: [
              'Repair items instead of replacing them',
              'Donate usable items',
              'Use cloth napkins instead of paper',
              'Repurpose glass jars and containers',
            ],
            icon: Icons.recycling,
          ),
          const SizedBox(height: 16),
          _buildTipCard(
            context,
            title: 'Recycle',
            tips: [
              'Learn local recycling guidelines',
              'Clean containers before recycling',
              'Separate different types of materials',
              'Check for recycling symbols on products',
            ],
            icon: Icons.restart_alt,
          ),
          const SizedBox(height: 16),
          _buildTipCard(
            context,
            title: 'Composting',
            tips: [
              'Start with fruit and vegetable scraps',
              'Add brown materials like leaves and paper',
              'Keep compost moist but not wet',
              'Turn compost regularly for aeration',
            ],
            icon: Icons.eco,
          ),
        ],
      ),
    );
  }

  Widget _buildTipCard(
    BuildContext context, {
    required String title,
    required List<String> tips,
    required IconData icon,
  }) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(icon, size: 24, color: Theme.of(context).primaryColor),
                const SizedBox(width: 8),
                Text(
                  title,
                  style: Theme.of(context).textTheme.titleLarge,
                ),
              ],
            ),
            const SizedBox(height: 16),
            ...tips.map((tip) => Padding(
                  padding: const EdgeInsets.only(bottom: 8.0),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Icon(Icons.check_circle, size: 16),
                      const SizedBox(width: 8),
                      Expanded(child: Text(tip)),
                    ],
                  ),
                )),
          ],
        ),
      ),
    );
  }
} 