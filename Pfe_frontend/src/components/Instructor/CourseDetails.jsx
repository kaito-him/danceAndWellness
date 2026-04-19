import React, { useState, useRef } from "react";
import api from "./../services/api";
import "../../styles/Coursedetails.css";

const DIFFICULTY_LEVELS = ["BEGINNER", "INTERMEDIATE", "ADVANCED"];
const CATEGORIES = ["DANCE", "WELLNESS"];
 
const BASE = "http://localhost:8080";
 
// Resolve a stored URL to an absolute src the browser can load
const toSrc = (url) =>
  url ? (url.startsWith("/api") ? `${BASE}${url}` : url) : null;
 
// Upload a file to GridFS, return the served URL
async function uploadFile(file) {
  const fd = new FormData();
  fd.append("file", file);
  const res = await api.post("/files/upload", fd, {
    headers: { "Content-Type": "multipart/form-data" },
  });
  return res.data.url;
}
 
export default function CourseDetails({ course, onClose, onSaved }) {
  const [form, setForm] = useState({
    title:        course.title    ?? "",
    isFree:       course.isFree  ?? false,
    price:        course.price   ?? "",
    level:        course.level   ?? "BEGINNER",
    category:     course.category ?? "DANCE",
    thumbnailUrl: course.thumbnailUrl ?? "",
    lessons:      course.lessons  ? course.lessons.map((l) => ({
      ...l,
      newVideoFile:    null,   // new File chosen by user
      newVideoPreview: null,   // local blob URL
    })) : [],
    quizzes: course.quizzes ? [...course.quizzes] : [],
  });
 
  // Thumbnail replacement state
  const [newThumbFile,    setNewThumbFile]    = useState(null);
  const [newThumbPreview, setNewThumbPreview] = useState(null);
  const thumbInputRef  = useRef(null);
  const videoInputRefs = useRef({});
 
  const [loading, setLoading] = useState(false);
 
  // ── Thumbnail ─────────────────────────────────────────────────
  const applyThumb = (file) => {
    if (!file || !file.type.startsWith("image/")) return;
    setNewThumbFile(file);
    setNewThumbPreview(URL.createObjectURL(file));
  };
 
  // ── Video per lesson ──────────────────────────────────────────
  const applyVideo = (idx, file) => {
    if (!file || !file.type.startsWith("video/")) return;
    setForm((f) => {
      const lessons = [...f.lessons];
      lessons[idx] = {
        ...lessons[idx],
        newVideoFile:    file,
        newVideoPreview: URL.createObjectURL(file),
      };
      return { ...f, lessons };
    });
  };
 
  const handleField = (field, value) =>
    setForm((f) => ({ ...f, [field]: value }));
 
  const handleLessonField = (idx, field, value) =>
    setForm((f) => {
      const lessons = [...f.lessons];
      lessons[idx] = { ...lessons[idx], [field]: value };
      return { ...f, lessons };
    });
 
  // ── Save ──────────────────────────────────────────────────────
  const handleSave = async () => {
    if (!form.lessons.length) {
      alert("Course must have at least one lesson.");
      return;
    }
    setLoading(true);
    try {
      // 1️⃣ Upload new thumbnail if chosen
      let thumbnailUrl = form.thumbnailUrl;
      if (newThumbFile) thumbnailUrl = await uploadFile(newThumbFile);
 
      // 2️⃣ Upload new videos for lessons that have a new file
      const lessons = await Promise.all(
        form.lessons.map(async (l) => {
          let mediaUrl = l.mediaUrl;
          if (l.newVideoFile) mediaUrl = await uploadFile(l.newVideoFile);
          // Strip browser-only fields before sending
          const { newVideoFile, newVideoPreview, ...rest } = l;
          return { ...rest, mediaUrl, duration: parseInt(l.duration) || 0 };
        })
      );
 
      // 3️⃣ PUT the updated course
      const payload = {
        title:        form.title,
        isFree:       form.isFree,
        price:        form.isFree ? 0 : parseFloat(form.price) || 0,
        level:        form.level,
        category:     form.category,
        thumbnailUrl,
        lessons,
        quizzes:      form.quizzes,
      };
 
      const res = await api.put(`/courses/${course.courseId}`, payload);
      onSaved(res.data);
      onClose();
    } catch (err) {
      alert(err?.response?.data || "Failed to save changes.");
    } finally {
      setLoading(false);
    }
  };
 
  // Current thumbnail src — prefer the new local preview, else the stored URL
  const thumbSrc = newThumbPreview ?? toSrc(form.thumbnailUrl);
 
  return (
    <div className="cd-overlay" onClick={(e) => e.target === e.currentTarget && onClose()}>
      <div className="cd-modal">
 
        {/* ── Header ── */}
        <div className="cd-head">
          <div>
            <div className="cd-title">Edit Course</div>
            <div className="cd-subtitle">Update the details and save.</div>
          </div>
          <button className="cd-close" onClick={onClose}>
            <svg width="20" height="20" viewBox="0 0 24 24" fill="none"
              stroke="currentColor" strokeWidth="2" strokeLinecap="round">
              <line x1="18" y1="6" x2="6" y2="18"/>
              <line x1="6" y1="6" x2="18" y2="18"/>
            </svg>
          </button>
        </div>
 
        {/* ── Body ── */}
        <div className="cd-body">
 
          {/* Title */}
          <div className="cd-group">
            <label className="cd-label">Course Title</label>
            <input className="cd-input" value={form.title}
              onChange={(e) => handleField("title", e.target.value)} />
          </div>
 
          {/* Level + Category */}
          <div className="cd-row">
            <div className="cd-group">
              <label className="cd-label">Difficulty Level</label>
              <select className="cd-select" value={form.level}
                onChange={(e) => handleField("level", e.target.value)}>
                {DIFFICULTY_LEVELS.map((l) => <option key={l}>{l}</option>)}
              </select>
            </div>
            <div className="cd-group">
              <label className="cd-label">Category</label>
              <select className="cd-select" value={form.category}
                onChange={(e) => handleField("category", e.target.value)}>
                {CATEGORIES.map((c) => <option key={c}>{c}</option>)}
              </select>
            </div>
          </div>
 
          {/* ── Thumbnail ── */}
          <div className="cd-group">
            <label className="cd-label">Course Thumbnail</label>
            <div className="cd-media-wrap">
              {thumbSrc ? (
                <img src={thumbSrc} alt="thumbnail" className="cd-thumb-img" />
              ) : (
                <div className="cd-media-empty">
                  <svg width="28" height="28" viewBox="0 0 24 24" fill="none"
                    stroke="currentColor" strokeWidth="1.5" strokeLinecap="round">
                    <rect x="3" y="3" width="18" height="18" rx="2"/>
                    <circle cx="8.5" cy="8.5" r="1.5"/>
                    <polyline points="21 15 16 10 5 21"/>
                  </svg>
                  <span>No thumbnail</span>
                </div>
              )}
              <div className="cd-media-overlay">
                <button type="button" className="cd-media-btn"
                  onClick={() => thumbInputRef.current?.click()}>
                  {thumbSrc ? "Change Photo" : "Upload Photo"}
                </button>
              </div>
            </div>
            {newThumbFile && (
              <span className="cd-filename">{newThumbFile.name}</span>
            )}
            <input ref={thumbInputRef} type="file"
              accept="image/png,image/jpeg,image/webp"
              style={{ display: "none" }}
              onChange={(e) => applyThumb(e.target.files[0])} />
          </div>
 
          {/* Pricing */}
          <div className="cd-row">
            <div className="cd-group">
              <label className="cd-label">Pricing</label>
              <div className="cd-toggle-row">
                <label className="cd-toggle">
                  <input type="checkbox" checked={form.isFree}
                    onChange={(e) => handleField("isFree", e.target.checked)} />
                  <span className="cd-toggle-slider" />
                </label>
                <span className="cd-toggle-label">
                  {form.isFree ? "Free course" : "Paid course"}
                </span>
              </div>
            </div>
            {!form.isFree && (
              <div className="cd-group">
                <label className="cd-label">Price (USD)</label>
                <input className="cd-input" type="number" min="0" step="0.01"
                  value={form.price}
                  onChange={(e) => handleField("price", e.target.value)} />
              </div>
            )}
          </div>
 
          {/* ── Lessons ── */}
          <div className="cd-divider">
            <span className="cd-divider-label">Lessons</span>
            <div className="cd-divider-line" />
          </div>
 
          {form.lessons.map((lesson, idx) => {
            const videoSrc = lesson.newVideoPreview ?? toSrc(lesson.mediaUrl);
            return (
              <div className="cd-lesson" key={lesson.lessonId ?? idx}>
                <div className="cd-lesson-head">
                  <span className="cd-lesson-num">Lesson {idx + 1}</span>
                </div>
 
                {/* Title + Duration */}
                <div className="cd-row" style={{ marginBottom: 14 }}>
                  <div className="cd-group cd-full">
                    <label className="cd-label">Title</label>
                    <input className="cd-input" value={lesson.title ?? ""}
                      onChange={(e) => handleLessonField(idx, "title", e.target.value)} />
                  </div>
                  <div className="cd-group">
                    <label className="cd-label">Duration (min)</label>
                    <input className="cd-input" type="number" min="1"
                      value={lesson.duration ?? ""}
                      onChange={(e) => handleLessonField(idx, "duration", e.target.value)} />
                  </div>
                </div>
 
                {/* Video preview + replace */}
                <div className="cd-group">
                  <label className="cd-label">Lesson Video</label>
                  <div className="cd-video-wrap">
                    {videoSrc ? (
                      <video src={videoSrc} className="cd-video" controls />
                    ) : (
                      <div className="cd-media-empty cd-media-empty--video">
                        <svg width="28" height="28" viewBox="0 0 24 24" fill="none"
                          stroke="currentColor" strokeWidth="1.5" strokeLinecap="round">
                          <polygon points="23 7 16 12 23 17 23 7"/>
                          <rect x="1" y="5" width="15" height="14" rx="2"/>
                        </svg>
                        <span>No video</span>
                      </div>
                    )}
                    <div className="cd-media-overlay">
                      <button type="button" className="cd-media-btn"
                        onClick={() => videoInputRefs.current[idx]?.click()}>
                        {videoSrc ? "Change Video" : "Upload Video"}
                      </button>
                    </div>
                  </div>
                  {lesson.newVideoFile && (
                    <span className="cd-filename">{lesson.newVideoFile.name}</span>
                  )}
                  <input
                    type="file"
                    accept="video/mp4,video/quicktime,video/webm"
                    style={{ display: "none" }}
                    ref={(el) => { videoInputRefs.current[idx] = el; }}
                    onChange={(e) => applyVideo(idx, e.target.files[0])}
                  />
                </div>
 
              </div>
            );
          })}
        </div>
 
        {/* ── Footer ── */}
        <div className="cd-footer">
          <button className="cd-btn-cancel" onClick={onClose}>Cancel</button>
          <button className="cd-btn-save" onClick={handleSave} disabled={loading}>
            {loading
              ? <><span className="cd-spinner" /> Saving…</>
              : "Save Changes"}
          </button>
        </div>
 
      </div>
    </div>
  );
}