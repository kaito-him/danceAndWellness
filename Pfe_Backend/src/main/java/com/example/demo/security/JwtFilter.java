package com.example.demo.security;
import jakarta.servlet.*;
import jakarta.servlet.http.*;
import org.springframework.security.authentication.UsernamePasswordAuthenticationToken;
import org.springframework.security.core.authority.SimpleGrantedAuthority;
import org.springframework.security.core.context.SecurityContextHolder;
import org.springframework.stereotype.Component;
import org.springframework.web.filter.OncePerRequestFilter;
import java.io.IOException;
import java.util.List;

@Component
public class JwtFilter extends OncePerRequestFilter {

    private final JwtUtil jwtUtil;

    public JwtFilter(JwtUtil jwtUtil) {
        this.jwtUtil = jwtUtil;
    }

    @Override
    protected void doFilterInternal(HttpServletRequest request,
                                    HttpServletResponse response,
                                    FilterChain chain)
            throws ServletException, IOException {

        String path = request.getServletPath();

        // ── Bypass auth endpoints entirely ────────────────────────────────
        if (path.startsWith("/api/auth")) {
            chain.doFilter(request, response);
            return;
        }

        // ── 1. Try Authorization header (all normal API calls) ────────────
        String token = null;
        String header = request.getHeader("Authorization");
        if (header != null && header.startsWith("Bearer ")) {
            token = header.substring(7);
        }

        // ── 2. Fallback: ?token= query param (SSE / EventSource only) ─────
        if (token == null) {
            String queryToken = request.getParameter("token");
            if (queryToken != null && !queryToken.isBlank()) {
                token = queryToken;
                System.out.println(">>> JWT loaded from query param for SSE: " + path);
            }
        }

        // ── 3. Validate and authenticate ──────────────────────────────────
        if (token != null) {
            try {
                String username = jwtUtil.extractUsername(token);
                String role     = jwtUtil.extractRole(token);

                System.out.println(">>> JWT role value: [" + role + "]");

                UsernamePasswordAuthenticationToken auth =
                    new UsernamePasswordAuthenticationToken(
                        username,
                        null,
                        List.of(new SimpleGrantedAuthority("ROLE_" + role))
                    );
                SecurityContextHolder.getContext().setAuthentication(auth);
                System.out.println(">>> SecurityContext set for: " + username);

            } catch (Exception e) {
                System.out.println(">>> JWT Filter Error: " + e.getMessage());
                response.setStatus(HttpServletResponse.SC_UNAUTHORIZED);
                return;
            }
        } else {
            System.out.println(">>> No token found (header or query param) for: " + path);
        }

        chain.doFilter(request, response);
    }
}