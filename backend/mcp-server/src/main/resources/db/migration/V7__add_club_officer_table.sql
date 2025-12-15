-- Create club_officer table for managing club officer positions
CREATE TABLE club_officer (
    id BIGSERIAL PRIMARY KEY,
    club_id BIGINT NOT NULL REFERENCES club(id) ON DELETE CASCADE,
    member_id BIGINT REFERENCES member(id) ON DELETE SET NULL,
    position VARCHAR(20) NOT NULL,
    term_start DATE,
    term_end DATE,
    is_active BOOLEAN NOT NULL DEFAULT true,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);

-- Unique constraint: only one active officer per position per club
CREATE UNIQUE INDEX uk_club_position_active ON club_officer (club_id, position) WHERE is_active = true;

-- Index for efficient queries
CREATE INDEX idx_club_officer_club_id ON club_officer(club_id);
CREATE INDEX idx_club_officer_member_id ON club_officer(member_id);
CREATE INDEX idx_club_officer_active ON club_officer(is_active);
