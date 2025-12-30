package com.toastlabplus.repository;

import com.toastlabplus.entity.ClubMembership;
import org.springframework.data.jpa.repository.JpaRepository;
import org.springframework.data.jpa.repository.Query;
import org.springframework.data.repository.query.Param;
import org.springframework.stereotype.Repository;

import java.util.List;
import java.util.Optional;

@Repository
public interface ClubMembershipRepository extends JpaRepository<ClubMembership, Long> {
    List<ClubMembership> findByMemberId(Long memberId);

    List<ClubMembership> findByClubId(Long clubId);

    List<ClubMembership> findByClubIdAndStatus(Long clubId, String status);

    // Get clubs that a member has joined with specific status
    List<ClubMembership> findByMemberIdAndStatus(Long memberId, String status);

    // Get club members with member details (avoid N+1)
    @Query("SELECT cm FROM ClubMembership cm JOIN FETCH cm.member WHERE cm.club.id = :clubId AND cm.status = :status")
    List<ClubMembership> findByClubIdAndStatusWithMember(@Param("clubId") Long clubId, @Param("status") String status);

    Optional<ClubMembership> findByMemberIdAndClubId(Long memberId, Long clubId);

    boolean existsByMemberIdAndClubId(Long memberId, Long clubId);

    boolean existsByMemberIdAndClubIdAndStatus(Long memberId, Long clubId, String status);

    void deleteByClubId(Long clubId);
}
