import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class FertilizerStockScreen extends StatefulWidget {
  @override
  _FertilizerStockScreenState createState() => _FertilizerStockScreenState();
}

class _FertilizerStockScreenState extends State<FertilizerStockScreen> {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text('Fertilizer Stock')),
      body: StreamBuilder<QuerySnapshot>(
        stream: FirebaseFirestore.instance
            .collection('fertilizer_stock')
            .snapshots(),
        builder: (context, snapshot) {
          if (snapshot.hasError) {
            return Center(child: Text('Error: ${snapshot.error}'));
          }

          if (snapshot.connectionState == ConnectionState.waiting) {
            return Center(child: CircularProgressIndicator());
          }

          final stocks = snapshot.data?.docs ?? [];

          return ListView.builder(
            padding: EdgeInsets.all(16),
            itemCount: stocks.length,
            itemBuilder: (context, index) {
              final stock = stocks[index].data() as Map<String, dynamic>;
              return Card(
                child: ListTile(
                  leading: Icon(Icons.inventory),
                  title: Text(stock['type'] ?? 'Unknown Type'),
                  subtitle: Text('Quantity: ${stock['quantity']?.toString() ?? '0'} kg'),
                  trailing: _buildStockStatus(stock['quantity'] ?? 0),
                ),
              );
            },
          );
        },
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: _showAddStockDialog,
        child: Icon(Icons.add),
      ),
    );
  }

  Widget _buildStockStatus(num quantity) {
    Color color;
    String text;

    if (quantity > 100) {
      color = Colors.green;
      text = 'High';
    } else if (quantity > 50) {
      color = Colors.orange;
      text = 'Medium';
    } else {
      color = Colors.red;
      text = 'Low';
    }

    return Container(
      padding: EdgeInsets.symmetric(horizontal: 12, vertical: 4),
      decoration: BoxDecoration(
        color: color.withOpacity(0.2),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Text(
        text,
        style: TextStyle(color: color, fontWeight: FontWeight.bold),
      ),
    );
  }

  void _showAddStockDialog() {
    final typeController = TextEditingController();
    final quantityController = TextEditingController();

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('Add Stock'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: typeController,
              decoration: InputDecoration(
                labelText: 'Fertilizer Type',
                border: OutlineInputBorder(),
              ),
            ),
            SizedBox(height: 16),
            TextField(
              controller: quantityController,
              decoration: InputDecoration(
                labelText: 'Quantity (kg)',
                border: OutlineInputBorder(),
              ),
              keyboardType: TextInputType.number,
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () async {
              if (typeController.text.isNotEmpty && quantityController.text.isNotEmpty) {
                try {
                  await FirebaseFirestore.instance.collection('fertilizer_stock').add({
                    'type': typeController.text,
                    'quantity': double.parse(quantityController.text),
                    'timestamp': FieldValue.serverTimestamp(),
                  });
                  Navigator.pop(context);
                } catch (e) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text('Error adding stock: $e')),
                  );
                }
              }
            },
            child: Text('Add'),
          ),
        ],
      ),
    );
  }
} 