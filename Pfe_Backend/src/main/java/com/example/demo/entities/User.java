package com.example.demo.entities;

import java.time.LocalDate;
import java.time.LocalDateTime;
import java.time.ZoneId;

import org.springframework.data.annotation.Id;
import org.springframework.data.mongodb.core.index.Indexed;
import org.springframework.data.mongodb.core.mapping.Document;
import lombok.*;

@Document(collection = "users")
@Data
@AllArgsConstructor
@RequiredArgsConstructor
@NoArgsConstructor
@EqualsAndHashCode(of = {"username"})
public class User {
    @Id
    private String userId; 

    @Indexed(unique = true)
    @lombok.NonNull
    private String username;

    @Indexed(unique = true)
    @lombok.NonNull
    private String email;

    @lombok.NonNull
    private String passwordHash;
    
    private String role;

    private AccountStatus status;

    private LocalDate createdAt = LocalDate.now(ZoneId.systemDefault());

    private LocalDateTime lastLoginDate;
    
    private String photo; // GridFS ObjectId

}