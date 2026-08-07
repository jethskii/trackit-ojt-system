-- ============================================================
-- TRACKIT migration: Confirm Company Details + requirement remarks
--
-- Run this AFTER schema.sql and schema_notifications_profile.sql.
-- Non-destructive -- safe to run even if some columns already exist.
--
-- Adds:
--   1. Self-reported company columns on student_profiles, populated by
--      the student's Confirm Company Details form (independent of the
--      HTE Directory / hte_companies table).
--   2. remarks on student_requirement_submissions, for instructor
--      feedback on a rejected/re-upload-requested document (no
--      Instructor module writes this yet, but the column is ready).
--   3. The "Registration/Enrollment Form" requirement template in
--      Phase 2, matching the app's mock data (no template, upload only).
-- ============================================================

ALTER TABLE student_profiles
  ADD COLUMN IF NOT EXISTS company_name TEXT,
  ADD COLUMN IF NOT EXISTS company_address TEXT,
  ADD COLUMN IF NOT EXISTS company_industry TEXT,
  ADD COLUMN IF NOT EXISTS company_supervisor_name TEXT,
  ADD COLUMN IF NOT EXISTS company_contact_number TEXT,
  ADD COLUMN IF NOT EXISTS company_confirmed_at TIMESTAMPTZ;

ALTER TABLE student_requirement_submissions
  ADD COLUMN IF NOT EXISTS remarks TEXT;

-- Shift Insurance (previously sort_order 7, last in Phase 2) down to make
-- room for Registration/Enrollment Form between it and Medical Certificate
-- (sort_order 6), matching the app's mock data order.
UPDATE ojt_requirement_templates
SET sort_order = 8
WHERE name = 'Insurance'
  AND phase_id = (SELECT id FROM ojt_requirement_phases WHERE order_index = 2)
  AND sort_order = 7;

INSERT INTO ojt_requirement_templates (phase_id, name, description, has_template, sort_order)
SELECT
  (SELECT id FROM ojt_requirement_phases WHERE order_index = 2),
  'Registration/Enrollment Form',
  'Proof of enrollment for the current term, obtained from the registrar.',
  false,
  7
WHERE NOT EXISTS (
  SELECT 1 FROM ojt_requirement_templates
  WHERE name = 'Registration/Enrollment Form'
    AND phase_id = (SELECT id FROM ojt_requirement_phases WHERE order_index = 2)
);
