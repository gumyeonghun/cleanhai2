import 'package:cloud_firestore/cloud_firestore.dart';

class Review {
  final double rating;
  final double? communicationRating;
  final double? qualityRating;
  final double? reliabilityRating;
  final double? priceRating;
  final String comment;
  final DateTime createdAt;

  Review({
    required this.rating,
    this.communicationRating,
    this.qualityRating,
    this.reliabilityRating,
    this.priceRating,
    required this.comment,
    required this.createdAt,
  });

  factory Review.fromMap(Map<String, dynamic> map) {
    return Review(
      rating: (map['rating'] as num).toDouble(),
      communicationRating: map['communicationRating'] != null ? (map['communicationRating'] as num).toDouble() : (map['rating'] as num).toDouble(),
      qualityRating: map['qualityRating'] != null ? (map['qualityRating'] as num).toDouble() : (map['rating'] as num).toDouble(),
      reliabilityRating: map['reliabilityRating'] != null ? (map['reliabilityRating'] as num).toDouble() : (map['rating'] as num).toDouble(),
      priceRating: map['priceRating'] != null ? (map['priceRating'] as num).toDouble() : (map['rating'] as num).toDouble(),
      comment: map['comment'] ?? '',
      createdAt: (map['createdAt'] as Timestamp).toDate(),
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'rating': rating,
      'communicationRating': communicationRating,
      'qualityRating': qualityRating,
      'reliabilityRating': reliabilityRating,
      'priceRating': priceRating,
      'comment': comment,
      'createdAt': Timestamp.fromDate(createdAt),
    };
  }
}
