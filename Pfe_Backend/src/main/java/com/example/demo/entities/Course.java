package com.example.demo.entities;

import java.time.LocalDateTime;
import java.util.List;
import org.springframework.data.annotation.Id;
import org.springframework.data.mongodb.core.mapping.Document;

import lombok.AllArgsConstructor;
import lombok.Data;
import lombok.NoArgsConstructor;

@Document(collection = "Courses")
@Data
@AllArgsConstructor
@NoArgsConstructor
public class Course {
	@Id
	private String courseId;
	private String title;
	private Boolean isFree;
	private Double price;
	private DifficultyLevel level;
	private CourseStatus status;
	private String thumbnailUrl;
	private LocalDateTime createdAt;
	private String categoryId;
	private Instructor instructor;

	private List<Lesson> lessons;
	private List<Quiz> quizzes;
}
