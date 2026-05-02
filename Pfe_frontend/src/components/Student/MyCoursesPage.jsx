// src/components/Student/MyCoursesPage.jsx
import React, { useEffect, useState } from "react";
import api from "../services/api";
import CourseCard from "./CourseCard";
import { FiBookOpen } from "react-icons/fi";

/* Skeleton — same as HomeContent */
const CourseCardSkeleton = ({ index }) => (
  <article className="sd-card-skeleton" style={{ animationDelay: `${index * 50}ms` }}>
    <div className="sd-skeleton-thumb"></div>
    <div className="sd-skeleton-body">
      <div className="sd-skeleton-line sd-cat-line"></div>
      <div className="sd-skeleton-line sd-title-line-1"></div>
      <div className="sd-skeleton-line sd-title-line-2"></div>
      <div className="sd-skeleton-instructor">
        <div className="sd-skeleton-avatar"></div>
        <div className="sd-skeleton-line sd-name-line"></div>
      </div>
      <div className="sd-skeleton-stats">
        <div className="sd-skeleton-line sd-stat-line"></div>
        <div className="sd-skeleton-line sd-stat-line"></div>
      </div>
      <div className="sd-skeleton-line sd-cta-line"></div>
    </div>
  </article>
);

export default function MyCoursesPage({ onCourseSelect }) {
  const [courses, setCourses] = useState([]);
  const [loading, setLoading] = useState(true);
  const studentId = localStorage.getItem("userId");

  useEffect(() => {
    if (!studentId) return;
    setLoading(true);

    const fetchCourses = async () => {
      try {
        /* Fetch free courses + categories in parallel */
        const [coursesRes, catsRes] = await Promise.all([
          api.get(`/students/${studentId}/courses/free`),
          api.get("/categories"),
        ]);

        const catMap = {};
        catsRes.data.forEach((c) => (catMap[c.id] = c.name));

        const enriched = coursesRes.data.map((course) => ({
          ...course,
          category: catMap[course.categoryId] || course.categoryId || "Uncategorized",
        }));

        setCourses(enriched);
      } catch (err) {
        console.error("Failed to fetch free courses:", err);
      } finally {
        setTimeout(() => setLoading(false), 600);
      }
    };

    fetchCourses();
  }, [studentId]);

  return (
    <div className="sd-home">
      <div className="sd-welcome-block">
        <p className="sd-welcome-label">My Library</p>
        <h1 className="sd-welcome-title">
          My <span>Courses</span>
        </h1>
        <p className="sd-welcome-sub">
          All the free courses you've enrolled in — pick up right where you left off.
        </p>
      </div>

      {loading ? (
        <div className="sd-course-grid">
          {Array.from({ length: 6 }).map((_, idx) => (
            <CourseCardSkeleton key={idx} index={idx} />
          ))}
        </div>
      ) : courses.length === 0 ? (
        <div className="sd-empty">
          <div className="sd-empty-icon">
            <FiBookOpen size={52} strokeWidth={1.2} />
          </div>
          <h2 className="sd-empty-title">No courses yet</h2>
          <p className="sd-empty-sub">
            You haven't enrolled in any free courses. Browse the catalog and start learning!
          </p>
        </div>
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
    </div>
  );
}
