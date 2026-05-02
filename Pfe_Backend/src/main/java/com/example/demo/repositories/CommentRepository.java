package com.example.demo.repositories;

import com.example.demo.entities.Comment;
import org.springframework.data.mongodb.repository.MongoRepository;

import java.util.List;

public interface CommentRepository extends MongoRepository<Comment, String> {

    /** Top-level comments for a course (no parent) */
    List<Comment> findByCourseIdAndParentCommentIdIsNull(String courseId);

    /** Replies to a specific comment */
    List<Comment> findByParentCommentId(String parentCommentId);

    /** All comments (top-level + replies) for a course */
    List<Comment> findByCourseId(String courseId);

    /** Cascade delete when a course is removed */
    void deleteByCourseId(String courseId);
}