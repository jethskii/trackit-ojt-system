-- ============================================================
-- TRACKIT migration: Weekly Accomplishment Reports
--
-- Run this AFTER the other migration_*.sql files. Non-destructive --
-- existing activity_reports rows and columns (title, report_date,
-- hours_rendered, company_id) are left in place, just unused going
-- forward. Activity Reports is now a recurring one-per-week upload slot
-- generated from the student's OJT Start Date, purely a
-- record/compilation with no link to attendance or hours.
-- ============================================================

ALTER TABLE activity_reports
  ADD COLUMN IF NOT EXISTS week_number INTEGER,
  ADD COLUMN IF NOT EXISTS week_start_date DATE,
  ADD COLUMN IF NOT EXISTS week_end_date DATE,
  ADD COLUMN IF NOT EXISTS remarks TEXT;

-- New rows no longer populate these; only relevant to pre-migration data.
ALTER TABLE activity_reports ALTER COLUMN title DROP NOT NULL;
ALTER TABLE activity_reports ALTER COLUMN report_date DROP NOT NULL;

DO $$ BEGIN
  ALTER TABLE activity_reports
    ADD CONSTRAINT activity_reports_student_week_unique UNIQUE (student_id, week_number);
EXCEPTION
  WHEN duplicate_object THEN NULL;
END $$;
