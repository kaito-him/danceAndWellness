package com.example.demo.services;

import com.example.demo.dto.*;
import com.example.demo.entities.*;
import com.example.demo.entities.Enrollment.EnrollmentType;
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
public class EnrollmentService {

    @Value("${stripe.secret.key}")
    private String stripeSecretKey;

    @Value("${app.platform.fee.percent}")
    private double platformFeePercent;

    private final CourseRepository      courseRepository;
    private final EnrollmentRepository  enrollmentRepository;

    @PostConstruct
    public void init() {
        Stripe.apiKey = stripeSecretKey;
        System.out.println(">>> Stripe key loaded: " + stripeSecretKey.substring(0, 12) + "...");
    }

    // ── FREE: enroll directly, no payment ────────────────────────────────
    public Enrollment enrollFree(String studentId, String courseId) {

        Course course = courseRepository.findById(courseId)
            .orElseThrow(() -> new RuntimeException("Course not found"));

        if (!Boolean.TRUE.equals(course.getIsFree()))
            throw new RuntimeException("Course is not free");

        // Idempotent — already enrolled, just return it
        return enrollmentRepository
            .findByStudentIdAndCourseId(studentId, courseId)
            .orElseGet(() -> enrollmentRepository.save(
                Enrollment.builder()
                    .studentId(studentId)
                    .courseId(courseId)
                    .type(EnrollmentType.FREE)
                    .enrolledAt(LocalDateTime.now())
                    .build()
            ));
    }

    // ── PAID step 1: create Stripe PaymentIntent ──────────────────────────
    public PaymentIntentResponse createPaymentIntent(PaymentIntentRequest req)
            throws StripeException {

        Course course = courseRepository.findById(req.getCourseId())
            .orElseThrow(() -> new RuntimeException("Course not found"));

        if (Boolean.TRUE.equals(course.getIsFree()))
            throw new RuntimeException("Course is free — use free enrollment");

        if (enrollmentRepository.existsByStudentIdAndCourseId(
                req.getStudentId(), req.getCourseId()))
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

        return new PaymentIntentResponse(
            intent.getClientSecret(),
            intent.getId(),
            amountCents
        );
    }

    // ── PAID step 2: verify with Stripe and save enrollment ──────────────
    public Enrollment confirmPaidEnrollment(EnrollmentConfirmRequest req)
            throws StripeException {

        PaymentIntent intent = PaymentIntent.retrieve(req.getPaymentIntentId());

        if (!"succeeded".equals(intent.getStatus()))
            throw new RuntimeException("Payment not confirmed by Stripe: "
                + intent.getStatus());

        // Idempotent guard
        return enrollmentRepository
            .findByPaymentIntentId(req.getPaymentIntentId())
            .orElseGet(() -> enrollmentRepository.save(
                Enrollment.builder()
                    .studentId(req.getStudentId())
                    .courseId(req.getCourseId())
                    .type(EnrollmentType.PAID)
                    .paymentIntentId(req.getPaymentIntentId())
                    .amountPaidCents(intent.getAmount())
                    .enrolledAt(LocalDateTime.now())
                    .build()
            ));
    }

    // ── Shared utility ────────────────────────────────────────────────────
    public boolean isEnrolled(String studentId, String courseId) {
        return enrollmentRepository.existsByStudentIdAndCourseId(studentId, courseId);
    }
}