package com.toastlabplus.entity;

import com.fasterxml.jackson.annotation.JsonIgnoreProperties;
import jakarta.persistence.*;
import java.time.LocalDateTime;
import java.time.LocalTime;

@Entity
@Table(name = "meeting_schedule")
public class MeetingSchedule {

    @Id
    @GeneratedValue(strategy = GenerationType.IDENTITY)
    private Long id;

    @ManyToOne(fetch = FetchType.LAZY)
    @JoinColumn(name = "club_id", nullable = false)
    @JsonIgnoreProperties({ "hibernateLazyInitializer", "handler" })
    private Club club;

    @Column(length = 100)
    private String name;

    // Frequency settings
    @Column(nullable = false, length = 20)
    private String frequency; // WEEKLY, BIWEEKLY, MONTHLY

    @Column(name = "day_of_week")
    private Integer dayOfWeek; // 1-7 (Monday-Sunday)

    @Column(name = "week_of_month", columnDefinition = "INT[]")
    private int[] weekOfMonth; // [1, 3] = 1st and 3rd week

    // Time settings
    @Column(name = "start_time", nullable = false)
    private LocalTime startTime;

    @Column(name = "end_time", nullable = false)
    private LocalTime endTime;

    // Defaults
    @Column(name = "template_id")
    private Long templateId;

    @Column(name = "default_speaker_count")
    private Integer defaultSpeakerCount = 3;

    @Column(name = "default_location", length = 200)
    private String defaultLocation;

    // Auto-generation settings
    @Column(name = "auto_generate_months")
    private Integer autoGenerateMonths = 3;

    @Column(name = "is_active")
    private Boolean isActive = true;

    @Column(name = "created_at")
    private LocalDateTime createdAt = LocalDateTime.now();

    @Column(name = "updated_at")
    private LocalDateTime updatedAt = LocalDateTime.now();

    @ManyToOne(fetch = FetchType.LAZY)
    @JoinColumn(name = "created_by_id")
    @JsonIgnoreProperties({ "hibernateLazyInitializer", "handler" })
    private Member createdBy;

    // Frequency constants
    public static final String FREQ_WEEKLY = "WEEKLY";
    public static final String FREQ_BIWEEKLY = "BIWEEKLY";
    public static final String FREQ_MONTHLY = "MONTHLY";

    // Constructors
    public MeetingSchedule() {
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

    public String getName() {
        return name;
    }

    public void setName(String name) {
        this.name = name;
    }

    public String getFrequency() {
        return frequency;
    }

    public void setFrequency(String frequency) {
        this.frequency = frequency;
    }

    public Integer getDayOfWeek() {
        return dayOfWeek;
    }

    public void setDayOfWeek(Integer dayOfWeek) {
        this.dayOfWeek = dayOfWeek;
    }

    public int[] getWeekOfMonth() {
        return weekOfMonth;
    }

    public void setWeekOfMonth(int[] weekOfMonth) {
        this.weekOfMonth = weekOfMonth;
    }

    public LocalTime getStartTime() {
        return startTime;
    }

    public void setStartTime(LocalTime startTime) {
        this.startTime = startTime;
    }

    public LocalTime getEndTime() {
        return endTime;
    }

    public void setEndTime(LocalTime endTime) {
        this.endTime = endTime;
    }

    public Long getTemplateId() {
        return templateId;
    }

    public void setTemplateId(Long templateId) {
        this.templateId = templateId;
    }

    public Integer getDefaultSpeakerCount() {
        return defaultSpeakerCount;
    }

    public void setDefaultSpeakerCount(Integer defaultSpeakerCount) {
        this.defaultSpeakerCount = defaultSpeakerCount;
    }

    public String getDefaultLocation() {
        return defaultLocation;
    }

    public void setDefaultLocation(String defaultLocation) {
        this.defaultLocation = defaultLocation;
    }

    public Integer getAutoGenerateMonths() {
        return autoGenerateMonths;
    }

    public void setAutoGenerateMonths(Integer autoGenerateMonths) {
        this.autoGenerateMonths = autoGenerateMonths;
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

    public Member getCreatedBy() {
        return createdBy;
    }

    public void setCreatedBy(Member createdBy) {
        this.createdBy = createdBy;
    }
}
