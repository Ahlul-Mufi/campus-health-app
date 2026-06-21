import 'package:flutter/foundation.dart';
import '../models/place.dart';

class FavoritesNotifier extends ChangeNotifier {
  final List<Place> _favorites = [];

  List<Place> get favorites => List.unmodifiable(_favorites);

  bool isFavorite(int placeId) =>
      _favorites.any((p) => p.id == placeId);

  void toggleFavorite(Place place) {
    if (isFavorite(place.id)) {
      _favorites.removeWhere((p) => p.id == place.id);
    } else {
      _favorites.add(place);
    }
    notifyListeners();
  }

  void remove(Place place) {
    _favorites.removeWhere((p) => p.id == place.id);
    notifyListeners();
  }
}

// Simple singleton so it can be used across screens without Provider
final favoritesNotifier = FavoritesNotifier();