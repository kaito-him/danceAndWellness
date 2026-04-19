package com.example.demo.dto;

import com.example.demo.entities.AccountStatus;
import lombok.*;
import java.time.LocalDate;

@Data
@Builder
@NoArgsConstructor
@AllArgsConstructor
public class InstructorDTO {
    private String id;
    private String userId;

    // ── From User ──────────────────────────────────────────────────────────
    private String username;
    private String email;
    private AccountStatus accountStatus;
    private boolean featured;

    // ── Professional info ──────────────────────────────────────────────────
    private String yearsOfExperience;
    private String specialization;
    private String studioName;
    private String bio;

    // ── Online presence ────────────────────────────────────────────────────
    private String linkedIn;
    private String website;

    // ── Files ──────────────────────────────────────────────────────────────
    private String photo;                  // GridFS ObjectId
    private String certificationFileId;
    private String certificationFileName;
    private String certificationFileType;

    // ── Metadata ───────────────────────────────────────────────────────────
    private LocalDate appliedAt;

    // ── Stats (extend when a points/reward system is added) ────────────────
    private int points;
    private int totalCourses;
}