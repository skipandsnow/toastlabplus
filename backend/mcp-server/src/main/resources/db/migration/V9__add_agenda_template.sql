-- V9__add_agenda_template.sql
-- Agenda template for storing Excel templates and their parsed structure

-- Drop if exists (in case of partial previous migration)
DROP TABLE IF EXISTS agenda_template CASCADE;

CREATE TABLE agenda_template (
    id BIGSERIAL PRIMARY KEY,
    club_id BIGINT NOT NULL REFERENCES club(id) ON DELETE CASCADE,
    name VARCHAR(200) NOT NULL,
    description TEXT,
    gcs_path VARCHAR(500),
    original_filename VARCHAR(255),
    parsed_structure JSONB,
    version INT DEFAULT 1,
    is_active BOOLEAN DEFAULT true,
    created_at TIMESTAMP DEFAULT NOW(),
    updated_at TIMESTAMP DEFAULT NOW(),
    created_by_id BIGINT REFERENCES member(id)
);

-- Index for faster queries
CREATE INDEX idx_agenda_template_club_id ON agenda_template(club_id);
CREATE INDEX idx_agenda_template_is_active ON agenda_template(is_active);

