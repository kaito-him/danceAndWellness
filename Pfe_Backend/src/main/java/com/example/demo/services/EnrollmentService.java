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
    private final NotificationService   notificationService;
    private final BadgeEvaluationService badgeEvaluationService;

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
        boolean alreadyEnrolled = enrollmentRepository.existsByStudentIdAndCourseId(studentId, courseId);
        Enrollment enrollment = enrollmentRepository
            .findByStudentIdAndCourseId(studentId, courseId)
            .orElseGet(() -> enrollmentRepository.save(
                Enrollment.builder()
                    .studentId(studentId)
                    .courseId(courseId)
                    .type(EnrollmentType.FREE)
                    .enrolledAt(LocalDateTime.now())
                    .build()
            ));
        if (!alreadyEnrolled) {
            notifyInstructorEnrollment(course, enrollment, studentId);
            badgeEvaluationService.evaluate(studentId);
        }
        return enrollment;
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
        boolean alreadyConfirmed = enrollmentRepository.findByPaymentIntentId(req.getPaymentIntentId()).isPresent();
        Enrollment enrollment = enrollmentRepository
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
        Course course = courseRepository.findById(req.getCourseId())
            .orElseThrow(() -> new RuntimeException("Course not found"));
        if (!alreadyConfirmed) {
            notifyInstructorEnrollment(course, enrollment, req.getStudentId());
            // Notify the student about successful purchase
            notificationService.create(
                req.getStudentId(),
                "You have successfully enrolled in \"" + course.getTitle() + "\". Enjoy learning!",
                "PURCHASE_SUCCESS",
                course.getCourseId(),
                false
            );
            badgeEvaluationService.evaluate(req.getStudentId());
        }
        return enrollment;
    }

    // ── Shared utility ────────────────────────────────────────────────────
    public boolean isEnrolled(String studentId, String courseId) {
        return enrollmentRepository.existsByStudentIdAndCourseId(studentId, courseId);
    }

    // ── CANCEL free enrollment ────────────────────────────────────────────
    public void cancelFreeEnrollment(String studentId, String courseId) {
        Course course = courseRepository.findById(courseId)
            .orElseThrow(() -> new RuntimeException("Course not found"));

        if (!Boolean.TRUE.equals(course.getIsFree()))
            throw new RuntimeException("Cannot cancel a paid enrollment");

        enrollmentRepository
            .findByStudentIdAndCourseId(studentId, courseId)
            .ifPresent(enrollmentRepository::delete);
    }

    private void notifyInstructorEnrollment(Course course, Enrollment enrollment, String studentId) {
        if (course.getInstructor() == null || course.getInstructor().getUserId() == null) return;
        if (enrollment.getEnrolledAt() == null) return;
        notificationService.create(
            course.getInstructor().getUserId(),
            "A student enrolled in your course \"" + course.getTitle() + "\".",
            "COURSE_ENROLLMENT",
            course.getCourseId(),
            false
        );
    }
}