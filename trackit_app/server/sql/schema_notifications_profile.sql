-- ============================================================
-- TRACKIT: Notifications + Profile module schema
--
-- Run this AFTER schema.sql -- it references students and
-- hte_companies created there.
--
-- NOTE: user_sessions and login_history reference a generic
-- "user" (student, instructor, or admin) that doesn't exist yet
-- -- there's no unified auth/users table until the login/
-- activation module is built. Their user_id columns are left as
-- plain BIGINT for now with a comment marking the future FK
-- target, same pattern as reviewed_by in schema.sql.
-- ============================================================

CREATE TYPE notification_category AS ENUM ('admin', 'instructor', 'system');

-- ---------- Advisers & Supervisors ----------

CREATE TABLE advisers (
  id          BIGSERIAL PRIMARY KEY,
  name        TEXT NOT NULL,
  position    TEXT NOT NULL DEFAULT 'OJT Adviser',
  email       TEXT NOT NULL,
  phone       TEXT NOT NULL,
  photo_url   TEXT,
  created_at  TIMESTAMPTZ NOT NULL DEFAULT now()
);

CREATE TABLE supervisors (
  id          BIGSERIAL PRIMARY KEY,
  company_id  BIGINT REFERENCES hte_companies(id) ON DELETE SET NULL,
  name        TEXT NOT NULL,
  position    TEXT NOT NULL DEFAULT 'HR Supervisor',
  email       TEXT NOT NULL,
  phone       TEXT NOT NULL,
  photo_url   TEXT,
  created_at  TIMESTAMPTZ NOT NULL DEFAULT now()
);

-- ---------- Student profile extension ----------
-- 1:1 with students. Keeps course/section/company on `students` as the
-- source of truth -- this only adds fields that don't already live there.

CREATE TABLE student_profiles (
  student_id         BIGINT PRIMARY KEY REFERENCES students(id) ON DELETE CASCADE,
  adviser_id         BIGINT REFERENCES advisers(id) ON DELETE SET NULL,
  supervisor_id      BIGINT REFERENCES supervisors(id) ON DELETE SET NULL,
  phone              TEXT,
  alternate_email    TEXT,
  address            TEXT,
  emergency_contact  TEXT,
  profile_photo_url  TEXT,
  created_at         TIMESTAMPTZ NOT NULL DEFAULT now(),
  updated_at         TIMESTAMPTZ NOT NULL DEFAULT now()
);

-- ---------- Notifications ----------

CREATE TABLE notifications (
  id                 BIGSERIAL PRIMARY KEY,
  receiver_id        BIGINT NOT NULL REFERENCES students(id) ON DELETE CASCADE,
  sender_id          BIGINT, -- future FK once a unified users/staff table exists
  category           notification_category NOT NULL,
  title              TEXT NOT NULL,
  message            TEXT NOT NULL,
  related_module     TEXT, -- e.g. 'documents', 'attendance', 'activity_reports'
  related_record_id  BIGINT,
  action_url         TEXT,
  is_read            BOOLEAN NOT NULL DEFAULT false,
  created_at         TIMESTAMPTZ NOT NULL DEFAULT now()
);

CREATE INDEX idx_notifications_receiver ON notifications (receiver_id, is_read);
CREATE INDEX idx_notifications_created_at ON notifications (created_at DESC);

CREATE TABLE notification_preferences (
  student_id            BIGINT PRIMARY KEY REFERENCES students(id) ON DELETE CASCADE,
  push_enabled          BOOLEAN NOT NULL DEFAULT true,
  email_enabled         BOOLEAN NOT NULL DEFAULT true,
  document_updates      BOOLEAN NOT NULL DEFAULT true,
  attendance_updates    BOOLEAN NOT NULL DEFAULT true,
  report_updates        BOOLEAN NOT NULL DEFAULT true,
  announcement_updates  BOOLEAN NOT NULL DEFAULT true,
  system_updates        BOOLEAN NOT NULL DEFAULT true
);

-- ---------- Help Center ----------

