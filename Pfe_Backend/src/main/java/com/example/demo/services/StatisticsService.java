package com.example.demo.services;

import com.example.demo.dto.OverallStatsDTO;
import com.example.demo.entities.*;
import com.example.demo.repositories.*;
import lombok.RequiredArgsConstructor;
import org.springframework.stereotype.Service;

import java.time.LocalDate;
import java.util.List;
import java.util.Map;
import java.util.stream.Collectors;
import com.example.demo.dto.TodayStatsDTO;

@Service
@RequiredArgsConstructor
public class StatisticsService {

        private final CourseRepository courseRepository;
        private final CategoryRepository categoryRepository;
        private final UserRepository userRepository;
        private final StudentRepository studentRepository;
        private final InstructorRepository instructorRepository;
        private final EnrollmentRepository enrollmentRepository;

        private static final double PLATFORM_FEE = 0.20;

        public OverallStatsDTO getOverallStats() {

                // ── Courses ───────────────────────────────────────────────────────
                List<Course> allCourses = courseRepository.findAll();

                long totalCourses = allCourses.size();
                long publishedCourses = allCourses.stream().filter(c -> CourseStatus.PUBLISHED.equals(c.getStatus()))
                                .count();
                long archivedCourses = allCourses.stream().filter(c -> CourseStatus.ARCHIVED.equals(c.getStatus()))
                                .count();
                long draftCourses = allCourses.stream().filter(c -> CourseStatus.DRAFT.equals(c.getStatus())).count();

                // Courses per category (published only, by category name)
                List<Category> categories = categoryRepository.findAll();
                Map<String, String> catIdToName = categories.stream()
                                .collect(Collectors.toMap(Category::getId, Category::getName, (a, b) -> a));

                Map<String, Long> coursesByCategory = allCourses.stream()
                                .filter(c -> CourseStatus.PUBLISHED.equals(c.getStatus()) && c.getCategoryId() != null)
                                .collect(Collectors.groupingBy(
                                                c -> catIdToName.getOrDefault(c.getCategoryId(), "Other"),
                                                Collectors.counting()));

                // ── Users ─────────────────────────────────────────────────────────
                long totalStudents = studentRepository.count();
                long totalInstructors = instructorRepository.count();

                List<User> allUsers = userRepository.findAll();
                long activeAccounts = allUsers.stream()
                                .filter(u -> AccountStatus.ACTIVE.equals(u.getStatus())
                                                && !"ADMIN".equalsIgnoreCase(u.getRole()))
                                .count();
                long bannedAccounts = allUsers.stream()
                                .filter(u -> AccountStatus.INACTIVE.equals(u.getStatus())
                                                && !"ADMIN".equalsIgnoreCase(u.getRole()))
                                .count();
                long pendingApplications = allUsers.stream()
                                .filter(u -> AccountStatus.PENDING.equals(u.getStatus())
                                                && "INSTRUCTOR".equalsIgnoreCase(u.getRole()))
                                .count();

                // ── Enrollments / Payments ────────────────────────────────────────
                List<Enrollment> enrollments = enrollmentRepository.findAll();
                long totalEnrollments = enrollments.size();
                long paidEnrollments = enrollments.stream()
                                .filter(e -> Enrollment.EnrollmentType.PAID.equals(e.getType())).count();
                long freeEnrollments = totalEnrollments - paidEnrollments;

                long totalRevenueCents = enrollments.stream()
                                .filter(e -> Enrollment.EnrollmentType.PAID.equals(e.getType()))
                                .mapToLong(e -> Math.round(
                                                (e.getAmountPaidCents() != null ? e.getAmountPaidCents() : 0L)
                                                                * PLATFORM_FEE))
                                .sum();

                return OverallStatsDTO.builder()
                                .totalCourses(totalCourses)
                                .publishedCourses(publishedCourses)
                                .archivedCourses(archivedCourses)
                                .draftCourses(draftCourses)
                                .coursesByCategory(coursesByCategory)
                                .totalStudents(totalStudents)
                                .totalInstructors(totalInstructors)
                                .activeAccounts(activeAccounts)
                                .bannedAccounts(bannedAccounts)
                                .pendingInstructorApplications(pendingApplications)
                                .totalEnrollments(totalEnrollments)
                                .paidEnrollments(paidEnrollments)
                                .freeEnrollments(freeEnrollments)
                                .totalRevenueCents(totalRevenueCents)
                                .build();
        }

        public TodayStatsDTO getTodayStats() {
                LocalDate today = LocalDate.now();

                // ── Users ─────────────────────────────────────────────────────────
                List<User> allUsers = userRepository.findAll();
                long newStudents = allUsers.stream()
                                .filter(u -> "STUDENT".equalsIgnoreCase(u.getRole()) && today.equals(u.getCreatedAt()))
                                .count();

                long newInstructorApps = allUsers.stream()
                                .filter(u -> "INSTRUCTOR".equalsIgnoreCase(u.getRole())
                                                && today.equals(u.getCreatedAt()))
                                .count();

                // ── Courses ───────────────────────────────────────────────────────
                List<Course> allCourses = courseRepository.findAll();
                long newCourses = allCourses.stream()
                                .filter(c -> c.getCreatedAt() != null && today.equals(c.getCreatedAt().toLocalDate()))
                                .count();

                // ── Enrollments ───────────────────────────────────────────────────
                List<Enrollment> enrollments = enrollmentRepository.findAll();
                List<Enrollment> todayEnrollments = enrollments.stream()
                                .filter(e -> e.getEnrolledAt() != null && today.equals(e.getEnrolledAt().toLocalDate()))
                                .collect(Collectors.toList());

                long totalEnrollmentsToday = todayEnrollments.size();
                long paidEnrollmentsToday = todayEnrollments.stream()
                                .filter(e -> Enrollment.EnrollmentType.PAID.equals(e.getType())).count();
                long freeEnrollmentsToday = totalEnrollmentsToday - paidEnrollmentsToday;

                long revenueTodayCents = todayEnrollments.stream()
                                .filter(e -> Enrollment.EnrollmentType.PAID.equals(e.getType()))
                                .mapToLong(e -> Math.round(
                                                (e.getAmountPaidCents() != null ? e.getAmountPaidCents() : 0L)
                                                                * PLATFORM_FEE))
                                .sum();

                // Distribution by category for today's enrollments
                List<Category> categories = categoryRepository.findAll();
                Map<String, String> catIdToName = categories.stream()
                                .collect(Collectors.toMap(Category::getId, Category::getName, (a, b) -> a));

                // Note: For enrollments, we need to map via Course
                Map<String, Course> courseMap = allCourses.stream()
                                .collect(Collectors.toMap(Course::getCourseId, c -> c, (a, b) -> a));

                Map<String, Long> enrollmentsByCategoryToday = todayEnrollments.stream()
                                .map(e -> courseMap.get(e.getCourseId()))
                                .filter(c -> c != null && c.getCategoryId() != null)
                                .collect(Collectors.groupingBy(
                                                c -> catIdToName.getOrDefault(c.getCategoryId(), "Other"),
                                                Collectors.counting()));

                return TodayStatsDTO.builder()
                                .newStudents(newStudents)
                                .newInstructorApplications(newInstructorApps)
                                .newCourses(newCourses)
                                .totalEnrollmentsToday(totalEnrollmentsToday)
                                .paidEnrollmentsToday(paidEnrollmentsToday)
                                .freeEnrollmentsToday(freeEnrollmentsToday)
                                .revenueTodayCents(revenueTodayCents)
                                .enrollmentsByCategoryToday(enrollmentsByCategoryToday)
                                .build();
        }
}
