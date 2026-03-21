import 'package:flutter/material.dart';
import '../theme/app_theme.dart';
import '../models/sale.dart';

class SalesHeatMap extends StatelessWidget {
  final List<Sale> sales;

  const SalesHeatMap({super.key, required this.sales});

  @override
  Widget build(BuildContext context) {
    // Aggregate hourly sales count
    final List<int> heatmapData = List.filled(24, 0);
    final today = DateTime.now();
    
    for (var sale in sales) {
      if (sale.date.year == today.year && sale.date.month == today.month && sale.date.day == today.day) {
        heatmapData[sale.date.hour]++;
      }
    }

    // Default to mock data for demonstration if no actual sales are recorded
    bool hasData = heatmapData.any((val) => val > 0);
    final displayData = hasData ? heatmapData : [2, 1, 0, 0, 0, 0, 2, 8, 15, 25, 40, 35, 30, 45, 50, 40, 35, 30, 45, 60, 55, 30, 15, 8];
    
    // Find peak value and its hour
    int maxVal = 0;
    int peakHour = 0;
    for (int i = 0; i < displayData.length; i++) {
      if (displayData[i] > maxVal) {
        maxVal = displayData[i];
        peakHour = i;
      }
    }

    String formatHour(int h) {
      if (h == 0) return '12 AM';
      if (h == 12) return '12 PM';
      return h < 12 ? '$h AM' : '${h - 12} PM';
    }

    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [AppTheme.cardBg(context), AppTheme.cardBg(context).withOpacity(0.9)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(32),
        border: Border.all(color: AppTheme.divider(context).withOpacity(0.5)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.02),
            blurRadius: 20,
            offset: const Offset(0, 10),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('Sales Intensity Radar', 
                    style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18, color: AppTheme.textHeading(context), letterSpacing: -0.5)
                  ),
                  const SizedBox(height: 4),
                  Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                        decoration: BoxDecoration(
                          color: Colors.greenAccent.withOpacity(0.2),
                          borderRadius: BorderRadius.circular(6),
                        ),
                        child: const Text('LIVE', style: TextStyle(color: Colors.green, fontSize: 9, fontWeight: FontWeight.bold)),
                      ),
                      const SizedBox(width: 8),
                      Text('Tracking 24-hour peak velocity', style: TextStyle(fontSize: 12, color: AppTheme.textBody(context))),
                    ],
                  ),
                ],
              ),
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: AppTheme.primary.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(14),
                ),
                child: const Icon(Icons.radar, size: 24, color: AppTheme.primary),
              ),
            ],
          ),
          const SizedBox(height: 32),
          
          if (maxVal > 0)
            Padding(
              padding: const EdgeInsets.only(bottom: 16),
              child: Row(
                children: [
                  const Icon(Icons.flash_on, color: Colors.amber, size: 16),
                  const SizedBox(width: 6),
                  Text('Peak Hour: ${formatHour(peakHour)} ($maxVal sales)', 
                    style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: AppTheme.textHeading(context))
                  ),
                ],
              ),
            ),

          SizedBox(
            height: 70,
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: List.generate(24, (index) {
                final int intensity = displayData[index];
                // Calculate relative height
                final double heightFactor = maxVal == 0 ? 0 : (intensity / maxVal);
                final bool isPeak = index == peakHour;

                return Expanded(
                  child: Tooltip(
                    message: '${formatHour(index)}: $intensity sales',
                    preferBelow: false,
                    decoration: BoxDecoration(
                      color: AppTheme.primary,
                      borderRadius: BorderRadius.circular(8),
                    ),
                    textStyle: const TextStyle(color: Colors.white, fontSize: 12, fontWeight: FontWeight.bold),
                    child: Container(
                      margin: const EdgeInsets.symmetric(horizontal: 2.5),
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.end,
                        children: [
                          if (isPeak)
                            const Padding(
                              padding: EdgeInsets.only(bottom: 4),
                              child: Icon(Icons.arrow_drop_down, size: 12, color: AppTheme.accent),
                            ),
                          AnimatedContainer(
                            duration: const Duration(milliseconds: 500),
                            height: 4 + (heightFactor * 50),
                            decoration: BoxDecoration(
                              gradient: LinearGradient(
                                colors: _getBarGradientColors(context, intensity, maxVal),
                                begin: Alignment.bottomCenter,
                                end: Alignment.topCenter,
                              ),
                              borderRadius: BorderRadius.circular(8),
                              boxShadow: isPeak ? [
                                BoxShadow(
                                  color: AppTheme.accent.withOpacity(0.4),
                                  blurRadius: 10,
                                  offset: const Offset(0, 0),
                                )
                              ] : null,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                );
              }),
            ),
          ),
          const SizedBox(height: 16),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text('12 AM', style: _axisTextStyle(context)),
              Text('6 AM', style: _axisTextStyle(context)),
              Text('12 PM', style: _axisTextStyle(context)),
              Text('6 PM', style: _axisTextStyle(context)),
              Text('11 PM', style: _axisTextStyle(context)),
            ],
          ),
        ],
      ),
    );
  }

  TextStyle _axisTextStyle(BuildContext context) {
    return TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: AppTheme.textBody(context).withOpacity(0.7), letterSpacing: 0.5);
  }

  List<Color> _getBarGradientColors(BuildContext context, int val, int maxVal) {
    if (val == 0) return [Colors.grey.withOpacity(0.1), Colors.grey.withOpacity(0.05)];
    
    double ratio = maxVal == 0 ? 0 : val / maxVal;
    
    if (ratio < 0.2) return [AppTheme.primary.withOpacity(0.2), AppTheme.primary.withOpacity(0.1)];
    if (ratio < 0.5) return [AppTheme.primary.withOpacity(0.5), AppTheme.primary.withOpacity(0.3)];
    if (ratio < 0.8) return [AppTheme.primary.withOpacity(0.8), AppTheme.primary.withOpacity(0.6)];
    
    // For peak values
    return [AppTheme.primary, AppTheme.accent];
  }
}

