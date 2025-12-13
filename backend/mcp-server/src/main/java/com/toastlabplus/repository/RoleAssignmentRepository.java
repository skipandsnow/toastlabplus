package com.toastlabplus.repository;

import com.toastlabplus.entity.RoleAssignment;
import org.springframework.data.jpa.repository.JpaRepository;
import org.springframework.stereotype.Repository;

import java.util.List;
import java.util.Optional;

@Repository
public interface RoleAssignmentRepository extends JpaRepository<RoleAssignment, Long> {
    List<RoleAssignment> findByMeetingId(Long meetingId);
    List<RoleAssignment> findByMemberId(Long memberId);
    Optional<RoleAssignment> findByMeetingIdAndRoleName(Long meetingId, String roleName);
    boolean existsByMeetingIdAndRoleNameAndMemberId(Long meetingId, String roleName, Long memberId);
}
