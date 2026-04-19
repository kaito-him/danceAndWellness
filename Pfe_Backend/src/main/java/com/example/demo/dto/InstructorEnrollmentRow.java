package com.example.demo.dto;

import java.time.LocalDateTime;

/**
 * A single row in the instructor's "My Earnings" table.
 * courseId / studentId are resolved to human-readable labels server-side.
 */
public class InstructorEnrollmentRow {

    private String enrollmentId;
    private String studentName;   // resolved from User collection
    private String studentEmail;  // resolved from User collection
    private String courseTitle;   // resolved from Course collection
    private String enrollmentType; // FREE | PAID
    private Long   amountPaidCents;
    private Long   instructorShareCents; // 80 % of amountPaidCents
    private LocalDateTime enrolledAt;

    public InstructorEnrollmentRow() {}

    // ── Getters / Setters ──────────────────────────────────────────────────
    public String getEnrollmentId()            { return enrollmentId; }
    public void   setEnrollmentId(String v)    { this.enrollmentId = v; }

    public String getStudentName()             { return studentName; }
    public void   setStudentName(String v)     { this.studentName = v; }

    public String getStudentEmail()            { return studentEmail; }
    public void   setStudentEmail(String v)    { this.studentEmail = v; }

    public String getCourseTitle()             { return courseTitle; }
    public void   setCourseTitle(String v)     { this.courseTitle = v; }

    public String getEnrollmentType()          { return enrollmentType; }
    public void   setEnrollmentType(String v)  { this.enrollmentType = v; }

    public Long getAmountPaidCents()           { return amountPaidCents; }
    public void setAmountPaidCents(Long v)     { this.amountPaidCents = v; }

    public Long getInstructorShareCents()      { return instructorShareCents; }
    public void setInstructorShareCents(Long v){ this.instructorShareCents = v; }

    public LocalDateTime getEnrolledAt()       { return enrolledAt; }
    public void setEnrolledAt(LocalDateTime v) { this.enrolledAt = v; }
}