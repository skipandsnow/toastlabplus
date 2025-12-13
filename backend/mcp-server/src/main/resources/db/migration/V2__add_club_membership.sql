-- Toastlabplus Database Schema
-- Version: V2
-- Description: Add club_membership table for two-stage registration

-- CLUB_MEMBERSHIP table for tracking club membership applications
CREATE TABLE club_membership (
    id BIGSERIAL PRIMARY KEY,
    member_id BIGINT NOT NULL REFERENCES member(id) ON DELETE CASCADE,
    club_id BIGINT NOT NULL REFERENCES club(id) ON DELETE CASCADE,
    status VARCHAR(20) NOT NULL DEFAULT 'PENDING',
    approved_by BIGINT REFERENCES member(id),
    approved_at TIMESTAMP,
    rejection_reason TEXT,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    UNIQUE(member_id, club_id)
);

CREATE INDEX idx_club_membership_member ON club_membership(member_id);
CREATE INDEX idx_club_membership_club ON club_membership(club_id);
CREATE INDEX idx_club_membership_status ON club_membership(status);

-- Remove the hardcoded admin from V1 (DataInitializer will create it dynamically)
DELETE FROM member WHERE email = 'admin@toastlabplus.com' AND password_hash = '$2a$10$placeholder_hash_change_me';
