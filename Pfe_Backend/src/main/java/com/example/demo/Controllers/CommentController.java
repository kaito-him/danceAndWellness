package com.example.demo.Controllers;

import com.example.demo.entities.Comment;
import com.example.demo.services.CommentService;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.http.HttpStatus;
import org.springframework.http.ResponseEntity;
import org.springframework.web.bind.annotation.*;

import java.util.List;
import java.util.Map;

@RestController
@RequestMapping("/api/courses/{courseId}/comments")
@CrossOrigin(origins = "*")
public class CommentController {

    @Autowired private CommentService commentService;

    // ── Read ──────────────────────────────────────────────────────────────

    /** GET /api/courses/{courseId}/comments  — top-level comments only */
    @GetMapping
    public ResponseEntity<List<Comment>> getComments(@PathVariable String courseId) {
        try {
            return ResponseEntity.ok(commentService.getTopLevelComments(courseId));
        } catch (SecurityException e) {
            return ResponseEntity.status(HttpStatus.FORBIDDEN).build();
        } catch (IllegalArgumentException e) {
            return ResponseEntity.status(HttpStatus.NOT_FOUND).build();
        }
    }

    /** GET /api/courses/{courseId}/comments/{commentId}/replies */
    @GetMapping("/{commentId}/replies")
    public ResponseEntity<List<Comment>> getReplies(
            @PathVariable String courseId,
            @PathVariable String commentId) {
        try {
            return ResponseEntity.ok(commentService.getReplies(commentId));
        } catch (IllegalArgumentException e) {
            return ResponseEntity.status(HttpStatus.NOT_FOUND).build();
        }
    }

    // ── Write ─────────────────────────────────────────────────────────────

    /** POST /api/courses/{courseId}/comments  — add a top-level comment */
    @PostMapping
    public ResponseEntity<?> addComment(
            @PathVariable String courseId,
            @RequestBody Map<String, String> body) {
        try {
            String content = body.get("content");
            if (content == null || content.isBlank()) {
                return ResponseEntity.badRequest().body("Content must not be empty.");
            }
            Comment saved = commentService.addComment(courseId, content.trim());
            return ResponseEntity.status(HttpStatus.CREATED).body(saved);
        } catch (SecurityException e) {
            return ResponseEntity.status(HttpStatus.FORBIDDEN).body(e.getMessage());
        } catch (IllegalArgumentException e) {
            return ResponseEntity.status(HttpStatus.NOT_FOUND).body(e.getMessage());
        }
    }

    /** POST /api/courses/{courseId}/comments/{commentId}/replies  — reply to a comment */
    @PostMapping("/{commentId}/replies")
    public ResponseEntity<?> replyToComment(
            @PathVariable String courseId,
            @PathVariable String commentId,
            @RequestBody Map<String, String> body) {
        try {
            String content = body.get("content");
            if (content == null || content.isBlank()) {
                return ResponseEntity.badRequest().body("Content must not be empty.");
            }
            Comment reply = commentService.replyToComment(courseId, commentId, content.trim());
            return ResponseEntity.status(HttpStatus.CREATED).body(reply);
        } catch (SecurityException e) {
            return ResponseEntity.status(HttpStatus.FORBIDDEN).body(e.getMessage());
        } catch (IllegalArgumentException e) {
            return ResponseEntity.status(HttpStatus.BAD_REQUEST).body(e.getMessage());
        }
    }

    // ── Delete ────────────────────────────────────────────────────────────

    /**
     * DELETE /api/courses/{courseId}/comments/{commentId}
     * Student  → own comment only
     * Instructor → any comment on their course
     * Admin    → any comment anywhere
     */
    @DeleteMapping("/{commentId}")
    public ResponseEntity<?> deleteComment(
            @PathVariable String courseId,
            @PathVariable String commentId) {
        try {
            commentService.deleteComment(courseId, commentId);
            return ResponseEntity.noContent().build();
        } catch (SecurityException e) {
            return ResponseEntity.status(HttpStatus.FORBIDDEN).body(e.getMessage());
        } catch (IllegalArgumentException e) {
            return ResponseEntity.status(HttpStatus.NOT_FOUND).body(e.getMessage());
        }
    }

    // ── Likes ─────────────────────────────────────────────────────────────

    /** POST /api/courses/{courseId}/comments/{commentId}/like */
    @PostMapping("/{commentId}/like")
    public ResponseEntity<?> likeComment(
            @PathVariable String courseId,
            @PathVariable String commentId) {
        try {
            return ResponseEntity.ok(commentService.likeComment(courseId, commentId));
        } catch (SecurityException e) {
            return ResponseEntity.status(HttpStatus.FORBIDDEN).body(e.getMessage());
        } catch (IllegalArgumentException e) {
            return ResponseEntity.status(HttpStatus.NOT_FOUND).body(e.getMessage());
        }
    }

    /** DELETE /api/courses/{courseId}/comments/{commentId}/like */
    @DeleteMapping("/{commentId}/like")
    public ResponseEntity<?> unlikeComment(
            @PathVariable String courseId,
            @PathVariable String commentId) {
        try {
            return ResponseEntity.ok(commentService.unlikeComment(courseId, commentId));
        } catch (SecurityException e) {
            return ResponseEntity.status(HttpStatus.FORBIDDEN).body(e.getMessage());
        } catch (IllegalArgumentException e) {
            return ResponseEntity.status(HttpStatus.NOT_FOUND).body(e.getMessage());
        }
    }
}