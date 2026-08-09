-- ============================================================
-- TRACKIT migration: Admin Announcement attachments (PDF/DOCX)
--
-- Run this AFTER migration_admin_announcements.sql. Non-destructive.
--
-- Admin announcement attachments are no longer image-only, so
-- image_url is renamed to the more accurate attachment_url, and a
-- new attachment_name column keeps the original filename (needed to
-- render a sensible label/icon for a PDF or DOCX, which can't be
-- previewed as an image).
-- ============================================================

DO $$
BEGIN
  IF EXISTS (
    SELECT 1 FROM information_schema.columns
    WHERE table_name = 'admin_announcements' AND column_name = 'image_url'
  ) THEN
    ALTER TABLE admin_announcements RENAME COLUMN image_url TO attachment_url;
  END IF;
END $$;

ALTER TABLE admin_announcements ADD COLUMN IF NOT EXISTS attachment_name TEXT;
