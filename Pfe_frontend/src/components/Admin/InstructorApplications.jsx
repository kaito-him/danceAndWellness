import React, { useState, useEffect } from "react";
import { useSearchParams } from "react-router-dom";
import InstructorApplicationCard from "./InstructorApplicationCard";
import api from "./../services/api";
import "../../styles/InstructorApplications.css";

const EXPERIENCE_OPTIONS = [
  "Less than 1 year",
  "1–3 years",
  "3–5 years",
  "5–10 years",
  "10+ years",
];

export default function InstructorApplications() {
  const [applications, setApplications] = useState([]);
  const [loading,      setLoading]      = useState(true);
  const [toast,        setToast]        = useState(null);

  const [searchParams, setSearchParams] = useSearchParams();

  const [searchUsername, setSearchUsername] = useState(searchParams.get("username") || "");
  const [searchSpecialization, setSearchSpecialization] = useState(searchParams.get("specialization") || "");
  const [searchExperience, setSearchExperience] = useState(searchParams.get("experience") || "");
  const [categories, setCategories] = useState([]);

  const fetchApplications = async (query = {}) => {
    setLoading(true);
    try {
      const params = new URLSearchParams();
      if (query.username) params.append("username", query.username);
      if (query.specialization) params.append("specialization", query.specialization);
      if (query.experience) params.append("experience", query.experience);

      const hasQuery = query.username || query.specialization || query.experience;
      const url = hasQuery
          ? `/admin/applications/search?${params.toString()}`
          : "/admin/applications";

      const res = await api.get(url);
      setApplications(res.data);
    } catch {
      showToast("error", "Failed to load applications.");
    } finally {
      setLoading(false);
    }
  };

  useEffect(() => {
    fetchApplications({
      username: searchParams.get("username") || "",
      specialization: searchParams.get("specialization") || "",
      experience: searchParams.get("experience") || ""
    });
    api.get("/categories")
      .then((res) => setCategories(res.data))
      .catch(() => setCategories([]));
  }, []);

  const handleSearch = () => {
    const newParams = new URLSearchParams(window.location.search);
    if (searchUsername) newParams.set("username", searchUsername); else newParams.delete("username");
    if (searchSpecialization) newParams.set("specialization", searchSpecialization); else newParams.delete("specialization");
    if (searchExperience) newParams.set("experience", searchExperience); else newParams.delete("experience");
    setSearchParams(newParams, { replace: true });

    fetchApplications({
        username: searchUsername,
        specialization: searchSpecialization,
        experience: searchExperience
    });
  };

  const handleClear = () => {
    setSearchUsername("");
    setSearchSpecialization("");
    setSearchExperience("");

    const newParams = new URLSearchParams(window.location.search);
    newParams.delete("username");
    newParams.delete("specialization");
    newParams.delete("experience");
    setSearchParams(newParams, { replace: true });

    fetchApplications({});
  };

  const showToast = (type, msg) => {
    setToast({ type, msg });
    setTimeout(() => setToast(null), 3500);
  };

  const handleApprove = async (userId) => {
    try {
      await api.patch(`/admin/applications/${userId}/approve`);
      setApplications((prev) => prev.filter((a) => a.userId !== userId));
      showToast("success", "Instructor approved and activated!");
    } catch {
      showToast("error", "Failed to approve application.");
    }
  };

  const handleDecline = async (userId) => {
    try {
      await api.patch(`/admin/applications/${userId}/decline`);
      setApplications((prev) => prev.filter((a) => a.userId !== userId));
      showToast("success", "Application declined.");
    } catch {
      showToast("error", "Failed to decline application.");
    }
  };

  return (
    <div className="ia-container">

      {/* ── Page header ── */}
      <div className="ia-header">
        <div>
          <h1 className="ia-title">Instructor Applications</h1>
          <p className="ia-subtitle">Review and manage pending instructor applications</p>
        </div>
        <div className="ia-badge">
          <span className="ia-count">{applications.length}</span>
          <span className="ia-count-label">Pending</span>
        </div>
      </div>

      {/* ── Search Bar ── */}
      <div className="ia-search-bar">
        <input
          type="text"
          placeholder="Search by username..."
          className="ia-search-input"
          value={searchUsername}
          onChange={(e) => setSearchUsername(e.target.value)}
        />
        <select 
          className="ia-search-select" 
          value={searchSpecialization} 
          onChange={(e) => setSearchSpecialization(e.target.value)}
        >
          <option value="">All Categories</option>
          {categories.map((cat) => (
             <option key={cat.id || cat.name} value={cat.name}>{cat.name}</option>
          ))}
          <option value="Other">Other</option>
        </select>
        <select 
          className="ia-search-select" 
          value={searchExperience} 
          onChange={(e) => setSearchExperience(e.target.value)}
        >
          <option value="">All Experience</option>
          {EXPERIENCE_OPTIONS.map((exp) => (
            <option key={exp} value={exp}>{exp}</option>
          ))}
        </select>
        <button className="ia-btn-search" onClick={handleSearch}>Search</button>
        <button className="ia-btn-clear" onClick={handleClear}>Clear</button>
      </div>

      {/* ── Body ── */}
      {loading ? (
        <div className="ia-loading">
          <div className="ia-spinner" />
          <p>Loading applications…</p>
        </div>
      ) : applications.length === 0 ? (
        <div className="ia-empty">
          <div className="ia-empty-icon">✅</div>
          <h2>All caught up!</h2>
          <p>No pending instructor applications at the moment.</p>
        </div>
      ) : (
        <div className="ia-grid">
          {applications.map((app) => (
            <InstructorApplicationCard
              key={app.userId}
              application={app}
              onApprove={handleApprove}
              onDecline={handleDecline}
            />
          ))}
        </div>
      )}

      {/* ── Toast ── */}
      {toast && (
        <div className={`ia-toast ${toast.type}`}>
          {toast.type === "success" ? "✓" : "✕"} {toast.msg}
        </div>
      )}

    </div>
  );
}