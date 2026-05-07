package com.example.demo.services;

import com.example.demo.dto.ProgressSnapshot;
import com.example.demo.dto.UpdateProgressRequest;
import com.example.demo.entities.*;
import com.example.demo.repositories.*;
import lombok.RequiredArgsConstructor;
import org.springframework.stereotype.Service;
import org.springframework.web.servlet.mvc.method.annotation.SseEmitter;

import java.io.IOException;
import java.time.LocalDateTime;
import java.util.ArrayList;
import java.util.Comparator;
import java.util.HashMap;
import java.util.List;
import java.util.Map;
import java.util.concurrent.ConcurrentHashMap;

@Service
@RequiredArgsConstructor
public class ProgressService {

    private final LessonProgressRepository  lessonProgressRepository;
    private final CourseProgressRepository  courseProgressRepository;
    private final CourseRepository          courseRepository;
    private final UserRepository            userRepository;
    private final UserProfileService userProfileService;
    private final BadgeEvaluationService badgeEvaluationService;
    // ── SSE emitter registry: one emitter per "studentId::courseId" ──────
    private final Map<String, SseEmitter> emitters = new ConcurrentHashMap<>();

    // ── Register an SSE connection ────────────────────────────────────────
    public SseEmitter subscribe(String studentId, String courseId) {
        String key = key(studentId, courseId);

        SseEmitter emitter = new SseEmitter(Long.MAX_VALUE); // keep-alive
        emitters.put(key, emitter);

        emitter.onCompletion(() -> emitters.remove(key));
        emitter.onTimeout(()    -> emitters.remove(key));
        emitter.onError(e       -> emitters.remove(key));

        return emitter;
    }

    // ── Core update: called every few seconds by the video player ─────────
    public ProgressSnapshot updateProgress(UpdateProgressRequest req) {

        // 1. Upsert LessonProgress
        LessonProgress lp = lessonProgressRepository
            .findByStudentIdAndCourseIdAndLessonId(
                    req.getStudentId(), req.getCourseId(), req.getLessonId())
            .orElseGet(() -> LessonProgress.builder()
                    .studentId(req.getStudentId())
                    .courseId(req.getCourseId())
                    .lessonId(req.getLessonId())
                    .build());

        int watched = req.getWatchedSeconds();
        int total   = req.getTotalSeconds() > 0 ? req.getTotalSeconds() : 1; // guard /0

        // Never reduce watchedSeconds — only advance forward
        int prevWatched = lp.getWatchedSeconds() != null ? lp.getWatchedSeconds() : 0;
        int effectiveWatched = Math.max(watched, prevWatched);

        double lessonPct = Math.min((effectiveWatched * 100.0) / total, 100.0);
        boolean done     = lessonPct >= 90.0; // mark complete at 90 %

        lp.setWatchedSeconds(effectiveWatched);
        lp.setTotalSeconds(total);
        lp.setCompletionPercent(lessonPct);
        lp.setCompleted(done);
        lp.setLastUpdated(LocalDateTime.now());
        lessonProgressRepository.save(lp);

        // 2. Recalculate CourseProgress
        Course course = courseRepository.findById(req.getCourseId())
                .orElseThrow(() -> new RuntimeException("Course not found"));

        int totalLessons     = course.getLessons() != null ? course.getLessons().size() : 1;
        long completedCount  = lessonProgressRepository
                .countByStudentIdAndCourseIdAndCompletedTrue(
                        req.getStudentId(), req.getCourseId());
        double coursePct     = Math.min((completedCount * 100.0) / totalLessons, 100.0);

        CourseProgress cp = courseProgressRepository
            .findByStudentIdAndCourseId(req.getStudentId(), req.getCourseId())
            .orElseGet(() -> CourseProgress.builder()
                    .studentId(req.getStudentId())
                    .courseId(req.getCourseId())
                    .build());

        cp.setCompletedLessons((int) completedCount);
        cp.setTotalLessons(totalLessons);
        cp.setCompletionPercent(coursePct);
        cp.setLastUpdated(LocalDateTime.now());
        courseProgressRepository.save(cp);

        // 3. Build snapshot
        ProgressSnapshot snapshot = ProgressSnapshot.builder()
                .lessonId(req.getLessonId())
                .lessonCompletionPercent(lessonPct)
                .lessonCompleted(done)
                .courseCompletionPercent(coursePct)
                .completedLessons((int) completedCount)
                .totalLessons(totalLessons)
                .build();

        // 4. Push to SSE subscriber (if connected)
        pushToEmitter(key(req.getStudentId(), req.getCourseId()), snapshot);
        userProfileService.recalculateStats(req.getStudentId());

        // 5. Evaluate badges after progress update
        if (done) {
            badgeEvaluationService.evaluate(req.getStudentId());
        }

        return snapshot;
    }

