import React, { useState, useEffect } from "react";
import api from "./../services/api";
import "../../styles/InstructorFeed.css";

const BASE_URL = "http://localhost:8080";

export default function InstructorFeed() {
  const [courses, setCourses]   = useState([]);
  const [loading, setLoading]   = useState(true);
  const [error,   setError]     = useState(null);

  useEffect(() => {
    const load = async () => {
      try {
        const res = await api.get("/courses/published");
        setCourses(res.data);
      } catch (_) {
        setError("Failed to load published courses.");
      } finally {
        setLoading(false);
      }
    };
    load();
  }, []);

  /* ── helpers ─────────────────────────────────────────────────── */
  const thumb = (url) =>
    url ? `${BASE_URL}${url}` : null;

  const instructorName = (course) => {
    const ins = course.instructor;
    if (!ins) return "Unknown Instructor";
    if (ins.firstName && ins.lastName) return `${ins.firstName} ${ins.lastName}`;
    if (ins.user?.username) return ins.user.username;
    return "Unknown Instructor";
  };

  const priceLabel = (course) =>
    course.isFree ? "Free" : course.price ? `$${Number(course.price).toFixed(2)}` : "Paid";

  /* ── states ──────────────────────────────────────────────────── */
  if (loading) {
    return (
      <div className="if-center">
        <div className="if-spinner" />
        <p className="if-hint">Loading courses…</p>
      </div>
    );
  }

  if (error) {
    return (
      <div className="if-center">
        <p className="if-error">{error}</p>
      </div>
    );
  }

  /* ── render ──────────────────────────────────────────────────── */
  return (
    <div className="if-root">
      <div className="if-header">
        <h1 className="if-heading">Feed</h1>
        <p className="if-sub">All published courses available to students</p>
        <span className="if-count">{courses.length} course{courses.length !== 1 ? "s" : ""}</span>
      </div>

      {courses.length === 0 ? (
        <div className="if-empty">
          <div className="if-empty-icon">📭</div>
          <p className="if-empty-title">No published courses yet</p>
          <p className="if-empty-hint">Approved courses will appear here.</p>
        </div>
      ) : (
        <div className="if-grid">
          {courses.map((course) => (
            <article key={course.courseId} className="if-card">

              {/* thumbnail */}
              <div className="if-thumb">
                {thumb(course.thumbnailUrl) ? (
                  <img
                    src={thumb(course.thumbnailUrl)}
                    alt={course.title}
                    className="if-thumb-img"
                  />
                ) : (
                  <div className="if-thumb-placeholder">
                    <span className="if-thumb-icon">🎓</span>
                  </div>
                )}

                {/* price badge */}
                <span className={`if-badge ${course.isFree ? "free" : "paid"}`}>
                  {priceLabel(course)}
                </span>
              </div>

              {/* body */}
              <div className="if-body">
                {course.level && (
                  <span className="if-level">{course.level}</span>
                )}
                <h2 className="if-title" title={course.title}>
                  {course.title}
                </h2>
                <p className="if-instructor">
                  <span className="if-instructor-dot" />
                  {instructorName(course)}
                </p>
              </div>
            </article>
          ))}
        </div>
      )}
    </div>
  );
}