package com.example.demo.entities;

import lombok.AllArgsConstructor;
import lombok.Builder;
import lombok.Data;
import lombok.NoArgsConstructor;
import org.springframework.data.annotation.Id;
import org.springframework.data.mongodb.core.mapping.Document;

import java.time.LocalDateTime;
import java.util.List;
import java.util.Map;

@Document(collection = "quiz_attempts")
@Data
@Builder
@AllArgsConstructor
@NoArgsConstructor
public class QuizAttempt {

    @Id
    private String id;

    private String studentId;
    private String studentUsername; // populated for instructor view
    private String courseId;
    private String quizId;

    /** questionId → list of chosen option indices */
    private Map<String, List<Integer>> answers;

    /** 0–100 */
    private int score;

    private LocalDateTime takenAt;

    /** Per-question result: questionId → was the selection fully correct */
    private Map<String, Boolean> questionResults;

    /** Total questions in the quiz at time of attempt */
    private int totalQuestions;

    /** Number of fully correct answers */
    private int correctCount;
}
