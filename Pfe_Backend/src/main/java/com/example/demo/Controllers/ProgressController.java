package com.example.demo.Controllers;

import com.example.demo.dto.ProgressSnapshot;
import com.example.demo.dto.UpdateProgressRequest;
import com.example.demo.entities.User;
import com.example.demo.repositories.UserRepository;
import com.example.demo.services.ProgressService;
import lombok.RequiredArgsConstructor;
import org.springframework.http.MediaType;
import org.springframework.http.ResponseEntity;
import org.springframework.security.core.Authentication;
import org.springframework.web.bind.annotation.*;
import org.springframework.web.servlet.mvc.method.annotation.SseEmitter;

@RestController
@RequestMapping("/api/progress")
@CrossOrigin(origins = "*")
@RequiredArgsConstructor
public class ProgressController {

    private final ProgressService progressService;
    private final UserRepository userRepository;

    /**
     * The video player calls this endpoint every ~5 s with current position.
     * Returns the updated snapshot and also pushes it over SSE.
     */
    @PostMapping("/update")
    public ResponseEntity<ProgressSnapshot> update(
            @RequestBody UpdateProgressRequest req) {
        return ResponseEntity.ok(progressService.updateProgress(req));
    }

    /**
     * SSE stream — frontend opens this once when the student enters a course.
     * Receives a "progress" event on every update.
     */
    @GetMapping(value = "/stream", produces = MediaType.TEXT_EVENT_STREAM_VALUE)
    public SseEmitter stream(
            @RequestParam String studentId,
            @RequestParam String courseId) {
        return progressService.subscribe(studentId, courseId);
    }

    /** Full course-level progress (completed lessons / total, overall %) */
    @GetMapping("/course")
    public ResponseEntity<?> courseProgress(
            @RequestParam String studentId,
            @RequestParam String courseId) {
        return ResponseEntity.ok(progressService.getCourseProgress(studentId, courseId));
    }

    /** Per-lesson progress list for a course */
    @GetMapping("/lessons")
    public ResponseEntity<?> lessonProgress(
            @RequestParam String studentId,
            @RequestParam String courseId) {
        return ResponseEntity.ok(progressService.getLessonProgressList(studentId, courseId));
    }

    @GetMapping("/instructor/student-course")
    public ResponseEntity<?> instructorStudentCourseProgress(
            @RequestParam String studentId,
            @RequestParam String courseId,
            Authentication authentication) {
        try {
            String username = authentication.getName();
            String requestingUserId = userRepository.findByUsername(username)
                    .map(User::getUserId)
                    .orElseThrow(() -> new IllegalArgumentException("User not found"));

            return ResponseEntity.ok(progressService.getInstructorStudentCourseProgress(
                    requestingUserId, studentId, courseId));
        } catch (SecurityException e) {
            return ResponseEntity.status(403).body(e.getMessage());
        } catch (IllegalArgumentException e) {
            return ResponseEntity.badRequest().body(e.getMessage());
        }
    }
}