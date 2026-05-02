package com.example.demo.services;

import com.example.demo.entities.*;
import com.example.demo.repositories.*;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.security.core.context.SecurityContextHolder;
import org.springframework.stereotype.Service;

import java.time.LocalDateTime;
import java.util.List;

@Service
public class CommentService {

    @Autowired private CommentRepository    commentRepository;
    @Autowired private CourseRepository     courseRepository;
    @Autowired private UserRepository       userRepository;
    @Autowired private StudentRepository    studentRepository;
    @Autowired private InstructorRepository instructorRepository;
    @Autowired private AdminRepository      adminRepository;
    @Autowired private NotificationService  notificationService;

    // ── Internal helpers ──────────────────────────────────────────────────

    private User currentUser() {
        String username = SecurityContextHolder.getContext()
                                               .getAuthentication()
                                               .getName();
        return userRepository.findByUsername(username)
            .orElseThrow(() -> new IllegalArgumentException("User not found: " + username));
    }

    private Course requireCourse(String courseId) {
        return courseRepository.findById(courseId)
            .orElseThrow(() -> new IllegalArgumentException("Course not found: " + courseId));
    }

    private Comment requireComment(String commentId) {
        return commentRepository.findById(commentId)
            .orElseThrow(() -> new IllegalArgumentException("Comment not found: " + commentId));
    }

    private boolean isAdmin(User user) {
        return "ADMIN".equalsIgnoreCase(user.getRole());
    }

    private boolean isInstructor(User user) {
        return "INSTRUCTOR".equalsIgnoreCase(user.getRole());
    }

    /** Returns true if the instructor owns the given course */
    private boolean instructorOwnsCourse(User user, Course course) {
        return instructorRepository.findByUserId(user.getUserId())
            .map(inst -> course.getInstructor() != null
                      && course.getInstructor().getId().equals(inst.getId()))
            .orElse(false);
    }

    private void validateInstructorCanInteract(Course course, User user) {
        if (isInstructor(user) && !instructorOwnsCourse(user, course)) {
            throw new SecurityException("Instructors can only interact with comments on their own courses.");
        }
    }

    private String resolveAuthorPhoto(User user) {
        if ("STUDENT".equalsIgnoreCase(user.getRole())) {
            return studentRepository.findByUserId(user.getUserId()).map(Student::getPhoto).orElse(null);
        }
        if ("INSTRUCTOR".equalsIgnoreCase(user.getRole())) {
            return instructorRepository.findByUserId(user.getUserId()).map(Instructor::getPhoto).orElse(null);
        }
        return null;
    }

    // ── Public API ────────────────────────────────────────────────────────

    /** Fetch top-level comments for a course, each with their replies populated inline */
    public List<Comment> getTopLevelComments(String courseId) {
        Course course = requireCourse(courseId);
        User user = currentUser();
        validateInstructorCanInteract(course, user);
        return commentRepository.findByCourseIdAndParentCommentIdIsNull(courseId);
    }

    /** Fetch direct replies to a given comment */
    public List<Comment> getReplies(String parentCommentId) {
        requireComment(parentCommentId);
        return commentRepository.findByParentCommentId(parentCommentId);
    }

    /** Add a top-level comment on a course (any authenticated user) */
    public Comment addComment(String courseId, String content) {
        Course course = requireCourse(courseId);
        User user = currentUser();
        validateInstructorCanInteract(course, user);

        Comment comment = Comment.builder()
            .courseId(courseId)
            .authorId(user.getUserId())
            .authorUsername(user.getUsername())
            .authorRole(user.getRole())
            .authorPhoto(resolveAuthorPhoto(user))
            .content(content)
            .build();

        Comment saved = commentRepository.save(comment);
        notifyInstructorOnCourseComment(course, user);
        return saved;
    }

    /** Reply to an existing comment (any authenticated user) */
    public Comment replyToComment(String courseId, String parentCommentId, String content) {
        Course course = requireCourse(courseId);
        Comment parent = requireComment(parentCommentId);

        if (!parent.getCourseId().equals(courseId)) {
            throw new IllegalArgumentException("Comment does not belong to this course.");
        }
        // Prevent deeply nested replies — only allow one level of nesting
        if (parent.getParentCommentId() != null) {
            throw new IllegalArgumentException(
                "Cannot reply to a reply. Reply to the original comment instead.");
        }

        User user = currentUser();
        validateInstructorCanInteract(course, user);

        Comment reply = Comment.builder()
            .courseId(courseId)
            .parentCommentId(parentCommentId)
            .authorId(user.getUserId())
            .authorUsername(user.getUsername())
            .authorRole(user.getRole())
            .authorPhoto(resolveAuthorPhoto(user))
            .content(content)
            .build();

        Comment saved = commentRepository.save(reply);
        notifyInstructorOnCourseComment(course, user);
        notifyCommentAuthorOnReply(parent, course, user);
        return saved;
    }

