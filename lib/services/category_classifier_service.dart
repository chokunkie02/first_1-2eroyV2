import 'dart:math';

class CategoryClassifierService {
  // Singleton
  static final CategoryClassifierService _instance = CategoryClassifierService._internal();
  factory CategoryClassifierService() => _instance;
  CategoryClassifierService._internal();

  // Weighted Knowledge Base: Category -> {Keyword: Score}
  final Map<String, Map<String, int>> _weightedKeywords = {
    'Food': {
      // High Priority (Score 50)
      'ขนมจีน': 50, 'หมูกระทะ': 50, 'หมูทอด': 50, 'ไก่ย่าง': 50, 'เนื้อย่าง': 50,
      'shabu': 50, 'sushi': 50, 'steak': 50, 'bistro': 50, 'cafe': 50, 'coffee': 50,
      'starbucks': 50, 'amazon': 50, 'restaurant': 50, 'ครัว': 50, 'kitchen': 50,
      'bar': 50, 'เบเกอรี่': 50, 'bakery': 50, 'ข้าว': 50, 'ก๋วยเตี๋ยว': 50,
      'food': 50, 'pizza': 50, 'mk': 50, 'kfc': 50, 'mcdonald': 50, 'burger': 50,
      // Medium Priority (Score 10)
      'mart': 10, 'market': 10,
    },
    'Shopping': {
      // High Priority (Score 50)
      '7-eleven': 50, 'seven': 50, 'cpall': 50, 'top': 50, 'big c': 50, 'lotus': 50,
      'makro': 50, 'watsons': 50, 'boots': 50, 'shopee': 50, 'lazada': 50,
      'officemate': 50, 'ikea': 50, 'uniqlo': 50, 'zara': 50, 'h&m': 50,
      // Low Priority / Noise (Score 1)
      'shop': 1, 'store': 1, 'ร้าน': 1, 'จำกัด': 1, 'ltd': 1, 'company': 1,
      'co.': 1, 'center': 1, 'mall': 1, 'plaza': 1, 'shopping': 1,
    },
    'Transport': {
      // High Priority (Score 50)
      'gas': 50, 'oil': 50, 'ptt': 50, 'shell': 50, 'esso': 50, 'caltex': 50,
      'bangchak': 50, 'susco': 50, 'bts': 50, 'mrt': 50, 'grab': 50, 'bolt': 50,
      'taxi': 50, 'line man': 50, 'ทางด่วน': 50, 'toll': 50, 'easy pass': 50, 'm-pass': 50,
    },
    'Bills': {
      // High Priority (Score 50)
      'electricity': 50, 'pea': 50, 'mea': 50, 'water': 50, 'mwa': 50, 'pwa': 50,
      'internet': 50, '3bb': 50, 'ais': 50, 'true': 50, 'dtac': 50, 'nt': 50,
      'การไฟฟ้า': 50, 'การประปา': 50,
    },
    'Transfer': {
      // Score 5
      'transfer': 5, 'promptpay': 5, 'โอนเงิน': 5, 'พร้อมเพย์': 5,
    },
  };

  String suggestCategory(String input) {
    if (input.trim().isEmpty) return 'Uncategorized';
    
    String normalizedInput = input.toLowerCase();
    Map<String, int> scores = {
      'Food': 0,
      'Shopping': 0,
      'Transport': 0,
      'Bills': 0,
      'Transfer': 0,
    };

    // Calculate Scores
    _weightedKeywords.forEach((category, keywords) {
      keywords.forEach((keyword, score) {
        if (normalizedInput.contains(keyword)) {
          scores[category] = (scores[category] ?? 0) + score;
        }
      });
    });

    // Find Winner
    String bestCategory = 'Uncategorized';
    int maxScore = 0;

    scores.forEach((category, score) {
      if (score > maxScore) {
        maxScore = score;
        bestCategory = category;
      }
    });

    // Tie-Breaker / Threshold
    // If maxScore < 5, it means only generic words were found (e.g. "Shop" = 1)
    if (maxScore < 5) {
      return 'Uncategorized';
    }

    return bestCategory;
  }
}
