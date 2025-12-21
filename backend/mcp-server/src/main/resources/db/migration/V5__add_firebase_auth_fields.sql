-- ToastLabPlus Database Schema
-- Version: V5
-- Description: Add Firebase Auth fields for social login support

-- Add auth_provider field (LOCAL, GOOGLE, FACEBOOK)
ALTER TABLE member ADD COLUMN IF NOT EXISTS auth_provider VARCHAR(20) DEFAULT 'LOCAL';

-- Add firebase_uid field for Firebase user ID
ALTER TABLE member ADD COLUMN IF NOT EXISTS firebase_uid VARCHAR(128);

-- Make password_hash nullable for social login users
ALTER TABLE member ALTER COLUMN password_hash DROP NOT NULL;

-- Create unique index on firebase_uid
CREATE UNIQUE INDEX IF NOT EXISTS idx_member_firebase_uid ON member(firebase_uid) WHERE firebase_uid IS NOT NULL;
