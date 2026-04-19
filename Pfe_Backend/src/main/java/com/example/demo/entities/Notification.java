package com.example.demo.entities;

import java.time.LocalDateTime;
import org.springframework.data.annotation.Id;
import org.springframework.data.mongodb.core.mapping.Document;
import lombok.*;

@Document(collection = "notifications")
@Data
@AllArgsConstructor
@NoArgsConstructor
public class Notification {
    @Id
    private String id;

    private String userId;        
    private String message;         
    private boolean read = false;
    private LocalDateTime createdAt = LocalDateTime.now();
    
}