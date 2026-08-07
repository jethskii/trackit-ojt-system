-- ============================================================
-- TRACKIT migration: Announcement images
--
-- Run this AFTER migration_teacher_documents.sql. Non-destructive.
--
-- Adds an optional image to instructor announcements, stored the same
-- way as avatars/requirement uploads (multer disk storage under
-- server/uploads/, served via the existing /uploads static mount) --
-- no new storage architecture, just a column to point at the file.
-- ============================================================

ALTER TABLE announcements
  ADD COLUMN IF NOT EXISTS image_url TEXT;
