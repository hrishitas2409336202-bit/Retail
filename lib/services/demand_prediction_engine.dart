import '../models/product.dart';
import '../models/sale.dart';

class DemandPredictionEngine {
  /// Predicts demand for the next [days] based on historical sales.
  static Map<String, dynamic> predictDemand(Product product, List<Sale> sales, {int days = 7}) {
    // Filter sales for this specific product in the last 14 days to get a trend
    final dualWeekAgo = DateTime.now().subtract(const Duration(days: 14));
    
    int totalQty = 0;
    int countDays = 14;

    for (var sale in sales) {
      if (sale.date.isAfter(dualWeekAgo)) {
        for (var item in sale.items) {
          if (item.id == product.id) {
            totalQty += item.qty;
          }
        }
      }
    }

    double avgDaily = totalQty / countDays;
    double predictedDemand = avgDaily * days;
    
    // Suggest restock if stock is less than predicted demand + threshold buffer
    int suggestedRestock = 0;
    if (product.stock < (predictedDemand + product.threshold)) {
      suggestedRestock = (predictedDemand + (product.threshold * 2) - product.stock).ceil();
    }

    return {
      'productId': product.id,
      'name': product.name,
      'avgDaily': avgDaily,
      'predictedDemand': predictedDemand,
      'suggestedRestock': suggestedRestock > 0 ? suggestedRestock : 0,
    };
  }

  static List<Map<String, dynamic>> getAllPredictions(List<Product> products, List<Sale> sales) {
    var predictions = products.map((p) => predictDemand(p, sales)).toList();
    predictions.sort((a, b) {
      int restockA = a['suggestedRestock'] as int;
      int restockB = b['suggestedRestock'] as int;
      if (restockA != restockB) {
        return restockB.compareTo(restockA);
      }
      double demandA = a['predictedDemand'] as double;
      double demandB = b['predictedDemand'] as double;
      return demandB.compareTo(demandA);
    });
    return predictions;
  }
}

