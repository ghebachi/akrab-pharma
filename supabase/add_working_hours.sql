-- Add working_hours JSONB column to pharmacies table.
-- Format: { "mon": {"open":"08:00","close":"20:00"}, "tue": ..., "sun": null }
-- null means closed on that day.

ALTER TABLE pharmacies
  ADD COLUMN IF NOT EXISTS working_hours JSONB DEFAULT NULL;

COMMENT ON COLUMN pharmacies.working_hours IS
  'Weekly schedule as JSONB. Keys: mon–sun. Values: {open, close} or null (closed).';
