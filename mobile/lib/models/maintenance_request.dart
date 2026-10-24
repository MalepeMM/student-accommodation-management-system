/// Domain model for a maintenance request.
class MaintenanceRequest {
  final String id;
  final String category;
  final String description;
  final String status;
  final DateTime createdAt;

  const MaintenanceRequest({required this.id, required this.category, required this.description, required this.status, required this.createdAt});
}
