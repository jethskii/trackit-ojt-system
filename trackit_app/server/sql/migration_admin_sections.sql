-- ============================================================
-- TRACKIT migration: Admin Sections (Students) overview
--
-- Run this AFTER migration_requirement_templates.sql. Non-destructive.
--
-- 1. instructor_classes.instructor_id becomes nullable -- Admin can now
--    create a section (Section Name + Program + Academic Year) before an
--    instructor has been assigned to it (Faculty/Instructors assignment
--    is a separate, not-yet-built feature).
-- 2. instructor_classes.activation_code_created_at tracks when the
--    section's Student Activation Code was generated/regenerated, shown
--    as "Created: <date>" next to the code.
-- 3. students.password_hash becomes nullable, and students.activated_at
--    is added -- Import Students pre-creates a real row with no password
--    (status: Pending) that the student later claims for themselves via
--    the section's activation code (status flips to Activated with a
--    real timestamp). Existing self-registered students are backfilled
--    as already-activated on their original created_at.
-- ============================================================

ALTER TABLE instructor_classes
  ALTER COLUMN instructor_id DROP NOT NULL;

-- Nullable first so existing rows can be backfilled from their real
-- class-creation date (the code has existed since then) rather than
-- from "now" at migration time; new rows always get one via the
-- DEFAULT, application code never needs to set it on INSERT.
ALTER TABLE instructor_classes
  ADD COLUMN IF NOT EXISTS activation_code_created_at TIMESTAMPTZ;

UPDATE instructor_classes
SET activation_code_created_at = created_at
WHERE activation_code_created_at IS NULL;

ALTER TABLE instructor_classes
  ALTER COLUMN activation_code_created_at SET DEFAULT now(),
  ALTER COLUMN activation_code_created_at SET NOT NULL;

ALTER TABLE students
  ALTER COLUMN password_hash DROP NOT NULL;

ALTER TABLE students
  ADD COLUMN IF NOT EXISTS activated_at TIMESTAMPTZ;

UPDATE students
SET activated_at = created_at
WHERE activated_at IS NULL AND password_hash IS NOT NULL;
