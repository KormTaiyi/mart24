import 'package:flutter/foundation.dart';
import 'package:mart24/features/home/models/product.dart';

class FavoriteManager {
  FavoriteManager._();

  static final ValueNotifier<Set<String>> favorites =
      ValueNotifier<Set<String>>(<String>{});
  static final Map<String, Product> _favoriteProductsByKey =
      <String, Product>{};

  static bool isFavorite(Product product) {
    return favorites.value.contains(product.favoriteKey);
  }

  static List<Product> get favoriteProducts {
    return _favoriteProductsByKey.values.toList(growable: false);
  }

  static void toggle(Product product) {
    final Set<String> updatedFavorites = Set<String>.from(favorites.value);
    final String key = product.favoriteKey;

    if (!updatedFavorites.add(key)) {
      updatedFavorites.remove(key);
      _favoriteProductsByKey.remove(key);
    } else {
      _favoriteProductsByKey[key] = product;
    }

    favorites.value = updatedFavorites;
  }
}
