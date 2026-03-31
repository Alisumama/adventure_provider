enum NearbyRouteDifficulty { easy, moderate, hard }

enum NearbyRouteKind { hike, offroad }

class NearbyRouteItem {
  const NearbyRouteItem({
    required this.name,
    required this.difficulty,
    required this.distanceKm,
    required this.rating,
    required this.emoji,
    required this.kind,
  });

  final String name;
  final NearbyRouteDifficulty difficulty;
  final double distanceKm;
  final double rating;
  final String emoji;
  final NearbyRouteKind kind;

  static const List<NearbyRouteItem> samples = [
    NearbyRouteItem(
      name: 'Kızıldağ Summit',
      difficulty: NearbyRouteDifficulty.hard,
      distanceKm: 12.3,
      rating: 4.8,
      emoji: '⛰️',
      kind: NearbyRouteKind.hike,
    ),
    NearbyRouteItem(
      name: 'Beytepe Forest',
      difficulty: NearbyRouteDifficulty.easy,
      distanceKm: 4.7,
      rating: 4.6,
      emoji: '🌲',
      kind: NearbyRouteKind.hike,
    ),
    NearbyRouteItem(
      name: 'Elmadağ Trail',
      difficulty: NearbyRouteDifficulty.moderate,
      distanceKm: 22,
      rating: 4.9,
      emoji: '🛤️',
      kind: NearbyRouteKind.offroad,
    ),
    NearbyRouteItem(
      name: 'Çamlıdere Valley',
      difficulty: NearbyRouteDifficulty.moderate,
      distanceKm: 8.5,
      rating: 4.7,
      emoji: '🏞️',
      kind: NearbyRouteKind.hike,
    ),
  ];
}
