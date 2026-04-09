-- Enforcing semester_id columns NOT NULL across all tables
-- This ensures consistent semester isolation at the database level

ALTER TABLE tasks ALTER COLUMN semester_id SET NOT NULL;
ALTER TABLE study_sessions ALTER COLUMN semester_id SET NOT NULL;
ALTER TABLE academic_deadlines ALTER COLUMN semester_id SET NOT NULL;
