import React from "react";
import { Link, useNavigate } from "react-router-dom";
import "../styles/AboutPage.css";
import Navbar from "./Navbar";
import mjBack from "../assets/MJBack.png";

const AboutPage = () => {
  const navigate = useNavigate();

  return (
    <div className="about-page">
      <Navbar />

      {/* ── Body: image left + content right ── */}
      <div className="about-body">

        {/* ── Left: scrollable content ── */}
        <div className="about-content">
         



          <h1 className="about-title">
            About <span className="about-highlight">danceAndWellness</span>
          </h1>

          <p className="about-tagline">
            Your All-in-One Dance &amp; Wellness Platform
          </p>

          <p className="about-intro">
            danceAndWellness is a comprehensive web solution designed to
            transform how dance instructors, wellness coaches, and students
            connect and grow together.
          </p>

          {/* ── What We Offer ── */}
          <div className="about-section">
            <h2 className="about-section-title">What We Offer</h2>
            <ul className="about-offer-list">
              <li>
                <span className="offer-label">Course Management</span>
                <span className="offer-dash">—</span>
                Organize, schedule, and manage dance and wellness courses with ease
              </li>
              <li>
                <span className="offer-label">User Tracking</span>
                <span className="offer-dash">—</span>
                Monitor student progress, achievements, and engagement in real-time
              </li>
              <li>
                <span className="offer-label">Multimedia Content</span>
                <span className="offer-dash">—</span>
                Access high-quality video lessons, tutorials, and wellness resources
              </li>
              <li>
                <span className="offer-label">E-Commerce Integration</span>
                <span className="offer-dash">—</span>
                Purchase courses, merchandise, and wellness products seamlessly
              </li>
              <li>
                <span className="offer-label">AI-Powered Recommendations</span>
                <span className="offer-dash">—</span>
                Get personalized course and content suggestions tailored to your interests and goals
              </li>
            </ul>
          </div>

          {/* ── Our Vision ── */}
          <div className="about-section">
            <h2 className="about-section-title">Our Vision</h2>
            <p className="about-vision-text">
              We believe that quality dance and wellness education should be
              accessible to everyone. By combining technology with expert
              instruction, we're building a community where students can achieve
              their fitness and artistic goals while instructors can focus on
              what they do best—inspiring and transforming lives.
            </p>
          </div>

          {/* ── Why Choose Us ── */}
          <div className="about-section">
            <h2 className="about-section-title">Why Choose Us?</h2>
            <ul className="about-why-list">
              {[
                "Centralized platform for all your dance & wellness needs",
                "Intelligent recommendations powered by AI",
                "User-friendly interface",
                "Community-driven approach",
                "Continuous innovation and improvement",
              ].map((item) => (
                <li key={item}>
                  <span className="why-check">✓</span>
                  {item}
                </li>
              ))}
            </ul>
          </div>

          <div className="about-cta">
            <Link to="/signup" className="about-cta-btn">
              Join Us Today
            </Link>
            <Link to="/courses" className="about-cta-btn-outline">
              Explore Courses
            </Link>
          </div>
        </div>

        {/* ── Right: sticky image ── */}
        <div className="about-image-col">
          <div className="about-image-glow"></div>
          <img
            src={mjBack}
            alt="Dance silhouette"
            className="about-hero-image"
          />
        </div>
      </div>
    </div>
  );
};

export default AboutPage;