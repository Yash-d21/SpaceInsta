import 'package:flutter/material.dart';

class BudgetBreakdownPage extends StatelessWidget {
  const BudgetBreakdownPage({super.key});

  @override
  Widget build(BuildContext context) {
    // Calculating 1/3 of the screen height
    double topHeight = MediaQuery.of(context).size.height * 0.33;

    return Scaffold(
      backgroundColor: Colors.grey[100],
      appBar: AppBar(
        title: const Text("Final Quotation"),
        backgroundColor: Colors.white,
        foregroundColor: Colors.black,
        elevation: 0,
      ),
      body: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // 1. Top 1/3rd Image
          Container(
            width: double.infinity,
            height: topHeight,
            decoration: const BoxDecoration(
              image: DecorationImage(
                image: NetworkImage('https://picsum.photos/id/237/800/600'),
                fit: BoxFit.cover,
              ),
            ),
          ),

          // 2. Budget Details Section
          Expanded(
            child: Container(
              width: double.infinity,
              padding: const EdgeInsets.all(25.0),
              decoration: const BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.vertical(top: Radius.circular(30)),
              ),
              child: SingleChildScrollView(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      "Budget Details/Breakup",
                      style: TextStyle(
                        fontSize: 24,
                        fontWeight: FontWeight.bold,
                        color: Colors.blueAccent,
                      ),
                    ),
                    const Divider(height: 30, thickness: 1),

                    // Placeholder for breakup details
                    _buildBudgetItem("Design Fee", "₹15,000"),
                    _buildBudgetItem("Material Cost", "₹1,20,000"),
                    _buildBudgetItem("Labor Charges", "₹45,000"),
                    _buildBudgetItem("Tax (18%)", "₹32,400"),

                    const Divider(height: 30, thickness: 2),
                    _buildBudgetItem(
                      "Total Estimated Budget",
                      "₹2,12,400",
                      isTotal: true,
                    ),

                    const SizedBox(height: 40),

                    // 3. Space for extra text at the bottom
                    const Text(
                      "Additional Notes",
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 10),
                    const Text(
                      "This is a preliminary estimate based on your selected specifications. Final prices may vary slightly based on actual site measurements and material availability.",
                      style: TextStyle(color: Colors.grey, height: 1.5),
                    ),
                    const SizedBox(height: 100), // Extra space for scrolling
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  // Helper widget to display budget rows
  Widget _buildBudgetItem(String label, String amount, {bool isTotal = false}) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8.0),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            label,
            style: TextStyle(
              fontSize: isTotal ? 18 : 16,
              fontWeight: isTotal ? FontWeight.bold : FontWeight.normal,
            ),
          ),
          Text(
            amount,
            style: TextStyle(
              fontSize: isTotal ? 20 : 16,
              fontWeight: isTotal ? FontWeight.bold : FontWeight.w500,
              color: isTotal ? Colors.blueAccent : Colors.black,
            ),
          ),
        ],
      ),
    );
  }
}
