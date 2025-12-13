-- V3: Add avatar_url column to member table for profile pictures
ALTER TABLE member ADD COLUMN IF NOT EXISTS avatar_url VARCHAR(500);
