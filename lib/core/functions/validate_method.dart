String? validateField(String? value, String fieldName) {
  if (value == null || value.trim().isEmpty) {
    return 'الرجاء إدخال $fieldName';
  }
  return null;
}
