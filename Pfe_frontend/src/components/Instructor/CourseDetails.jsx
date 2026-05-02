import React, { useEffect, useMemo, useRef, useState } from "react";
import { FiEdit3 } from "react-icons/fi";
import api from "./../services/api";
import "../../styles/Coursedetails.css";
import "../../styles/Addcourseform.css";

const DIFFICULTY_LEVELS = ["BEGINNER", "INTERMEDIATE", "ADVANCED"];
const PRICE_TIERS = ["10", "20", "30"];

const emptyOption = () => ({
  optionId: crypto.randomUUID(),
  text: "",
  isCorrect: false,
});

const emptyQuestion = () => ({
  questionId: crypto.randomUUID(),
  text: "",
  options: [{ ...emptyOption(), isCorrect: true }, emptyOption()],
});

const emptyQuiz = () => ({
  quizId: crypto.randomUUID(),
  title: "",
  questions: [emptyQuestion()],
});
 
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
 
export default function CourseDetails({ course, onClose, onSaved, instructor }) {
  const isDraft = course?.status === "DRAFT";

  const [categories, setCategories] = useState([]);
  const [catsLoading, setCatsLoading] = useState(true);
  const [stripeStatus, setStripeStatus] = useState(null);
  const [stripeLoading, setStripeLoading] = useState(false);
  const [isEditing, setIsEditing] = useState(isDraft);
  const [activeTab, setActiveTab] = useState("lessons"); // "lessons" | "quizzes"

  const [form, setForm] = useState({
    title:        course.title    ?? "",
    description:  course.description ?? "",
    isFree:       course.isFree  ?? false,
    priceType:    PRICE_TIERS.includes(String(course.price ?? "")) ? "predefined" : "custom",
    price:        String(course.price ?? "10"),
    level:        course.level   ?? "BEGINNER",
    categoryId:   course.categoryId ?? "",
    thumbnailUrl: course.thumbnailUrl ?? "",
    lessons:      course.lessons  ? course.lessons.map((l) => ({
      ...l,
      newVideoFile:    null,   // new File chosen by user
      newVideoPreview: null,   // local blob URL
    })) : [],
    quizzes: course.quizzes ? [...course.quizzes] : [],
  });
 
  useEffect(() => {
    api.get("/categories")
      .then((res) => {
        const cats = Array.isArray(res.data) ? res.data : [];
        setCategories(cats);
        const specialization = instructor?.specialization;
        const matchedCat = specialization
          ? cats.find((c) => c.name?.toLowerCase() === specialization.toLowerCase())
          : null;

        setForm((f) => {
          if (matchedCat) return { ...f, categoryId: matchedCat.id };
          if (f.categoryId) return f;
          return { ...f, categoryId: cats[0]?.id ?? "" };
        });
      })
      .catch(() => setCategories([]))
      .finally(() => setCatsLoading(false));
  }, [instructor]);

  useEffect(() => {
    if (!instructor?.id) return;
    setStripeLoading(true);
    api.get(`/instructor/payments/${instructor.id}/status`)
      .then((res) => setStripeStatus(res.data))
      .catch(() => setStripeStatus(null))
      .finally(() => setStripeLoading(false));
  }, [instructor]);

  // Thumbnail replacement state
  const [newThumbFile,    setNewThumbFile]    = useState(null);
  const [newThumbPreview, setNewThumbPreview] = useState(null);
  const thumbInputRef  = useRef(null);
  const videoInputRefs = useRef({});
 
  const [loading, setLoading] = useState(false);
  const matchedCategoryBySpec = useMemo(() => {
    if (!instructor?.specialization) return null;
    return categories.find(
      (c) => c.name?.toLowerCase() === instructor.specialization.toLowerCase()
    ) ?? null;
  }, [categories, instructor]);
 
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

  const addLesson = () =>
    setForm((f) => ({
      ...f,
      lessons: [
        ...f.lessons,
        {
          lessonId: crypto.randomUUID(),
          title: "",
          duration: 0,
          mediaUrl: "",
          newVideoFile: null,
          newVideoPreview: null,
        },
      ],
    }));

  const removeLesson = (idx) =>
    setForm((f) => ({
      ...f,
      lessons: f.lessons.filter((_, i) => i !== idx),
    }));
 
  // ── Quizzes ───────────────────────────────────────────────────
  const addQuiz = () =>
    setForm((f) => ({ ...f, quizzes: [...(f.quizzes || []), emptyQuiz()] }));

  const removeQuiz = (idx) =>
    setForm((f) => ({ ...f, quizzes: (f.quizzes || []).filter((_, i) => i !== idx) }));

  const handleQuizField = (idx, field, value) =>
    setForm((f) => {
      const quizzes = [...(f.quizzes || [])];
      quizzes[idx] = { ...quizzes[idx], [field]: value };
      return { ...f, quizzes };
    });

  const addQuestion = (qIdx) =>
    setForm((f) => {
      const quizzes = [...(f.quizzes || [])];
      quizzes[qIdx] = { 
        ...quizzes[qIdx], 
        questions: [...quizzes[qIdx].questions, emptyQuestion()] 
      };
      return { ...f, quizzes };
    });

  const removeQuestion = (qIdx, qstIdx) =>
    setForm((f) => {
      const quizzes = [...(f.quizzes || [])];
      quizzes[qIdx] = {
        ...quizzes[qIdx],
        questions: quizzes[qIdx].questions.filter((_, i) => i !== qstIdx)
      };
      return { ...f, quizzes };
    });

  const handleQuestionField = (qIdx, qstIdx, field, value) =>
    setForm((f) => {
      const quizzes = [...(f.quizzes || [])];
      const questions = [...quizzes[qIdx].questions];
      questions[qstIdx] = { ...questions[qstIdx], [field]: value };
      quizzes[qIdx] = { ...quizzes[qIdx], questions };
      return { ...f, quizzes };
    });

  const addOption = (qIdx, qstIdx) =>
    setForm((f) => {
      const quizzes = [...(f.quizzes || [])];
      const questions = [...quizzes[qIdx].questions];
      questions[qstIdx] = { 
        ...questions[qstIdx], 
        options: [...questions[qstIdx].options, emptyOption()] 
      };
      quizzes[qIdx] = { ...quizzes[qIdx], questions };
      return { ...f, quizzes };
    });

  const removeOption = (qIdx, qstIdx, optIdx) =>
    setForm((f) => {
      const quizzes = [...(f.quizzes || [])];
      const questions = [...quizzes[qIdx].questions];
      questions[qstIdx] = {
        ...questions[qstIdx],
        options: questions[qstIdx].options.filter((_, i) => i !== optIdx)
      };
      quizzes[qIdx] = { ...quizzes[qIdx], questions };
      return { ...f, quizzes };
    });

  const handleOptionField = (qIdx, qstIdx, optIdx, field, value) =>
    setForm((f) => {
      const quizzes = [...(f.quizzes || [])];
      const questions = [...quizzes[qIdx].questions];
      const options = [...questions[qstIdx].options];
      options[optIdx] = { ...options[optIdx], [field]: value };
      questions[qstIdx] = { ...questions[qstIdx], options };
      quizzes[qIdx] = { ...quizzes[qIdx], questions };
      return { ...f, quizzes };
    });

  // ── Save ──────────────────────────────────────────────────────
  const handleSave = async () => {
    if (!isEditing) return;

    if (!isDraft && !form.lessons.length) {
      alert("Course must have at least one lesson.");
      return;
    }
    if (!form.isFree && form.priceType === "custom") {
      const p = parseFloat(form.price);
      if (isNaN(p) || p < 10 || p > 100) {
        alert("Custom price must be between $10 and $100.");
        return;
      }
    }

    if (!isDraft && form.quizzes && form.quizzes.length > 0) {
      for (let i = 0; i < form.quizzes.length; i++) {
        const q = form.quizzes[i];
        for (let j = 0; j < q.questions.length; j++) {
          const qst = q.questions[j];
          if (qst.options.length < 2) {
            alert(`Quiz ${i+1}, Question ${j+1} must have at least 2 options.`);
            return;
          }
          if (!qst.options.some(opt => opt.isCorrect)) {
            alert(`Quiz ${i+1}, Question ${j+1} must have at least one correct option.`);
            return;
          }
        }
      }
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
        description:  form.description || "",
        isFree:       form.isFree,
        price:        form.isFree ? 0 : parseFloat(form.price) || 0,
        level:        form.level,
        categoryId:   form.categoryId,
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
  const stripeBlocked = !form.isFree && stripeStatus && !stripeStatus.chargesEnabled;
 
  return (
    <div className="cd-overlay" onClick={(e) => e.target === e.currentTarget && onClose()}>
      <div className="cd-modal">
 
        {/* ── Header ── */}
        <div className="cd-head">
          <div>
            <div className="cd-title">Course Preview</div>
            <div className="cd-subtitle">
              {isEditing ? "Editing enabled." : "Preview mode. Click the edit icon to unlock fields."}
            </div>
          </div>
          <div className="cd-head-actions">
            <button
              className={`cd-edit-toggle ${isEditing ? "active" : ""}`}
              onClick={() => setIsEditing((v) => !v)}
              title={isEditing ? "Disable editing" : "Enable editing"}
            >
              <FiEdit3 size={16} />
            </button>
            <button className="cd-close" onClick={onClose}>
              <svg width="20" height="20" viewBox="0 0 24 24" fill="none"
                stroke="currentColor" strokeWidth="2" strokeLinecap="round">
                <line x1="18" y1="6" x2="6" y2="18"/>
                <line x1="6" y1="6" x2="18" y2="18"/>
              </svg>
            </button>
          </div>
        </div>
 
        {/* ── Body ── */}
        <div className="cd-body">
 
          {/* Title */}
          <div className="cd-group">
            <label className="cd-label">Course Title</label>
            <input className="cd-input" value={form.title}
              disabled={!isEditing}
              onChange={(e) => handleField("title", e.target.value)} />
          </div>

          {/* Description */}
          <div className="cd-group">
            <label className="cd-label">Description <span style={{ color: "#aaa", fontWeight: 400, fontSize: 11 }}>(optional)</span></label>
            <textarea
              className="cd-input"
              rows={4}
              value={form.description}
              disabled={!isEditing}
              placeholder="Describe what students will learn…"
              onChange={(e) => handleField("description", e.target.value)}
              style={{ resize: "vertical", minHeight: 90, fontFamily: "inherit" }}
            />
          </div>
 
          {/* Level + Category */}
          <div className="cd-row">
            <div className="cd-group">
              <label className="cd-label">Difficulty Level</label>
              <select className="cd-select" value={form.level}
                disabled={!isEditing}
                onChange={(e) => handleField("level", e.target.value)}>
                {DIFFICULTY_LEVELS.map((l) => <option key={l}>{l}</option>)}
              </select>
            </div>
            {!matchedCategoryBySpec && (
              <div className="cd-group">
                <label className="cd-label">Category</label>
                {catsLoading ? (
                  <div className="cd-input" style={{ opacity: 0.7 }}>Loading…</div>
                ) : (
                  <select className="cd-select" value={form.categoryId}
                    disabled={!isEditing}
                    onChange={(e) => handleField("categoryId", e.target.value)}>
                    {categories.map((c) => (
                      <option key={c.id} value={c.id}>{c.name}</option>
                    ))}
                  </select>
                )}
              </div>
            )}
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
                  disabled={!isEditing}
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
              <div 
                className="cd-toggle-row" 
                title={isEditing && form.isFree && (!stripeStatus || !stripeStatus.chargesEnabled) ? "Connect Stripe to enable paid courses" : ""}
              >
                <label className="cd-toggle">
                  <input type="checkbox" checked={form.isFree}
                    disabled={!isEditing || stripeLoading || (form.isFree && (!stripeStatus || !stripeStatus.chargesEnabled))}
                    onChange={(e) => handleField("isFree", e.target.checked)} />
                  <span className="cd-toggle-slider" />
                </label>
                <span className="cd-toggle-label">
                  {form.isFree ? "Free course" : "Paid course"}
                </span>
              </div>
              {isEditing && form.isFree && (!stripeStatus || !stripeStatus.chargesEnabled) && (
                <div className="cd-hint warn" style={{ marginTop: 8 }}>
                  Finish your Stripe onboarding to enable paid publishing.
                </div>
              )}
            </div>
          </div>

          {!form.isFree && (
            <div className="cd-pricing-details">
              <div className="cd-price-type-selector">
                <button
                  type="button"
                  className={`cd-pts-btn ${form.priceType === "predefined" ? "active" : ""}`}
                  disabled={!isEditing}
                  onClick={() => {
                    handleField("priceType", "predefined");
                    if (!PRICE_TIERS.includes(form.price)) handleField("price", PRICE_TIERS[0]);
                  }}
                >
                  Tiers
                </button>
                <button
                  type="button"
                  className={`cd-pts-btn ${form.priceType === "custom" ? "active" : ""}`}
                  disabled={!isEditing}
                  onClick={() => handleField("priceType", "custom")}
                >
                  Custom
                </button>
              </div>

              {form.priceType === "predefined" ? (
                <div className="cd-price-tiers">
                  {PRICE_TIERS.map((tier) => (
                    <button
                      key={tier}
                      type="button"
                      className={`cd-tier-chip ${form.price === tier ? "active" : ""}`}
                      disabled={!isEditing}
                      onClick={() => handleField("price", tier)}
                    >
                      ${tier}
                    </button>
                  ))}
                </div>
              ) : (
                <div className="cd-group">
                  <label className="cd-label">Custom Price ($)</label>
                  <input className="cd-input" type="number" min="10" max="100" step="1"
                    value={form.price}
                    disabled={!isEditing}
                    onChange={(e) => handleField("price", e.target.value)} />
                </div>
              )}

              {stripeLoading && <div className="cd-hint">Checking Stripe status...</div>}
              {stripeBlocked && <div className="cd-hint warn">Stripe onboarding is incomplete for paid publishing.</div>}
            </div>
          )}
 
          {/* ── Tabs (published only) ── */}
          {!isDraft && (
            <div className="cd-tabs">
              <button
                className={`cd-tab ${activeTab === "lessons" ? "active" : ""}`}
                onClick={() => setActiveTab("lessons")}
              >
                Lessons
                <span className="cd-tab-badge">{form.lessons.length}</span>
              </button>
              <button
                className={`cd-tab ${activeTab === "quizzes" ? "active" : ""}`}
                onClick={() => setActiveTab("quizzes")}
              >
                Quizzes
                <span className="cd-tab-badge">{(form.quizzes || []).length}</span>
              </button>
            </div>
          )}

          {/* ── Lessons ── */}
          {(isDraft || activeTab === "lessons") && (<>
          {isDraft && (
            <div className="cd-divider">
              <span className="cd-divider-label">Lessons</span>
              <div className="cd-divider-line" />
            </div>
          )}
 
          {form.lessons.map((lesson, idx) => {
            const videoSrc = lesson.newVideoPreview ?? toSrc(lesson.mediaUrl);
            return (
              <div className="cd-lesson" key={lesson.lessonId ?? idx}>
                <div className="cd-lesson-head">
                  <span className="cd-lesson-num">Lesson {idx + 1}</span>
                  {isEditing && (
                    <button
                      type="button"
                      className="cd-media-btn"
                      style={{ marginLeft: "auto", padding: "6px 10px", fontSize: 12 }}
                      onClick={() => removeLesson(idx)}
                      disabled={!isDraft && form.lessons.length <= 1}
                      title={!isDraft && form.lessons.length <= 1 ? "At least one lesson is required for publish" : "Remove lesson"}
                    >
                      Remove
                    </button>
                  )}
                </div>
 
                {/* Title */}
                <div className="cd-row" style={{ marginBottom: 14 }}>
                  <div className="cd-group cd-full">
                    <label className="cd-label">Title</label>
                    <input className="cd-input" value={lesson.title ?? ""}
                      disabled={!isEditing}
                      onChange={(e) => handleLessonField(idx, "title", e.target.value)} />
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
                        disabled={!isEditing}
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
          {isEditing && (
            <button
              type="button"
              className="cd-btn-save"
              style={{ alignSelf: "flex-start", marginTop: 6 }}
              onClick={addLesson}
            >
              + Add Lesson
            </button>
          )}
          </>)}

        {/* ── Quizzes ── */}
          {(isDraft || activeTab === "quizzes") && (
          <div className="acf-section" style={{ border: 'none', padding: 0, marginTop: 0, boxShadow: 'none' }}>
            {isDraft && (
              <div className="cd-divider" style={{ marginBottom: 24 }}>
                <span className="cd-divider-label">Quizzes (Optional)</span>
                <div className="cd-divider-line" />
              </div>
            )}
              {(form.quizzes || []).map((quiz, qIdx) => (
                <div className="acf-lesson" key={quiz.quizId ?? qIdx}>
                  <div className="acf-lesson-head">
                    <div className="acf-lesson-num">
                      <span>#{qIdx + 1}</span>
                    </div>
                    <span className="acf-lesson-tag">Quiz {qIdx + 1}</span>
                    {isEditing && (
                      <button type="button" className="acf-lesson-remove"
                        onClick={() => removeQuiz(qIdx)} title="Remove quiz">
                        <svg width="15" height="15" viewBox="0 0 24 24" fill="none" stroke="currentColor" strokeWidth="2" strokeLinecap="round">
                          <polyline points="3 6 5 6 21 6"/>
                          <path d="M19 6l-1 14H6L5 6"/>
                          <path d="M10 11v6M14 11v6"/>
                        </svg>
                      </button>
                    )}
                  </div>

                  <div className="acf-field">
                    <label className="acf-label">Quiz Title <span className="acf-req">*</span></label>
                    <input className="acf-input" placeholder="e.g. Mid-term Assessment"
                      value={quiz.title ?? ""}
                      disabled={!isEditing}
                      onChange={(e) => handleQuizField(qIdx, "title", e.target.value)}
                      required />
                  </div>

                  <div className="acf-questions" style={{ marginTop: '16px', paddingLeft: '16px', borderLeft: '2px solid #e8e4da' }}>
                    <h4 style={{ fontSize: '13px', color: '#666', marginBottom: '10px' }}>Questions & Answers</h4>
                    {quiz.questions.map((qst, qstIdx) => (
                      <div key={qst.questionId ?? qstIdx} style={{ marginBottom: '24px', padding: '16px', background: '#fafafa', borderRadius: '8px', border: '1px solid #eee' }}>
                        <div style={{ display: 'flex', gap: '10px', marginBottom: '12px', alignItems: 'center' }}>
                          <span style={{ fontSize: '13px', fontWeight: '600', color: '#444' }}>Q{qstIdx + 1}:</span>
                          <input className="acf-input" placeholder="e.g. What is the main characteristic of ballet?"
                            style={{ flex: 1 }}
                            value={qst.text}
                            disabled={!isEditing}
                            onChange={(e) => handleQuestionField(qIdx, qstIdx, "text", e.target.value)}
                            required />
                          {isEditing && quiz.questions.length > 1 && (
                            <button type="button" className="acf-lesson-remove" style={{ background: 'none' }}
                              onClick={() => removeQuestion(qIdx, qstIdx)} title="Remove question">
                              <svg width="14" height="14" viewBox="0 0 24 24" fill="none" stroke="currentColor" strokeWidth="2" strokeLinecap="round">
                                <line x1="18" y1="6" x2="6" y2="18"/><line x1="6" y1="6" x2="18" y2="18"/>
                              </svg>
                            </button>
                          )}
                        </div>

                        <div style={{ paddingLeft: '24px' }}>
                          <h5 style={{ fontSize: '12px', color: '#888', marginBottom: '8px', textTransform: 'uppercase' }}>Options</h5>
                          {qst.options.map((opt, optIdx) => (
                            <div key={opt.optionId ?? optIdx} style={{ display: 'flex', gap: '10px', marginBottom: '8px', alignItems: 'center' }}>
                              <input type="checkbox" 
                                checked={opt.isCorrect} 
                                disabled={!isEditing}
                                onChange={(e) => handleOptionField(qIdx, qstIdx, optIdx, "isCorrect", e.target.checked)}
                                title="Mark as correct answer"
                                style={{ width: '16px', height: '16px', accentColor: 'var(--id-gold)' }}
                              />
                              <input className="acf-input" placeholder={`Option ${optIdx + 1}`}
                                style={{ flex: 1, padding: '8px 12px', fontSize: '13px' }}
                                value={opt.text}
                                disabled={!isEditing}
                                onChange={(e) => handleOptionField(qIdx, qstIdx, optIdx, "text", e.target.value)}
                                required />
                              {isEditing && qst.options.length > 2 && (
                                <button type="button" className="acf-lesson-remove" style={{ background: 'none' }}
                                  onClick={() => removeOption(qIdx, qstIdx, optIdx)} title="Remove option">
                                  ✕
                                </button>
                              )}
                            </div>
                          ))}
                          {isEditing && (
                            <button type="button" className="acf-add-lesson" style={{ marginTop: '4px', padding: '4px 8px', fontSize: '12px', border: '1px dashed #ccc', background: 'transparent' }} onClick={() => addOption(qIdx, qstIdx)}>
                              + Add Option
                            </button>
                          )}
                        </div>
                      </div>
                    ))}
                    {isEditing && (
                      <button type="button" className="acf-add-lesson" style={{ marginTop: '8px', padding: '8px 14px', fontSize: '13px', border: '1px solid #e8e4da', background: '#fff', fontWeight: '500' }} onClick={() => addQuestion(qIdx)}>
                        + Add Question
                      </button>
                    )}
                  </div>
                </div>
              ))}
            </div>

            {isEditing && (
              <button
                type="button"
                className="acf-add-lesson"
                onClick={addQuiz}
              >
                <svg width="14" height="14" viewBox="0 0 24 24" fill="none" stroke="currentColor" strokeWidth="2.5" strokeLinecap="round">
                  <line x1="12" y1="5" x2="12" y2="19"/><line x1="5" y1="12" x2="19" y2="12"/>
                </svg>
                Add a quiz (optional)
              </button>
            )}
          </div>
          )}
        </div>
 
        {/* ── Footer ── */}
        <div className="cd-footer">
          <button className="cd-btn-cancel" onClick={onClose}>Cancel</button>
          {isEditing && (
            <button className="cd-btn-save" onClick={handleSave} disabled={loading || stripeLoading}>
              {loading
                ? <><span className="cd-spinner" /> Saving…</>
                : "Save Changes"}
            </button>
          )}
        </div>
 
      </div>
    </div>
  );
}