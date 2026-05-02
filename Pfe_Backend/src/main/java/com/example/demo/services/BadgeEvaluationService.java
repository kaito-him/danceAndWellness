package com.example.demo.services;

import com.example.demo.entities.*;
import com.example.demo.repositories.*;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.stereotype.Service;

import java.time.LocalDateTime;
import java.time.Month;
import java.util.*;
import java.util.stream.Collectors;

/**
 * Evaluates badge criteria for a student and awards badges when earned.
 * 
 * Badge criteria:
 *  - "Early Bird"      → Complete 5 lessons before 8:00 AM
 *  - "Streak Starter"  → Maintain a 7-day activity streak
 *  - "Monthly Master"  → Complete 20 courses in a single month
 *  - "Style Explorer"  → Enroll in courses of 5 different categories (dance styles)
 */
@Service
public class BadgeEvaluationService {

    @Autowired private BadgeRepository badgeRepository;
    @Autowired private StudentRepository studentRepository;
    @Autowired private LessonProgressRepository lessonProgressRepository;
    @Autowired private CourseProgressRepository courseProgressRepository;
    @Autowired private EnrollmentRepository enrollmentRepository;
    @Autowired private CourseRepository courseRepository;
    @Autowired private NotificationService notificationService;

    /**
     * Evaluate all badge criteria for a student and award any newly earned badges.
     * Call this after key actions (lesson completion, enrollment, etc.).
     */
    public void evaluate(String studentUserId) {
        Optional<Student> studentOpt = studentRepository.findByUserId(studentUserId);
        if (studentOpt.isEmpty()) return;

        Student student = studentOpt.get();
        boolean changed = false;

        // Record today's activity
        if (student.getLoginDates() == null) {
            student.setLoginDates(new HashSet<>());
        }
        if (student.getLoginDates().add(java.time.LocalDate.now())) {
            changed = true;
        }

        List<String> currentBadgeIds = student.getBadgeIds() == null
                ? new ArrayList<>() : new ArrayList<>(student.getBadgeIds());

        List<Badge> allBadges = badgeRepository.findAll();

        for (Badge badge : allBadges) {
            if (currentBadgeIds.contains(badge.getId())) continue; // already earned

            boolean earned = switch (badge.getName()) {
                case "Early Bird"      -> checkEarlyBird(student);
                case "Streak Starter"  -> checkStreakStarter(student);
                case "Monthly Master"  -> checkMonthlyMaster(student);
                case "Style Explorer"  -> checkStyleExplorer(student);
                default -> false;
            };

            if (earned) {
                currentBadgeIds.add(badge.getId());
                student.setBadgeIds(currentBadgeIds); // update the student object for the next iterations
                changed = true;
                notificationService.create(
                    studentUserId,
                    "🏆 You earned the \"" + badge.getName() + "\" badge! " + badge.getAchievement(),
                    "BADGE_EARNED",
                    null,
                    false
                );
            }
        }

        if (changed) {
            student.setBadgeIds(currentBadgeIds);
            studentRepository.save(student);
        }
    }

    /** Early Bird: Attend 5 lessons before 8:00 AM */
    private boolean checkEarlyBird(Student student) {
        List<LessonProgress> allProgress = lessonProgressRepository.findByStudentId(student.getUserId());
        long earlyCount = allProgress.stream()
            .filter(lp -> lp.getLastUpdated() != null)
            .filter(lp -> lp.getLastUpdated().getHour() < 8)
            .count();
        return earlyCount >= 5;
    }

    /** Streak Starter: 7 consecutive days of logging in */
    private boolean checkStreakStarter(Student student) {
        Set<java.time.LocalDate> loginDates = student.getLoginDates();
        if (loginDates == null || loginDates.size() < 7) return false;

        List<java.time.LocalDate> sorted = new ArrayList<>(loginDates);
        Collections.sort(sorted);

        int streak = 1;
        for (int i = 1; i < sorted.size(); i++) {
            if (sorted.get(i).equals(sorted.get(i - 1).plusDays(1))) {
                streak++;
                if (streak >= 7) return true;
            } else {
                streak = 1;
            }
        }
        return false;
    }

    /** Monthly Master: Complete 20 courses in a single month */
    private boolean checkMonthlyMaster(Student student) {
        List<CourseProgress> allCp = courseProgressRepository.findByStudentId(student.getUserId());
        // Group completed courses by month
        Map<String, Long> monthCounts = allCp.stream()
            .filter(cp -> cp.getCompletionPercent() != null && cp.getCompletionPercent() >= 100.0)
            .filter(cp -> cp.getLastUpdated() != null)
            .collect(Collectors.groupingBy(
                cp -> cp.getLastUpdated().getYear() + "-" + cp.getLastUpdated().getMonthValue(),
                Collectors.counting()
            ));
        return monthCounts.values().stream().anyMatch(count -> count >= 20);
    }

    /** Style Explorer: Enroll in courses from 5 different categories (dance styles) */
    private boolean checkStyleExplorer(Student student) {
        List<Enrollment> enrollments = enrollmentRepository.findByStudentId(student.getUserId());
        Set<String> courseIds = enrollments.stream()
            .map(Enrollment::getCourseId)
            .collect(Collectors.toSet());

        if (courseIds.size() < 5) return false;

        Set<String> categories = new HashSet<>();
        for (String courseId : courseIds) {
            courseRepository.findById(courseId).ifPresent(course -> {
                if (course.getCategoryId() != null) {
                    categories.add(course.getCategoryId());
                }
            });
        }
        return categories.size() >= 5;
    }

    /**
     * Returns all badges with earned status for a student.
     */
    public List<Map<String, Object>> getBadgeStatusForUser(String userId) {
        Optional<Student> studentOpt = studentRepository.findByUserId(userId);
        List<String> earnedIds = studentOpt
            .map(s -> s.getBadgeIds() != null ? s.getBadgeIds() : List.<String>of())
            .orElse(List.of());

        List<Badge> allBadges = badgeRepository.findAll();
        List<Map<String, Object>> result = new ArrayList<>();

        for (Badge badge : allBadges) {
            Map<String, Object> entry = new LinkedHashMap<>();
            entry.put("id", badge.getId());
            entry.put("name", badge.getName());
            entry.put("achievement", badge.getAchievement());
            entry.put("icon", badge.getIcon());
            entry.put("earned", earnedIds.contains(badge.getId()));
            result.add(entry);
        }
        return result;
    }
}
