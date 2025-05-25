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

  final List<Map<String, dynamic>> _news = [
    {
      'title': 'Pahang Launches New Community Composting Initiative',
      'date': '15 March 2024',
      'image': 'assets/images/community_composting.jpg',  // You'll need to add this image
      'summary': 'The state of Pahang has launched a new community composting initiative aimed at reducing organic waste in landfills. The program will establish composting centers in major townships, starting with Kuantan and Gambang.',
      'link': 'Read more about the initiative',
    },
    {
      'title': 'Local Schools Join Green Waste Management Program',
      'date': '10 March 2024',
      'image': 'assets/images/school_composting.jpg',  // You'll need to add this image
      'summary': 'Five schools in the Kuantan district have joined a new program to implement composting practices in their facilities. The initiative aims to educate students about sustainable waste management while reducing the schools\' environmental impact.',
      'link': 'Learn about the school program',
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
            'Composting Tips & News',
            style: Theme.of(context).textTheme.headlineMedium,
          ),
          SizedBox(height: 8),
          Text(
            'Learn how to improve your composting practices',
            style: Theme.of(context).textTheme.bodyLarge?.copyWith(
              color: Colors.grey[600],
            ),
          ),
          SizedBox(height: 24),
          Text(
            'Latest News',
            style: Theme.of(context).textTheme.titleLarge,
          ),
          SizedBox(height: 16),
          ..._buildNewsSection(context),
          SizedBox(height: 32),
          Text(
            'Composting Guidelines',
            style: Theme.of(context).textTheme.titleLarge,
          ),
          SizedBox(height: 16),
          ..._tips.map((section) => _buildSection(context, section)).toList(),
        ],
      ),
    );
  }

  List<Widget> _buildNewsSection(BuildContext context) {
    return _news.map((newsItem) => Card(
      margin: EdgeInsets.only(bottom: 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            height: 200,
            width: double.infinity,
            decoration: BoxDecoration(
              color: Colors.grey[300],
              borderRadius: BorderRadius.only(
                topLeft: Radius.circular(4),
                topRight: Radius.circular(4),
              ),
              image: DecorationImage(
                image: AssetImage(newsItem['image'] as String),
                fit: BoxFit.cover,
              ),
            ),
          ),
          Padding(
            padding: EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  newsItem['date'] as String,
                  style: TextStyle(
                    color: Colors.grey[600],
                    fontSize: 14,
                  ),
                ),
                SizedBox(height: 8),
                Text(
                  newsItem['title'] as String,
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                ),
                SizedBox(height: 8),
                Text(
                  newsItem['summary'] as String,
                  style: Theme.of(context).textTheme.bodyMedium,
                ),
                SizedBox(height: 16),
                TextButton(
                  onPressed: () {
                    // TODO: Implement news link action
                  },
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(newsItem['link'] as String),
                      SizedBox(width: 8),
                      Icon(Icons.arrow_forward, size: 16),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    )).toList();
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
