-- Toastlabplus Database Schema
-- Version: V1
-- Description: Initial schema setup

-- 1. CLUB
CREATE TABLE club (
    id BIGSERIAL PRIMARY KEY,
    name VARCHAR(100) NOT NULL,
    description TEXT,
    location VARCHAR(200),
    meeting_day VARCHAR(20),
    meeting_time TIME,
    contact_email VARCHAR(100),
    contact_phone VARCHAR(30),
    is_active BOOLEAN DEFAULT TRUE,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);

-- 2. MEMBER
CREATE TABLE member (
    id BIGSERIAL PRIMARY KEY,
    club_id BIGINT REFERENCES club(id),
    email VARCHAR(100) NOT NULL UNIQUE,
    password_hash VARCHAR(255) NOT NULL,
    name VARCHAR(100) NOT NULL,
    phone VARCHAR(30),
    role VARCHAR(30) NOT NULL DEFAULT 'MEMBER',
    club_position VARCHAR(30),
    status VARCHAR(20) NOT NULL DEFAULT 'PENDING',
    notification_push BOOLEAN DEFAULT TRUE,
    notification_email BOOLEAN DEFAULT TRUE,
    fcm_token TEXT,
    approved_by BIGINT REFERENCES member(id),
    approved_at TIMESTAMP,
    rejection_reason TEXT,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);

CREATE INDEX idx_member_club ON member(club_id);
CREATE INDEX idx_member_email ON member(email);
CREATE INDEX idx_member_status ON member(status);

-- 3. MEETING
CREATE TABLE meeting (
    id BIGSERIAL PRIMARY KEY,
    club_id BIGINT NOT NULL REFERENCES club(id),
    title VARCHAR(200),
    theme VARCHAR(200),
    meeting_date DATE NOT NULL,
    start_time TIME NOT NULL,
    end_time TIME,
    location VARCHAR(200),
    status VARCHAR(20) NOT NULL DEFAULT 'DRAFT',
    created_by BIGINT REFERENCES member(id),
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);

CREATE INDEX idx_meeting_club ON meeting(club_id);
CREATE INDEX idx_meeting_date ON meeting(meeting_date);
CREATE INDEX idx_meeting_status ON meeting(status);

-- 4. ROLE_ASSIGNMENT
CREATE TABLE role_assignment (
    id BIGSERIAL PRIMARY KEY,
    meeting_id BIGINT NOT NULL REFERENCES meeting(id) ON DELETE CASCADE,
    member_id BIGINT REFERENCES member(id),
    role_name VARCHAR(50) NOT NULL,
    external_name VARCHAR(100),
    assigned_by BIGINT REFERENCES member(id),
    assigned_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    is_admin_assigned BOOLEAN DEFAULT FALSE,
    notes TEXT,
    UNIQUE(meeting_id, role_name, member_id)
);

CREATE INDEX idx_role_meeting ON role_assignment(meeting_id);
CREATE INDEX idx_role_member ON role_assignment(member_id);

-- 5. AGENDA_TEMPLATE
CREATE TABLE agenda_template (
    id BIGSERIAL PRIMARY KEY,
    club_id BIGINT NOT NULL REFERENCES club(id),
    name VARCHAR(100) NOT NULL,
    description TEXT,
    structure JSONB NOT NULL,
    is_default BOOLEAN DEFAULT FALSE,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);

CREATE INDEX idx_template_club ON agenda_template(club_id);

-- 6. AGENDA_ITEM
CREATE TABLE agenda_item (
    id BIGSERIAL PRIMARY KEY,
    meeting_id BIGINT NOT NULL REFERENCES meeting(id) ON DELETE CASCADE,
    sequence_order INT NOT NULL,
    title VARCHAR(200) NOT NULL,
    duration_min INT,
    start_time TIME,
    end_time TIME,
    assigned_member_id BIGINT REFERENCES member(id),
    assigned_person_name VARCHAR(100),
    notes TEXT,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);

CREATE INDEX idx_agenda_meeting ON agenda_item(meeting_id);

-- 7. NOTIFICATION
CREATE TABLE notification (
    id BIGSERIAL PRIMARY KEY,
    user_id BIGINT NOT NULL REFERENCES member(id) ON DELETE CASCADE,
    type VARCHAR(50) NOT NULL,
    title VARCHAR(200) NOT NULL,
    body TEXT,
    related_meeting_id BIGINT REFERENCES meeting(id),
    related_member_id BIGINT REFERENCES member(id),
    is_read BOOLEAN DEFAULT FALSE,
    read_at TIMESTAMP,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);

CREATE INDEX idx_notification_user ON notification(user_id);
CREATE INDEX idx_notification_read ON notification(user_id, is_read);

-- 8. VOTING
CREATE TABLE voting (
    id BIGSERIAL PRIMARY KEY,
    meeting_id BIGINT NOT NULL REFERENCES meeting(id) ON DELETE CASCADE,
    title VARCHAR(200) NOT NULL,
    description TEXT,
    status VARCHAR(20) NOT NULL DEFAULT 'PENDING',
    started_at TIMESTAMP,
    ended_at TIMESTAMP,
    created_by BIGINT REFERENCES member(id),
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);

CREATE TABLE voting_option (
    id BIGSERIAL PRIMARY KEY,
    voting_id BIGINT NOT NULL REFERENCES voting(id) ON DELETE CASCADE,
    option_text VARCHAR(200) NOT NULL,
    display_order INT
);

CREATE TABLE vote (
    id BIGSERIAL PRIMARY KEY,
    voting_id BIGINT NOT NULL REFERENCES voting(id) ON DELETE CASCADE,
    option_id BIGINT NOT NULL REFERENCES voting_option(id) ON DELETE CASCADE,
    voter_id BIGINT NOT NULL REFERENCES member(id),
    voted_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    UNIQUE(voting_id, voter_id)
);

CREATE INDEX idx_voting_meeting ON voting(meeting_id);
CREATE INDEX idx_vote_voting ON vote(voting_id);

-- Initial Data: Platform Admin
INSERT INTO member (email, password_hash, name, role, status, club_id)
VALUES ('admin@toastlabplus.com', '$2a$10$placeholder_hash_change_me', 'Platform Admin', 'PLATFORM_ADMIN', 'APPROVED', NULL);
