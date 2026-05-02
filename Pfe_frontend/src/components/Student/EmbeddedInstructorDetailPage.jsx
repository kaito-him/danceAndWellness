import React, { useState, useEffect } from "react";
import { FiArrowLeft, FiMail, FiGlobe, FiLinkedin, FiClock, FiBookOpen, FiMessageSquare } from "react-icons/fi";
import ChatModal from "./ChatModal";
import api from "../../components/services/api";
import CourseCard from "./CourseCard";
import "../../styles/StudentInstructors.css";

export default function EmbeddedInstructorDetailPage({ instructorId, onBack, onCourseSelect }) {
  const [instructor, setInstructor] = useState(null);
  const [courses, setCourses] = useState([]);
  const [loading, setLoading] = useState(true);
  const [chatOpen, setChatOpen] = useState(false);
  useEffect(() => {
    const fetchData = async () => {
      setLoading(true);
      try {
        // We fetch the full list and find the one, 
        // or if there's a specific detail endpoint we'd use that.
        // Assuming /instructors returns bio etc or we fetch from a detail endpoint.
        const instRes = await api.get("/instructors");
        const found = instRes.data.find(i => i.id === instructorId);
        setInstructor(found);

        if (found) {
          const coursesRes = await api.get(`/instructors/${instructorId}/courses`);
          // Only show PUBLISHED courses to students
          const published = coursesRes.data.filter(c => c.status === "PUBLISHED").map(c => ({
            ...c,
            instructor: found
          }));
          setCourses(published);
        }
      } catch (err) {
        console.error("Failed to fetch instructor detail:", err);
      } finally {
        setLoading(false);
      }
    };
    fetchData();
  }, [instructorId]);

  if (loading) return (
    <div className="sd-courses-loading" style={{ minHeight: '60vh' }}>
      <div className="sd-spinner" /><p>Loading profile...</p>
    </div>
  );

  if (!instructor) return (
    <div className="sd-empty" style={{ minHeight: '60vh' }}>
      <p>Instructor not found.</p>
      <button className="si-back-btn" onClick={onBack}><FiArrowLeft /> Back to Instructors</button>
    </div>
  );

  const photoUrl = instructor.photo
    ? `http://localhost:8080/api/files/${instructor.photo}`
    : null;

  return (
    <div className="sid-page">
      <button className="sid-back-pill" onClick={onBack}>
        <FiArrowLeft size={14} /> Back to Instructors
      </button>

      <div className="sid-header">
        <div className="sid-hero-left">
          <div className="sid-avatar-wrap">
            {photoUrl ? (
              <img src={photoUrl} alt={instructor.username} className="sid-avatar-img" />
            ) : (
              <div className="sid-avatar-fallback">
                {(instructor.username ?? "?").charAt(0).toUpperCase()}
              </div>
            )}
          </div>
          <div className="sid-hero-info">
            <h1 className="sid-name">{instructor.username}</h1>
            <p className="sid-specialty">{instructor.specialization || "Instructor"}</p>
            <div className="sid-stats-row">
              <span className="sid-stat-chip"><FiClock size={12} /> {instructor.yearsOfExperience || 0} years exp.</span>
              <span className="sid-stat-chip"><FiBookOpen size={12} /> {courses.length} Courses</span>
            </div>
          </div>
        </div>

        <div className="sid-hero-right">
          {instructor.email && (
            <div className="sid-contact-item">
              <FiMail size={14} /> <span>{instructor.email}</span>
            </div>
          )}
          {instructor.website && (
            <a href={instructor.website} target="_blank" rel="noopener noreferrer" className="sid-social-link">
              <FiGlobe size={14} /> <span>Website</span>
            </a>
          )}
          {instructor.linkedIn && (
            <a href={instructor.linkedIn} target="_blank" rel="noopener noreferrer" className="sid-social-link">
              <FiLinkedin size={14} /> <span>LinkedIn</span>
            </a>
          )}
          <button className="sid-message-btn" onClick={() => setChatOpen(true)}>
            <FiMessageSquare size={15} />
            Message {instructor.username}
          </button>
        </div>
      </div>

      <div className="sid-content-grid">
        <div className="sid-main-col">
          {instructor.bio && (
            <section className="sid-section">
              <h2 className="sid-section-title">About the Instructor</h2>
              <p className="sid-bio-text">{instructor.bio}</p>
            </section>
          )}

          <section className="sid-section">
            <h2 className="sid-section-title">Courses Portfolio</h2>
            {courses.length === 0 ? (
              <p className="sid-empty-text">No courses available at the moment.</p>
            ) : (
              <div className="sd-course-grid">
                {courses.map((course, idx) => (
                  <CourseCard
                    key={course.courseId}
                    course={course}
                    index={idx}
                    onSelect={onCourseSelect}
                  />
                ))}
              </div>
            )}
          </section>
        </div>
      </div>
      {chatOpen && (
        <ChatModal instructor={instructor} onClose={() => setChatOpen(false)} />
      )}
    </div>
  );
}
