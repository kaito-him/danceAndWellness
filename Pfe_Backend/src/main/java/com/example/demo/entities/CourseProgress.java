package com.example.demo.entities;

import lombok.*;
import org.springframework.data.annotation.Id;
import org.springframework.data.mongodb.core.mapping.Document;
import java.time.LocalDateTime;

@Document(collection = "course_progress")
@Data @NoArgsConstructor @AllArgsConstructor @Builder
public class CourseProgress {

    @Id
    private String id;

    private String studentId;
    private String courseId;

    private Integer completedLessons;
    private Integer totalLessons;
    private Double  completionPercent;   // (completedLessons / totalLessons) * 100

    private LocalDateTime lastUpdated;
}