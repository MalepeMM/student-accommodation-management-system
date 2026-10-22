/// Domain model for a student's accommodation application.
class StudentApplication {
  final String id;
  final String accommodationId;
  final String studentName;
  final String status;
  final DateTime submittedAt;

  const StudentApplication({required this.id, required this.accommodationId, required this.studentName, required this.status, required this.submittedAt});
}
