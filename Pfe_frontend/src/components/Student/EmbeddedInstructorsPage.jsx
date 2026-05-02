import React, { useState, useEffect, useMemo } from "react";
import { FiSearch, FiX, FiUsers, FiClock, FiBookOpen, FiChevronRight } from "react-icons/fi";
import api from "../../components/services/api";
import "../../styles/StudentInstructors.css";

const InstructorCard = ({ instructor, onClick }) => {
  const photoUrl = instructor.photo
    ? `http://localhost:8080/api/files/${instructor.photo}`
    : null;

  return (
    <div className="si-card" onClick={() => onClick(instructor.id)}>
      <div className="si-card-photo-wrap">
        {photoUrl ? (
          <img src={photoUrl} alt={instructor.username} className="si-card-photo" />
        ) : (
          <div className="si-card-photo-fallback">
            {(instructor.username ?? "?").charAt(0).toUpperCase()}
          </div>
        )}
      </div>
      <div className="si-card-body">
        <h3 className="si-card-name">{instructor.username}</h3>
        <p className="si-card-spec">{instructor.specialization ?? "Instructor"}</p>
        
        <div className="si-card-meta">
          <div className="si-card-meta-item">
            <FiBookOpen size={12} />
            <span>{instructor.totalCourses || 0} Courses</span>
          </div>
          <div className="si-card-meta-item">
            <FiClock size={12} />
            <span>{instructor.yearsOfExperience || 0}y Exp.</span>
          </div>
        </div>
        
        <button className="si-card-cta">
          View Profile <FiChevronRight size={14} />
        </button>
      </div>
    </div>
  );
};

const InstructorCardSkeleton = () => (
  <div className="si-card-skeleton">
    <div className="si-skeleton-circle"></div>
    <div className="si-skeleton-line si-line-1"></div>
    <div className="si-skeleton-line si-line-2"></div>
    <div className="si-skeleton-line si-line-3"></div>
    <div className="si-skeleton-line si-line-4"></div>
  </div>
);

export default function EmbeddedInstructorsPage({ onInstructorSelect }) {
  const [instructors, setInstructors] = useState([]);
  const [loading, setLoading] = useState(true);
  const [search, setSearch] = useState("");

  useEffect(() => {
    const fetchInstructors = async () => {
      try {
        const res = await api.get("/instructors");
        // Only show ACTIVE instructors
        const active = res.data.filter(i => i.accountStatus === "ACTIVE");
        setInstructors(active);
      } catch (err) {
        console.error("Failed to fetch instructors:", err);
      } finally {
        // Minimum 800ms loading time to show skeleton
        setTimeout(() => setLoading(false), 800);
      }
    };
    fetchInstructors();
  }, []);

  const filtered = useMemo(() => {
    const q = search.toLowerCase().trim();
    if (!q) return instructors;
    return instructors.filter(i => 
      i.username?.toLowerCase().includes(q) || 
      i.specialization?.toLowerCase().includes(q)
    );
  }, [instructors, search]);

  return (
    <div className="si-page">
      <div className="sd-welcome-block">
        <p className="sd-welcome-label">Meet our team</p>
        <h1 className="sd-welcome-title">Expert <span>Instructors</span></h1>
        <p className="sd-welcome-sub">Learn from industry professionals and passionate artists.</p>
      </div>

      <div className="sd-search-wrap">
        <span className="sd-search-icon"><FiSearch size={17} /></span>
        <input 
          type="text" 
          className="sd-search-input"
          placeholder="Search by name or specialization (e.g. Yoga)..."
          value={search}
          onChange={e => setSearch(e.target.value)} 
        />
        {search && (
          <button className="sd-search-clear" onClick={() => setSearch("")}>
            <FiX size={15} />
          </button>
        )}
      </div>

      {loading ? (
        <div className="si-grid">
          {Array.from({ length: 6 }).map((_, idx) => (
            <InstructorCardSkeleton key={idx} />
          ))}
        </div>
      ) : filtered.length === 0 ? (
        <div className="sd-empty">
          <div className="sd-empty-icon"><FiUsers size={44} /></div>
          <h2 className="sd-empty-title">No instructors found</h2>
          <p className="sd-empty-sub">Try searching for something else.</p>
        </div>
      ) : (
        <div className="si-grid">
          {filtered.map(inst => (
            <InstructorCard key={inst.id} instructor={inst} onClick={onInstructorSelect} />
          ))}
        </div>
      )}
    </div>
  );
}
