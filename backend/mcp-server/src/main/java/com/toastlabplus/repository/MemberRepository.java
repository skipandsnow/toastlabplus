package com.toastlabplus.repository;

import com.toastlabplus.entity.Member;
import org.springframework.data.jpa.repository.JpaRepository;
import org.springframework.stereotype.Repository;

import java.util.List;
import java.util.Optional;

@Repository
public interface MemberRepository extends JpaRepository<Member, Long> {
    Optional<Member> findByEmail(String email);
    List<Member> findByClubId(Long clubId);
    List<Member> findByClubIdAndStatus(Long clubId, String status);
    List<Member> findByStatus(String status);
    boolean existsByEmail(String email);
}
