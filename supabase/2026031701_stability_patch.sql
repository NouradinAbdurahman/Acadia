-- Stability Patch: Fix session_type constraints and defaults
-- Part of Academic Risk Scoring preparation

-- 1. Correct null session types
UPDATE study_sessions
SET session_type = 'deep_work'
WHERE session_type IS NULL;

-- 2. Ensure constraints exist for session types
-- First check if the constraint exists, if not add it
DO $$
BEGIN
    IF NOT EXISTS (
        SELECT 1 
        FROM information_schema.constraint_column_usage 
        WHERE table_name = 'study_sessions' AND constraint_name = 'study_sessions_session_type_check'
    ) THEN
        ALTER TABLE study_sessions 
        ADD CONSTRAINT study_sessions_session_type_check 
        CHECK (session_type IN ('pomodoro', 'deep_work', 'review', 'practice'));
    END IF;
END $$;

-- 3. Ensure academic_profile_completed exists on users table
DO $$
BEGIN
    IF NOT EXISTS (
        SELECT 1 FROM information_schema.columns 
        WHERE table_name = 'users' AND column_name = 'academic_profile_completed'
    ) THEN
        ALTER TABLE users ADD COLUMN academic_profile_completed BOOLEAN DEFAULT false;
    END IF;
END $$;
