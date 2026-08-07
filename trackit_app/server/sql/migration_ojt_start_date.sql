-- ============================================================
-- TRACKIT migration: OJT Start Date
--
-- Run this AFTER the other migration_*.sql files. Non-destructive.
--
-- Adds ojt_start_date to student_profiles, captured by the student on
-- the Confirm Company Details form. Gives the Home tab's OJT Hours
-- Progress status badge (On Track/Behind/Needs Attention/Ahead of
-- Schedule/Completed) a real timeline to compare actual attendance pace
-- against, instead of a hardcoded heuristic.
-- ============================================================

ALTER TABLE student_profiles
  ADD COLUMN IF NOT EXISTS ojt_start_date DATE;
