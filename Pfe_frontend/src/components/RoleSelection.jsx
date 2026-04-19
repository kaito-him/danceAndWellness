import { Link } from "react-router-dom";
import Navbar from "./Navbar";
import "../styles/RoleSelection.css";

// ✅ Import images directly so Vite resolves them correctly
import bgImage from "../assets/dance-wellness-bg.svg";
import studentImg from "../assets/DanceStudent.jpg";
import instructorImg from "../assets/DanceInstructor.png";

const RoleSelection = () => {
  return (
    <>
      <Navbar />
      <div className="role-page">
        {/* Background layers */}
        <div className="role-bg">
          <img src={bgImage} alt="" className="role-bg-img" />
          <div className="role-bg-overlay" />
        </div>

        {/* Content */}
        <div className="role-container">
          <div className="role-header">
            <span className="role-eyebrow">Welcome</span>
            <h1 className="role-title">Join Our Platform</h1>
            <p className="role-subtitle">
              Choose how you want to be part of our community
            </p>
          </div>

          <div className="role-cards">
            {/* Student Card */}
            <div className="role-card" style={{ "--card-delay": "0.1s" }}>
              <div className="role-card-img-wrap">
                <img src={studentImg} alt="Dance Student" className="role-card-img" />
                <div className="role-card-img-overlay" />
              </div>
              <div className="role-card-body">
                <h2 className="role-card-title">Student</h2>
                <p className="role-card-desc">
                  Discover courses, learn from expert instructors, and grow your
                  skills at your own pace.
                </p>
                <Link to="/signup/student" className="role-btn role-btn--student">
                  <span>Join as Student</span>
                  <svg width="16" height="16" viewBox="0 0 16 16" fill="none">
                    <path d="M3 8h10M9 4l4 4-4 4" stroke="currentColor" strokeWidth="1.8" strokeLinecap="round" strokeLinejoin="round"/>
                  </svg>
                </Link>
              </div>
            </div>

            {/* Instructor Card */}
            <div className="role-card" style={{ "--card-delay": "0.25s" }}>
              <div className="role-card-img-wrap">
                <img src={instructorImg} alt="Dance Instructor" className="role-card-img" />
                <div className="role-card-img-overlay" />
              </div>
              <div className="role-card-body">
                <h2 className="role-card-title">Instructor</h2>
                <p className="role-card-desc">
                  Share your knowledge, inspire students worldwide, and build
                  your teaching brand.
                </p>
                <Link to="/signup/instructor" className="role-btn role-btn--instructor">
                  <span>Apply as Instructor</span>
                  <svg width="16" height="16" viewBox="0 0 16 16" fill="none">
                    <path d="M3 8h10M9 4l4 4-4 4" stroke="currentColor" strokeWidth="1.8" strokeLinecap="round" strokeLinejoin="round"/>
                  </svg>
                </Link>
              </div>
            </div>
          </div>
        </div>
      </div>
    </>
  );
};

export default RoleSelection;