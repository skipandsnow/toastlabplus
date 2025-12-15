package com.toastlabplus.entity;

import jakarta.persistence.*;
import java.time.LocalDate;
import java.time.LocalDateTime;

@Entity
@Table(name = "club_officer")
public class ClubOfficer {

    @Id
    @GeneratedValue(strategy = GenerationType.IDENTITY)
    private Long id;

    @ManyToOne(fetch = FetchType.LAZY)
    @JoinColumn(name = "club_id", nullable = false)
    private Club club;

    @ManyToOne(fetch = FetchType.LAZY)
    @JoinColumn(name = "member_id")
    private Member member;

    @Column(nullable = false, length = 20)
    private String position;

    @Column(name = "term_start")
    private LocalDate termStart;

    @Column(name = "term_end")
    private LocalDate termEnd;

    @Column(name = "is_active", nullable = false)
    private Boolean isActive = true;

    @Column(name = "created_at")
    private LocalDateTime createdAt = LocalDateTime.now();

    @Column(name = "updated_at")
    private LocalDateTime updatedAt = LocalDateTime.now();

    // Constructors
    public ClubOfficer() {
    }

    public ClubOfficer(Club club, String position) {
        this.club = club;
        this.position = position;
        this.isActive = true;
    }

    // Getters and Setters
    public Long getId() {
        return id;
    }

    public void setId(Long id) {
        this.id = id;
    }

    public Club getClub() {
        return club;
    }

    public void setClub(Club club) {
        this.club = club;
    }

    public Member getMember() {
        return member;
    }

    public void setMember(Member member) {
        this.member = member;
    }

    public String getPosition() {
        return position;
    }

    public void setPosition(String position) {
        this.position = position;
    }

    public LocalDate getTermStart() {
        return termStart;
    }

    public void setTermStart(LocalDate termStart) {
        this.termStart = termStart;
    }

    public LocalDate getTermEnd() {
        return termEnd;
    }

    public void setTermEnd(LocalDate termEnd) {
        this.termEnd = termEnd;
    }

    public Boolean getIsActive() {
        return isActive;
    }

    public void setIsActive(Boolean isActive) {
        this.isActive = isActive;
    }

    public LocalDateTime getCreatedAt() {
        return createdAt;
    }

    public void setCreatedAt(LocalDateTime createdAt) {
        this.createdAt = createdAt;
    }

    public LocalDateTime getUpdatedAt() {
        return updatedAt;
    }

    public void setUpdatedAt(LocalDateTime updatedAt) {
        this.updatedAt = updatedAt;
    }

    // Position constants
    public static final String PRESIDENT = "PRESIDENT";
    public static final String VPE = "VPE";
    public static final String VPM = "VPM";
    public static final String VPPR = "VPPR";
    public static final String SECRETARY = "SECRETARY";
    public static final String TREASURER = "TREASURER";
    public static final String SAA = "SAA";

    public static final String[] ALL_POSITIONS = {
            PRESIDENT, VPE, VPM, VPPR, SECRETARY, TREASURER, SAA
    };
}
