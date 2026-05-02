package com.example.demo.entities;

import java.time.LocalDate;
import java.util.HashSet;
import java.util.List;
import java.util.Set;

import org.springframework.data.annotation.Id;
import org.springframework.data.mongodb.core.mapping.Document;
import lombok.*;

@Document(collection = "students") 
@Data
@Builder
@NoArgsConstructor
@AllArgsConstructor
public class Student {
		@Id
	    private String id;
		private String userId; 
		private List<String> badgeIds; 
		
		@Builder.Default
		private Set<LocalDate> loginDates = new HashSet<>();
		
		private String photo; 
		
		public Student(String userId) {
	        this.userId = userId;
	        this.loginDates = new HashSet<>();
	    }
}