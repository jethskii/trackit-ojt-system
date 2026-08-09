import 'package:flutter/material.dart';

enum AttachmentKind { image, pdf, doc, other }

/// Determines how to render an attachment from its filename/URL extension
/// -- images get an inline preview, PDF/DOCX get a labeled file chip
/// (they can't be previewed inline without a dedicated viewer).
AttachmentKind attachmentKindOf(String? nameOrUrl) {
  if (nameOrUrl == null) return AttachmentKind.other;
  final ext = nameOrUrl.split('.').last.toLowerCase();
  switch (ext) {
    case 'jpg':
    case 'jpeg':
    case 'png':
    case 'webp':
      return AttachmentKind.image;
    case 'pdf':
      return AttachmentKind.pdf;
    case 'doc':
    case 'docx':
      return AttachmentKind.doc;
    default:
      return AttachmentKind.other;
  }
}

IconData attachmentIconOf(AttachmentKind kind) {
  switch (kind) {
    case AttachmentKind.image:
      return Icons.image_outlined;
    case AttachmentKind.pdf:
      return Icons.picture_as_pdf_outlined;
    case AttachmentKind.doc:
      return Icons.description_outlined;
    case AttachmentKind.other:
      return Icons.insert_drive_file_outlined;
  }
}
