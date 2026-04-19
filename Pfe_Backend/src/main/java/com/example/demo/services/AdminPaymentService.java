package com.example.demo.services;

import com.example.demo.dto.AdminRevenueSummary;
import com.example.demo.dto.AdminTransactionRow;
import com.example.demo.entities.Course;
import com.example.demo.entities.Enrollment;
import com.example.demo.entities.Enrollment.EnrollmentType;
import com.example.demo.entities.User;
import com.example.demo.repositories.CourseRepository;
import com.example.demo.repositories.EnrollmentRepository;
import com.example.demo.repositories.UserRepository;
import lombok.RequiredArgsConstructor;
import org.springframework.stereotype.Service;

import java.time.LocalDate;
import java.time.LocalDateTime;
import java.time.LocalTime;
import java.util.Collections;
import java.util.List;
import java.util.Map;
import java.util.Set;
import java.util.stream.Collectors;

@Service
@RequiredArgsConstructor
public class AdminPaymentService {

    private final EnrollmentRepository enrollmentRepository;
    private final CourseRepository     courseRepository;
    private final UserRepository       userRepository;

    private static final double PLATFORM_FEE_PERCENT = 0.20;

    public AdminRevenueSummary getRevenueSummary() {
        List<Enrollment> paidEnrollments = enrollmentRepository.findAll().stream()
                .filter(e -> EnrollmentType.PAID.equals(e.getType()))
                .collect(Collectors.toList());

        long totalRevenue = 0;
        long todayRevenue = 0;
        
        LocalDate today = LocalDate.now();
        LocalDateTime todayStart = today.atStartOfDay();

        for (Enrollment e : paidEnrollments) {
            long fee = Math.round((e.getAmountPaidCents() != null ? e.getAmountPaidCents() : 0L) * PLATFORM_FEE_PERCENT);
            totalRevenue += fee;
            
            if (e.getEnrolledAt() != null && e.getEnrolledAt().isAfter(todayStart)) {
                todayRevenue += fee;
            }
        }

        return AdminRevenueSummary.builder()
                .totalPlatformRevenueCents(totalRevenue)
                .todayPlatformRevenueCents(todayRevenue)
                .totalTransactionsCount(paidEnrollments.size())
                .build();
    }

    public List<AdminTransactionRow> getAllTransactions() {
        List<Enrollment> paidEnrollments = enrollmentRepository.findAll().stream()
                .filter(e -> EnrollmentType.PAID.equals(e.getType()))
                .sorted((a, b) -> b.getEnrolledAt().compareTo(a.getEnrolledAt()))
                .collect(Collectors.toList());

        if (paidEnrollments.isEmpty()) return Collections.emptyList();

        // Batch load all unique courses
        Set<String> courseIds = paidEnrollments.stream()
                .map(Enrollment::getCourseId)
                .collect(Collectors.toSet());
        Map<String, Course> courseMap = courseRepository.findAllById(courseIds).stream()
                .collect(Collectors.toMap(Course::getCourseId, c -> c));

        // Batch load all involved users (students and instructors)
        Set<String> studentIds = paidEnrollments.stream()
                .map(Enrollment::getStudentId)
                .collect(Collectors.toSet());
        Set<String> instructorIds = courseMap.values().stream()
                .map(c -> c.getInstructor().getId())
                .collect(Collectors.toSet());
        // Since we need Usernames, we need the matching User records for Instructor and Students. 
        // Note: Course has instructor ID, but it's the Instructor entity ID. 
        // We need to fetch Instructor objects to find their UserIds.
        
        // Let's get unique people names... this might need a bit of mapping.
        
        // 1. All Students (UserIds)
        // 2. All Instructors (InstructorIds) -> then their userIds
        
        return paidEnrollments.stream().map(e -> {
            Course c = courseMap.get(e.getCourseId());
            String instructorName = "Unknown";
            String instructorId = "";
            if (c != null && c.getInstructor() != null) {
                instructorName = c.getInstructor().getUsername();
                instructorId = c.getInstructor().getId();
            }

            String studentName = userRepository.findById(e.getStudentId())
                    .map(User::getUsername)
                    .orElse("Unknown");

            long total = e.getAmountPaidCents() != null ? e.getAmountPaidCents() : 0L;
            long fee = Math.round(total * PLATFORM_FEE_PERCENT);

            return AdminTransactionRow.builder()
                    .id(e.getId())
                    .studentName(studentName)
                    .studentId(e.getStudentId())
                    .courseTitle(c != null ? c.getTitle() : "Unknown Course")
                    .instructorName(instructorName)
                    .instructorId(instructorId)
                    .totalAmountCents(total)
                    .platformFeeCents(fee)
                    .enrolledAt(e.getEnrolledAt())
                    .build();
        }).collect(Collectors.toList());
    }
}
