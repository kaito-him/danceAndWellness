package com.example.demo.Controllers;

import com.example.demo.entities.Course;
import com.example.demo.entities.Instructor;
import com.example.demo.entities.User;
import com.example.demo.repositories.InstructorRepository;
import com.example.demo.repositories.UserRepository;
import com.example.demo.services.CourseService;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.http.HttpStatus;
import org.springframework.http.ResponseEntity;
import org.springframework.security.core.Authentication;
import org.springframework.security.core.context.SecurityContextHolder;
import org.springframework.web.bind.annotation.*;

import java.util.List;

@RestController
@RequestMapping("/api/courses")
@CrossOrigin(origins = "*")
public class CourseController {

    @Autowired private CourseService        courseService;
    @Autowired private UserRepository       userRepository;
    @Autowired private InstructorRepository instructorRepository;

    // ── Helper ────────────────────────────────────────────────────
    private Instructor resolveInstructor() {
        String username = SecurityContextHolder.getContext()
                                               .getAuthentication()
                                               .getName();
        User user = userRepository.findByUsername(username)
            .orElseThrow(() -> new IllegalArgumentException("User not found: " + username));
        return instructorRepository.findByUserId(user.getUserId())
            .orElseThrow(() -> new IllegalArgumentException("Instructor profile not found."));
    }
    
    @GetMapping("/my-published")
    public ResponseEntity<List<Course>> getMyPublishedCourses() {
        try {
            Instructor instructor = resolveInstructor();
            System.out.println(">>> Fetching published courses for instructor ID: " + instructor.getId() + ", userId: " + instructor.getUserId());
            List<Course> courses = courseService.getPublishedCoursesByInstructor(instructor);
            System.out.println(">>> Found " + courses.size() + " published courses");
            return ResponseEntity.ok(courses);
        } catch (IllegalArgumentException e) {
            System.err.println(">>> Error fetching published courses: " + e.getMessage());
            return ResponseEntity.status(HttpStatus.NOT_FOUND).build();
        }
    }
    
    @GetMapping("/{courseId}/enrollments/count")
    public ResponseEntity<Long> getEnrollmentCount(@PathVariable String courseId) {
        try {
            long count = courseService.getEnrollmentCount(courseId);
            return ResponseEntity.ok(count);
        } catch (IllegalArgumentException e) {
            return ResponseEntity.status(HttpStatus.NOT_FOUND).build();
        }
    }

    // ── Endpoints ─────────────────────────────────────────────────
    @GetMapping("/published")
    public ResponseEntity<List<Course>> getPublishedCourses() {
        return ResponseEntity.ok(courseService.getAllPublishedCourses());
    }

    @GetMapping("/my-drafts")
    public ResponseEntity<List<Course>> getMyDraftCourses() {
        try {
            Instructor instructor = resolveInstructor();
            System.out.println(">>> Fetching drafts for instructor ID: " + instructor.getId() + ", userId: " + instructor.getUserId());
            List<Course> drafts = courseService.getDraftCoursesByInstructor(instructor);
            System.out.println(">>> Found " + drafts.size() + " draft courses");
            return ResponseEntity.ok(drafts);
        } catch (IllegalArgumentException e) {
            System.err.println(">>> Error fetching drafts: " + e.getMessage());
            return ResponseEntity.status(HttpStatus.NOT_FOUND).build();
        }
    }

    @GetMapping("/my-archived")
    public ResponseEntity<List<Course>> getMyArchivedCourses() {
        try {
            Instructor instructor = resolveInstructor();
            return ResponseEntity.ok(courseService.getArchivedCoursesByInstructor(instructor));
        } catch (IllegalArgumentException e) {
            return ResponseEntity.status(HttpStatus.NOT_FOUND).build();
        }
    }

    @PostMapping
    public ResponseEntity<?> addCourse(@RequestBody Course course) {
        try {
            Instructor instructor = resolveInstructor();
            course.setInstructor(instructor);
            Course saved = courseService.addCourse(course);
            return ResponseEntity.status(HttpStatus.CREATED).body(saved);
        } catch (IllegalArgumentException e) {
            return ResponseEntity.status(HttpStatus.BAD_REQUEST).body(e.getMessage());
        } catch (IllegalStateException e) {
            return ResponseEntity.status(HttpStatus.BAD_REQUEST).body(e.getMessage());
        }
    }

    @PostMapping("/draft")
    public ResponseEntity<?> addDraftCourse(@RequestBody Course course) {
        try {
            Instructor instructor = resolveInstructor();
            course.setInstructor(instructor);
            Course saved = courseService.addDraftCourse(course);
            return ResponseEntity.status(HttpStatus.CREATED).body(saved);
        } catch (IllegalArgumentException e) {
            return ResponseEntity.status(HttpStatus.BAD_REQUEST).body(e.getMessage());
        }
    }
    
