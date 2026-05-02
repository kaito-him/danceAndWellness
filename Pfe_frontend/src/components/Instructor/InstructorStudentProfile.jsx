import React, { useEffect, useState } from "react";
import { FiArrowLeft, FiUser, FiMail, FiMessageSquare, FiBookOpen } from "react-icons/fi";
import api from "../services/api";
import ChatModal from "../Student/ChatModal";
import "../../styles/AdminStudentDetail.css";
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

        // Show only courses this student is enrolled in that belong to current instructor
        const coursesRes = await api.get(`/students/${studentRes.data.id}/courses`);
        const allCourses = Array.isArray(coursesRes.data) ? coursesRes.data : [];
        const mine = allCourses.filter(
          (c) => c?.instructor?.userId && c.instructor.userId === instructor?.userId
        );
        setCourses(mine);
      } catch {
        setStudent(null);
        setCourses([]);
      } finally {
        setLoading(false);
      }
    };
    if (studentUserId && instructor?.userId) load();
  }, [studentUserId, instructor]);

  if (loading) return <div className="asd-wrap"><div className="asd-card">Loading student profile...</div></div>;
  if (!student || !user) return <div className="asd-wrap"><div className="asd-card">Student profile not found.</div></div>;

  const photoUrl = student.photo ? `http://localhost:8080/api/files/${student.photo}` : null;

  return (
    <div className="asd-wrap">
      <div className="asd-header">
        <button className="asd-back" onClick={onBack}><FiArrowLeft size={14} /> {backLabel}</button>
      </div>
      <div className="asd-card">
        <div className="asd-profile">
          {photoUrl ? (
            <img src={photoUrl} alt={user.username} className="asd-avatar" />
          ) : (
            <div className="asd-avatar asd-avatar-fallback">{user.username?.charAt(0)?.toUpperCase() || "S"}</div>
          )}
          <div className="asd-user-main">
            <h2>{user.username}</h2>
            <p>Student Profile</p>
          </div>
        </div>
        <div className="asd-info-grid">
          <div className="asd-info-card"><FiUser size={15} /><span>Username: {user.username}</span></div>
          <div className="asd-info-card"><FiMail size={15} /><span>Email: {user.email}</span></div>
          <button
            className="asd-info-card"
            style={{ cursor: "pointer", justifyContent: "flex-start" }}
            onClick={() => setChatOpen(true)}
          >
            <FiMessageSquare size={15} />
            <span>Message {user.username}</span>
          </button>
        </div>

        <div className="asd-courses-section" style={{ marginTop: 20 }}>
          <div className="asd-section-title">
            <FiBookOpen size={16} />
            <h3>Enrolled In Your Courses</h3>
          </div>
          {courses.length === 0 ? (
            <p style={{ color: "#777", marginTop: 8 }}>This student is not enrolled in any of your courses yet.</p>
          ) : (
            <div style={{ display: "grid", gap: 10, marginTop: 10 }}>
              {courses.map((c) => (
                <button
                  key={c.courseId}
                  onClick={() => onCourseSelect?.(c.courseId)}
                  style={{
                    textAlign: "left",
                    border: "1px solid #eadfc8",
                    borderRadius: 10,
                    padding: "10px 12px",
                    background: "#fffdf8",
                    cursor: "pointer"
                  }}
                >
                  <strong>{c.title}</strong>
                  <div style={{ fontSize: 12, color: "#777", marginTop: 4 }}>
                    {c.level} · {c.isFree ? "Free" : `$${c.price}`}
                  </div>
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
            photo: student.photo || "",
          }}
          onClose={() => setChatOpen(false)}
        />
      )}
    </div>
  );
}
