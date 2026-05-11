package com.example.demo.dto;

import com.example.demo.entities.AccountStatus;
import lombok.*;
import java.time.LocalDate;
import java.time.LocalDateTime;

@Data
@Builder
@NoArgsConstructor
@AllArgsConstructor
public class StudentDTO {
    private String id;
    private String userId;

    private String username;
    private String email;
    private AccountStatus accountStatus;

    private String photo;                  // GridFS ObjectId

    private LocalDate createdAt;
    private LocalDateTime lastLoginDate;
    private java.util.List<String> badgeIds;
}
