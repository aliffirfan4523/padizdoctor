import 'package:flutter/material.dart';

class MyHistory extends StatefulWidget {
  const MyHistory({super.key});

  @override
  State<MyHistory> createState() => _MyHistoryState();
}

class _MyHistoryState extends State<MyHistory> {
  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      child: Column(
        children: [
          AppBar(
            automaticallyImplyLeading: false,
            title: Text(
              'My History',
              style: TextStyle(fontSize: 24),
            ),
          ),
          SizedBox(height: 20),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Padding(
                padding: const EdgeInsets.all(16.0),
                child: Text(
                  'Recent Scans',
                  style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
                ),
              ),
              TextButton(
                onPressed: () {
                  // Handle view all action
                },
                child: Text('View All'),
              ),
            ],
          ),
          ListView.builder(
            itemCount: 20,
            shrinkWrap: true,
            physics: NeverScrollableScrollPhysics(),
            itemBuilder: (BuildContext context, int index) {
              return Padding(
                padding: const EdgeInsets.all(10),
                child: Card(
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      SizedBox(width: 10),
                      Icon(Icons.image, size: 80),
                      Column(
                        children: [
                          Text("Tomato Blight"),
                          Text("Action Required"),
                          Text("Confidence: 96%")
                        ],
                      ),
                      Text("3 hours ago"),
                      Icon(Icons.arrow_forward_ios),
                      SizedBox(width: 10)
                    ],
                  ),
                ),
              );
            },
          ),
        ],
      ),
    );
  }
}
