package com.example.demo.dto;

import lombok.*;

@Data @AllArgsConstructor @NoArgsConstructor @Builder
public class ProgressSnapshot {
    private String  lessonId;
    private Double  lessonCompletionPercent;
    private Boolean lessonCompleted;

    private Double  courseCompletionPercent;
    private Integer completedLessons;
    private Integer totalLessons;
}