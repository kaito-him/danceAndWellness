package com.example.demo.dto;

import lombok.Data;
import java.util.List;
import java.util.Map;

@Data
public class QuizSubmitRequest {
    private String courseId;
    private String quizId;
    /** questionId → list of chosen option indices (supports multiple correct answers) */
    private Map<String, List<Integer>> answers;
}
