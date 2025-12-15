package com.toastlabplus.repository;

import com.toastlabplus.entity.RoleSlot;
import org.springframework.data.jpa.repository.JpaRepository;
import org.springframework.data.jpa.repository.Query;
import org.springframework.data.repository.query.Param;
import org.springframework.stereotype.Repository;

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

    void deleteByMeetingId(Long meetingId);
}
