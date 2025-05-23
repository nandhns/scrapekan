import 'package:flutter/material.dart';

class CompostTipsScreen extends StatelessWidget {
  final List<Map<String, dynamic>> _tips = [
    {
      'title': 'What to Compost',
      'icon': Icons.eco,
      'items': [
        'Fruit and vegetable scraps',
        'Coffee grounds and filters',
        'Tea bags',
        'Eggshells',
        'Yard trimmings',
        'Grass clippings',
        'Dry leaves',
        'Shredded paper',
      ],
    },
    {
      'title': 'What Not to Compost',
      'icon': Icons.do_not_disturb,
      'items': [
        'Meat or fish scraps',
        'Dairy products',
        'Oils or fats',
        'Diseased plants',
        'Chemically treated wood products',
        'Colored paper',
        'Pet wastes',
        'Inorganic materials',
      ],
    },
    {
      'title': 'Composting Tips',
      'icon': Icons.lightbulb,
      'items': [
        'Keep a good balance of green and brown materials',
        'Maintain proper moisture (like a wrung-out sponge)',
        'Turn your compost regularly',
        'Chop materials into smaller pieces',
        'Keep the pile at least 3 feet cubed',
        'Monitor temperature',
        'Add materials in layers',
        'Be patient - good compost takes time',
      ],
    },
  ];

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: EdgeInsets.all(16.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Composting Guide',
            style: Theme.of(context).textTheme.headlineMedium,
          ),
          SizedBox(height: 24),
          ..._tips.map((section) => _buildSection(context, section)).toList(),
        ],
      ),
    );
  }

  Widget _buildSection(BuildContext context, Map<String, dynamic> section) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Icon(section['icon'] as IconData, color: Theme.of(context).primaryColor),
            SizedBox(width: 8),
            Text(
              section['title'] as String,
              style: Theme.of(context).textTheme.titleLarge,
            ),
          ],
        ),
        SizedBox(height: 16),
        Card(
          child: Padding(
            padding: EdgeInsets.all(16.0),
            child: Column(
              children: (section['items'] as List<String>).map((item) => 
                Padding(
                  padding: EdgeInsets.symmetric(vertical: 4.0),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Icon(Icons.fiber_manual_record, size: 12, color: Theme.of(context).primaryColor),
                      SizedBox(width: 8),
                      Expanded(
                        child: Text(item),
                      ),
                    ],
                  ),
                ),
              ).toList(),
            ),
          ),
        ),
        SizedBox(height: 24),
      ],
    );
  }
}
