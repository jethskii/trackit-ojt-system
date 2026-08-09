const ALLOWED_MIME_TYPES = new Set([
  'application/pdf',
  'application/msword',
  'application/vnd.openxmlformats-officedocument.wordprocessingml.document',
  'application/vnd.ms-excel',
  'application/vnd.openxmlformats-officedocument.spreadsheetml.sheet',
]);

// Requirement documents (both student submissions and instructor
// templates) are restricted to real office-document formats -- unlike
// e.g. announcement attachments, there's no reason a requirement file
// would ever be an image.
function requirementFileFilter(req, file, cb) {
  cb(null, ALLOWED_MIME_TYPES.has(file.mimetype));
}

module.exports = { requirementFileFilter };
