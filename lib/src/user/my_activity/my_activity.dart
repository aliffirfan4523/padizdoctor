import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';

class MyActivity extends StatefulWidget {
  const MyActivity({super.key});

  @override
  State<MyActivity> createState() => _MyActivityState();
}

class _MyActivityState extends State<MyActivity> {
  int touchedIndex = -1;
  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      child: Column(
        children: [
          AppBar(
            automaticallyImplyLeading: false,
            title: Text(
              'My Activity',
              style: TextStyle(fontSize: 24),
            ),
          ),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16.0),
            child: Row(
              children: [
                _buildStatCard("45", "SCANS"),
                const SizedBox(width: 12), // Spacing between cards
                _buildStatCard("85%", "HEALTH"),
                const SizedBox(width: 12),
                _buildStatCard("12", "WEEK"),
              ],
            ),
          ),
          SizedBox(height: 20),
          Padding(
            padding: const EdgeInsets.all(20.0),
            child: _diseaseDistribution(),
          )
        ],
      ),
    );
  }

  Container _diseaseDistribution() {
    return Container(
      decoration: BoxDecoration(
          border: Border.all(color: Colors.grey.shade300, width: 5),
          borderRadius: BorderRadius.circular(40)),
      child: Column(
        spacing: 10,
        children: [
          SizedBox(height: 10),
          Text(
            'Recent Scans',
            style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
          ),
          Divider(),
          AspectRatio(
            aspectRatio: 1.4,
            child: AspectRatio(
              aspectRatio: 1.4,
              child: PieChart(
                PieChartData(
                  sections: showingSections(),
                  pieTouchData: PieTouchData(
                    touchCallback: (FlTouchEvent event, pieTouchResponse) {
                      setState(() {
                        if (!event.isInterestedForInteractions ||
                            pieTouchResponse == null ||
                            pieTouchResponse.touchedSection == null) {
                          touchedIndex = -1;
                          return;
                        }
                        touchedIndex = pieTouchResponse
                            .touchedSection!.touchedSectionIndex;
                      });
                    },
                  ),
                  borderData: FlBorderData(
                    show: false,
                  ),
                  sectionsSpace: 0,
                  centerSpaceRadius: 60,
                ),
              ),
            ),
          ),
          DataTable(columns: <DataColumn>[
            DataColumn(label: Text('Type')),
            DataColumn(label: Text('Accuracy')),
            DataColumn(label: Text('Date')),
          ], rows: <DataRow>[
            DataRow(cells: <DataCell>[
              DataCell(Text('Tomato Blight')),
              DataCell(Text('96%')),
              DataCell(Text('3 hours ago')),
            ]),
            DataRow(cells: <DataCell>[
              DataCell(Text('Potato Disease')),
              DataCell(Text('89%')),
              DataCell(Text('1 day ago')),
            ]),
            DataRow(cells: <DataCell>[
              DataCell(Text('Corn Leaf Spot')),
              DataCell(Text('92%')),
              DataCell(Text('2 days ago')),
            ]),
          ]),
        ],
      ),
    );
  }

  List<PieChartSectionData> showingSections() {
    return List.generate(4, (i) {
      final isTouched = i == touchedIndex;
      final fontSize = isTouched ? 25.0 : 16.0;
      final radius = isTouched ? 60.0 : 50.0;
      const shadows = [Shadow(color: Colors.black, blurRadius: 2)];
      return switch (i) {
        0 => PieChartSectionData(
            color: Colors.blue,
            value: 40,
            title: '40%',
            radius: radius,
            titleStyle: TextStyle(
              fontSize: fontSize,
              fontWeight: FontWeight.bold,
              color: Colors.black,
              shadows: shadows,
            ),
          ),
        1 => PieChartSectionData(
            color: Colors.yellow,
            value: 30,
            title: '30%',
            radius: radius,
            titleStyle: TextStyle(
              fontSize: fontSize,
              fontWeight: FontWeight.bold,
              color: Colors.black,
              shadows: shadows,
            ),
          ),
        2 => PieChartSectionData(
            color: Colors.purple,
            value: 15,
            title: '15%',
            radius: radius,
            titleStyle: TextStyle(
              fontSize: fontSize,
              fontWeight: FontWeight.bold,
              color: Colors.black,
              shadows: shadows,
            ),
          ),
        3 => PieChartSectionData(
            color: Colors.green,
            value: 15,
            title: '15%',
            radius: radius,
            titleStyle: TextStyle(
              fontSize: fontSize,
              fontWeight: FontWeight.bold,
              color: Colors.black,
              shadows: shadows,
            ),
          ),
        _ => throw StateError('Invalid'),
      };
    });
  }
}

Widget _buildStatCard(String value, String label) {
  return Expanded(
    child: Container(
      padding: const EdgeInsets.symmetric(vertical: 20),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(15),
        border: Border.all(color: Colors.green.withOpacity(0.5)),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            value,
            style: const TextStyle(
              color: Colors.green,
              fontSize: 24,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            label,
            style: const TextStyle(
              color: Colors.green,
              fontSize: 10,
              letterSpacing: 1.2,
            ),
          ),
        ],
      ),
    ),
  );
}