    /**
     * Delete a comment.
     * Rules:
     *  - Any user can delete their own comment.
     *  - Instructor can delete any comment on their own courses.
     *  - Admin can delete any comment anywhere.
     */
    public void deleteComment(String courseId, String commentId) {
        Course  course  = requireCourse(courseId);
        Comment comment = requireComment(commentId);

        if (!comment.getCourseId().equals(courseId)) {
            throw new IllegalArgumentException("Comment does not belong to this course.");
        }

        User user = currentUser();

        boolean isOwner      = comment.getAuthorId().equals(user.getUserId());
        boolean isAdminUser  = isAdmin(user);
        boolean isCourseInst = isInstructor(user) && instructorOwnsCourse(user, course);

        if (!isOwner && !isAdminUser && !isCourseInst) {
            throw new SecurityException("You are not allowed to delete this comment.");
        }

        // Cascade: also delete all replies to this comment
        commentRepository.findByParentCommentId(commentId)
                         .forEach(reply -> commentRepository.deleteById(reply.getCommentId()));

        commentRepository.deleteById(commentId);
    }

    /** Like a comment — idempotent (liking twice has no effect) */
    public Comment likeComment(String courseId, String commentId) {
        Course course = requireCourse(courseId);
        Comment comment = requireComment(commentId);

        if (!comment.getCourseId().equals(courseId)) {
            throw new IllegalArgumentException("Comment does not belong to this course.");
        }

        User user = currentUser();
        validateInstructorCanInteract(course, user);
        if (!comment.getLikedByUserIds().contains(user.getUserId())) {
            comment.getLikedByUserIds().add(user.getUserId());
            comment.setUpdatedAt(LocalDateTime.now());
            commentRepository.save(comment);
            notifyCommentAuthorOnLike(comment, course, user);
        }
        return comment;
    }

    /** Remove a like from a comment */
    public Comment unlikeComment(String courseId, String commentId) {
        Course course = requireCourse(courseId);
        Comment comment = requireComment(commentId);

        if (!comment.getCourseId().equals(courseId)) {
            throw new IllegalArgumentException("Comment does not belong to this course.");
        }

        User user = currentUser();
        validateInstructorCanInteract(course, user);
        boolean removed = comment.getLikedByUserIds().remove(user.getUserId());
        if (removed) {
            comment.setUpdatedAt(LocalDateTime.now());
            commentRepository.save(comment);
        }
        return comment;
    }

    private void notifyInstructorOnCourseComment(Course course, User actor) {
        if (course.getInstructor() == null || course.getInstructor().getUserId() == null) return;
        String instructorUserId = course.getInstructor().getUserId();
        if (instructorUserId.equals(actor.getUserId())) return; // don't notify self
        notificationService.create(
            instructorUserId,
            "A new comment was posted on your course \"" + course.getTitle() + "\".",
            "COURSE_COMMENT",
            course.getCourseId(),
            true
        );
    }

    private void notifyCommentAuthorOnReply(Comment parentComment, Course course, User replier) {
        if (parentComment.getAuthorId() == null) return;
        // Don't notify if the replier is the same as the original commenter
        if (parentComment.getAuthorId().equals(replier.getUserId())) return;
        notificationService.create(
            parentComment.getAuthorId(),
            replier.getUsername() + " replied to your comment on \"" + course.getTitle() + "\".",
            "COMMENT_REPLY",
            course.getCourseId(),
            true
        );
    }

    private void notifyCommentAuthorOnLike(Comment comment, Course course, User liker) {
        if (comment.getAuthorId() == null) return;
        // Don't notify if the liker is the comment author themselves
        if (comment.getAuthorId().equals(liker.getUserId())) return;
        notificationService.create(
            comment.getAuthorId(),
            liker.getUsername() + " liked your comment on \"" + course.getTitle() + "\".",
            "COMMENT_LIKE",
            course.getCourseId(),
            true
        );
    }
}