    @GetMapping("/{courseId}")
    public ResponseEntity<Course> getCourseById(@PathVariable String courseId) {
        try {
            return ResponseEntity.ok(courseService.getCourseDetail(courseId));
        } catch (RuntimeException e) {
            return ResponseEntity.notFound().build();
        }
    }
     

    @PutMapping("/{courseId}")
    public ResponseEntity<?> updateCourse(
            @PathVariable String courseId,
            @RequestBody Course course) {
        try {
            Instructor instructor = resolveInstructor();
            Course updated = courseService.updateCourse(courseId, course, instructor);
            return ResponseEntity.ok(updated);
        } catch (SecurityException e) {
            return ResponseEntity.status(HttpStatus.FORBIDDEN).body(e.getMessage());
        } catch (IllegalArgumentException e) {
            return ResponseEntity.status(HttpStatus.BAD_REQUEST).body(e.getMessage());
        }
    }

    @DeleteMapping("/{courseId}")
    public ResponseEntity<?> deleteCourse(@PathVariable String courseId) {
        try {
            Instructor instructor = resolveInstructor();
            courseService.deleteCourse(courseId, instructor);
            return ResponseEntity.noContent().build();
        } catch (SecurityException e) {
            return ResponseEntity.status(HttpStatus.FORBIDDEN).body(e.getMessage());
        } catch (IllegalArgumentException e) {
            return ResponseEntity.status(HttpStatus.NOT_FOUND).body(e.getMessage());
        }
    }

    @PatchMapping("/{courseId}/publish")
    public ResponseEntity<?> publishDraft(@PathVariable String courseId) {
        try {
            Instructor instructor = resolveInstructor();
            Course published = courseService.publishDraft(courseId, instructor);
            return ResponseEntity.ok(published);
        } catch (SecurityException e) {
            return ResponseEntity.status(HttpStatus.FORBIDDEN).body(e.getMessage());
        } catch (IllegalStateException e) {
            return ResponseEntity.status(HttpStatus.BAD_REQUEST).body(e.getMessage());
        } catch (IllegalArgumentException e) {
            return ResponseEntity.status(HttpStatus.BAD_REQUEST).body(e.getMessage());
        }
    }

    @PatchMapping("/{courseId}/archive-instructor")
    public ResponseEntity<?> archiveByInstructor(@PathVariable String courseId) {
        try {
            Instructor instructor = resolveInstructor();
            Course archived = courseService.archiveCourseByInstructor(courseId, instructor);
            return ResponseEntity.ok(archived);
        } catch (SecurityException e) {
            return ResponseEntity.status(HttpStatus.FORBIDDEN).body(e.getMessage());
        } catch (IllegalStateException | IllegalArgumentException e) {
            return ResponseEntity.status(HttpStatus.BAD_REQUEST).body(e.getMessage());
        }
    }

    @PatchMapping("/{courseId}/unarchive")
    public ResponseEntity<?> unarchiveByInstructor(@PathVariable String courseId) {
        try {
            Instructor instructor = resolveInstructor();
            Course published = courseService.unarchiveCourseByInstructor(courseId, instructor);
            return ResponseEntity.ok(published);
        } catch (SecurityException e) {
            return ResponseEntity.status(HttpStatus.FORBIDDEN).body(e.getMessage());
        } catch (IllegalArgumentException e) {
            return ResponseEntity.status(HttpStatus.BAD_REQUEST).body(e.getMessage());
        }
    }
    
    
    @PatchMapping("/{courseId}/archive")
    public ResponseEntity<?> archiveCourse(
            @PathVariable String courseId,
            @RequestBody java.util.Map<String, String> body) {
        try {
            String message = body.get("message");
            Course archived = courseService.archiveCourse(courseId, message);
            return ResponseEntity.ok(archived);
        } catch (IllegalArgumentException e) {
            return ResponseEntity.status(HttpStatus.NOT_FOUND).body(e.getMessage());
        }
    }

    @GetMapping("/admin-archived")
    public ResponseEntity<List<Course>> getAdminArchivedCourses() {
        return ResponseEntity.ok(courseService.getAllAdminArchivedCourses());
    }

    @PatchMapping("/{courseId}/unarchive-admin")
    public ResponseEntity<?> unarchiveCourseByAdmin(@PathVariable String courseId) {
        try {
            Course unarchived = courseService.unarchiveCourseByAdmin(courseId);
            return ResponseEntity.ok(unarchived);
        } catch (IllegalArgumentException | IllegalStateException e) {
            return ResponseEntity.status(HttpStatus.BAD_REQUEST).body(e.getMessage());
        }
    }
}