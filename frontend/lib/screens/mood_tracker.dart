import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';

class MoodTracker extends StatefulWidget {
  @override
  _MoodTrackerState createState() => _MoodTrackerState();
}

class _MoodTrackerState extends State<MoodTracker> {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  List<FlSpot> _sentimentData = [];

  @override
  void initState() {
    super.initState();
    _fetchConversations();
  }

  Future<void> _fetchConversations() async {
    try {
      QuerySnapshot conversationsSnapshot = await _firestore.collection('conversations').get();
      List<FlSpot> tempData = [];
      double previousTimestamp = 0;
      
      for (var conversation in conversationsSnapshot.docs) {
        QuerySnapshot messagesSnapshot = await conversation.reference.collection('messages').get();
        previousTimestamp = 0;
        
        for (var message in messagesSnapshot.docs) {
          String content = message['content'];
          Timestamp timestamp = message['timestamp'];
          double score = await _analyzeSentiment(content);
          
          double currentTimestamp = timestamp.seconds.toDouble();
          double timeDifference = previousTimestamp == 0 ? 0 : currentTimestamp - previousTimestamp;
          
          tempData.add(FlSpot(timeDifference, score));
          previousTimestamp = currentTimestamp;
        }
      }
      
      tempData.sort((a, b) => a.x.compareTo(b.x));
      
      setState(() {
        _sentimentData = tempData;
      });
    } catch (e) {
      print('Error fetching conversations: $e');
    }
  }

  Future<double> _analyzeSentiment(String text) async {
    try {
      final sentimentResponse = await http.post(
        Uri.parse('http://127.0.0.1:5000/analyze_sentiment'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({
          'text': text,
        }),
      );

      if (sentimentResponse.statusCode == 200) {
        final data = jsonDecode(sentimentResponse.body);
        return data['score'].toDouble();
      } else {
        print('Error analyzing sentiment: ${sentimentResponse.body}');
        return 0.0;
      }
    } catch (e) {
      print('Error during sentiment analysis: $e');
      return 0.0;
    }
  }

  String _formatTimeInterval(double seconds) {
    if (seconds < 60) {
      return '${seconds.toInt()}s';
    } else if (seconds < 3600) {
      return '${(seconds / 60).toInt()}m';
    } else {
      return '${(seconds / 3600).toStringAsFixed(1)}h';
    }
  }

  String _getSentimentEmoji(double score) {
    if (score >= 0.5) return '😄';
    if (score >= 0.2) return '🙂';
    if (score >= -0.2) return '😐';
    if (score >= -0.5) return '🙁';
    return '😢';
  }

  Widget _buildSentimentIcon(double score, Offset offset) {
    return Positioned(
      left: offset.dx - 10,
      top: offset.dy - 25,
      child: Text(
        _getSentimentEmoji(score),
        style: TextStyle(fontSize: 20),
      ),
    );
  }

  LineChartData _createChartData() {
    final LineChartBarData lineChartBarData = LineChartBarData(
      spots: _sentimentData,
      isCurved: true,
      color: Colors.blue,
      barWidth: 3,
      isStrokeCapRound: true,
      dotData: FlDotData(
        show: true,
        getDotPainter: (spot, percent, bar, index) {
          return FlDotCirclePainter(
            radius: 4,
            color: Colors.blue,
            strokeWidth: 1,
            strokeColor: Colors.white,
          );
        },
      ),
      belowBarData: BarAreaData(show: false),
    );

    return LineChartData(
      gridData: FlGridData(show: false),
      titlesData: FlTitlesData(
        bottomTitles: AxisTitles(
          axisNameWidget: Text('Time between messages', style: TextStyle(fontSize: 12)),
          sideTitles: SideTitles(
            showTitles: true,
            reservedSize: 30,
            interval: 300,
            getTitlesWidget: (value, meta) {
              return SideTitleWidget(
                axisSide: meta.axisSide,
                child: Text(
                  _formatTimeInterval(value),
                  style: TextStyle(fontSize: 10),
                ),
              );
            },
          ),
        ),
        leftTitles: AxisTitles(
          axisNameWidget: Text('Sentiment Score', style: TextStyle(fontSize: 12)),
          sideTitles: SideTitles(
            showTitles: true,
            reservedSize: 40,
            interval: 0.2,
            getTitlesWidget: (value, meta) {
              return SideTitleWidget(
                axisSide: meta.axisSide,
                child: Text(
                  value.toStringAsFixed(1),
                  style: TextStyle(fontSize: 10),
                ),
              );
            },
          ),
        ),
        rightTitles: AxisTitles(sideTitles: SideTitles(showTitles: false)),
        topTitles: AxisTitles(sideTitles: SideTitles(showTitles: false)),
      ),
      borderData: FlBorderData(show: true),
      minX: _sentimentData.isNotEmpty ? _sentimentData.first.x : 0,
      maxX: _sentimentData.isNotEmpty ? _sentimentData.last.x : 1,
      minY: -1,
      maxY: 1,
      lineBarsData: [lineChartBarData],
      showingTooltipIndicators: _sentimentData.asMap().entries.map((entry) {
        return ShowingTooltipIndicators([
          LineBarSpot(lineChartBarData, entry.key, _sentimentData[entry.key]),
        ]);
      }).toList(),
      lineTouchData: LineTouchData(
        enabled: true,
        touchCallback: (FlTouchEvent event, LineTouchResponse? response) {
          // Handle touch events if needed
        },
        getTouchedSpotIndicator: (LineChartBarData barData, List<int> spotIndexes) {
          return spotIndexes.map((index) {
            return TouchedSpotIndicatorData(
              FlLine(color: Colors.transparent),
              FlDotData(
                show: true,
                getDotPainter: (spot, percent, bar, index) => FlDotCirclePainter(
                  radius: 4,
                  color: Colors.blue,
                  strokeWidth: 1,
                  strokeColor: Colors.white,
                ),
              ),
            );
          }).toList();
        },
        touchTooltipData: LineTouchTooltipData(
          tooltipBgColor: Colors.transparent,
          tooltipRoundedRadius: 8,
          getTooltipItems: (List<LineBarSpot> lineBarsSpot) {
            return lineBarsSpot.map((lineBarSpot) {
              return LineTooltipItem(
                '',
                const TextStyle(color: Colors.transparent),
              );
            }).toList();
          },
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text('Mood Tracker')),
      body: Column(
        children: [
          Expanded(
            child: Padding(
              padding: const EdgeInsets.all(16.0),
              child: _sentimentData.isEmpty
                  ? Center(child: CircularProgressIndicator())
                  : Stack(
                      children: [
                        LineChart(_createChartData()),
                        ..._sentimentData.map((spot) {
                          final tooltipPos = Offset(
                            (spot.x - _sentimentData.first.x) /
                                    (_sentimentData.last.x - _sentimentData.first.x) *
                                    (MediaQuery.of(context).size.width - 72) +
                                36,
                            (1 - (spot.y + 1) / 2) *
                                    (MediaQuery.of(context).size.height - 100) +
                                16,
                          );
                          return _buildSentimentIcon(spot.y, tooltipPos);
                        }).toList(),
                      ],
                    ),
            ),
          ),
        ],
      ),
    );
  }
}