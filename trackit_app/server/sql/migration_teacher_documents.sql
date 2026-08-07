-- ============================================================
-- TRACKIT migration: Teacher Document (OJT Management) module
--
-- Run this AFTER migration_teacher_notifications_announcements.sql.
-- Non-destructive.
--
-- 1. reviewed_by on student_requirement_submissions and
--    attendance_corrections now gets a real FK -- `advisers` exists as
--    a real auth table as of this session, so these are the first real
--    instructor review actions in the app.
-- 2. custom_requirements / custom_requirement_targets: an instructor's
--    ad hoc "Additional Requirement", targeted at their own class(es),
--    same targeting pattern as announcements.
-- 3. student_custom_requirement_submissions: one row per student per
--    custom requirement, mirroring student_requirement_submissions.
-- ============================================================

DO $$ BEGIN
  ALTER TABLE student_requirement_submissions
    ADD CONSTRAINT fk_submissions_reviewed_by
    FOREIGN KEY (reviewed_by) REFERENCES advisers(id) ON DELETE SET NULL;
EXCEPTION
  WHEN duplicate_object THEN NULL;
END $$;

DO $$ BEGIN
  ALTER TABLE attendance_corrections
    ADD CONSTRAINT fk_corrections_reviewed_by
    FOREIGN KEY (reviewed_by) REFERENCES advisers(id) ON DELETE SET NULL;
EXCEPTION
  WHEN duplicate_object THEN NULL;
END $$;

CREATE TABLE IF NOT EXISTS custom_requirements (
  id             BIGSERIAL PRIMARY KEY,
  instructor_id  BIGINT NOT NULL REFERENCES advisers(id) ON DELETE CASCADE,
  title          TEXT NOT NULL,
  description    TEXT NOT NULL DEFAULT '',
  deadline       DATE,
  created_at     TIMESTAMPTZ NOT NULL DEFAULT now()
);

CREATE INDEX IF NOT EXISTS idx_custom_requirements_instructor
  ON custom_requirements (instructor_id, created_at DESC);

CREATE TABLE IF NOT EXISTS custom_requirement_targets (
  id                     BIGSERIAL PRIMARY KEY,
  custom_requirement_id  BIGINT NOT NULL REFERENCES custom_requirements(id) ON DELETE CASCADE,
  class_id               BIGINT NOT NULL REFERENCES instructor_classes(id) ON DELETE CASCADE
);

CREATE INDEX IF NOT EXISTS idx_custom_requirement_targets_requirement
  ON custom_requirement_targets (custom_requirement_id);
CREATE INDEX IF NOT EXISTS idx_custom_requirement_targets_class
  ON custom_requirement_targets (class_id);

CREATE TABLE IF NOT EXISTS student_custom_requirement_submissions (
  id                     BIGSERIAL PRIMARY KEY,
  student_id             BIGINT NOT NULL REFERENCES students(id) ON DELETE CASCADE,
  custom_requirement_id  BIGINT NOT NULL REFERENCES custom_requirements(id) ON DELETE CASCADE,
  status                 requirement_doc_status NOT NULL DEFAULT 'missing',
  uploaded_file_name     TEXT,
  uploaded_file_url      TEXT,
  submitted_at           TIMESTAMPTZ,
  reviewed_at            TIMESTAMPTZ,
  reviewed_by            BIGINT REFERENCES advisers(id) ON DELETE SET NULL,
  remarks                TEXT,
  created_at             TIMESTAMPTZ NOT NULL DEFAULT now(),
  updated_at             TIMESTAMPTZ NOT NULL DEFAULT now(),
  UNIQUE (student_id, custom_requirement_id)
);

CREATE INDEX IF NOT EXISTS idx_custom_submissions_student
  ON student_custom_requirement_submissions (student_id);
