package com.example.demo.services;

import com.example.demo.entities.LessonProgress;
import com.example.demo.entities.UserProfile;
import com.example.demo.repositories.CourseProgressRepository;
import com.example.demo.repositories.LessonProgressRepository;
import com.example.demo.repositories.UserProfileRepository;
import lombok.RequiredArgsConstructor;
import org.springframework.stereotype.Service;

import java.util.List;

@Service
@RequiredArgsConstructor
public class UserProfileService {

    private final UserProfileRepository  userProfileRepository;
    private final LessonProgressRepository lessonProgressRepository;
    private final CourseProgressRepository courseProgressRepository;

    /**
     * Recomputes totalWatchTime and completionRate from live progress data
     * and saves them back to the student's UserProfile.
     * Called automatically after every progress update.
     */
    public void recalculateStats(String studentId) {

        // ── 1. totalWatchTime: sum of watchedSeconds across ALL lessons ───
        List<LessonProgress> allLessonProgress =
            lessonProgressRepository.findByStudentId(studentId);

        int totalWatchedSeconds = allLessonProgress.stream()
            .mapToInt(lp -> lp.getWatchedSeconds() != null ? lp.getWatchedSeconds() : 0)
            .sum();

        // ── 2. completionRate: average courseCompletionPercent across ALL courses ──
        List<com.example.demo.entities.CourseProgress> allCourseProgress =
            courseProgressRepository.findByStudentId(studentId);

        double avgCompletion = allCourseProgress.isEmpty() ? 0.0
            : allCourseProgress.stream()
                .mapToDouble(cp -> cp.getCompletionPercent() != null ? cp.getCompletionPercent() : 0.0)
                .average()
                .orElse(0.0);

        // ── 3. Upsert UserProfile ─────────────────────────────────────────
        UserProfile profile = userProfileRepository
            .findByStudentId(studentId)
            .orElseGet(() -> {
                UserProfile p = new UserProfile();
                p.setStudentId(studentId);
                return p;
            });

        profile.setTotalWatchTime(totalWatchedSeconds);
        profile.setCompletionRate(Math.round(avgCompletion * 100.0) / 100.0); // 2 decimal places

        userProfileRepository.save(profile);
    }
}