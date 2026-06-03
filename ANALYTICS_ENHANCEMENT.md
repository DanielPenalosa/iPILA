# Analytics Dashboard Enhancement Plan

## Current State
The analytics currently uses:
- Simple colored progress bars
- Basic bar charts
- Circular progress indicators
- Static data visualizations

## Proposed Enhancements

### 1. **Interactive Line Chart with Trends**
- Add a time-series line chart showing report submissions over time
- Hoverable tooltips showing exact values
- Zoom and pan capabilities
- Compare different time periods (7d, 30d, 90d, all time)

### 2. **Advanced Pie Charts with Legends**
- Replace simple bars with interactive pie charts for:
  - Reports by category
  - Reports by status
  - Reports by barangay
- Click-to-filter functionality
- Percentage labels
- Color-coded legends

### 3. **Heat Map Visualizations**
- Time-of-day heat map (when reports are submitted)
- Geographic heat map (which barangays report most)
- Day-of-week patterns

### 4. **Trend Indicators**
- Show percentage changes (↑ 15% from last month)
- Visual trend arrows (up/down)
- Color-coded trends (green for good, red for concerning)

### 5. **Real-Time Updates**
- Live data streaming from Firebase
- Auto-refresh every 30 seconds
- Visual indicators when data updates

### 6. **Data Export**
- Export to CSV
- Export to PDF report
- Email reports functionality

### 7. **Predictive Analytics**
- Forecast future report volumes
- Identify peak reporting times
- Suggest optimal resource allocation

## Implementation Steps

### Phase 1: Enhanced Charts (Priority)
1. Replace current analytics_screen.dart with advanced version
2. Add interactive line charts for trends
3. Add proper pie charts with legends
4. Add time range filters

### Phase 2: Advanced Features
1. Add heat maps
2. Add export functionality  
3. Add predictive analytics

### Phase 3: Polish
1. Add animations
2. Add loading states
3. Add error handling
4. Optimize performance

## Technical Requirements

- fl_chart: ^0.70.2 (already installed)
- intl: ^0.20.2 (already installed)
- Add: syncfusion_flutter_charts: ^latest (for advanced charts)
- Add: csv: ^latest (for export functionality)

## Next Steps

1. Review current analytics code
2. Implement Phase 1 enhancements
3. Test with real data
4. Deploy and gather feedback
5. Implement Phase 2 & 3 based on usage

---

## Code Example: Advanced Line Chart

```dart
import 'package:fl_chart/fl_chart.dart';
import 'package:intl/intl.dart';

class AdvancedLineChart extends StatefulWidget {
  final List<ReportModel> reports;
  final String timeRange; // '7d', '30d', '90d', 'all'
  
  const AdvancedLineChart({
    required this.reports,
    required this.timeRange,
  });
  
  @override
  State<AdvancedLineChart> createState() => _AdvancedLineChartState();
}

class _AdvancedLineChartState extends State<AdvancedLineChart> {
  int? touchedIndex;
  
  @override
  Widget build(BuildContext context) {
    final dataPoints = _generateDataPoints();
    
    return SizedBox(
      height: 300,
      child: LineChart(
        LineChartData(
          lineTouchData: LineTouchData(
            touchTooltipData: LineTouchTooltipData(
              tooltipBgColor: AppTheme.primaryBlue,
              getTooltipItems: (spots) {
                return spots.map((spot) {
                  final date = _getDateFromIndex(spot.x.toInt());
                  return LineTooltipItem(
                    '${DateFormat('MMM d').format(date)}\n',
                    const TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
                    ),
                    children: [
                      TextSpan(
                        text: '${spot.y.toInt()} reports',
                        style: const TextStyle(
                          color: Colors.white70,
                          fontSize: 12,
                        ),
                      ),
                    ],
                  );
                }).toList();
              },
            ),
            handleBuiltInTouches: true,
          ),
          gridData: FlGridData(
            show: true,
            drawVerticalLine: false,
            horizontalInterval: 5,
            getDrawingHorizontalLine: (value) {
              return FlLine(
                color: Colors.grey[200]!,
                strokeWidth: 1,
              );
            },
          ),
          titlesData: FlTitlesData(
            leftTitles: AxisTitles(
              sideTitles: SideTitles(
                showTitles: true,
                reservedSize: 40,
                getTitlesWidget: (value, meta) {
                  return Text(
                    value.toInt().toString(),
                    style: const TextStyle(
                      color: AppTheme.textMuted,
                      fontSize: 12,
                    ),
                  );
                },
              ),
            ),
            bottomTitles: AxisTitles(
              sideTitles: SideTitles(
                showTitles: true,
                interval: _getInterval(),
                getTitlesWidget: (value, meta) {
                  final date = _getDateFromIndex(value.toInt());
                  return Padding(
                    padding: const EdgeInsets.only(top: 8),
                    child: Text(
                      DateFormat('MMM d').format(date),
                      style: const TextStyle(
                        color: AppTheme.textMuted,
                        fontSize: 10,
                      ),
                    ),
                  );
                },
              ),
            ),
            topTitles: AxisTitles(sideTitles: SideTitles(showTitles: false)),
            rightTitles: AxisTitles(sideTitles: SideTitles(showTitles: false)),
          ),
          borderData: FlBorderData(show: false),
          lineBarsData: [
            LineChartBarData(
              spots: dataPoints,
              isCurved: true,
              color: AppTheme.primaryBlue,
              barWidth: 3,
              isStrokeCapRound: true,
              dotData: FlDotData(
                show: true,
                getDotPainter: (spot, percent, barData, index) {
                  return FlDotCirclePainter(
                    radius: index == touchedIndex ? 6 : 3,
                    color: Colors.white,
                    strokeWidth: 2,
                    strokeColor: AppTheme.primaryBlue,
                  );
                },
              ),
              belowBarData: BarAreaData(
                show: true,
                gradient: LinearGradient(
                  colors: [
                    AppTheme.primaryBlue.withOpacity(0.3),
                    AppTheme.primaryBlue.withOpacity(0.0),
                  ],
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
  
  List<FlSpot> _generateDataPoints() {
    final days = _getDaysCount();
    final now = DateTime.now();
    final spots = <FlSpot>[];
    
    for (int i = 0; i < days; i++) {
      final date = now.subtract(Duration(days: days - i - 1));
      final count = widget.reports.where((r) =>
        r.createdAt.year == date.year &&
        r.createdAt.month == date.month &&
        r.createdAt.day == date.day
      ).length;
      spots.add(FlSpot(i.toDouble(), count.toDouble()));
    }
    
    return spots;
  }
  
  int _getDaysCount() {
    switch (widget.timeRange) {
      case '7d': return 7;
      case '30d': return 30;
      case '90d': return 90;
      default: return 30;
    }
  }
  
  double _getInterval() {
    final days = _getDaysCount();
    return days / 6;
  }
  
  DateTime _getDateFromIndex(int index) {
    final days = _getDaysCount();
    final now = DateTime.now();
    return now.subtract(Duration(days: days - index - 1));
  }
}
```

