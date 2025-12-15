package com.toastlabplus.entity;

import jakarta.persistence.*;
import java.time.LocalDateTime;

@Entity
@Table(name = "role_slot")
public class RoleSlot {

    @Id
    @GeneratedValue(strategy = GenerationType.IDENTITY)
    private Long id;

    @ManyToOne(fetch = FetchType.LAZY)
    @JoinColumn(name = "meeting_id", nullable = false)
    private Meeting meeting;

    @Column(name = "role_name", nullable = false, length = 50)
    private String roleName;

    @Column(name = "slot_index")
    private Integer slotIndex = 1;

    @ManyToOne(fetch = FetchType.LAZY)
    @JoinColumn(name = "assigned_member_id")
    private Member assignedMember;

    @Column(name = "speech_title", length = 200)
    private String speechTitle;

    @Column(name = "project_name", length = 100)
    private String projectName;

    @Column(name = "assigned_at")
    private LocalDateTime assignedAt;

    @ManyToOne(fetch = FetchType.LAZY)
    @JoinColumn(name = "assigned_by_id")
    private Member assignedBy;

    @Column(name = "created_at")
    private LocalDateTime createdAt = LocalDateTime.now();

    // Role name constants
    public static final String TME = "TME";
    public static final String TIMER = "TIMER";
    public static final String AH_COUNTER = "AH_COUNTER";
    public static final String VOTE_COUNTER = "VOTE_COUNTER";
    public static final String GRAMMARIAN = "GRAMMARIAN";
    public static final String GE = "GE";
    public static final String LE = "LE";
    public static final String SPEAKER = "SPEAKER";
    public static final String EVALUATOR = "EVALUATOR";
    public static final String TT_MASTER = "TT_MASTER";
    public static final String SESSION_MASTER = "SESSION_MASTER";
    public static final String PHOTOGRAPHER = "PHOTOGRAPHER";

    // Constructors
    public RoleSlot() {
    }

    public RoleSlot(Meeting meeting, String roleName, Integer slotIndex) {
        this.meeting = meeting;
        this.roleName = roleName;
        this.slotIndex = slotIndex;
    }

    // Getters and Setters
    public Long getId() {
        return id;
    }

    public void setId(Long id) {
        this.id = id;
    }

    public Meeting getMeeting() {
        return meeting;
    }

    public void setMeeting(Meeting meeting) {
        this.meeting = meeting;
    }

    public String getRoleName() {
        return roleName;
    }

    public void setRoleName(String roleName) {
        this.roleName = roleName;
    }

    public Integer getSlotIndex() {
        return slotIndex;
    }

    public void setSlotIndex(Integer slotIndex) {
        this.slotIndex = slotIndex;
    }

    public Member getAssignedMember() {
        return assignedMember;
    }

    public void setAssignedMember(Member assignedMember) {
        this.assignedMember = assignedMember;
    }

    public String getSpeechTitle() {
        return speechTitle;
    }

    public void setSpeechTitle(String speechTitle) {
        this.speechTitle = speechTitle;
    }

    public String getProjectName() {
        return projectName;
    }

    public void setProjectName(String projectName) {
        this.projectName = projectName;
    }

    public LocalDateTime getAssignedAt() {
        return assignedAt;
    }

    public void setAssignedAt(LocalDateTime assignedAt) {
        this.assignedAt = assignedAt;
    }

    public Member getAssignedBy() {
        return assignedBy;
    }

    public void setAssignedBy(Member assignedBy) {
        this.assignedBy = assignedBy;
    }

    public LocalDateTime getCreatedAt() {
        return createdAt;
    }

    public void setCreatedAt(LocalDateTime createdAt) {
        this.createdAt = createdAt;
    }

    public boolean isAssigned() {
        return assignedMember != null;
    }

    public String getDisplayName() {
        if (SPEAKER.equals(roleName) || EVALUATOR.equals(roleName)) {
            return roleName + " " + slotIndex;
        }
        return roleName;
    }
}
