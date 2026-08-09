/// Shared between student requirement submissions and instructor
/// template uploads -- both are restricted to real office-document
/// formats, matching the server's requirementFileFilter.
const List<String> requirementFileExtensions = ['pdf', 'doc', 'docx', 'xls', 'xlsx'];

String requirementFileContentType(String? extension) {
  switch (extension?.toLowerCase()) {
    case 'pdf':
      return 'application/pdf';
    case 'doc':
      return 'application/msword';
    case 'docx':
      return 'application/vnd.openxmlformats-officedocument.wordprocessingml.document';
    case 'xls':
      return 'application/vnd.ms-excel';
    case 'xlsx':
      return 'application/vnd.openxmlformats-officedocument.spreadsheetml.sheet';
    default:
      return 'application/octet-stream';
  }
}
