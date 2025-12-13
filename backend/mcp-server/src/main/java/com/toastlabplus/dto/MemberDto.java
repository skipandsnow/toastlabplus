package com.toastlabplus.dto;

import com.toastlabplus.entity.Member;
import java.util.List;
import java.util.ArrayList;

public class MemberDto {

    private Long id;
    private String name;
    private String email;
    private String role;
    private String status;
    private Long clubId; // Kept for backward compatibility (first club or null)
    private String clubName; // Kept for backward compatibility
    private String avatarUrl;
    private List<Long> adminClubIds = new ArrayList<>(); // NEW: List of clubs user is admin of

    // Constructors
    public MemberDto() {
    }

    public static MemberDto fromEntity(Member member) {
        return fromEntity(member, new ArrayList<>());
    }

    public static MemberDto fromEntity(Member member, List<Long> adminClubIds) {
        MemberDto dto = new MemberDto();
        dto.setId(member.getId());
        dto.setName(member.getName());
        dto.setEmail(member.getEmail());
        dto.setRole(member.getRole());
        dto.setStatus(member.getStatus());
        if (member.getClub() != null) {
            dto.setClubId(member.getClub().getId());
            dto.setClubName(member.getClub().getName());
        }
        dto.setAvatarUrl(member.getAvatarUrl());
        dto.setAdminClubIds(adminClubIds);
        return dto;
    }

    // Getters and Setters
    public Long getId() {
        return id;
    }

    public void setId(Long id) {
        this.id = id;
    }

    public String getName() {
        return name;
    }

    public void setName(String name) {
        this.name = name;
    }

    public String getEmail() {
        return email;
    }

    public void setEmail(String email) {
        this.email = email;
    }

    public String getRole() {
        return role;
    }

    public void setRole(String role) {
        this.role = role;
    }

    public String getStatus() {
        return status;
    }

    public void setStatus(String status) {
        this.status = status;
    }

    public Long getClubId() {
        return clubId;
    }

    public void setClubId(Long clubId) {
        this.clubId = clubId;
    }

    public String getClubName() {
        return clubName;
    }

    public void setClubName(String clubName) {
        this.clubName = clubName;
    }

    public String getAvatarUrl() {
        return avatarUrl;
    }

    public void setAvatarUrl(String avatarUrl) {
        this.avatarUrl = avatarUrl;
    }

    public List<Long> getAdminClubIds() {
        return adminClubIds;
    }

    public void setAdminClubIds(List<Long> adminClubIds) {
        this.adminClubIds = adminClubIds != null ? adminClubIds : new ArrayList<>();
    }
}
