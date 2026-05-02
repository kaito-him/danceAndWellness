package com.example.demo.dto;

import lombok.Builder;
import lombok.Data;
import java.util.Map;

@Data
@Builder
public class OverallStatsDTO {

    // Courses
    private long totalCourses;
    private long publishedCourses;
    private long archivedCourses;
    private long draftCourses;
    private Map<String, Long> coursesByCategory;   // categoryName → count

    // Users
    private long totalStudents;
    private long totalInstructors;
    private long activeAccounts;
    private long bannedAccounts;
    private long pendingInstructorApplications;

    // Enrollments / Payments
    private long totalEnrollments;
    private long paidEnrollments;
    private long freeEnrollments;
    private long totalRevenueCents;               // platform share (20 %)
}
