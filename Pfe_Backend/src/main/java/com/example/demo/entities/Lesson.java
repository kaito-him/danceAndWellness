package com.example.demo.entities;
import org.springframework.data.annotation.Id;
import org.springframework.data.mongodb.core.mapping.Document;

import lombok.AllArgsConstructor;
import lombok.Data;
import lombok.NoArgsConstructor;

@Document(collection = "Lessons")
@Data
@AllArgsConstructor
@NoArgsConstructor
public class Lesson {
	@Id
	private String lessonId;
	private Integer duration;
	private String title;
	private String mediaUrl;

}
