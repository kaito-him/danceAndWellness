package com.example.demo.entities;
import org.springframework.data.annotation.Id;
import org.springframework.data.mongodb.core.mapping.Document;

import lombok.AllArgsConstructor;
import lombok.Data;
import lombok.NoArgsConstructor;

@Document(collection = "badges")
@Data
@AllArgsConstructor
@NoArgsConstructor
public class Badge {
	@Id
    private String id;

	
	 private String name;
	 private String achievement;
	 private String icon;  ///GridFs
}
