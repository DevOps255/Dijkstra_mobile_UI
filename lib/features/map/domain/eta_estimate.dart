class EtaEstimate {
  const EtaEstimate({
    required this.distanceMeters,
    required this.estimatedMinutes,
    required this.isApproaching,
  });

  final int distanceMeters;
  final int? estimatedMinutes;
  final bool isApproaching;
}
