class StudentValidation {
  static String? studentNumberError(String? value) {
    final text = value ?? '';
    return text.length == 9 && RegExp(r'^[0-9]{9}$').hasMatch(text)
      ? null : 'Student number must contain exactly 9 digits';
  }
}
