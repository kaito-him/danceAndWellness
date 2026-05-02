package com.example.demo.entities;

import lombok.*;
import org.springframework.data.annotation.Id;
import org.springframework.data.mongodb.core.mapping.Document;
import java.time.LocalDateTime;

@Document(collection = "lesson_progress")
@Data @NoArgsConstructor @AllArgsConstructor @Builder
public class LessonProgress {

    @Id
    private String id;

    private String studentId;
    private String courseId;
    private String lessonId;

    private Integer watchedSeconds;   // how many seconds the student has watched
    private Integer totalSeconds;     // full lesson duration in seconds

    private Double completionPercent; // 0.0 → 100.0
    private Boolean completed;        // true when completionPercent >= 90

    private LocalDateTime lastUpdated;
}