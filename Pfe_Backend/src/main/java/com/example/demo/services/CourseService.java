package com.example.demo.services;

import com.example.demo.entities.Course;
import com.example.demo.entities.CourseStatus;
import com.example.demo.entities.Instructor;
import com.example.demo.entities.User;
import com.example.demo.repositories.CourseRepository;
import com.example.demo.repositories.EnrollmentRepository;
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
    
    @Autowired
    private EnrollmentRepository enrollmentRepository;

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

    private void validatePublishable(Course course) {
        if (course.getLessons() == null || course.getLessons().isEmpty()) {
            throw new IllegalArgumentException("Course must have at least one lesson.");
        }
        boolean missingMedia = course.getLessons().stream()
                .anyMatch(l -> l == null || l.getMediaUrl() == null || l.getMediaUrl().isBlank());
        if (missingMedia) {
            throw new IllegalArgumentException("All lessons must have a video before publishing.");
        }
    }

    /**
     * Applies publish rules and returns whether admin review is needed.
     * Updated: Both free and paid courses now publish immediately (no admin review).
     */
    private boolean applyPublishRules(Course course) {
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
        }
        course.setStatus(CourseStatus.PUBLISHED);
        return false; // No admin review needed
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

    public List<Course> getMostPopularCourses(int limit) {
        List<Course> allPublished = courseRepository.findByStatus(CourseStatus.PUBLISHED);
        
        // Sort by enrollment count (descending)
        allPublished.sort((c1, c2) -> {
            long count1 = enrollmentRepository.countByCourseId(c1.getCourseId());
            long count2 = enrollmentRepository.countByCourseId(c2.getCourseId());
            return Long.compare(count2, count1);
        });
        
        // Set instructor usernames and limit results
        List<Course> popular = allPublished.stream()
                .limit(limit)
                .peek(c -> {
                    if (c.getInstructor() != null)
                        c.getInstructor().setUsername(
                                getInstructorUsername(c.getInstructor().getUserId()));
                })
                .collect(java.util.stream.Collectors.toList());
        
        return popular;
    }
    
    public long getEnrollmentCount(String courseId) {
        // Optional: verify course exists
        if (!courseRepository.existsById(courseId)) {
            throw new IllegalArgumentException("Course not found: " + courseId);
        }

        return enrollmentRepository.countByCourseId(courseId);
    }

    public List<Course> getPublishedCoursesByInstructor(Instructor instructor) {
        return courseRepository.findByInstructor_IdAndStatus(instructor.getId(), CourseStatus.PUBLISHED);
    }

    public Course getCourseDetail(String courseId) {
        Course course = courseRepository.findById(courseId)
                .orElseThrow(() -> new RuntimeException("Course not found: " + courseId));
        if (course.getInstructor() != null)
            course.getInstructor().setUsername(
                    getInstructorUsername(course.getInstructor().getUserId()));
        return course;
    }

    public List<Course> getDraftCoursesByInstructor(Instructor instructor) {
        System.out.println(">>> Querying drafts with instructor.id: " + instructor.getId());
        List<Course> drafts = courseRepository.findByInstructor_IdAndStatus(instructor.getId(), CourseStatus.DRAFT);
        System.out.println(">>> Query returned " + drafts.size() + " drafts");
        if (!drafts.isEmpty()) {
            System.out.println(">>> First draft instructor.id: " + drafts.get(0).getInstructor().getId());
        }
        return drafts;
    }

    public List<Course> getArchivedCoursesByInstructor(Instructor instructor) {
        return courseRepository.findByInstructor_IdAndStatus(instructor.getId(), CourseStatus.ARCHIVED);
    }

    // ── Create ────────────────────────────────────────────────────

    /**
     * Business rules:
     * - All courses (free and paid) → PUBLISHED immediately
     * Instructor must have an active Stripe account for paid courses.
     */
    public Course addCourse(Course course) {
        validatePublishable(course); // at least one lesson with media.
        applyPublishRules(course); // Always publishes immediately, must connect a Stripe account before publishing paid courses.
        course.setCreatedAt(LocalDateTime.now());
        Course saved = courseRepository.save(course);
        // Notify all admins about the newly published course
        String instructorName = saved.getInstructor() != null
            ? getInstructorUsername(saved.getInstructor().getUserId())
            : "An instructor";
        notificationService.notifyAllAdmins(
            instructorName + " published a new course: \"" + saved.getTitle() + "\".",
            "COURSE_PUBLISHED",
            saved.getCourseId(),
            false
        );
        return saved;
    }

    public Course addDraftCourse(Course course) {
        course.setStatus(CourseStatus.DRAFT);
        if (course.getCreatedAt() == null) {
            course.setCreatedAt(LocalDateTime.now());
        }
        if (course.getLessons() == null) {
            course.setLessons(java.util.List.of());
        }
        if (course.getQuizzes() == null) {
            course.setQuizzes(java.util.List.of());
        }
        return courseRepository.save(course);
    }

    public Course publishDraft(String courseId, Instructor requestingInstructor) {
        Course existing = courseRepository.findById(courseId)
                .orElseThrow(() -> new IllegalArgumentException("Course not found: " + courseId));

        if (existing.getInstructor() == null
                || !existing.getInstructor().getUserId().equals(requestingInstructor.getUserId())) {
            throw new SecurityException("You are not the owner of this course.");
        }

        if (existing.getStatus() != CourseStatus.DRAFT) {
            throw new IllegalArgumentException("Only draft courses can be published.");
        }

        validatePublishable(existing);
        applyPublishRules(existing); // Always publishes immediately now
        Course saved = courseRepository.save(existing);

        // Notify all admins about the newly published course
        String instructorName = saved.getInstructor() != null
            ? getInstructorUsername(saved.getInstructor().getUserId())
            : "An instructor";
        notificationService.notifyAllAdmins(
            instructorName + " published a new course: \"" + saved.getTitle() + "\".",
            "COURSE_PUBLISHED",
            saved.getCourseId(),
            false
        );

        return saved;
    }

    public Course archiveCourseByInstructor(String courseId, Instructor requestingInstructor) {
        Course existing = courseRepository.findById(courseId)
                .orElseThrow(() -> new IllegalArgumentException("Course not found: " + courseId));

        if (existing.getInstructor() == null
                || !existing.getInstructor().getUserId().equals(requestingInstructor.getUserId())) {
            throw new SecurityException("You are not the owner of this course.");
        }

        if (existing.getStatus() != CourseStatus.PUBLISHED) {
            throw new IllegalArgumentException("Only published courses can be archived.");
        }

        // Paid courses can only be archived if no one is enrolled
        if (!Boolean.TRUE.equals(existing.getIsFree())) {
            long enrollmentCount = enrollmentRepository.countByCourseId(courseId);
            if (enrollmentCount > 0) {
                throw new IllegalStateException(
                    "Paid courses with active enrollments cannot be archived. " +
                    "This course has " + enrollmentCount + " enrolled student(s)."
                );
            }
        }

        existing.setStatus(CourseStatus.ARCHIVED);
        existing.setArchivedByAdmin(false);
        return courseRepository.save(existing);
    }

    public Course unarchiveCourseByInstructor(String courseId, Instructor requestingInstructor) {
        Course existing = courseRepository.findById(courseId)
                .orElseThrow(() -> new IllegalArgumentException("Course not found: " + courseId));

        if (existing.getInstructor() == null
                || !existing.getInstructor().getUserId().equals(requestingInstructor.getUserId())) {
            throw new SecurityException("You are not the owner of this course.");
        }

        if (existing.getStatus() != CourseStatus.ARCHIVED) {
            throw new IllegalArgumentException("Only archived courses can be unarchived.");
        }

        if (Boolean.TRUE.equals(existing.getArchivedByAdmin())) {
            throw new IllegalStateException("This course was archived by an admin and cannot be unarchived by you. Please contact support.");
        }

        existing.setStatus(CourseStatus.PUBLISHED);
        return courseRepository.save(existing);
    }

    // ── Update ────────────────────────────────────────────────────

    public Course updateCourse(String courseId, Course updated, Instructor requestingInstructor) {
        Course existing = courseRepository.findById(courseId)
                .orElseThrow(() -> new IllegalArgumentException("Course not found: " + courseId));

        if (!existing.getInstructor().getUserId().equals(requestingInstructor.getUserId())) {
            throw new SecurityException("You are not the owner of this course.");
        }

        if (existing.getStatus() != CourseStatus.DRAFT) {
            if (updated.getLessons() == null || updated.getLessons().isEmpty()) {
                throw new IllegalArgumentException("Course must have at least one lesson.");
            }
        }

        // Detect new lessons added to a published course
        int oldLessonCount = existing.getLessons() == null ? 0 : existing.getLessons().size();
        int newLessonCount = updated.getLessons() == null ? 0 : updated.getLessons().size();
        boolean isPublished = existing.getStatus() == CourseStatus.PUBLISHED;

        existing.setTitle(updated.getTitle());
        existing.setDescription(updated.getDescription());
        existing.setIsFree(updated.getIsFree());
        existing.setPrice(updated.getPrice());
        existing.setLevel(updated.getLevel());
        existing.setCategoryId(updated.getCategoryId());
        existing.setThumbnailUrl(updated.getThumbnailUrl());
        existing.setLessons(updated.getLessons() == null ? java.util.List.of() : updated.getLessons());
        existing.setQuizzes(updated.getQuizzes() == null ? java.util.List.of() : updated.getQuizzes());
        // Keep original instructor, status, createdAt unchanged
        Course saved = courseRepository.save(existing);

        // Notify enrolled students about new lessons
        if (isPublished && newLessonCount > oldLessonCount) {
            int addedCount = newLessonCount - oldLessonCount;
            notifyEnrolledStudentsNewLesson(saved, addedCount);
        }

        return saved;
    }

    private void notifyEnrolledStudentsNewLesson(Course course, int addedCount) {
        String lessonWord = addedCount == 1 ? "lesson" : "lessons";
        java.util.List<com.example.demo.entities.Enrollment> enrollments =
            enrollmentRepository.findByCourseId(course.getCourseId());
        for (com.example.demo.entities.Enrollment enrollment : enrollments) {
            notificationService.create(
                enrollment.getStudentId(),
                addedCount + " new " + lessonWord + " added to \"" + course.getTitle() + "\".",
                "NEW_LESSON",
                course.getCourseId(),
                false
            );
        }
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

    // ── Archive (Admin) → ARCHIVED ────────────────────────────────

    public Course archiveCourse(String courseId, String message) {
        Course course = courseRepository.findById(courseId)
                .orElseThrow(() -> new IllegalArgumentException("Course not found: " + courseId));

        course.setStatus(CourseStatus.ARCHIVED);
        course.setArchivedByAdmin(true);
        course.setArchiveReason(message != null ? message.trim() : null);
        course.setArchivedAt(java.time.LocalDateTime.now());
        Course saved = courseRepository.save(course);

        String instructorUserId = resolveInstructorUserId(course.getInstructor());
        if (instructorUserId != null) {
            String notificationMessage = "Your course \"" + course.getTitle() + "\" has been archived by an admin.";
            if (message != null && !message.isBlank()) {
                notificationMessage += " Reason: " + message;
            }
            notificationService.create(
                    instructorUserId,
                    notificationMessage,
                    "COURSE_ARCHIVED",
                    course.getCourseId(),
                    false);
        }

        return saved;
    }

    public List<Course> getAllAdminArchivedCourses() {
        List<Course> courses = courseRepository.findByArchivedByAdmin(true);
        courses.forEach(c -> {
            if (c.getInstructor() != null) {
                c.getInstructor().setUsername(getInstructorUsername(c.getInstructor().getUserId()));
            }
        });
        return courses;
    }

    public Course unarchiveCourseByAdmin(String courseId) {
        Course course = courseRepository.findById(courseId)
                .orElseThrow(() -> new IllegalArgumentException("Course not found: " + courseId));

        if (!Boolean.TRUE.equals(course.getArchivedByAdmin())) {
            throw new IllegalStateException("This course was not archived by an admin.");
        }

        course.setStatus(CourseStatus.PUBLISHED);
        course.setArchivedByAdmin(false);
        course.setArchiveReason(null);
        course.setArchivedAt(null);
        Course saved = courseRepository.save(course);

        // Notify the instructor
        String instructorUserId = resolveInstructorUserId(course.getInstructor());
        if (instructorUserId != null) {
            notificationService.create(
                    instructorUserId,
                    "Your course \"" + course.getTitle() + "\" has been unarchived by an admin and is now live again.",
                    "COURSE_UNARCHIVED",
                    course.getCourseId(),
                    false);
        }

        return saved;
    }
}
