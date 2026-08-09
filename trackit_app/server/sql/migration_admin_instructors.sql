-- ============================================================
-- TRACKIT migration: Admin Faculty/Instructors overview
--
-- Run this AFTER migration_admin_sections.sql. Non-destructive.
--
-- Turns advisers into fully admin-manageable Faculty accounts, mirroring
-- the Student Import/activation pattern: Admin creates the row (no
-- password yet -- Pending), a real Instructor Activation Code is
-- generated, and the instructor claims their own account by registering
-- with that code (see routes/instructorAuth.js). This activation code is
-- a completely separate value from any Student activation code
-- (instructor_classes.activation_code) -- there is no shared code space.
--
-- status is a separate, admin-controlled enable/disable flag (Revoke
-- Access / Reactivate), independent of whether the account has been
-- activated yet.
-- ============================================================

ALTER TABLE advisers
  ADD COLUMN IF NOT EXISTS instructor_number TEXT,
  ADD COLUMN IF NOT EXISTS department TEXT,
  ADD COLUMN IF NOT EXISTS date_hired DATE,
  ADD COLUMN IF NOT EXISTS status TEXT NOT NULL DEFAULT 'active',
  ADD COLUMN IF NOT EXISTS activation_code TEXT,
  ADD COLUMN IF NOT EXISTS activation_code_created_at TIMESTAMPTZ,
  ADD COLUMN IF NOT EXISTS activated_at TIMESTAMPTZ,
  ADD COLUMN IF NOT EXISTS last_login_at TIMESTAMPTZ;

-- Deterministic backfill for existing rows -- id is already unique, so
-- these are guaranteed collision-free without a procedural loop. New
-- rows going forward get a randomly-generated code instead (see
-- utils/activationCode.js's generateInstructorActivationCode), so a
-- regenerated code is actually different each time rather than always
-- recomputing back to the same id-derived value.
UPDATE advisers
SET instructor_number = 'DCSE-' || LPAD(id::text, 3, '0')
WHERE instructor_number IS NULL;

UPDATE advisers
SET activation_code = 'FAC-' || EXTRACT(YEAR FROM now())::int || '-' || LPAD(id::text, 3, '0')
WHERE activation_code IS NULL;

UPDATE advisers
SET activation_code_created_at = created_at
WHERE activation_code_created_at IS NULL;

-- Existing advisers already have a password (the old free-registration
-- flow) -- they were, in effect, activated the moment they registered.
UPDATE advisers
SET activated_at = created_at
WHERE activated_at IS NULL AND password_hash IS NOT NULL;

DO $$ BEGIN
  ALTER TABLE advisers ADD CONSTRAINT advisers_instructor_number_unique UNIQUE (instructor_number);
EXCEPTION
  WHEN duplicate_object THEN NULL;
END $$;

DO $$ BEGIN
  ALTER TABLE advisers ADD CONSTRAINT advisers_activation_code_unique UNIQUE (activation_code);
EXCEPTION
  WHEN duplicate_object THEN NULL;
END $$;

ALTER TABLE advisers
  ALTER COLUMN instructor_number SET NOT NULL,
  ALTER COLUMN activation_code SET NOT NULL,
  ALTER COLUMN activation_code_created_at SET NOT NULL,
  ALTER COLUMN activation_code_created_at SET DEFAULT now();
