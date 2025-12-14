package com.toastlabplus.service;

import com.toastlabplus.entity.Member;
import com.toastlabplus.repository.MemberRepository;
import org.springframework.security.crypto.password.PasswordEncoder;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;

import java.time.LocalDateTime;
import java.util.Optional;

@Service
public class AuthService {

    private final MemberRepository memberRepository;
    private final PasswordEncoder passwordEncoder;
    private final JwtService jwtService;

    public AuthService(MemberRepository memberRepository,
            PasswordEncoder passwordEncoder,
            JwtService jwtService) {
        this.memberRepository = memberRepository;
        this.passwordEncoder = passwordEncoder;
        this.jwtService = jwtService;
    }

    @Transactional
    public Member register(String name, String email, String password) {
        // Check if email already exists
        if (memberRepository.existsByEmail(email)) {
            throw new IllegalArgumentException("Email already registered");
        }

        Member member = new Member();
        member.setName(name);
        member.setEmail(email);
        member.setPasswordHash(passwordEncoder.encode(password));
        member.setRole("MEMBER"); // Default role for platform member
        member.setCreatedAt(LocalDateTime.now());
        member.setUpdatedAt(LocalDateTime.now());

        return memberRepository.save(member);
    }

    public String login(String email, String password) {
        Optional<Member> memberOpt = memberRepository.findByEmail(email);

        if (memberOpt.isEmpty()) {
            throw new IllegalArgumentException("Invalid email or password");
        }

        Member member = memberOpt.get();

        if (!passwordEncoder.matches(password, member.getPasswordHash())) {
            throw new IllegalArgumentException("Invalid email or password");
        }

        return jwtService.generateToken(member.getEmail(), member.getRole(), member.getId());
    }

    public Member getMemberByEmail(String email) {
        return memberRepository.findByEmail(email)
                .orElseThrow(() -> new IllegalArgumentException("Member not found"));
    }

    public Member getMemberById(Long id) {
        return memberRepository.findById(id)
                .orElseThrow(() -> new IllegalArgumentException("Member not found"));
    }

    @Transactional
    public void changePassword(String email, String currentPassword, String newPassword) {
        Member member = memberRepository.findByEmail(email)
                .orElseThrow(() -> new IllegalArgumentException("Member not found"));

        // Verify current password
        if (!passwordEncoder.matches(currentPassword, member.getPasswordHash())) {
            throw new IllegalArgumentException("Current password is incorrect");
        }

        // Update to new password
        member.setPasswordHash(passwordEncoder.encode(newPassword));
        member.setUpdatedAt(LocalDateTime.now());
        memberRepository.save(member);
    }
}
