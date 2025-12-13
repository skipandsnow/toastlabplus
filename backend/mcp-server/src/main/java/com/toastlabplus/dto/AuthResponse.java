package com.toastlabplus.dto;

public class AuthResponse {

    private String token;
    private Long expiresIn;
    private MemberDto member;

    // Constructors
    public AuthResponse() {
    }

    public AuthResponse(String token, Long expiresIn, MemberDto member) {
        this.token = token;
        this.expiresIn = expiresIn;
        this.member = member;
    }

    // Getters and Setters
    public String getToken() {
        return token;
    }

    public void setToken(String token) {
        this.token = token;
    }

    public Long getExpiresIn() {
        return expiresIn;
    }

    public void setExpiresIn(Long expiresIn) {
        this.expiresIn = expiresIn;
    }

    public MemberDto getMember() {
        return member;
    }

    public void setMember(MemberDto member) {
        this.member = member;
    }
}
