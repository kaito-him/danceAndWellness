// PaymentService.java
package com.example.demo.services;

import com.example.demo.dto.*;
import com.example.demo.entities.*;
import com.example.demo.repositories.*;
import com.stripe.Stripe;
import com.stripe.exception.StripeException;
import com.stripe.model.PaymentIntent;
import com.stripe.param.PaymentIntentCreateParams;
import jakarta.annotation.PostConstruct;
import lombok.RequiredArgsConstructor;
import org.springframework.beans.factory.annotation.Value;
import org.springframework.stereotype.Service;

import java.time.LocalDateTime;

@Service
@RequiredArgsConstructor
public class PaymentService {

    @Value("${stripe.secret.key}")
    private String stripeSecretKey;

    @Value("${app.platform.fee.percent}")
    private double platformFeePercent;           // 0.20

    private final CourseRepository      courseRepository;
    private final EnrollmentRepository  enrollmentRepository;
    private final NotificationService   notificationService;


	@PostConstruct
	public void init() {
	    Stripe.apiKey = stripeSecretKey;
	}
    // ── Step 1: create a PaymentIntent and return its client_secret ──────
    public PaymentIntentResponse createPaymentIntent(PaymentIntentRequest req) throws StripeException {

        Course course = courseRepository.findById(req.getCourseId())
            .orElseThrow(() -> new RuntimeException("Course not found"));

        if (Boolean.TRUE.equals(course.getIsFree()))
            throw new RuntimeException("Course is free — no payment needed");

        if (enrollmentRepository.existsByStudentIdAndCourseId(req.getStudentId(), req.getCourseId()))
            throw new RuntimeException("Already enrolled");

        long amountCents = Math.round(course.getPrice() * 100);  

        PaymentIntent intent = PaymentIntent.create(
            PaymentIntentCreateParams.builder()
                .setAmount(amountCents)
                .setCurrency("usd")
                .putMetadata("courseId",  req.getCourseId())
                .putMetadata("studentId", req.getStudentId())
                .addPaymentMethodType("card")
                .build()
        );

        return new PaymentIntentResponse(intent.getClientSecret(), intent.getId(), amountCents);
    }

    // ── Step 2: confirm payment succeeded → enroll student ──────────────
    public Enrollment confirmEnrollment(EnrollmentConfirmRequest req) throws StripeException {

        // Verify with Stripe that the payment actually succeeded
        PaymentIntent intent = PaymentIntent.retrieve(req.getPaymentIntentId());

        if (!"succeeded".equals(intent.getStatus()))
            throw new RuntimeException("Payment not confirmed by Stripe: " + intent.getStatus());

        // Idempotency guard
        if (enrollmentRepository.existsByStudentIdAndCourseId(req.getStudentId(), req.getCourseId()))
            return enrollmentRepository.findByPaymentIntentId(req.getPaymentIntentId()).orElseThrow();

        Course course = courseRepository.findById(req.getCourseId())
            .orElseThrow(() -> new RuntimeException("Course not found"));

        Enrollment enrollment = Enrollment.builder()
            .studentId(req.getStudentId())
            .courseId(req.getCourseId())
            .paymentIntentId(req.getPaymentIntentId())
            .amountPaidCents(intent.getAmount())
            .enrolledAt(LocalDateTime.now())
            .build();

        Enrollment saved = enrollmentRepository.save(enrollment);
        if (course.getInstructor() != null && course.getInstructor().getUserId() != null) {
            notificationService.create(
                course.getInstructor().getUserId(),
                "A student enrolled in your course \"" + course.getTitle() + "\".",
                "COURSE_ENROLLMENT",
                course.getCourseId(),
                false
            );
        }
        return saved;
    }

    // ── Utility: check if a student is already enrolled ─────────────────
    public boolean isEnrolled(String studentId, String courseId) {
        return enrollmentRepository.existsByStudentIdAndCourseId(studentId, courseId);
    }
}