package com.example.demo.services;

import com.example.demo.entities.Course;
import com.example.demo.entities.CourseStatus;
import com.example.demo.entities.Instructor;
import com.example.demo.entities.User;
import com.example.demo.repositories.CourseRepository;
import com.example.demo.repositories.InstructorRepository;
import com.example.demo.repositories.UserRepository;

import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.stereotype.Service;

import java.time.LocalDateTime;
import java.util.List;

@Service
public class CourseService {

    @Autowired
    private CourseRepository courseRepository;
    @Autowired
    private NotificationService notificationService;
    @Autowired
    private InstructorRepository instructorRepository;
    @Autowired
    private UserRepository userRepository;

    // ── Helpers ───────────────────────────────────────────────────

    public String getInstructorUsername(String userId) {
        return userRepository.findById(userId)
                .map(User::getUsername)
                .orElse("Unknown Instructor");
    }

    private String resolveInstructorUserId(Instructor instructor) {
        if (instructor == null)
            return null;
        return instructor.getUserId();
    }

    // ── Read ──────────────────────────────────────────────────────

    public List<Course> getAllPublishedCourses() {
        List<Course> courses = courseRepository.findByStatus(CourseStatus.PUBLISHED);
        courses.forEach(c -> {
            if (c.getInstructor() != null)
                c.getInstructor().setUsername(
                        getInstructorUsername(c.getInstructor().getUserId()));
        });
        return courses;
    }

    public List<Course> getPublishedCoursesByInstructor(Instructor instructor) {
        return courseRepository.findByInstructorAndStatus(instructor, CourseStatus.PUBLISHED);
    }

    public Course getCourseDetail(String courseId) {
        Course course = courseRepository.findById(courseId)
                .orElseThrow(() -> new RuntimeException("Course not found: " + courseId));
        if (course.getInstructor() != null)
            course.getInstructor().setUsername(
                    getInstructorUsername(course.getInstructor().getUserId()));
        return course;
    }

    public List<Course> getAllPendingCourses() {
        return courseRepository.findByStatus(CourseStatus.PENDING_REVIEW);
    }

    public List<Course> getPendingCoursesByInstructor(Instructor instructor) {
        return courseRepository.findByInstructorAndStatus(instructor, CourseStatus.PENDING_REVIEW);
    }

    // ── Create ────────────────────────────────────────────────────

    /**
     * Business rules:
     * - Free courses → PUBLISHED immediately (no admin review needed)
     * - Paid courses → PENDING_REVIEW (admin must approve before going live)
     * Instructor must have an active Stripe account first.
     */
    public Course addCourse(Course course) {
        if (course.getLessons() == null || course.getLessons().isEmpty()) {
            throw new IllegalArgumentException("Course must have at least one lesson.");
        }

        boolean isFree = Boolean.TRUE.equals(course.getIsFree());

        if (!isFree) {
            // Paid course — require the instructor to have a connected Stripe account
            Instructor instructor = course.getInstructor();
            if (instructor != null && instructor.getId() != null) {
                instructorRepository.findById(instructor.getId()).ifPresent(fullInstructor -> {
                    if (fullInstructor.getStripeAccountId() == null
                            || fullInstructor.getStripeAccountId().isBlank()) {
                        throw new IllegalStateException(
                                "You must connect a Stripe account before publishing paid courses.");
                    }
                });
            }
            course.setStatus(CourseStatus.PENDING_REVIEW);
        } else {
            // Free course → publish straight away, no review needed
            course.setStatus(CourseStatus.PUBLISHED);
        }

        course.setCreatedAt(LocalDateTime.now());
        Course saved = courseRepository.save(course);

        // Notify admin of new paid course awaiting review
        if (!isFree) {
            String instructorUserId = resolveInstructorUserId(course.getInstructor());
            if (instructorUserId != null) {
                notificationService.create(
                        instructorUserId,
                        "Your paid course \"" + course.getTitle()
                                + "\" has been submitted for admin review.");
            }
        }

        return saved;
    }

    // ── Update ────────────────────────────────────────────────────

    public Course updateCourse(String courseId, Course updated, Instructor requestingInstructor) {
        Course existing = courseRepository.findById(courseId)
                .orElseThrow(() -> new IllegalArgumentException("Course not found: " + courseId));

        if (!existing.getInstructor().getUserId().equals(requestingInstructor.getUserId())) {
            throw new SecurityException("You are not the owner of this course.");
        }

        if (updated.getLessons() == null || updated.getLessons().isEmpty()) {
            throw new IllegalArgumentException("Course must have at least one lesson.");
        }

        existing.setTitle(updated.getTitle());
        existing.setIsFree(updated.getIsFree());
        existing.setPrice(updated.getPrice());
        existing.setLevel(updated.getLevel());
        existing.setCategoryId(updated.getCategoryId());
        existing.setThumbnailUrl(updated.getThumbnailUrl());
        existing.setLessons(updated.getLessons());
        existing.setQuizzes(updated.getQuizzes());
        // Keep original instructor, status, createdAt unchanged
        return courseRepository.save(existing);
    }

    // ── Delete ────────────────────────────────────────────────────

    public void deleteCourse(String courseId, Instructor requestingInstructor) {
        Course existing = courseRepository.findById(courseId)
                .orElseThrow(() -> new IllegalArgumentException("Course not found: " + courseId));

        if (!existing.getInstructor().getUserId().equals(requestingInstructor.getUserId())) {
            throw new SecurityException("You are not the owner of this course.");
        }

        courseRepository.deleteById(courseId);
    }

    // ── Approve (Admin) → PUBLISHED ───────────────────────────────

    public Course approveCourse(String courseId) {
        Course course = courseRepository.findById(courseId)
                .orElseThrow(() -> new IllegalArgumentException("Course not found: " + courseId));

        course.setStatus(CourseStatus.PUBLISHED);
        Course saved = courseRepository.save(course);

        String instructorUserId = resolveInstructorUserId(course.getInstructor());
        if (instructorUserId != null)
            notificationService.create(
                    instructorUserId,
                    "Your course \"" + course.getTitle()
                            + "\" has been approved and is now published!");

        return saved;
    }

    // ── Archive (Admin) → ARCHIVED ────────────────────────────────

    public Course archiveCourse(String courseId) {
        Course course = courseRepository.findById(courseId)
                .orElseThrow(() -> new IllegalArgumentException("Course not found: " + courseId));

        course.setStatus(CourseStatus.ARCHIVED);
        Course saved = courseRepository.save(course);

        String instructorUserId = resolveInstructorUserId(course.getInstructor());
        if (instructorUserId != null)
            notificationService.create(
                    instructorUserId,
                    "Your course \"" + course.getTitle()
                            + "\" has been archived by an admin.");

        return saved;
    }
}