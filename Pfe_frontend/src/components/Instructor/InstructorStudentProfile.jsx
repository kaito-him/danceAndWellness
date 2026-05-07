import React, { useEffect, useState } from "react";
import { FiArrowLeft, FiUser, FiMail, FiMessageSquare, FiBookOpen } from "react-icons/fi";
import api from "../services/api";
import ChatModal from "../Student/ChatModal";
import "../../styles/InstructorStudentProfile.css";
import "../../styles/Messages.css";

export default function InstructorStudentProfile({ studentUserId, instructor, onBack, onCourseSelect, backLabel = "Back to Course" }) {
  const [student, setStudent] = useState(null);
  const [user, setUser] = useState(null);
  const [courses, setCourses] = useState([]);
  const [loading, setLoading] = useState(true);
  const [chatOpen, setChatOpen] = useState(false);

  useEffect(() => {
    const load = async () => {
      setLoading(true);
      try {
        const [studentRes, userRes] = await Promise.all([
          api.get(`/students/by-user/${studentUserId}`),
          api.get(`/users/${studentUserId}`),
        ]);
        setStudent(studentRes.data);
        setUser(userRes.data);

        // Fetch all courses this student is enrolled in, then filter by this instructor
        // Enrollments store userId as studentId, so use userId not student._id
        const coursesRes = await api.get(`/students/${studentRes.data.userId}/courses`);
        const allCourses = Array.isArray(coursesRes.data) ? coursesRes.data : [];
        const mine = allCourses.filter((c) => {
          if (!c?.instructor) return false;
          const courseInstructorUserId = c.instructor.userId ?? c.instructor.id;
          return courseInstructorUserId === instructor?.userId;
        });
        setCourses(mine);
      } catch (err) {
        console.error("Failed to load student profile:", err);
        setStudent(null);
        setCourses([]);
      } finally {
        setLoading(false);
      }
    };
    if (studentUserId && instructor?.userId) load();
  }, [studentUserId, instructor]);

  if (loading) {
    return (
      <div className="isp-wrap">
        <div className="isp-card" style={{ color: "#888", textAlign: "center", padding: "48px" }}>
          Loading student profile...
        </div>
      </div>
    );
  }

  if (!student || !user) {
    return (
      <div className="isp-wrap">
        <div className="isp-card" style={{ color: "#888", textAlign: "center", padding: "48px" }}>
          Student profile not found.
        </div>
      </div>
    );
  }

  // Prefer student.photo, fall back to user.photo (both are GridFS file IDs)
  const photoFileId = student.photo || user.photo || null;
  const photoUrl = photoFileId ? `http://localhost:8080/api/files/${photoFileId}` : null;

  return (
    <div className="isp-wrap">
      <button className="isp-back" onClick={onBack}>
        <FiArrowLeft size={14} /> {backLabel}
      </button>

      <div className="isp-card">
        {/* ── Profile header ── */}
        <div className="isp-profile">
          {photoUrl ? (
            <img
              src={photoUrl}
              alt={user.username}
              className="isp-avatar"
              onError={(e) => {
                // If image fails to load, swap to fallback
                e.currentTarget.style.display = "none";
                e.currentTarget.nextSibling.style.display = "flex";
              }}
            />
          ) : null}
          <div
            className="isp-avatar-fallback"
            style={{ display: photoUrl ? "none" : "flex" }}
          >
            {user.username?.charAt(0)?.toUpperCase() || "S"}
          </div>
          <div className="isp-user-main">
            <h2>{user.username}</h2>
            <p>Student Profile</p>
          </div>
        </div>

        {/* ── Info grid ── */}
        <div className="isp-info-grid">
          <div className="isp-info-card">
            <FiUser size={15} />
            <span>{user.username}</span>
          </div>
          <div className="isp-info-card">
            <FiMail size={15} />
            <span>{user.email}</span>
          </div>
          <button className="isp-info-card" onClick={() => setChatOpen(true)}>
            <FiMessageSquare size={15} />
            <span>Message {user.username}</span>
          </button>
        </div>

        {/* ── Enrolled courses ── */}
        <div className="isp-courses-section">
          <div className="isp-section-title">
            <FiBookOpen size={16} />
            <h3>Enrolled In Your Courses</h3>
          </div>

          {courses.length === 0 ? (
            <p className="isp-empty">
              This student is not enrolled in any of your courses yet.
            </p>
          ) : (
            <div className="isp-courses-list">
              {courses.map((c) => (
                <button
                  key={c.courseId}
                  className="isp-course-btn"
                  onClick={() => onCourseSelect?.(c.courseId)}
                >
                  <strong>{c.title}</strong>
                  <span className="isp-course-meta">
                    {c.level} · {c.isFree ? "Free" : `$${c.price}`}
                  </span>
                </button>
              ))}
            </div>
          )}
        </div>
      </div>

      {chatOpen && (
        <ChatModal
          instructor={{
            userId: studentUserId,
            username: user.username,
            specialization: "Student",
            photo: photoFileId || "",
          }}
          onClose={() => setChatOpen(false)}
        />
      )}
    </div>
  );
}
