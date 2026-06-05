import 'package:flutter/material.dart';
import '../models/place.dart';

class PlaceCard extends StatelessWidget {
  final Place place;
  final VoidCallback onTap;
  final double? distance;

  const PlaceCard({super.key, required this.place, required this.onTap, this.distance});

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
      elevation: 3,
      shadowColor: Colors.black.withValues(alpha: 0.15),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(14),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Row(
            children: [
              Container(
                width: 56,
                height: 56,
                decoration: BoxDecoration(
                  color: const Color(0xFF96B6C5).withValues(alpha: 0.15),
                  borderRadius: BorderRadius.circular(14),
                ),
                child: const Icon(
                  Icons.local_hospital,
                  color: Color(0xFF96B6C5),
                  size: 28,
                ),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      place.name,
                      style: const TextStyle(
                        fontSize: 17,
                        fontWeight: FontWeight.w600,
                        color: Color(0xFF222222),
                      ),
                    ),
                    if (place.address != null) ...[
                      const SizedBox(height: 5),
                      Text(
                        place.address!,
                        style: TextStyle(
                          fontSize: 14,
                          color: Colors.grey[600],
                          height: 1.3,
                        ),
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ],
                    if (distance != null) ...[
                      const SizedBox(height: 6),
                      Row(
                        children: [
                          Icon(Icons.near_me,
                              size: 16, color: const Color(0xFF96B6C5)),
                          const SizedBox(width: 4),
                          Text(
                            distance! < 1
                                ? '${(distance! * 1000).toStringAsFixed(0)} m'
                                : '${distance!.toStringAsFixed(1)} km',
                            style: const TextStyle(
                                fontSize: 14, color: Color(0xFF555555)),
                          ),
                        ],
                      ),
                    ],
                    if (place.rating != null) ...[
                      const SizedBox(height: 6),
                      Row(
                        children: [
                          const Icon(Icons.star, size: 16, color: Colors.amber),
                          const SizedBox(width: 4),
                          Text(
                            place.rating!.toStringAsFixed(1),
                            style: const TextStyle(
                                fontSize: 14, color: Color(0xFF555555)),
                          ),
                        ],
                      ),
                    ],
                    if (place.openingHours != null) ...[
                      const SizedBox(height: 6),
                      Row(
                        children: [
                          Icon(Icons.access_time,
                              size: 16, color: const Color(0xFF96B6C5)),
                          const SizedBox(width: 4),
                          Text(
                            place.openingHours!.trim() == '24 Jam'
                                ? 'Buka 24 Jam'
                                : place.openingHours!
                                    .split('\n')
                                    .first,
                            style: const TextStyle(
                                fontSize: 13, color: Color(0xFF555555)),
                          ),
                        ],
                      ),
                    ],
                  ],
                ),
              ),
              Container(
                padding: const EdgeInsets.all(6),
                decoration: BoxDecoration(
                  color: const Color(0xFF96B6C5).withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: const Icon(Icons.chevron_right,
                    color: Color(0xFF96B6C5), size: 20),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
