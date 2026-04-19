package com.example.demo.dto;

// ── Response for Stripe Connect onboarding link ──────────────────────────────
public class StripeOnboardingResponse {
    private String url;

    public StripeOnboardingResponse() {}
    public StripeOnboardingResponse(String url) { this.url = url; }

    public String getUrl() { return url; }
    public void setUrl(String url) { this.url = url; }
}