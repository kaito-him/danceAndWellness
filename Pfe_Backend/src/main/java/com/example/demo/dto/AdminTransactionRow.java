package com.example.demo.dto;

import lombok.AllArgsConstructor;
import lombok.Builder;
import lombok.Data;
import lombok.NoArgsConstructor;
import java.time.LocalDateTime;

@Data
@NoArgsConstructor
@AllArgsConstructor
@Builder
public class AdminTransactionRow {
    private String id;
    private String studentName;
    private String studentId;
    private String courseTitle;
    private String instructorName;
    private String instructorId;
    private long totalAmountCents;
    private long platformFeeCents;
    private LocalDateTime enrolledAt;
}
