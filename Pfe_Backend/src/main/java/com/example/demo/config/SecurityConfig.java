package com.example.demo.config;

import com.example.demo.security.JwtFilter;
import org.springframework.context.annotation.Bean;
import org.springframework.context.annotation.Configuration;
import org.springframework.http.HttpMethod;
import org.springframework.security.config.annotation.web.builders.HttpSecurity;
import org.springframework.security.config.annotation.web.configuration.EnableWebSecurity;
import org.springframework.security.config.http.SessionCreationPolicy;
import org.springframework.security.crypto.bcrypt.BCryptPasswordEncoder;
import org.springframework.security.crypto.password.PasswordEncoder;
import org.springframework.security.web.SecurityFilterChain;
import org.springframework.security.web.authentication.UsernamePasswordAuthenticationFilter;

@Configuration
@EnableWebSecurity
public class SecurityConfig {

    private final JwtFilter jwtFilter;

    public SecurityConfig(JwtFilter jwtFilter) { this.jwtFilter = jwtFilter; }

    @Bean
    public PasswordEncoder passwordEncoder() { return new BCryptPasswordEncoder(); }

    @Bean
    public SecurityFilterChain filterChain(HttpSecurity http) throws Exception {
        http
            .cors(cors -> cors.configurationSource(corsConfigurationSource()))
            .csrf(csrf -> csrf.disable())
            .sessionManagement(s -> s.sessionCreationPolicy(SessionCreationPolicy.STATELESS))
            .authorizeHttpRequests(auth -> auth
                .requestMatchers("/api/students/**").authenticated()
                .requestMatchers("/api/users/**").authenticated()

                // ── Public ────────────────────────────────────────────────
                .requestMatchers("/api/auth/**").permitAll()
                .requestMatchers(HttpMethod.GET, "/api/files/**").permitAll()
                .requestMatchers("/api/auth/register/instructor").permitAll()
                .requestMatchers(HttpMethod.GET, "/api/categories/**").permitAll()
                
                // ── Users ─────────────────────────────────────────────────
                .requestMatchers("/api/users/**").authenticated()

                // ── Files ─────────────────────────────────────────────────
                .requestMatchers(HttpMethod.POST, "/api/files/upload")
                    .hasAnyRole("INSTRUCTOR", "ADMIN", "STUDENT")

                // ── Admin — 
                .requestMatchers(HttpMethod.GET,   "/api/admin/applications")
                    .hasRole("ADMIN")
                .requestMatchers(HttpMethod.PATCH, "/api/admin/applications/**")
                    .hasRole("ADMIN")
                .requestMatchers("/api/admin/payments/**")
                    .hasRole("ADMIN")
                .requestMatchers(HttpMethod.GET, "/api/statistics/**")
                    .hasRole("ADMIN")
                 .requestMatchers(HttpMethod.POST, "/api/categories")
                    .hasAnyRole("ADMIN")
                    
                    
                 // Instructors
                    .requestMatchers(HttpMethod.GET, "/api/instructors/**").permitAll()
        
                 // ── Progress (add this block with the enrollment rules) ──────────────
                    .requestMatchers("/api/progress/stream").authenticated()
                    .requestMatchers("/api/progress/**").authenticated()
                    // ── Comments (MUST come before the generic /api/courses/** rules) ──
                    .requestMatchers(HttpMethod.GET,    "/api/courses/*/comments").permitAll()
                    .requestMatchers(HttpMethod.GET,    "/api/courses/*/comments/*/replies").permitAll()
                    .requestMatchers(HttpMethod.POST,   "/api/courses/*/comments").authenticated()
                    .requestMatchers(HttpMethod.POST,   "/api/courses/*/comments/*/replies").authenticated()
                    .requestMatchers(HttpMethod.POST,   "/api/courses/*/comments/*/like").authenticated()
                    .requestMatchers(HttpMethod.DELETE, "/api/courses/*/comments/*/like").authenticated()
                    .requestMatchers(HttpMethod.DELETE, "/api/courses/*/comments/**").authenticated() // ← before course DELETE

                // ── Courses ───────────────────────────────────────────────
                .requestMatchers(HttpMethod.GET,    "/api/courses/pending").hasRole("ADMIN")
                .requestMatchers(HttpMethod.GET,    "/api/courses/admin-archived").hasRole("ADMIN")
                .requestMatchers(HttpMethod.PATCH,  "/api/courses/*/unarchive-admin").hasRole("ADMIN")
                .requestMatchers(HttpMethod.GET,    "/api/courses/my-published").hasRole("INSTRUCTOR")
                .requestMatchers(HttpMethod.GET,    "/api/courses/my-pending").hasRole("INSTRUCTOR")
                .requestMatchers(HttpMethod.GET,    "/api/courses/my-drafts").hasRole("INSTRUCTOR")
                .requestMatchers(HttpMethod.GET,    "/api/courses/my-archived").hasRole("INSTRUCTOR")
                .requestMatchers(HttpMethod.POST,   "/api/courses").hasAnyRole("INSTRUCTOR", "ADMIN")
                .requestMatchers(HttpMethod.POST,   "/api/courses/draft").hasRole("INSTRUCTOR")
                .requestMatchers(HttpMethod.PUT,    "/api/courses/**").hasAnyRole("INSTRUCTOR", "ADMIN")
                .requestMatchers(HttpMethod.DELETE, "/api/courses/**").hasAnyRole("INSTRUCTOR", "ADMIN")
                .requestMatchers(HttpMethod.PATCH,  "/api/courses/*/publish").hasRole("INSTRUCTOR")
                .requestMatchers(HttpMethod.PATCH,  "/api/courses/*/archive-instructor").hasRole("INSTRUCTOR")
                .requestMatchers(HttpMethod.PATCH,  "/api/courses/*/unarchive").hasRole("INSTRUCTOR")
                .requestMatchers(HttpMethod.PATCH,  "/api/courses/**").hasRole("ADMIN")

                // Public reads (must come after protected /my-* routes)
                .requestMatchers(HttpMethod.GET, "/api/courses/*/enrollments/count").permitAll()
                .requestMatchers(HttpMethod.GET, "/api/courses/*").permitAll()

                
                
                // ── Notifications ─────────────────────────────────────────
                .requestMatchers("/api/notifications/**").authenticated()

                // ── Payment ───────────────────────────────────────────────
             // ── Payment / Enrollment ──────────────────────────────────────────────
                .requestMatchers(HttpMethod.GET,  "/api/payment/is-enrolled").authenticated()
                .requestMatchers("/api/enrollment/**").authenticated()

                // ── Progress ──────────────────────────────────────────────────────────
                .requestMatchers(HttpMethod.GET,  "/api/progress/stream").authenticated()  // SSE
                .requestMatchers(HttpMethod.GET,  "/api/progress/course").authenticated()
                .requestMatchers(HttpMethod.GET,  "/api/progress/lessons").authenticated()
                .requestMatchers(HttpMethod.POST, "/api/progress/update").authenticated()
                
                
                .requestMatchers("/api/instructor/payments/**")
                .hasAnyRole("INSTRUCTOR", "ADMIN")
             // ── Messages ─────────────────────────────────────────────
                .requestMatchers("/api/messages/**").authenticated()

                // ── Badges ───────────────────────────────────────────────
                .requestMatchers("/api/badges/**").authenticated()

                // ── Quizzes ───────────────────────────────────────────────
                .requestMatchers("/api/quizzes/**").authenticated()

                .anyRequest().authenticated()
            )
            .addFilterBefore(jwtFilter, UsernamePasswordAuthenticationFilter.class);

        return http.build();
    }

    @Bean
    public org.springframework.web.cors.CorsConfigurationSource corsConfigurationSource() {
        var config = new org.springframework.web.cors.CorsConfiguration();
        config.setAllowedOrigins(java.util.List.of("http://localhost:5173"));
        config.setAllowedMethods(java.util.List.of("GET","POST","PUT","DELETE","PATCH","OPTIONS"));
        config.setAllowedHeaders(java.util.List.of("*"));
        config.setAllowCredentials(true);
        var source = new org.springframework.web.cors.UrlBasedCorsConfigurationSource();
        source.registerCorsConfiguration("/**", config);
        return source;
    }
}