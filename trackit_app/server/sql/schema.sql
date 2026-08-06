-- ============================================================
-- TRACKIT database schema
--
-- Covers what's implemented in the app so far: Student profile,
-- OJT hours/attendance, HTE Directory, the 4-phase OJT
-- Requirements workflow, and Activity Reports.
--
-- NOT included yet (next phase): authentication, activation
-- codes, sections, instructors, admin. `students` below is a
-- minimal identity table just so attendance/documents/reports
-- have something real to reference.
-- ============================================================

-- ---------- Enums ----------

CREATE TYPE requirement_doc_status AS ENUM (
  'missing', 'pending', 'submitted', 'approved', 'rejected'
);

CREATE TYPE activity_report_status AS ENUM (
  'draft', 'submitted', 'reviewed', 'approved', 'needs_revision'
);

-- ---------- HTE Directory ----------

CREATE TABLE hte_companies (
  id                  BIGSERIAL PRIMARY KEY,
  name                TEXT NOT NULL,
  industry            TEXT NOT NULL,
  address             TEXT NOT NULL,
  available_positions INTEGER NOT NULL DEFAULT 0,
  available_slots     INTEGER NOT NULL DEFAULT 0,
  email               TEXT NOT NULL,
  phone               TEXT NOT NULL,
  website             TEXT,
  description         TEXT NOT NULL DEFAULT '',
  created_at          TIMESTAMPTZ NOT NULL DEFAULT now(),
  updated_at          TIMESTAMPTZ NOT NULL DEFAULT now()
);

-- ---------- Students ----------

CREATE TABLE students (
  id              BIGSERIAL PRIMARY KEY,
  name            TEXT NOT NULL,
  email           TEXT NOT NULL UNIQUE,
  password_hash   TEXT NOT NULL,
  course          TEXT NOT NULL,
  section         TEXT NOT NULL,
  company_id      BIGINT REFERENCES hte_companies(id) ON DELETE SET NULL,
  avatar_url      TEXT,
  required_hours  INTEGER NOT NULL DEFAULT 486,
  created_at      TIMESTAMPTZ NOT NULL DEFAULT now(),
  updated_at      TIMESTAMPTZ NOT NULL DEFAULT now()
);

-- ---------- Attendance ----------
-- One row per student per day. Completed hours, days attended,
-- and hour averages shown on the dashboard are computed from
-- this table with queries, not stored redundantly.

CREATE TABLE attendance_records (
  id          BIGSERIAL PRIMARY KEY,
  student_id  BIGINT NOT NULL REFERENCES students(id) ON DELETE CASCADE,
  work_date   DATE NOT NULL,
  clock_in    TIMESTAMPTZ,
  clock_out   TIMESTAMPTZ,
  created_at  TIMESTAMPTZ NOT NULL DEFAULT now(),
  updated_at  TIMESTAMPTZ NOT NULL DEFAULT now(),
  UNIQUE (student_id, work_date)
);

CREATE INDEX idx_attendance_student_date ON attendance_records (student_id, work_date);

-- ---------- OJT Requirements workflow ----------

CREATE TABLE ojt_requirement_phases (
  id           BIGSERIAL PRIMARY KEY,
  order_index  INTEGER NOT NULL UNIQUE,
  title        TEXT NOT NULL,
  description  TEXT NOT NULL
);

CREATE TABLE ojt_requirement_templates (
  id            BIGSERIAL PRIMARY KEY,
  phase_id      BIGINT NOT NULL REFERENCES ojt_requirement_phases(id) ON DELETE CASCADE,
  name          TEXT NOT NULL,
  description   TEXT NOT NULL,
  has_template  BOOLEAN NOT NULL DEFAULT false,
  template_url  TEXT,
  sort_order    INTEGER NOT NULL DEFAULT 0
);

-- One row per student per requirement document.
CREATE TABLE student_requirement_submissions (
  id                       BIGSERIAL PRIMARY KEY,
  student_id               BIGINT NOT NULL REFERENCES students(id) ON DELETE CASCADE,
  requirement_template_id  BIGINT NOT NULL REFERENCES ojt_requirement_templates(id) ON DELETE CASCADE,
  status                   requirement_doc_status NOT NULL DEFAULT 'missing',
  uploaded_file_name       TEXT,
  uploaded_file_url        TEXT,
  deadline                 DATE,
  submitted_at             TIMESTAMPTZ,
  reviewed_at              TIMESTAMPTZ,
  reviewed_by              BIGINT, -- instructor/admin id, once that table exists
  created_at               TIMESTAMPTZ NOT NULL DEFAULT now(),
  updated_at                TIMESTAMPTZ NOT NULL DEFAULT now(),
  UNIQUE (student_id, requirement_template_id)
);

CREATE INDEX idx_submissions_student ON student_requirement_submissions (student_id);

-- A phase counts as completed for a student once every one of its
-- documents is submitted or approved -- compute this with a query
-- (or a view) rather than storing a redundant phase-status column.

-- ---------- Activity Reports ----------

CREATE TABLE activity_reports (
  id              BIGSERIAL PRIMARY KEY,
  student_id      BIGINT NOT NULL REFERENCES students(id) ON DELETE CASCADE,
  title           TEXT NOT NULL,
  report_date     DATE NOT NULL,
  hours_rendered  NUMERIC(5,2) NOT NULL DEFAULT 0,
  description     TEXT NOT NULL DEFAULT '',
  status          activity_report_status NOT NULL DEFAULT 'draft',
  created_at      TIMESTAMPTZ NOT NULL DEFAULT now(),
  updated_at      TIMESTAMPTZ NOT NULL DEFAULT now()
);

CREATE INDEX idx_activity_reports_student ON activity_reports (student_id);

