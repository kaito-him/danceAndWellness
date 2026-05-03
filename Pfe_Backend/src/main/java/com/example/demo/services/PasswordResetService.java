package com.example.demo.services;

import com.example.demo.entities.User;
import com.example.demo.repositories.UserRepository;
import jakarta.mail.MessagingException;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.security.crypto.password.PasswordEncoder;
import org.springframework.stereotype.Service;

import java.security.SecureRandom;
import java.time.LocalDateTime;
import java.util.Map;
import java.util.Optional;
import java.util.concurrent.ConcurrentHashMap;

@Service
public class PasswordResetService {

    @Autowired private UserRepository userRepository;
    @Autowired private EmailService emailService;
    @Autowired private PasswordEncoder passwordEncoder;

    // In-memory store: userId → { code, expiresAt }
    private final Map<String, ResetEntry> store = new ConcurrentHashMap<>();

    private static final int CODE_TTL_SECONDS = 60;

    // ── Step 1: request a reset code ─────────────────────────────────────────
    public void requestReset(String usernameOrEmail) throws MessagingException {
        // Try username first, then email (case-insensitive email fallback)
        Optional<User> found = userRepository.findByUsername(usernameOrEmail);
        if (found.isEmpty()) {
            found = userRepository.findByEmail(usernameOrEmail);
        }
        if (found.isEmpty()) {
            // Try case-insensitive email match as last resort
            found = userRepository.findAll().stream()
                    .filter(u -> usernameOrEmail.equalsIgnoreCase(u.getEmail())
                              || usernameOrEmail.equalsIgnoreCase(u.getUsername()))
                    .findFirst();
        }
        User user = found.orElseThrow(() ->
                new IllegalArgumentException("No account found with that username or email."));

        String code = generateCode();
        store.put(user.getUserId(), new ResetEntry(code, LocalDateTime.now().plusSeconds(CODE_TTL_SECONDS)));

        emailService.sendPasswordResetCode(user.getEmail(), user.getUsername(), code);
    }

    // ── Step 2: verify the code ───────────────────────────────────────────────
    public String verifyCode(String usernameOrEmail, String code) {
        User user = userRepository.findByUsername(usernameOrEmail)
                .or(() -> userRepository.findByEmail(usernameOrEmail))
                .orElseThrow(() -> new IllegalArgumentException("No account found."));

        ResetEntry entry = store.get(user.getUserId());
        if (entry == null) {
            throw new IllegalStateException("No reset code was requested for this account.");
        }
        if (LocalDateTime.now().isAfter(entry.expiresAt())) {
            store.remove(user.getUserId());
            throw new IllegalStateException("Code has expired. Please request a new one.");
        }
        if (!entry.code().equals(code)) {
            throw new IllegalArgumentException("Incorrect code. Please try again.");
        }
        // Code is valid — return userId as a token for the reset step
        return user.getUserId();
    }

    // ── Step 3: reset the password ────────────────────────────────────────────
    public void resetPassword(String userId, String newPassword) {
        if (!store.containsKey(userId)) {
            throw new IllegalStateException("Reset session expired. Please start over.");
        }
        validatePasswordStrength(newPassword);

        User user = userRepository.findById(userId)
                .orElseThrow(() -> new IllegalArgumentException("User not found."));

        user.setPasswordHash(passwordEncoder.encode(newPassword));
        userRepository.save(user);
        store.remove(userId);
    }

    // ── Helpers ───────────────────────────────────────────────────────────────
    private String generateCode() {
        SecureRandom rng = new SecureRandom();
        int n = rng.nextInt(900_000) + 100_000; // 100000–999999
        return String.valueOf(n);
    }

    private void validatePasswordStrength(String password) {
        if (password == null || password.length() < 8)
            throw new IllegalArgumentException("Password must be at least 8 characters.");
        if (!password.matches(".*[A-Z].*"))
            throw new IllegalArgumentException("Password must contain at least one uppercase letter.");
        if (!password.matches(".*[a-z].*"))
            throw new IllegalArgumentException("Password must contain at least one lowercase letter.");
        if (!password.matches(".*\\d.*"))
            throw new IllegalArgumentException("Password must contain at least one number.");
        if (!password.matches(".*[!@#$%^&*()_+\\-=\\[\\]{};':\"\\\\|,.<>/?].*"))
            throw new IllegalArgumentException("Password must contain at least one special character.");
    }

    // ── Inner record ──────────────────────────────────────────────────────────
    private record ResetEntry(String code, LocalDateTime expiresAt) {}
}
