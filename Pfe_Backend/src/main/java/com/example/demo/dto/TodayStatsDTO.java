package com.example.demo.dto;

import lombok.*;
import java.util.Map;

@Data
@Builder
@NoArgsConstructor
@AllArgsConstructor
public class TodayStatsDTO {
    private long newStudents;
    private long newInstructorApplications;
    private long newCourses;
    private long totalEnrollmentsToday;
    private long paidEnrollmentsToday;
    private long freeEnrollmentsToday;
    private long revenueTodayCents;
    
    // Distribution of today's enrollments by category
    private Map<String, Long> enrollmentsByCategoryToday;
}
