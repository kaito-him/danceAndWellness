import React, { useRef, useEffect, useState } from "react";
import "../styles/HomePage.css";
import { Link } from "react-router-dom";
import Navbar from "../components/Navbar";
import api from "../components/services/api";
import { FiCalendar, FiBarChart2, FiMessageCircle, FiTarget } from "react-icons/fi";
import des1 from "../assets/decs1.jpg";
import des2 from "../assets/des2.jpg";
import mobileApp from "../assets/mobileApp.webp";


const BASE_URL = "http://localhost:8080";


const FEATURES = [
  {
    icon: <FiCalendar size={36} strokeWidth={1.5} />,
    title: "Smart Scheduling",
    desc: "AI-powered class management that adapts to your rhythm.",
  },
  {
    icon: <FiBarChart2 size={36} strokeWidth={1.5} />,
    title: "Performance Analytics",
    desc: "Deep insights on student progress, attendance, and wellness trends.",
  },
  {
    icon: <FiMessageCircle size={36} strokeWidth={1.5} />,
    title: "Live Communication",
    desc: "Seamless messaging between instructors and students.",
  },
  {
    icon: <FiTarget size={36} strokeWidth={1.5} />,
    title: "Progress Tracking",
    desc: "Personalized dashboards that celebrate every milestone.",
  },
];