CREATE TABLE help_center_articles (
  id          BIGSERIAL PRIMARY KEY,
  category    TEXT NOT NULL, -- 'faq', 'guide', 'policy', ...
  title       TEXT NOT NULL,
  content     TEXT NOT NULL,
  sort_order  INTEGER NOT NULL DEFAULT 0,
  created_at  TIMESTAMPTZ NOT NULL DEFAULT now()
);

-- ---------- Sessions & login history ----------
-- user_id has no FK yet -- see note at top of file.

CREATE TABLE user_sessions (
  id             BIGSERIAL PRIMARY KEY,
  user_id        BIGINT NOT NULL,
  device_name    TEXT,
  ip_address     TEXT,
  last_login     TIMESTAMPTZ NOT NULL DEFAULT now(),
  last_activity  TIMESTAMPTZ NOT NULL DEFAULT now(),
  is_active      BOOLEAN NOT NULL DEFAULT true
);

CREATE INDEX idx_user_sessions_user ON user_sessions (user_id);

CREATE TABLE login_history (
  id          BIGSERIAL PRIMARY KEY,
  user_id     BIGINT NOT NULL,
  login_at    TIMESTAMPTZ NOT NULL DEFAULT now(),
  logout_at   TIMESTAMPTZ,
  ip_address  TEXT,
  device      TEXT,
  browser     TEXT
);

CREATE INDEX idx_login_history_user ON login_history (user_id);

-- ---------- Profile photo uploads ----------

CREATE TABLE profile_photo_uploads (
  id           BIGSERIAL PRIMARY KEY,
  student_id   BIGINT NOT NULL REFERENCES students(id) ON DELETE CASCADE,
  file_name    TEXT NOT NULL,
  file_path    TEXT NOT NULL,
  mime_type    TEXT NOT NULL,
  file_size    INTEGER NOT NULL,
  uploaded_at  TIMESTAMPTZ NOT NULL DEFAULT now()
);

CREATE INDEX idx_profile_photo_uploads_student ON profile_photo_uploads (student_id);

-- ============================================================
-- Seed data
-- ============================================================

-- Sample adviser/supervisor (matches the app's mock data). Supervisor is
-- linked to the GMMTV company seeded in schema.sql.
INSERT INTO advisers (name, position, email, phone) VALUES
  ('Gawin Caskey', 'OJT Adviser', 'gawin.caskey@dlsp.edu.ph', '+63 917 555 0101');

INSERT INTO supervisors (company_id, name, position, email, phone) VALUES
  (
    (SELECT id FROM hte_companies WHERE name = 'GMMTV Company Limited'),
    'Ayden Sng', 'HR Supervisor', 'ayden.sng@gmmtv.com', '+66 2 111 2233'
  );

-- Help Center content (matches the app's static FAQ/policy content).
INSERT INTO help_center_articles (category, title, content, sort_order) VALUES
  ('faq', 'How do I activate my TRACKIT account?', 'Use the activation code given by your department. Only students on the DCSE master list can activate an account.', 1),
  ('faq', 'How does attendance tracking work?', 'Clock in and out from the Attendance tab. Your total OJT hours and days attended update automatically from your clock-in records.', 2),
  ('faq', 'How do I submit OJT requirements?', 'Go to Document > OJT Requirements. Complete each phase in order -- later phases unlock once the current one is fully submitted and approved.', 3),
  ('faq', 'Can I apply to a company through the app?', 'No. The HTE Directory is for reference only -- you apply to companies directly. TRACKIT does not process internship applications.', 4),
  ('faq', 'What if I need to correct my attendance?', 'Use the Correction Request Form on the Attendance tab to flag an issue for your instructor to review.', 5),
  ('policy', 'Privacy Policy', 'TRACKIT collects only the information needed for OJT monitoring and documentation. Data is used solely by DCSE for OJT purposes and is not shared with third parties.', 1),
  ('policy', 'Terms & Conditions', 'TRACKIT is exclusive to DCSE students, instructors, and administrators. Only students on the department''s master list may activate an account.', 2);

-- No sample rows for student_profiles / notifications / notification_preferences /
-- profile_photo_uploads: those need a real student_id, and no student rows
-- exist yet since account activation/auth isn't built. Once a student can
-- register, the app inserts a matching student_profiles +
-- notification_preferences row alongside it.
