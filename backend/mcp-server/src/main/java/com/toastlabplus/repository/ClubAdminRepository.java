package com.toastlabplus.repository;

import com.toastlabplus.entity.ClubAdmin;
import org.springframework.data.jpa.repository.JpaRepository;
import org.springframework.stereotype.Repository;

import java.util.List;
import java.util.Optional;

@Repository
public interface ClubAdminRepository extends JpaRepository<ClubAdmin, Long> {

    // Find all clubs a member is admin of
    List<ClubAdmin> findByMemberId(Long memberId);

    // Find all admins of a club
    List<ClubAdmin> findByClubId(Long clubId);

    // Check if a member is admin of a specific club
    boolean existsByMemberIdAndClubId(Long memberId, Long clubId);

    // Find specific admin assignment
    Optional<ClubAdmin> findByMemberIdAndClubId(Long memberId, Long clubId);

    // Delete by member and club
    void deleteByMemberIdAndClubId(Long memberId, Long clubId);

    // Check if a member is admin of ANY club (for Spring Security)
    boolean existsByMemberId(Long memberId);

    // Delete all admins of a club
    void deleteByClubId(Long clubId);
}
