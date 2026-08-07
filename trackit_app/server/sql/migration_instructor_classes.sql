-- ============================================================
-- TRACKIT migration: Instructor classes + activation codes
--
-- Run this AFTER migration_instructor_auth_and_dashboard.sql.
-- Non-destructive.
--
-- The Teacher Students tab wants a "Class Activation Code" that
-- students use to join -- normally admin-generated, but there's no
-- Admin module yet, so instructors create their own class (program +
-- section + academic year) and the server generates the code. Student
-- registration now joins a class by code instead of free-typing
-- course/section and picking an adviser separately (see
-- migration_instructor_classes' companion route changes).
-- ============================================================

CREATE TABLE IF NOT EXISTS instructor_classes (
  id                BIGSERIAL PRIMARY KEY,
  instructor_id     BIGINT NOT NULL REFERENCES advisers(id) ON DELETE CASCADE,
  program           TEXT NOT NULL,
  section           TEXT NOT NULL,
  academic_year     TEXT NOT NULL,
  activation_code   TEXT NOT NULL UNIQUE,
  created_at        TIMESTAMPTZ NOT NULL DEFAULT now()
);

CREATE INDEX IF NOT EXISTS idx_instructor_classes_instructor
  ON instructor_classes (instructor_id);

-- Students join a class, not just pick an adviser -- this is what
-- registration now sets (replacing the free-typed course/section and
-- the plain adviser_id-only linkage from the previous migration).
ALTER TABLE student_profiles
  ADD COLUMN IF NOT EXISTS class_id BIGINT REFERENCES instructor_classes(id) ON DELETE SET NULL;