CREATE TABLE activity_report_attachments (
  id                  BIGSERIAL PRIMARY KEY,
  activity_report_id  BIGINT NOT NULL REFERENCES activity_reports(id) ON DELETE CASCADE,
  file_name           TEXT NOT NULL,
  file_url            TEXT,
  uploaded_at         TIMESTAMPTZ NOT NULL DEFAULT now()
);

-- ============================================================
-- Seed data
-- ============================================================

-- The 4 fixed OJT requirement phases (matches the app's mock data).
INSERT INTO ojt_requirement_phases (order_index, title, description) VALUES
  (1, 'Pre-Application', 'Submit your Pre-Application Form & Company Details.'),
  (2, 'Requirements', 'Submit Required Documents to proceed.'),
  (3, 'Internship Docs', 'Submit Internship Related Documents.'),
  (4, 'Final Documents', 'Track the Status & Submission of All Documents.');

-- Phase 1: Pre-Application
INSERT INTO ojt_requirement_templates (phase_id, name, description, has_template, sort_order) VALUES
  ((SELECT id FROM ojt_requirement_phases WHERE order_index = 1), 'Pre-Application Form', 'Basic student and company information form.', true, 1),
  ((SELECT id FROM ojt_requirement_phases WHERE order_index = 1), 'Company Details', 'Details of your chosen HTE.', false, 2);

-- Phase 2: Requirements
INSERT INTO ojt_requirement_templates (phase_id, name, description, has_template, sort_order) VALUES
  ((SELECT id FROM ojt_requirement_phases WHERE order_index = 2), 'Resume', 'Updated resume/CV.', true, 1),
  ((SELECT id FROM ojt_requirement_phases WHERE order_index = 2), 'Application Letter', 'Letter of intent to the HTE.', true, 2),
  ((SELECT id FROM ojt_requirement_phases WHERE order_index = 2), 'Endorsement Letter', 'Endorsement from the department.', false, 3),
  ((SELECT id FROM ojt_requirement_phases WHERE order_index = 2), 'MOA', 'Memorandum of Agreement between school and HTE.', true, 4),
  ((SELECT id FROM ojt_requirement_phases WHERE order_index = 2), 'Parent Consent', 'Signed parental consent form.', true, 5),
  ((SELECT id FROM ojt_requirement_phases WHERE order_index = 2), 'Medical Certificate', 'Certificate of fitness to work.', false, 6),
  ((SELECT id FROM ojt_requirement_phases WHERE order_index = 2), 'Insurance', 'Proof of student insurance coverage.', false, 7);

-- Phase 3: Internship Docs
INSERT INTO ojt_requirement_templates (phase_id, name, description, has_template, sort_order) VALUES
  ((SELECT id FROM ojt_requirement_phases WHERE order_index = 3), 'Weekly Report', 'Weekly activity report.', true, 1),
  ((SELECT id FROM ojt_requirement_phases WHERE order_index = 3), 'Monthly Report', 'Monthly summary report.', true, 2),
  ((SELECT id FROM ojt_requirement_phases WHERE order_index = 3), 'Attendance', 'Attendance summary for the period.', false, 3),
  ((SELECT id FROM ojt_requirement_phases WHERE order_index = 3), 'Supervisor Evaluation', 'Evaluation from your HTE supervisor.', false, 4),
  ((SELECT id FROM ojt_requirement_phases WHERE order_index = 3), 'Faculty Evaluation', 'Evaluation from your assigned instructor.', false, 5),
  ((SELECT id FROM ojt_requirement_phases WHERE order_index = 3), 'Company Evaluation', 'Evaluation of the HTE by the student.', false, 6);

-- Phase 4: Final Documents
INSERT INTO ojt_requirement_templates (phase_id, name, description, has_template, sort_order) VALUES
  ((SELECT id FROM ojt_requirement_phases WHERE order_index = 4), 'Final Report', 'Comprehensive final OJT report.', true, 1),
  ((SELECT id FROM ojt_requirement_phases WHERE order_index = 4), 'Completion Certificate', 'Certificate of completion from the HTE.', false, 2),
  ((SELECT id FROM ojt_requirement_phases WHERE order_index = 4), 'Clearance', 'Department clearance form.', true, 3),
  ((SELECT id FROM ojt_requirement_phases WHERE order_index = 4), 'Exit Evaluation', 'Final exit evaluation form.', false, 4),
  ((SELECT id FROM ojt_requirement_phases WHERE order_index = 4), 'Final Rating', 'Final rating given by the HTE.', false, 5);

-- Sample HTE companies (matches the app's mock data, optional -- delete
-- this block if you'd rather start with an empty directory).
INSERT INTO hte_companies (name, industry, address, available_positions, available_slots, email, phone, website, description) VALUES
  ('GMMTV Company Limited', 'Media & Entertainment', 'Bangkok, Thailand', 3, 5, 'careers@gmmtv.com', '+66 2 111 2222', 'https://gmmtv.com', 'A leading media production company specializing in digital content, broadcasting, and artist management.'),
  ('Accenture Philippines', 'Information Technology', 'San Pablo City, Laguna', 10, 12, 'internship@accenture.com', '+63 2 8988 5000', 'https://accenture.com', 'Global professional services company offering IT and consulting internship programs for computing students.'),
  ('San Pablo City Hall - IT Department', 'Government', 'San Pablo City, Laguna', 4, 4, 'it@sanpablocity.gov.ph', '+63 49 562 1234', NULL, 'Local government IT department handling systems, networks, and digital services for the city.'),
  ('Innodata Philippines', 'Business Process Outsourcing', 'Calamba, Laguna', 6, 8, 'careers@innodata.com', '+63 49 545 6789', 'https://innodata.com', 'BPO company providing data engineering, annotation, and AI training data services.');