    // ── Read-only getters ─────────────────────────────────────────────────
    public CourseProgress getCourseProgress(String studentId, String courseId) {
        return courseProgressRepository
                .findByStudentIdAndCourseId(studentId, courseId)
                .orElseGet(() -> CourseProgress.builder()
                        .studentId(studentId)
                        .courseId(courseId)
                        .completedLessons(0)
                        .totalLessons(0)
                        .completionPercent(0.0)
                        .build());
    }

    public List<LessonProgress> getLessonProgressList(String studentId, String courseId) {
        return lessonProgressRepository.findByStudentIdAndCourseId(studentId, courseId);
    }

    public Map<String, Object> getInstructorStudentCourseProgress(
            String requestingInstructorUserId,
            String studentId,
            String courseId) {

        Course course = courseRepository.findById(courseId)
                .orElseThrow(() -> new IllegalArgumentException("Course not found"));

        String ownerUserId = course.getInstructor() != null ? course.getInstructor().getUserId() : null;
        
        // Allow if owner OR if the requesting user is an ADMIN
        User requestingUser = userRepository.findById(requestingInstructorUserId).orElse(null);
        boolean isAdmin = requestingUser != null && "ADMIN".equalsIgnoreCase(requestingUser.getRole());

        if (!isAdmin && (ownerUserId == null || !ownerUserId.equals(requestingInstructorUserId))) {
            throw new SecurityException("You are not allowed to view this course progress.");
        }

        CourseProgress courseProgress = getCourseProgress(studentId, courseId);
        List<LessonProgress> existing = getLessonProgressList(studentId, courseId);

        Map<String, LessonProgress> byLessonId = new HashMap<>();
        for (LessonProgress lp : existing) {
            byLessonId.put(lp.getLessonId(), lp);
        }

        List<Map<String, Object>> lessons = new ArrayList<>();
        List<Lesson> courseLessons = course.getLessons() != null ? course.getLessons() : List.of();
        for (int i = 0; i < courseLessons.size(); i++) {
            Lesson lesson = courseLessons.get(i);
            LessonProgress lp = byLessonId.get(lesson.getLessonId());

            Map<String, Object> row = new HashMap<>();
            row.put("lessonId", lesson.getLessonId());
            row.put("lessonTitle", lesson.getTitle());
            row.put("order", i);
            row.put("completionPercent", lp != null ? lp.getCompletionPercent() : 0.0);
            row.put("completed", lp != null && Boolean.TRUE.equals(lp.getCompleted()));
            row.put("watchedSeconds", lp != null ? lp.getWatchedSeconds() : 0);
            row.put("totalSeconds", lp != null ? lp.getTotalSeconds() : 0);
            row.put("lastUpdated", lp != null ? lp.getLastUpdated() : null);
            lessons.add(row);
        }
        lessons.sort(Comparator.comparingInt(m -> (Integer) m.get("order")));

        String studentUsername = userRepository.findById(studentId)
                .map(User::getUsername)
                .orElse("Student");

        Map<String, Object> result = new HashMap<>();
        result.put("studentId", studentId);
        result.put("studentUsername", studentUsername);
        result.put("courseId", courseId);
        result.put("courseTitle", course.getTitle());
        result.put("courseProgress", courseProgress);
        result.put("lessonProgress", lessons);
        return result;
    }

    // ── Internal helpers ──────────────────────────────────────────────────
    private void pushToEmitter(String key, ProgressSnapshot snapshot) {
        SseEmitter emitter = emitters.get(key);
        if (emitter == null) return;
        try {
            emitter.send(SseEmitter.event()
                    .name("progress")
                    .data(snapshot));
        } catch (IOException e) {
            emitters.remove(key);
        }
    }

    private String key(String studentId, String courseId) {
        return studentId + "::" + courseId;
    }
}