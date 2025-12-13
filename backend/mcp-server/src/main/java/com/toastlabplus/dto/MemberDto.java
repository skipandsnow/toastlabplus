package com.toastlabplus.dto;

import com.toastlabplus.entity.Member;

public class MemberDto {

    private Long id;
    private String name;
    private String email;
    private String role;
    private String status;
    private Long clubId;
    private String clubName;

    // Constructors
    public MemberDto() {
    }

    public static MemberDto fromEntity(Member member) {
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
}
