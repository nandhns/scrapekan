import 'package:flutter/material.dart';

class RewardsScreen extends StatelessWidget {
  const RewardsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("My Rewards")),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              "Track your eco-points and redeem rewards!",
              style: TextStyle(fontSize: 16),
            ),
            const SizedBox(height: 24),
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                border: Border.all(color: Colors.grey.shade300),
                borderRadius: BorderRadius.circular(12),
              ),
              child: const Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text("Points Collected", style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                  SizedBox(height: 8),
                  Text(
                    "120 eco-points",
                    style: const TextStyle(
                    fontWeight: FontWeight.bold,
                   fontSize: 16,  
                      )
                    ),
                ],
              ),
            ),
            const SizedBox(height: 24),
            const Text("Redeemable Rewards", style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
            const SizedBox(height: 12),
            Expanded(
              child: ListView(
                children: [
                  RewardItem(title: "10% Off Grocery Voucher", points: 100),
                  RewardItem(title: "Reusable Bag", points: 50),
                  RewardItem(title: "Free Compost Packet", points: 80),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class RewardItem extends StatelessWidget {
  final String title;
  final int points;

  const RewardItem({required this.title, required this.points, super.key});

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.symmetric(vertical: 6),
      child: ListTile(
        title: Text(
          title,
          style: const TextStyle(fontWeight: FontWeight.bold),
          ),
        subtitle: Text(
          "$points eco-points",
          ),
        trailing: TextButton(
          onPressed: () {},
          child: const Text("Redeem"),
        ),
      ),
    );
  }
}
