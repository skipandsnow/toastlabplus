-- V8: Add meeting management entities

-- 1. Add new columns to meeting table
ALTER TABLE meeting ADD COLUMN IF NOT EXISTS meeting_number INT;
ALTER TABLE meeting ADD COLUMN IF NOT EXISTS speaker_count INT DEFAULT 3;
ALTER TABLE meeting ADD COLUMN IF NOT EXISTS template_id BIGINT;
ALTER TABLE meeting ADD COLUMN IF NOT EXISTS schedule_id BIGINT;

-- 2. Create role_slot table
CREATE TABLE IF NOT EXISTS role_slot (
    id BIGSERIAL PRIMARY KEY,
    meeting_id BIGINT NOT NULL REFERENCES meeting(id) ON DELETE CASCADE,
    role_name VARCHAR(50) NOT NULL,
    slot_index INT DEFAULT 1,
    assigned_member_id BIGINT REFERENCES member(id),
    speech_title VARCHAR(200),
    project_name VARCHAR(100),
    assigned_at TIMESTAMP,
    assigned_by_id BIGINT REFERENCES member(id),
    created_at TIMESTAMP DEFAULT NOW()
);

CREATE INDEX idx_role_slot_meeting ON role_slot(meeting_id);
CREATE INDEX idx_role_slot_member ON role_slot(assigned_member_id);

-- 3. Create meeting_schedule table for recurring meetings
CREATE TABLE IF NOT EXISTS meeting_schedule (
    id BIGSERIAL PRIMARY KEY,
    club_id BIGINT NOT NULL REFERENCES club(id) ON DELETE CASCADE,
    name VARCHAR(100),
    
    -- Frequency settings
    frequency VARCHAR(20) NOT NULL, -- WEEKLY, BIWEEKLY, MONTHLY
    day_of_week INT, -- 1-7 (Monday-Sunday)
    week_of_month INT[], -- [1, 3] = 1st and 3rd week
    
    -- Time settings
    start_time TIME NOT NULL,
    end_time TIME NOT NULL,
    
    -- Defaults
    template_id BIGINT,
    default_speaker_count INT DEFAULT 3,
    default_location VARCHAR(200),
    
    -- Auto-generation settings
    auto_generate_months INT DEFAULT 3,
    
    is_active BOOLEAN DEFAULT true,
    created_at TIMESTAMP DEFAULT NOW(),
    updated_at TIMESTAMP DEFAULT NOW(),
    created_by_id BIGINT REFERENCES member(id)
);

CREATE INDEX idx_meeting_schedule_club ON meeting_schedule(club_id);

-- 4. Add foreign key for schedule_id in meeting
ALTER TABLE meeting ADD CONSTRAINT fk_meeting_schedule 
    FOREIGN KEY (schedule_id) REFERENCES meeting_schedule(id) ON DELETE SET NULL;
