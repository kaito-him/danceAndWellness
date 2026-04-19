package com.example.demo.entities;

import lombok.*;
import org.springframework.data.annotation.Id;
import org.springframework.data.mongodb.core.mapping.Document;
import java.time.LocalDateTime;

@Document(collection = "enrollments")
@Data
@NoArgsConstructor
@AllArgsConstructor
@Builder
public class Enrollment {
    @Id
    private String id;

    private String studentId;
    private String courseId;

    private EnrollmentType type;     
    // Only populated for paid enrollments
    private String paymentIntentId;
    private Long   amountPaidCents;

    private LocalDateTime enrolledAt;

    public enum EnrollmentType {
        FREE, PAID
    }
}