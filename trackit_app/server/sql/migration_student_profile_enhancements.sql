-- ============================================================
-- TRACKIT migration: Student profile -- name-change cooldown +
-- real login history
--
-- Run this AFTER migration_attendance_daily_attempts.sql.
-- Non-destructive.
--
-- 1. students.name_changed_at -- null until the student's first name
--    change; PATCH /api/profile enforces a 14-day cooldown against it
--    (see routes/profile.js). Existing accounts start eligible (null).
-- 2. login_history -- one row per issued token (register or login),
--    closed by POST /api/auth/logout. The JWT itself carries the row's
--    id as `sessionId` (see middleware/auth.js) so logout closes
--    exactly the right session even with multiple devices logged in
--    at once, rather than guessing "the most recent open one."
--
--    schema_notifications_profile.sql already created a placeholder
--    `login_history` table (generic user_id, never written to by any
--    real code path -- it predates the auth system). CREATE TABLE IF
--    NOT EXISTS would silently keep that incompatible table instead
--    of this one, so it's dropped and recreated here. Safe: nothing
--    ever wrote to the placeholder, so there's no real data to lose.
-- ============================================================

ALTER TABLE students
  ADD COLUMN IF NOT EXISTS name_changed_at TIMESTAMPTZ;

DROP TABLE IF EXISTS login_history;

CREATE TABLE login_history (
  id          BIGSERIAL PRIMARY KEY,
  student_id  BIGINT NOT NULL REFERENCES students(id) ON DELETE CASCADE,
  login_at    TIMESTAMPTZ NOT NULL DEFAULT now(),
  logout_at   TIMESTAMPTZ,
  user_agent  TEXT,
  created_at  TIMESTAMPTZ NOT NULL DEFAULT now()
);

CREATE INDEX idx_login_history_student
  ON login_history (student_id, login_at DESC);
