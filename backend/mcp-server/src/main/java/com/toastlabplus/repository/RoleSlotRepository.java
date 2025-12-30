package com.toastlabplus.repository;

import com.toastlabplus.entity.RoleSlot;
import org.springframework.data.jpa.repository.JpaRepository;
import org.springframework.data.jpa.repository.Query;
import org.springframework.data.repository.query.Param;
import org.springframework.stereotype.Repository;

import java.time.LocalDate;
import java.util.List;
import java.util.Optional;

@Repository
public interface RoleSlotRepository extends JpaRepository<RoleSlot, Long> {

    List<RoleSlot> findByMeetingId(Long meetingId);

    @Query("SELECT rs FROM RoleSlot rs LEFT JOIN FETCH rs.assignedMember WHERE rs.meeting.id = :meetingId ORDER BY rs.roleName, rs.slotIndex")
    List<RoleSlot> findByMeetingIdWithMember(@Param("meetingId") Long meetingId);

    Optional<RoleSlot> findByMeetingIdAndRoleNameAndSlotIndex(Long meetingId, String roleName, Integer slotIndex);

    List<RoleSlot> findByMeetingIdAndRoleName(Long meetingId, String roleName);

    List<RoleSlot> findByAssignedMemberId(Long memberId);

    @Query("SELECT rs FROM RoleSlot rs WHERE rs.meeting.id = :meetingId AND rs.assignedMember IS NULL")
    List<RoleSlot> findUnassignedByMeetingId(@Param("meetingId") Long meetingId);

    @Query("SELECT rs FROM RoleSlot rs WHERE rs.meeting.id = :meetingId AND rs.assignedMember IS NOT NULL")
    List<RoleSlot> findAssignedByMeetingId(@Param("meetingId") Long meetingId);

    // Query upcoming roles for a member
    @Query("SELECT rs FROM RoleSlot rs JOIN FETCH rs.meeting m JOIN FETCH m.club WHERE rs.assignedMember.id = :memberId AND m.meetingDate >= :date ORDER BY m.meetingDate ASC")
    List<RoleSlot> findUpcomingByMemberId(@Param("memberId") Long memberId, @Param("date") LocalDate date);

    // Count total role participations for a member
    @Query("SELECT COUNT(rs) FROM RoleSlot rs WHERE rs.assignedMember.id = :memberId")
    long countByAssignedMemberIdTotal(@Param("memberId") Long memberId);

    // Count role participations for a member in a specific club
    @Query("SELECT COUNT(rs) FROM RoleSlot rs JOIN rs.meeting m WHERE rs.assignedMember.id = :memberId AND m.club.id = :clubId")
    long countByMemberIdAndClubId(@Param("memberId") Long memberId, @Param("clubId") Long clubId);

    void deleteByMeetingId(Long meetingId);
}