const HomePage = ({ instructorsRef }) => {
  // IntersectionObserver — triggers .visible when section enters viewport
  useEffect(() => {
    const observer = new IntersectionObserver(
      (entries) => {
        entries.forEach((entry) => {
          if (entry.isIntersecting) {
            entry.target.classList.add("visible");
          }
        });
      },
      { threshold: 0.15 }
    );

    document.querySelectorAll(".scroll-reveal").forEach((el) => observer.observe(el));
    return () => observer.disconnect();
  }, []);

  const [featuredInstructors, setFeaturedInstructors] = useState([]);
  const [carouselIndex, setCarouselIndex] = useState(0);

const VISIBLE = 5;

// Infinite carousel - arrows always visible if we have enough instructors
const canPrev = featuredInstructors.length > VISIBLE;
const canNext = featuredInstructors.length > VISIBLE;

// Handle right arrow: move first instructor to the end
const handleNext = () => {
  setFeaturedInstructors(prev => {
    if (prev.length <= VISIBLE) return prev;
    const [first, ...rest] = prev;
    return [...rest, first];
  });
};

// Handle left arrow: move last instructor to the beginning
const handlePrev = () => {
  setFeaturedInstructors(prev => {
    if (prev.length <= VISIBLE) return prev;
    const last = prev[prev.length - 1];
    const rest = prev.slice(0, -1);
    return [last, ...rest];
  });
};

useEffect(() => {
  api.get("/instructors/featured")
    .then((res) => setFeaturedInstructors(res.data))
    .catch(() => {});
}, []);

  return (
    <div className="homepage">
      <Navbar instructorsRef={instructorsRef} />

      {/* ── Hero ── */}
      <section className="hero">
        <div className="badge">Dance & Wellness Platform</div>
        <h1 className="hero-title">
          Our Web for <span className="highlight">Intelligent</span> <br />
          <span className="highlight">Management</span> <br />
          and Performance Tracking
        </h1>
        <p className="hero-description">
          A modern, scalable, and intelligent digital platform combining
          management, communication, and data-driven insights for dance and
          wellness environments.
        </p>
        <div className="hero-buttons">
          <Link to="/courses" className="secondary-btn">Browse Courses</Link>
          <Link to="/signup"  className="primary-btn">Get Started — It's Free</Link>
        </div>
      </section>

      {/* ── Features ── */}
      <section className="features-section scroll-reveal">
        <p className="section-eyebrow">WHAT WE OFFER</p>
        <h2 className="section-title">
          Built for Every <em className="highlight-italic">Dancer</em> &amp; Studio
        </h2>
        <div className="features-grid">
          {FEATURES.map(({ icon, title, desc }) => (
            <div key={title} className="feature-card">
              <div className="feature-icon">{icon}</div>
              <h3 className="feature-title">{title}</h3>
              <p className="feature-desc">{desc}</p>
            </div>
          ))}
        </div>
      </section>

  

    {/* ── Instructors ── */}
<section className="instructors-section scroll-reveal" ref={instructorsRef}>
  <h2 className="instructors-heading">Meet Your Instructors</h2>
  <p className="instructors-sub">Over 80 Instructors to Choose From</p>

  <div className="instructors-carousel-wrap">
    {/* Left arrow */}
    {featuredInstructors.length > VISIBLE && (
      <button
        className="carousel-arrow carousel-arrow--left"
        onClick={handlePrev}
        aria-label="Previous"
      >
        &#8249;
      </button>
    )}

    {/* Cards track */}
    <div className="instructors-track-outer">
      {featuredInstructors.length === 0 ? (
        <p className="instructors-empty">No featured instructors yet.</p>
      ) : (
        <div className="instructors-track">
          {featuredInstructors.map((inst) => {
            const photoUrl = inst.photo
              ? `${BASE_URL}/api/files/${inst.photo}`
              : null;

            return (
              <div key={inst.id} className="instructor-card">
                <div className="instructor-avatar">
                  {photoUrl ? (
                    <img
                      src={photoUrl}
                      alt={inst.username}
                      className="instructor-avatar-img"
                    />
                  ) : (
                    <span className="avatar-initials">
                      {(inst.username ?? "?").charAt(0).toUpperCase()}
                    </span>
                  )}
                </div>
                <p className="instructor-handle">@{inst.username}</p>
                {inst.specialization && (
                  <p className="instructor-spec">
                    {inst.specialization.replace(/_/g, " ")}
                  </p>
                )}
              </div>
            );
          })}
        </div>
      )}
    </div>

    {/* Right arrow */}
    {featuredInstructors.length > VISIBLE && (
      <button
        className="carousel-arrow carousel-arrow--right"
        onClick={handleNext}
        aria-label="Next"
      >
        &#8250;
      </button>
    )}
  </div>

  <p className="instructors-cta-text">
    Join thousands of instructors who've transformed their workflow.
  </p>
  <p className="instructors-cta-highlight">
    Set up in minutes, results from day one.
  </p>
</section>

          {/* ── Art of Movement ── */}
      <section className="movement-section scroll-reveal">
        <div className="movement-text">
          <p className="movement-eyebrow">DANCE &amp; WELLNESS</p>
          <h2 className="movement-heading">Experience the Art of Movement</h2>
          <p className="movement-desc">
            Our platform elegantly bridges the gap between artistic expression
            and physical well-being. We provide a sanctuary for continuous
            growth, offering intelligent tools that seamlessly integrate into
            your daily routine. Whether mastering a new form or finding inner
            peace, our holistic approach ensures balance and excellence in
            every step.
          </p>
          <Link to="/signup" className="movement-btn">Discover More</Link>
        </div>

        <div className="movement-images">
          {/* Back image — dance studio */}
          <div className="img-back">
            <img src={des2} alt="Dance studio" />
          </div>
          {/* Front image — meditation hands */}
          <div className="img-front">
            <img src={des1} alt="Meditation" />
          </div>
        </div>
      </section>

          {/* ── Mobile App ── */}
<section className="mobile-section scroll-reveal">
  <div className="mobile-text">
    <h2 className="mobile-heading">
      Join Us in Our Mobile<br />Application
    </h2>
    <p className="mobile-desc">
      Take your dance and wellness journey on the go. Our mobile app puts
      powerful class management, instructor connections, and progress
      tracking right in your pocket.
    </p>
    <ul className="mobile-features">
      {[
        "Real-time class notifications and scheduling",
        "Direct messaging with instructors",
        "Track your progress and achievements",
        "Personalized wellness recommendations",
      ].map((item) => (
        <li key={item}>
          <span className="mobile-check">✓</span>
          {item}
        </li>
      ))}
    </ul>
    <a
  href="https://play.google.com/store"
  target="_blank"
  rel="noreferrer"
  className="google-play-btn"
>
  <svg width="28" height="28" viewBox="0 0 24 24" fill="white">
    <path d="M3 20.5v-17c0-.83 1-.83 1.5-.5l15 8.5-15 8.5c-.5.33-1.5.33-1.5-.5z"/>
  </svg>
  <span>
    <span className="gp-top">GET IT ON</span>
    <span className="gp-bottom">Google Play</span>
  </span>
</a>
  </div>

  <div className="mobile-image-wrap">
    <img src={mobileApp} alt="Dance & Wellness mobile app" className="mobile-phone-img" />
  </div>
</section>
    </div>
  );
};

export default HomePage;