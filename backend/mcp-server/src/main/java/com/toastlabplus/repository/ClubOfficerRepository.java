package com.toastlabplus.repository;

import com.toastlabplus.entity.ClubOfficer;
import org.springframework.data.jpa.repository.JpaRepository;
import org.springframework.data.jpa.repository.Query;
import org.springframework.data.repository.query.Param;
import org.springframework.stereotype.Repository;

import java.util.List;
import java.util.Optional;

@Repository
public interface ClubOfficerRepository extends JpaRepository<ClubOfficer, Long> {

    /**
     * Find all active officers for a club
     */
    List<ClubOfficer> findByClubIdAndIsActiveTrue(Long clubId);

    /**
     * Find a specific position holder for a club
     */
    Optional<ClubOfficer> findByClubIdAndPositionAndIsActiveTrue(Long clubId, String position);

    /**
     * Find all officer positions held by a member
     */
    List<ClubOfficer> findByMemberIdAndIsActiveTrue(Long memberId);

    /**
     * Check if a member holds a specific position in a club
     */
    boolean existsByClubIdAndMemberIdAndPositionAndIsActiveTrue(Long clubId, Long memberId, String position);

    /**
     * Check if a position is filled in a club
     */
    boolean existsByClubIdAndPositionAndIsActiveTrue(Long clubId, String position);

    /**
     * Find all officers with member details (to avoid N+1 queries)
     */
    @Query("SELECT o FROM ClubOfficer o LEFT JOIN FETCH o.member WHERE o.club.id = :clubId AND o.isActive = true")
    List<ClubOfficer> findByClubIdWithMember(@Param("clubId") Long clubId);
}
