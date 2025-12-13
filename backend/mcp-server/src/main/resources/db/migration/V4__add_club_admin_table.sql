-- Create club_admin table for multi-club admin assignments
CREATE TABLE IF NOT EXISTS club_admin (
    id BIGSERIAL PRIMARY KEY,
    member_id BIGINT NOT NULL REFERENCES member(id) ON DELETE CASCADE,
    club_id BIGINT NOT NULL REFERENCES club(id) ON DELETE CASCADE,
    assigned_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    assigned_by BIGINT REFERENCES member(id),
    UNIQUE(member_id, club_id)
);

-- Create index for faster lookups
CREATE INDEX IF NOT EXISTS idx_club_admin_member ON club_admin(member_id);
CREATE INDEX IF NOT EXISTS idx_club_admin_club ON club_admin(club_id);