## Interactive Pie Chart Example

```dart
class InteractivePieChart extends StatefulWidget {
  final Map<String, int> data;
  final String title;
  
  const InteractivePieChart({
    required this.data,
    required this.title,
  });
  
  @override
  State<InteractivePieChart> createState() => _InteractivePieChartState();
}

class _InteractivePieChartState extends State<InteractivePieChart> {
  int? touchedIndex;
  
  @override
  Widget build(BuildContext context) {
    final total = widget.data.values.reduce((a, b) => a + b);
    
    return Column(
      children: [
        Text(
          widget.title,
          style: const TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 20),
        Row(
          children: [
            Expanded(
              flex: 2,
              child: PieChart(
                PieChartData(
                  pieTouchData: PieTouchData(
                    touchCallback: (FlTouchEvent event, pieTouchResponse) {
                      setState(() {
                        if (!event.isInterestedForInteractions ||
                            pieTouchResponse == null ||
                            pieTouchResponse.touchedSection == null) {
                          touchedIndex = null;
                          return;
                        }
                        touchedIndex = pieTouchResponse
                            .touchedSection!.touchedSectionIndex;
                      });
                    },
                  ),
                  sections: _generateSections(total),
                  sectionsSpace: 2,
                  centerSpaceRadius: 60,
                ),
              ),
            ),
            Expanded(
              child: _buildLegend(),
            ),
          ],
        ),
      ],
    );
  }
  
  List<PieChartSectionData> _generateSections(int total) {
    final colors = [
      AppTheme.primaryBlue,
      AppTheme.successGreen,
      Colors.orange,
      AppTheme.primaryRed,
      Colors.purple,
      Colors.teal,
    ];
    
    return widget.data.entries.toList().asMap().entries.map((entry) {
      final index = entry.key;
      final data = entry.value;
      final isTouched = index == touchedIndex;
      final radius = isTouched ? 70.0 : 60.0;
      final percentage = (data.value / total * 100).toStringAsFixed(1);
      
      return PieChartSectionData(
        color: colors[index % colors.length],
        value: data.value.toDouble(),
        title: '$percentage%',
        radius: radius,
        titleStyle: TextStyle(
          fontSize: isTouched ? 18 : 14,
          fontWeight: FontWeight.bold,
          color: Colors.white,
        ),
      );
    }).toList();
  }
  
  Widget _buildLegend() {
    final colors = [
      AppTheme.primaryBlue,
      AppTheme.successGreen,
      Colors.orange,
      AppTheme.primaryRed,
      Colors.purple,
      Colors.teal,
    ];
    
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisAlignment: MainAxisAlignment.center,
      children: widget.data.entries.toList().asMap().entries.map((entry) {
        final index = entry.key;
        final data = entry.value;
        
        return Padding(
          padding: const EdgeInsets.symmetric(vertical: 4),
          child: Row(
            children: [
              Container(
                width: 16,
                height: 16,
                decoration: BoxDecoration(
                  color: colors[index % colors.length],
                  shape: BoxShape.circle,
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  data.key,
                  style: const TextStyle(fontSize: 12),
                ),
              ),
              Text(
                '${data.value}',
                style: const TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
        );
      }).toList(),
    );
  }
}
```

---

**To implement these enhancements:**

1. Copy the code examples above
2. Integrate them into your analytics_screen.dart
3. Test with real data
4. Adjust colors and styling to match your theme
5. Add more interactive features as needed
