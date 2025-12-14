package com.toastlabplus.dto;

import com.toastlabplus.entity.Member;
import java.util.List;
import java.util.ArrayList;

public class MemberDto {

    private Long id;
    private String name;
    private String email;
    private String role;
    private String avatarUrl;
    private List<Long> adminClubIds = new ArrayList<>(); // Clubs user is admin of
    private List<Long> memberClubIds = new ArrayList<>(); // Clubs user has joined (APPROVED membership)
    private List<Long> pendingClubIds = new ArrayList<>(); // Clubs user has applied to (PENDING status)

    // Constructors
    public MemberDto() {
    }

    public static MemberDto fromEntity(Member member) {
        return fromEntity(member, new ArrayList<>(), new ArrayList<>(), new ArrayList<>());
    }

    public static MemberDto fromEntity(Member member, List<Long> adminClubIds) {
        return fromEntity(member, adminClubIds, new ArrayList<>(), new ArrayList<>());
    }

    public static MemberDto fromEntity(Member member, List<Long> adminClubIds, List<Long> memberClubIds) {
        return fromEntity(member, adminClubIds, memberClubIds, new ArrayList<>());
    }

    public static MemberDto fromEntity(Member member, List<Long> adminClubIds, List<Long> memberClubIds,
            List<Long> pendingClubIds) {
        MemberDto dto = new MemberDto();
        dto.setId(member.getId());
        dto.setName(member.getName());
        dto.setEmail(member.getEmail());
        dto.setRole(member.getRole());
        dto.setAvatarUrl(member.getAvatarUrl());
        dto.setAdminClubIds(adminClubIds);
        dto.setMemberClubIds(memberClubIds);
        dto.setPendingClubIds(pendingClubIds);
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

    public List<Long> getMemberClubIds() {
        return memberClubIds;
    }

    public void setMemberClubIds(List<Long> memberClubIds) {
        this.memberClubIds = memberClubIds != null ? memberClubIds : new ArrayList<>();
    }

    public List<Long> getPendingClubIds() {
        return pendingClubIds;
    }

    public void setPendingClubIds(List<Long> pendingClubIds) {
        this.pendingClubIds = pendingClubIds != null ? pendingClubIds : new ArrayList<>();
    }
}
