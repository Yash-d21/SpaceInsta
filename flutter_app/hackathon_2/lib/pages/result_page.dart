
import 'package:flutter/material.dart';
import 'package:fl_chart/fl_chart.dart';
import 'dart:ui';

class AnalysisResultPage extends StatelessWidget {
  final Map<String, dynamic> data;

  const AnalysisResultPage({super.key, required this.data});

  @override
  Widget build(BuildContext context) {
    final vision = data['vision_analysis'] ?? {};
    final costs = data['cost_estimates'] ?? {};
    final business = data['business_classification'] ?? {};

    return Scaffold(
      backgroundColor: const Color(0xFF0A0E21),
      body: CustomScrollView(
        slivers: [
          _buildAppBar(vision),
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.all(20.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _buildGlassCard(
                    title: "Room Vision",
                    child: Column(
                      children: [
                        _buildInfoRow(Icons. मीटिंग_रूम, "Type", vision['room_type'] ?? "Unknown"),
                        _buildInfoRow(Icons.palette, "Style", vision['style_guess'] ?? "Unknown"),
                        _buildInfoRow(Icons.high_quality, "Tier", "${vision['quality_tier_guess']?['tier'] ?? 'Standard'}"),
                      ],
                    ),
                  ),
                  const SizedBox(height: 24),
                  
                  _buildSectionTitle("Market Valuation"),
                  _buildCostChart(costs),
                  
                  const SizedBox(height: 24),
                  
                  _buildSectionTitle("Project DNA"),
                  Row(
                    children: [
                      Expanded(child: _buildMetricCard("Timeline", "${business['estimated_timeline_weeks']} Weeks", Icons.timer)),
                      const SizedBox(width: 12),
                      Expanded(child: _buildMetricCard("Complexity", "${business['complexity_level']}", Icons.speed)),
                    ],
                  ),
                  
                  const SizedBox(height: 24),
                  
                  _buildSectionTitle("Critical Items"),
                  _buildPriorityList(business['item_prioritization'] ?? []),
                  
                  const SizedBox(height: 50),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildAppBar(Map vision) {
    return SliverAppBar(
      expandedHeight: 200.0,
      floating: false,
      pinned: true,
      backgroundColor: const Color(0xFF0A0E21),
      flexibleSpace: FlexibleSpaceBar(
        title: Text(vision['room_type'] ?? "Analysis", 
          style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
        background: Stack(
          fit: StackFit.expand,
          children: [
            Container(color: Colors.blueAccent.withOpacity(0.2)),
            Center(child: Icon(Icons.auto_awesome, size: 80, color: Colors.blueAccent.withOpacity(0.5))),
            Container(
              decoration: const BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [Colors.transparent, Color(0xFF0A0E21)],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSectionTitle(String title) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Text(
        title.toUpperCase(),
        style: const TextStyle(
          color: Colors.blueAccent,
          letterSpacing: 1.5,
          fontWeight: FontWeight.bold,
          fontSize: 13,
        ),
      ),
    );
  }

  Widget _buildGlassCard({required String title, required Widget child}) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(20),
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
        child: Container(
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            color: Colors.white.withOpacity(0.05),
            borderRadius: BorderRadius.circular(20),
            border: Border.all(color: Colors.white.withOpacity(0.1)),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(title, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 18, color: Colors.white)),
              const SizedBox(height: 15),
              child,
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildInfoRow(IconData icon, String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
        children: [
          Icon(icon, size: 20, color: Colors.blueAccent),
          const SizedBox(width: 12),
          Text(label, style: const TextStyle(color: Colors.white70)),
          const Spacer(),
          Text(value, style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
        ],
      ),
    );
  }

  Widget _buildMetricCard(String label, String value, IconData icon) {
    return Container(
      padding: const EdgeInsets.all(15),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.05),
        borderRadius: BorderRadius.circular(15),
        border: Border.all(color: Colors.white.withOpacity(0.1)),
      ),
      child: Column(
        children: [
          Icon(icon, color: Colors.blueAccent, size: 24),
          const SizedBox(height: 8),
          Text(value, style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Colors.white)),
          Text(label, style: const TextStyle(fontSize: 11, color: Colors.white54)),
        ],
      ),
    );
  }

  Widget _buildCostChart(Map costs) {
    final tiers = ['economy', 'standard', 'premium'];
    final values = tiers.map((t) => (costs[t]?['total'] ?? 0).toDouble()).toList();
    final maxValue = values.reduce((a, b) => a > b ? a : b);

    return Container(
      height: 220,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.05),
        borderRadius: BorderRadius.circular(20),
      ),
      child: BarChart(
        BarChartData(
          gridData: const FlGridData(show: false),
          titlesData: FlTitlesData(
            show: true,
            leftTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
            topTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
            rightTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
            bottomTitles: AxisTitles(
              sideTitles: SideTitles(
                showTitles: true,
                getTitlesWidget: (val, meta) => Padding(
                  padding: const EdgeInsets.only(top: 8),
                  child: Text(tiers[val.toInt()].substring(0, 3).toUpperCase(), 
                    style: const TextStyle(color: Colors.white54, fontSize: 10)),
                ),
              ),
            ),
          ),
          borderData: FlBorderData(show: false),
          barGroups: List.generate(3, (i) => BarChartGroupData(
            x: i,
            barRods: [
              BarChartRodData(
                toY: values[i],
                gradient: LinearGradient(
                  colors: [Colors.blueAccent, Colors.blueAccent.withOpacity(0.5)],
                  begin: Alignment.bottomCenter,
                  end: Alignment.topCenter,
                ),
                width: 30,
                borderRadius: BorderRadius.circular(6),
              )
            ],
          )),
        ),
      ),
    );
  }

  Widget _buildPriorityList(List priorities) {
    return Column(
      children: priorities.map((p) {
        String priority = p['priority']?.toString().toLowerCase() ?? 'medium';
        Color pColor = Colors.orange;
        if (priority.contains('critical') || priority.contains('high')) pColor = Colors.redAccent;
        if (priority.contains('low')) pColor = Colors.greenAccent;

        return Container(
          margin: const EdgeInsets.only(bottom: 10),
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: Colors.white.withOpacity(0.03),
            borderRadius: BorderRadius.circular(12),
          ),
          child: Row(
            children: [
              Container(width: 4, height: 40, decoration: BoxDecoration(color: pColor, borderRadius: BorderRadius.circular(2))),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(p['item_name'], style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
                    Text(p['rationale'], style: const TextStyle(color: Colors.white54, fontSize: 11), maxLines: 1, overflow: TextOverflow.ellipsis),
                  ],
                ),
              ),
              Text(priority.toUpperCase(), style: TextStyle(color: pColor, fontWeight: FontWeight.bold, fontSize: 10)),
            ],
          ),
        );
      }).toList(),
    );
  }
}
