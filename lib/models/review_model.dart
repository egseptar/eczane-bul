class ReviewModel {
  final String id;
  final String authorName;
  final String authorInitials;
  final double rating;
  final String comment;
  final String timeAgo;
  final int helpfulCount;

  const ReviewModel({
    required this.id,
    required this.authorName,
    required this.authorInitials,
    required this.rating,
    required this.comment,
    required this.timeAgo,
    required this.helpfulCount,
  });

  factory ReviewModel.fromJson(Map<String, dynamic> json) {
    return ReviewModel(
      id: json['id'] as String,
      authorName: json['authorName'] as String,
      authorInitials: json['authorInitials'] as String,
      rating: (json['rating'] as num).toDouble(),
      comment: json['comment'] as String,
      timeAgo: json['timeAgo'] as String,
      helpfulCount: json['helpfulCount'] as int,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'authorName': authorName,
      'authorInitials': authorInitials,
      'rating': rating,
      'comment': comment,
      'timeAgo': timeAgo,
      'helpfulCount': helpfulCount,
    };
  }
}
