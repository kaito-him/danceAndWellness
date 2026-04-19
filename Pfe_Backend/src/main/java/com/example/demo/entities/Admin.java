package com.example.demo.entities;

import org.springframework.data.annotation.Id;
import org.springframework.data.mongodb.core.mapping.Document;
import lombok.*;

@Document(collection = "admins")
@Getter
@Setter
@ToString
@NoArgsConstructor
@AllArgsConstructor
public class Admin {
	 	@Id
	    private String id;

	    private String userId; 
	    
	    public Admin(String userId) {
	        this.userId = userId;
	    }
}