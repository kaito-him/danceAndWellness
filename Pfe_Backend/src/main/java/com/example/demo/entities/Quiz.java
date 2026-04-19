package com.example.demo.entities;

import java.util.Set;

import org.springframework.data.annotation.Id;
import org.springframework.data.mongodb.core.mapping.Document;

import lombok.AllArgsConstructor;
import lombok.Data;
import lombok.NoArgsConstructor;
@Document(collection = "Quizzes") 
@Data
@AllArgsConstructor
@NoArgsConstructor
public class Quiz {
	@Id
	private String quizId;
	private String title;
    private Set<Question> questions;
}
