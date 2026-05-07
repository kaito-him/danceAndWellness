package com.example.demo.services;

import com.example.demo.dto.QuizSubmitRequest;
import com.example.demo.entities.*;
import com.example.demo.repositories.CourseRepository;
import com.example.demo.repositories.QuizAttemptRepository;
import com.example.demo.repositories.UserRepository;
import lombok.RequiredArgsConstructor;
import org.springframework.stereotype.Service;

import java.time.LocalDateTime;
import java.util.*;

@Service
@RequiredArgsConstructor
public class QuizService {

    private final CourseRepository courseRepository;
    private final QuizAttemptRepository quizAttemptRepository;
    private final UserRepository userRepository;

    /** Instructor view: all attempts for a course, sorted by score desc, with studentUsername populated */
    public List<QuizAttempt> getAttemptsForCourseInstructor(String courseId) {
        List<QuizAttempt> attempts = quizAttemptRepository.findByCourseId(courseId);
        // Enrich with student username
        for (QuizAttempt a : attempts) {
            if (a.getStudentId() != null && a.getStudentUsername() == null) {
                userRepository.findById(a.getStudentId())
                    .ifPresent(u -> a.setStudentUsername(u.getUsername()));
            }
        }
        // Sort by score descending
        attempts.sort(Comparator.comparingInt(QuizAttempt::getScore).reversed());
        return attempts;
    }

    public Map<String, QuizAttempt> getAttemptsForCourse(String studentId, String courseId) {
        List<QuizAttempt> attempts = quizAttemptRepository.findByStudentIdAndCourseId(studentId, courseId);
        Map<String, QuizAttempt> map = new LinkedHashMap<>();
        for (QuizAttempt a : attempts) map.put(a.getQuizId(), a);
        return map;
    }

    public QuizAttempt submit(String studentId, QuizSubmitRequest req) {
        quizAttemptRepository.findByStudentIdAndQuizId(studentId, req.getQuizId())
                .ifPresent(e -> { throw new IllegalStateException("You have already taken this quiz."); });

        Course course = courseRepository.findById(req.getCourseId())
                .orElseThrow(() -> new IllegalArgumentException("Course not found."));

        Quiz quiz = (course.getQuizzes() == null ? Collections.<Quiz>emptySet() : course.getQuizzes())
                .stream()
                .filter(q -> req.getQuizId().equals(q.getQuizId()))
                .findFirst()
                .orElseThrow(() -> new IllegalArgumentException("Quiz not found in course."));

        List<Question> questions = quiz.getQuestions() == null
                ? Collections.emptyList()
                : new ArrayList<>(quiz.getQuestions());

        int total = questions.size();
        int correct = 0;
        Map<String, Boolean> questionResults = new LinkedHashMap<>();

        for (Question q : questions) {
            List<Integer> chosenIndices = req.getAnswers() == null
                    ? Collections.emptyList()
                    : req.getAnswers().getOrDefault(q.getQuestionId(), Collections.emptyList());

            List<AnswerOption> options = q.getOptions() == null
                    ? Collections.emptyList()
                    : q.getOptions();

            // Collect the set of correct option indices
            Set<Integer> correctIndices = new HashSet<>();
            for (int i = 0; i < options.size(); i++) {
                if (Boolean.TRUE.equals(options.get(i).getIsCorrect())) {
                    correctIndices.add(i);
                }
            }

            // A question is fully correct only when chosen == correct (exact match)
            Set<Integer> chosenSet = new HashSet<>(chosenIndices);
            boolean isCorrect = chosenSet.equals(correctIndices);

            if (isCorrect) correct++;
            questionResults.put(q.getQuestionId(), isCorrect);
        }

        int score = total > 0 ? Math.round((correct * 100f) / total) : 0;

        QuizAttempt attempt = QuizAttempt.builder()
                .studentId(studentId)
                .courseId(req.getCourseId())
                .quizId(req.getQuizId())
                .answers(req.getAnswers() != null ? req.getAnswers() : Collections.emptyMap())
                .score(score)
                .correctCount(correct)
                .totalQuestions(total)
                .questionResults(questionResults)
                .takenAt(LocalDateTime.now())
                .build();

        return quizAttemptRepository.save(attempt);
    }
}
