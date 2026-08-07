-- ============================================================
-- TRACKIT migration: Attendance geofencing + Correction Requests
--
-- Run this AFTER schema.sql, schema_notifications_profile.sql, and
-- migration_company_details_remarks.sql. Non-destructive.
--
-- Adds:
--   1. company_latitude/company_longitude on student_profiles -- the
--      geofence center captured by the student via "Set My Location" on
--      Confirm Company Details. Clock In/Out is rejected server-side if
--      the student is outside 100m of this point (or if it isn't set).
--   2. attendance_corrections -- a student's request to fix an attendance
--      record, routed to an instructor for approve/reject. No Instructor
--      module exists yet to review these, so they stay 'pending' -- the
--      table and status column are ready for when it does.
-- ============================================================

ALTER TABLE student_profiles
  ADD COLUMN IF NOT EXISTS company_latitude DOUBLE PRECISION,
  ADD COLUMN IF NOT EXISTS company_longitude DOUBLE PRECISION;

DO $$ BEGIN
  CREATE TYPE attendance_correction_status AS ENUM ('pending', 'approved', 'rejected');
EXCEPTION
  WHEN duplicate_object THEN NULL;
END $$;

CREATE TABLE IF NOT EXISTS attendance_corrections (
  id                    BIGSERIAL PRIMARY KEY,
  student_id            BIGINT NOT NULL REFERENCES students(id) ON DELETE CASCADE,
  work_date             DATE NOT NULL,
  reason                TEXT NOT NULL,
  attachment_file_name  TEXT,
  attachment_file_url   TEXT,
  status                attendance_correction_status NOT NULL DEFAULT 'pending',
  reviewer_note         TEXT,
  reviewed_at           TIMESTAMPTZ,
  reviewed_by           BIGINT, -- instructor/admin id, once that table exists
  created_at            TIMESTAMPTZ NOT NULL DEFAULT now()
);

CREATE INDEX IF NOT EXISTS idx_attendance_corrections_student
  ON attendance_corrections (student_id, created_at DESC);
