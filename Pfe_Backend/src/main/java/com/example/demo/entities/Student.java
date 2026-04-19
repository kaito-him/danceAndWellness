package com.example.demo.entities;

import java.util.List;

import org.springframework.data.annotation.Id;
import org.springframework.data.mongodb.core.mapping.Document;
import lombok.*;

@Document(collection = "students") 
@Getter
@Setter
@ToString
@NoArgsConstructor
@AllArgsConstructor
public class Student {
		@Id
	    private String id;
		private String userId; 
		private List<String> badgeIds; 
		private String userProfileId;
		private String photo; // gridFs
		
		public Student(String userId) {
	        this.userId = userId;
	    }
}