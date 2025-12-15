package com.toastlabplus.repository;

import com.toastlabplus.entity.ClubMembership;
import org.springframework.data.jpa.repository.JpaRepository;
import org.springframework.stereotype.Repository;

import java.util.List;
import java.util.Optional;

@Repository
public interface ClubMembershipRepository extends JpaRepository<ClubMembership, Long> {
    List<ClubMembership> findByMemberId(Long memberId);

    List<ClubMembership> findByClubId(Long clubId);

    List<ClubMembership> findByClubIdAndStatus(Long clubId, String status);

    Optional<ClubMembership> findByMemberIdAndClubId(Long memberId, Long clubId);

    boolean existsByMemberIdAndClubId(Long memberId, Long clubId);

    boolean existsByMemberIdAndClubIdAndStatus(Long memberId, Long clubId, String status);

    void deleteByClubId(Long clubId);
}
