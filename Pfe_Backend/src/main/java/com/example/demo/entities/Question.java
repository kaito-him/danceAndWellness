package com.example.demo.entities;

import org.springframework.data.annotation.Id;
import org.springframework.data.mongodb.core.mapping.Document;

import lombok.*;
@Document(collection = "Questions")
@Data
@AllArgsConstructor
@NoArgsConstructor
public class Question {
	@Id
	private String questionId;
	private String text;
	private boolean isCorrect;

}
