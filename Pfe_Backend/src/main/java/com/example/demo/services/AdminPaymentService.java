package com.example.demo.services;

import com.example.demo.dto.AdminRevenueSummary;
import com.example.demo.dto.AdminTransactionRow;
import com.example.demo.entities.Course;
import com.example.demo.entities.Enrollment;
import com.example.demo.entities.Enrollment.EnrollmentType;
import com.example.demo.entities.Instructor;
import com.example.demo.entities.User;
import com.example.demo.repositories.CourseRepository;
import com.example.demo.repositories.EnrollmentRepository;
import com.example.demo.repositories.InstructorRepository;
import com.example.demo.repositories.UserRepository;
import lombok.RequiredArgsConstructor;
import org.springframework.stereotype.Service;

import java.time.LocalDate;
import java.time.LocalDateTime;
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
    private final InstructorRepository instructorRepository;

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

        // Collect instructor doc IDs from embedded instructor objects
        Set<String> instructorDocIds = courseMap.values().stream()
                .filter(c -> c.getInstructor() != null && c.getInstructor().getId() != null)
                .map(c -> c.getInstructor().getId())
                .collect(Collectors.toSet());

        // Batch load full Instructor documents (they have userId persisted)
        Map<String, Instructor> instructorMap = instructorRepository.findAllById(instructorDocIds).stream()
                .collect(Collectors.toMap(Instructor::getId, i -> i));

        // Collect all user IDs we need: students + instructor userIds
        Set<String> studentIds = paidEnrollments.stream()
                .map(Enrollment::getStudentId)
                .collect(Collectors.toSet());
        Set<String> instructorUserIds = instructorMap.values().stream()
                .filter(i -> i.getUserId() != null)
                .map(Instructor::getUserId)
                .collect(Collectors.toSet());

        Set<String> allUserIds = new java.util.HashSet<>();
        allUserIds.addAll(studentIds);
        allUserIds.addAll(instructorUserIds);

        // Batch load all users at once
        Map<String, User> userMap = userRepository.findAllById(allUserIds).stream()
                .collect(Collectors.toMap(User::getUserId, u -> u));

        return paidEnrollments.stream().map(e -> {
            Course c = courseMap.get(e.getCourseId());

            // Resolve instructor name
            String instructorName = "Unknown";
            String instructorId = "";
            if (c != null && c.getInstructor() != null) {
                instructorId = c.getInstructor().getId();
                Instructor fullInstructor = instructorMap.get(instructorId);
                if (fullInstructor != null && fullInstructor.getUserId() != null) {
                    User instructorUser = userMap.get(fullInstructor.getUserId());
                    if (instructorUser != null) {
                        instructorName = instructorUser.getUsername();
                    }
                }

            }

            // Resolve student name
            User student = userMap.get(e.getStudentId());
            String studentName = student != null ? student.getUsername() : "Unknown";

            long total = e.getAmountPaidCents() != null ? e.getAmountPaidCents() : 0L;
            long fee = Math.round(total * PLATFORM_FEE_PERCENT);

            return AdminTransactionRow.builder()
                    .id(e.getId())
                    .studentName(studentName)
                    .studentId(e.getStudentId())
                    .courseTitle(c != null ? c.getTitle() : "Unknown Course")
                    .courseId(c != null ? c.getCourseId() : null)
                    .instructorName(instructorName)
                    .instructorId(instructorId)
                    .totalAmountCents(total)
                    .platformFeeCents(fee)
                    .enrolledAt(e.getEnrolledAt())
                    .build();
        }).collect(Collectors.toList());
    }
}
