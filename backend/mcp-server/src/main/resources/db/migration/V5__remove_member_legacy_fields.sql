-- Toastlabplus Database Schema
-- Version: V5
-- Description: Remove legacy fields from member table

-- Remove legacy fields (now managed by club_membership and club_admin tables)
ALTER TABLE member DROP COLUMN IF EXISTS club_id;
ALTER TABLE member DROP COLUMN IF EXISTS status;
ALTER TABLE member DROP COLUMN IF EXISTS approved_by;
ALTER TABLE member DROP COLUMN IF EXISTS approved_at;
ALTER TABLE member DROP COLUMN IF EXISTS rejection_reason;

-- Update existing CLUB_ADMIN roles to MEMBER (CLUB_ADMIN is now tracked in club_admin table)
UPDATE member SET role = 'MEMBER' WHERE role = 'CLUB_ADMIN';
