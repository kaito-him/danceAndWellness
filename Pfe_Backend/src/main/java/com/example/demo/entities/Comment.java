package com.example.demo.entities;

import lombok.*;
import org.springframework.data.annotation.Id;
import org.springframework.data.mongodb.core.mapping.Document;

import java.time.LocalDateTime;
import java.util.ArrayList;
import java.util.List;

@Document(collection = "comments")
@Data
@NoArgsConstructor
@AllArgsConstructor
@Builder
public class Comment {

    @Id
    private String commentId;

    private String courseId;

    private String authorId;        // userId of commenter
    private String authorUsername;
    private String authorRole;      // "STUDENT", "INSTRUCTOR", "ADMIN"
    private String authorPhoto;     // photo file id when available

    private String content;

    @Builder.Default
    private LocalDateTime createdAt = LocalDateTime.now();
    private LocalDateTime updatedAt;

    /** null = top-level comment; non-null = reply to another comment */
    private String parentCommentId;

    /** userIds of users who liked this comment */
    @Builder.Default
    private List<String> likedByUserIds = new ArrayList<>();
}