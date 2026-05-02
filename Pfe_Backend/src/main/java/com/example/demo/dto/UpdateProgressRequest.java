package com.example.demo.dto;

import lombok.Data;

@Data
public class UpdateProgressRequest {
    private String studentId;
    private String courseId;
    private String lessonId;
    private Integer watchedSeconds;  // sent periodically by the video player
    private Integer totalSeconds;    // total duration of the lesson
}