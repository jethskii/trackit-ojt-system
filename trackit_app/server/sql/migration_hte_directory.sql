-- ============================================================
-- TRACKIT migration: HTE Directory redesign (Admin-managed)
--
-- Run this AFTER migration_admin_announcements_attachments.sql.
-- Non-destructive.
--
-- The HTE Directory is now fully Admin-managed: a short "location"
-- label (distinct from the full address), a "date accredited", and
-- one-to-many contact persons (name + phone each) replace the single
-- company-level phone. available_positions/available_slots/
-- description stay in the table (still have their DEFAULT, so
-- inserts that omit them are unaffected) but are no longer surfaced
-- anywhere -- the feature has no application/slot-tracking per the
-- current spec, so nothing reads or writes them going forward.
-- ============================================================

ALTER TABLE hte_companies
  ADD COLUMN IF NOT EXISTS location TEXT,
  ADD COLUMN IF NOT EXISTS date_accredited DATE;

ALTER TABLE hte_companies ALTER COLUMN phone DROP NOT NULL;

CREATE TABLE IF NOT EXISTS hte_company_contacts (
  id          BIGSERIAL PRIMARY KEY,
  company_id  BIGINT NOT NULL REFERENCES hte_companies(id) ON DELETE CASCADE,
  name        TEXT NOT NULL,
  phone       TEXT NOT NULL,
  created_at  TIMESTAMPTZ NOT NULL DEFAULT now()
);

CREATE INDEX IF NOT EXISTS idx_hte_company_contacts_company
  ON hte_company_contacts (company_id);
