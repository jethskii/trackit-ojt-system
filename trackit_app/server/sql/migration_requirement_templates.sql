-- ============================================================
-- TRACKIT migration: Requirement template files
--
-- Wires up real instructor-uploaded template files for both Official
-- Requirements (ojt_requirement_templates already had an unused
-- template_url column) and Additional Requirements (custom_requirements,
-- which had no template columns at all). Non-destructive.
-- ============================================================

ALTER TABLE ojt_requirement_templates
  ADD COLUMN IF NOT EXISTS template_name TEXT;

ALTER TABLE custom_requirements
  ADD COLUMN IF NOT EXISTS template_url  TEXT,
  ADD COLUMN IF NOT EXISTS template_name TEXT;
