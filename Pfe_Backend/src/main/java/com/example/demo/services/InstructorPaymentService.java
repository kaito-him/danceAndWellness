package com.example.demo.services;

import com.example.demo.dto.InstructorEnrollmentRow;
import com.example.demo.dto.StripeOnboardingResponse;
import com.example.demo.entities.Course;
import com.example.demo.entities.Enrollment;
import com.example.demo.entities.Instructor;
import com.example.demo.repositories.*;
import com.stripe.Stripe;
import com.stripe.exception.StripeException;
import com.stripe.model.Account;
import com.stripe.model.AccountLink;
import com.stripe.param.AccountCreateParams;
import com.stripe.param.AccountLinkCreateParams;
import jakarta.annotation.PostConstruct;
import lombok.RequiredArgsConstructor;
import org.springframework.beans.factory.annotation.Value;
import org.springframework.stereotype.Service;

import java.util.*;
import java.util.stream.Collectors;

@Service
@RequiredArgsConstructor
public class InstructorPaymentService {

    @Value("${stripe.secret.key}")
    private String stripeSecretKey;

    /** Platform keeps 20 % → instructor earns 80 % */
    private static final double INSTRUCTOR_SHARE = 0.80;

    @Value("${app.frontend.url:http://localhost:5173}")
    private String frontendUrl;

    private final InstructorRepository instructorRepository;
    private final CourseRepository courseRepository;
    private final EnrollmentRepository enrollmentRepository;
    private final UserRepository userRepository;

    @PostConstruct
    public void init() {
        Stripe.apiKey = stripeSecretKey;
    }

    // ══════════════════════════════════════════════════════════════════════
    // 1. Create (or retrieve) a Stripe Express account + return onboarding URL
    // ══════════════════════════════════════════════════════════════════════
    public StripeOnboardingResponse createOrGetOnboardingLink(String instructorId)
            throws StripeException {

        Instructor instructor = instructorRepository.findById(instructorId)
                .orElseThrow(() -> new RuntimeException("Instructor not found"));

        String accountId = instructor.getStripeAccountId();

        // Create a new Express account if none exists yet
        if (accountId == null || accountId.isBlank()) {
            Account account = Account.create(
                    AccountCreateParams.builder()
                            .setType(AccountCreateParams.Type.EXPRESS)
                            .setCountry("US")
                            .setCapabilities(
                                    AccountCreateParams.Capabilities.builder()
                                            .setTransfers(
                                                    AccountCreateParams.Capabilities.Transfers.builder()
                                                            .setRequested(true)
                                                            .build())
                                            .build())
                            .build());
            accountId = account.getId();
            instructor.setStripeAccountId(accountId);
            instructorRepository.save(instructor);
        }

        // Generate a fresh Account Link (they expire quickly)
        AccountLink link = AccountLink.create(
                AccountLinkCreateParams.builder()
                        .setAccount(accountId)
                        .setRefreshUrl(frontendUrl + "/instructor?section=payments&onboarding=refresh")
                        .setReturnUrl(frontendUrl + "/instructor?section=payments&onboarding=complete")
                        .setType(AccountLinkCreateParams.Type.ACCOUNT_ONBOARDING)
                        .build());

        return new StripeOnboardingResponse(link.getUrl());
    }

    // ══════════════════════════════════════════════════════════════════════
    // 2. Check whether the connected account has finished onboarding
    // ══════════════════════════════════════════════════════════════════════
    public boolean isOnboardingComplete(String instructorId) throws StripeException {
        Instructor instructor = instructorRepository.findById(instructorId)
                .orElseThrow(() -> new RuntimeException("Instructor not found"));

        if (instructor.getStripeAccountId() == null)
            return false;

        Account account = Account.retrieve(instructor.getStripeAccountId());
        return Boolean.TRUE.equals(account.getChargesEnabled());
    }

    // ══════════════════════════════════════════════════════════════════════
    // 3. Fetch all enrollments for courses owned by this instructor
    // ══════════════════════════════════════════════════════════════════════
    public List<InstructorEnrollmentRow> getEnrollments(String instructorId) {

        Instructor instructor = instructorRepository.findById(instructorId)
                .orElseThrow(() -> new RuntimeException("Instructor not found"));

        // All courses whose embedded instructor.id == instructorId
        List<Course> myCourses = courseRepository.findByInstructor_Id(instructorId);

        if (myCourses.isEmpty())
            return Collections.emptyList();

        Set<String> courseIds = myCourses.stream()
                .map(Course::getCourseId)
                .collect(Collectors.toSet());

        Map<String, String> courseTitles = myCourses.stream()
                .collect(Collectors.toMap(Course::getCourseId, Course::getTitle));

        List<Enrollment> enrollments = enrollmentRepository.findByCourseIdIn(courseIds);

        return enrollments.stream().map(e -> {
            InstructorEnrollmentRow row = new InstructorEnrollmentRow();
            row.setEnrollmentId(e.getId());
            row.setCourseId(e.getCourseId());
            row.setStudentId(e.getStudentId());
            row.setCourseTitle(courseTitles.getOrDefault(e.getCourseId(), e.getCourseId()));
            row.setEnrollmentType(e.getType() != null ? e.getType().name() : "—");
            row.setEnrolledAt(e.getEnrolledAt());

            // Resolve student name/email from User collection via Student
            userRepository.findById(e.getStudentId()).ifPresentOrElse(
                    user -> {
                        row.setStudentName(user.getUsername());
                        row.setStudentEmail(user.getEmail());
                    },
                    () -> {
                        row.setStudentName("Unknown");
                        row.setStudentEmail("—");
                    });

            // Earnings
            if (e.getAmountPaidCents() != null) {
                row.setAmountPaidCents(e.getAmountPaidCents());
                row.setInstructorShareCents(
                        Math.round(e.getAmountPaidCents() * INSTRUCTOR_SHARE));
            } else {
                row.setAmountPaidCents(0L);
                row.setInstructorShareCents(0L);
            }

            return row;
        }).collect(Collectors.toList());
    }

    public List<InstructorEnrollmentRow> getEnrollmentsByCourse(String courseId) {
        Course course = courseRepository.findById(courseId)
                .orElseThrow(() -> new RuntimeException("Course not found"));

        List<Enrollment> enrollments = enrollmentRepository.findByCourseId(courseId);

        return enrollments.stream().map(e -> {
            InstructorEnrollmentRow row = new InstructorEnrollmentRow();
            row.setEnrollmentId(e.getId());
            row.setCourseId(e.getCourseId());
            row.setStudentId(e.getStudentId());
            row.setCourseTitle(course.getTitle());
            row.setEnrollmentType(e.getType() != null ? e.getType().name() : "—");
            row.setEnrolledAt(e.getEnrolledAt());

            userRepository.findById(e.getStudentId()).ifPresentOrElse(
                    user -> {
                        row.setStudentName(user.getUsername());
                        row.setStudentEmail(user.getEmail());
                    },
                    () -> {
                        row.setStudentName("Unknown");
                        row.setStudentEmail("—");
                    });

            if (e.getAmountPaidCents() != null) {
                row.setAmountPaidCents(e.getAmountPaidCents());
                row.setInstructorShareCents(
                        Math.round(e.getAmountPaidCents() * INSTRUCTOR_SHARE));
            } else {
                row.setAmountPaidCents(0L);
                row.setInstructorShareCents(0L);
            }

            return row;
        }).collect(Collectors.toList());
    }

    // ══════════════════════════════════════════════════════════════════════
    // 4. Stripe account status for the UI
    // ══════════════════════════════════════════════════════════════════════
    public Map<String, Object> getAccountStatus(String instructorId) throws StripeException {
        Instructor instructor = instructorRepository.findById(instructorId)
                .orElseThrow(() -> new RuntimeException("Instructor not found"));

        Map<String, Object> result = new HashMap<>();
        result.put("hasAccount", instructor.getStripeAccountId() != null);
        result.put("stripeAccountId", instructor.getStripeAccountId());

        if (instructor.getStripeAccountId() != null) {
            Account account = Account.retrieve(instructor.getStripeAccountId());
            result.put("chargesEnabled", account.getChargesEnabled());
            result.put("payoutsEnabled", account.getPayoutsEnabled());
            result.put("detailsSubmitted", account.getDetailsSubmitted());
        }
        return result;
    }

    public List<InstructorEnrollmentRow> getEnrollmentsByUserId(String userId) {
        Instructor instructor = instructorRepository.findByUserId(userId)
                .orElseThrow(() -> new RuntimeException("Instructor not found"));

        return getEnrollments(instructor.getId());
    }
}