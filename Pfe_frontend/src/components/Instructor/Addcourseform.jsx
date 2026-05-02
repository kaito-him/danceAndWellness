import React, { useState, useRef, useEffect } from "react";
import api from "./../services/api";
import "../../styles/Addcourseform.css";

const DIFFICULTY_LEVELS = ["BEGINNER", "INTERMEDIATE", "ADVANCED"];
const PRICE_TIERS = ["10", "20", "30"];

const emptyLesson = () => ({
  lessonId: crypto.randomUUID(),
  title: "",
  duration: "",
  videoFile: null,
  videoPreview: null,
});

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

const emptyForm = {
  title: "",
  description: "",
  isFree: true,
  priceType: "predefined", // "predefined" | "custom"
  price: "10",
  level: "BEGINNER",
  categoryId: "",
  lessons: [emptyLesson()],
  quizzes: [],
};

async function uploadFile(file) {
  const fd = new FormData();
  fd.append("file", file);
  const res = await api.post("/files/upload", fd, {
    headers: { "Content-Type": "multipart/form-data" },
  });
  return res.data.url;
}

export default function AddCourseForm({ onClose, onSuccess, instructor }) {
  const [form, setForm]                         = useState(emptyForm);
  const [thumbnailFile, setThumbnailFile]       = useState(null);
  const [thumbnailPreview, setThumbnailPreview] = useState(null);
  const [thumbDragging, setThumbDragging]       = useState(false);
  const [videoDragging, setVideoDragging]       = useState({});
  const [loading, setLoading]                   = useState(false);

  // ── Remote data ──────────────────────────────────────────────
  const [categories, setCategories]         = useState([]);
  const [catsLoading, setCatsLoading]       = useState(true);
  const [stripeStatus, setStripeStatus]     = useState(null); // null | {chargesEnabled, hasAccount}
  const [stripeLoading, setStripeLoading]   = useState(false);

  const thumbInputRef  = useRef(null);
  const videoInputRefs = useRef({});

  // ── Fetch categories on mount ─────────────────────────────────
  useEffect(() => {
    api.get("/categories")
      .then((res) => {
        const cats = Array.isArray(res.data) ? res.data : [];
        setCategories(cats);
        
        if (cats.length > 0) {
          // If we have an instructor specialization, try to find a matching category
          const specialization = instructor?.specialization;
          const matchedCat = specialization 
            ? cats.find(c => c.name.toLowerCase() === specialization.toLowerCase())
            : null;

          if (matchedCat) {
            setForm((f) => ({ ...f, categoryId: matchedCat.id }));
          } else {
            setForm((f) => ({ ...f, categoryId: cats[0].id }));
          }
        }
      })
      .catch(() => {/* silently fall back to empty list */})
      .finally(() => setCatsLoading(false));
  }, [instructor]);

  // ── Fetch Stripe status on mount ──────
  useEffect(() => {
    if (!instructor?.id) return;
    setStripeLoading(true);
    api.get(`/instructor/payments/${instructor.id}/status`)
      .then((res) => setStripeStatus(res.data))
      .catch(() => setStripeStatus(null))
      .finally(() => setStripeLoading(false));
  }, [instructor]);

  // ── Thumbnail ─────────────────────────────────────────────────
  const applyThumbnail = (file) => {
    if (!file || !file.type.startsWith("image/")) return;
    setThumbnailFile(file);
    setThumbnailPreview(URL.createObjectURL(file));
  };

  const removeThumbnail = () => {
    setThumbnailFile(null);
    setThumbnailPreview(null);
    if (thumbInputRef.current) thumbInputRef.current.value = "";
  };

  // ── Form helpers ──────────────────────────────────────────────
  const handleField = (field, value) =>
    setForm((f) => ({ ...f, [field]: value }));

  const handleLessonField = (idx, field, value) =>
    setForm((f) => {
      const lessons = [...f.lessons];
      lessons[idx] = { ...lessons[idx], [field]: value };
      return { ...f, lessons };
    });

  // ── Video ─────────────────────────────────────────────────────
  const applyVideo = (idx, file) => {
    if (!file || !file.type.startsWith("video/")) return;
    const objectUrl = URL.createObjectURL(file);
    const tempVideo = document.createElement("video");
    tempVideo.preload = "metadata";
    tempVideo.src = objectUrl;
    tempVideo.onloadedmetadata = () => {
      const minutes = Math.round(tempVideo.duration / 60);
      URL.revokeObjectURL(objectUrl);
      setForm((f) => {
        const lessons = [...f.lessons];
        lessons[idx] = {
          ...lessons[idx],
          videoFile: file,
          videoPreview: URL.createObjectURL(file),
          duration: String(minutes || 1),
        };
        return { ...f, lessons };
      });
    };
  };

  const removeVideo = (idx) => {
    const id = form.lessons[idx].lessonId;
    handleLessonField(idx, "videoFile", null);
    handleLessonField(idx, "videoPreview", null);
    if (videoInputRefs.current[id]) videoInputRefs.current[id].value = "";
  };

  // ── Lessons ───────────────────────────────────────────────────
  const addLesson = () =>
    setForm((f) => ({ ...f, lessons: [...f.lessons, emptyLesson()] }));

  const removeLesson = (idx) =>
    setForm((f) => ({ ...f, lessons: f.lessons.filter((_, i) => i !== idx) }));

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

  // ── Stripe gate check ─────────────────────────────────────────
  const stripeBlocked = !form.isFree && stripeStatus && !stripeStatus.chargesEnabled;

  // ── Submit ────────────────────────────────────────────────────
  const handleSubmit = async (mode) => {
    const isDraft = mode === "draft";

    if (isDraft) {
      if (!form.title || !form.title.trim()) {
        onSuccess?.("error", "Please provide at least a course title to save a draft.");
        return;
      }
    }

    if (!isDraft) {
      if (!form.title || !form.title.trim()) {
        onSuccess?.("error", "Course title is required to publish.");
        return;
      }
      if (form.lessons.length === 0) {
        onSuccess?.("error", "Add at least one lesson before submitting.");
        return;
      }
      const missingVideo = form.lessons.findIndex((l) => !l.videoFile);
      if (missingVideo !== -1) {
        onSuccess?.("error", `Please upload a video for Lesson ${missingVideo + 1}.`);
        return;
      }
      if (stripeBlocked) {
        onSuccess?.("error", "Connect your Stripe account before publishing a paid course.");
        return;
      }

      // Price validation for custom mode
      if (!form.isFree && form.priceType === "custom") {
        const p = parseFloat(form.price);
        if (isNaN(p) || p < 10 || p > 100) {
          onSuccess?.("error", "Custom price must be between $10 and $100.");
          return;
        }
      }

      // Quiz validation
      if (form.quizzes && form.quizzes.length > 0) {
        for (let i = 0; i < form.quizzes.length; i++) {
          const q = form.quizzes[i];
          for (let j = 0; j < q.questions.length; j++) {
            const qst = q.questions[j];
            if (qst.options.length < 2) {
              onSuccess?.("error", `Quiz ${i+1}, Question ${j+1} must have at least 2 options.`);
              return;
            }
            if (!qst.options.some(opt => opt.isCorrect)) {
              onSuccess?.("error", `Quiz ${i+1}, Question ${j+1} must have at least one correct option.`);
              return;
            }
          }
        }
      }
    }

    setLoading(true);
    try {
      let thumbnailUrl = "";
      if (thumbnailFile) thumbnailUrl = await uploadFile(thumbnailFile);

      const lessons = [];
      if (Array.isArray(form.lessons) && form.lessons.length > 0) {
        // Upload videos sequentially to preserve order
        const videoUrls = [];
        for (const lesson of form.lessons) {
          if (lesson.videoFile) {
            videoUrls.push(await uploadFile(lesson.videoFile));
          } else {
            videoUrls.push(null);
          }
        }
        lessons.push(
          ...form.lessons.map((l, i) => ({
            lessonId: l.lessonId,
            title:    l.title,
            duration: parseInt(l.duration) || 0,
            mediaUrl: videoUrls[i],
            order:    i,
          }))
        );
      }

      const payload = {
        title:       form.title,
        description: form.description || "",
        isFree:      form.isFree,
        price:       form.isFree ? 0 : parseFloat(form.price) || 0,
        level:       form.level,
        categoryId:  form.categoryId,
        thumbnailUrl,
        lessons,
        quizzes: (form.quizzes || []).map(q => ({
          title: q.title,
          questions: q.questions.map(qst => ({
            text: qst.text,
            options: qst.options.map(opt => ({
              text: opt.text,
              isCorrect: opt.isCorrect,
            }))
          }))
        })),
      };

      if (isDraft) {
        await api.post("/courses/draft", payload);
        onSuccess?.("success", "Draft saved.");
      } else {
        await api.post("/courses", payload);
        onSuccess?.("success", "Course published successfully! 🎉");
      }

      onClose();
    } catch (err) {
      const msg = err?.response?.data || (isDraft ? "Failed to save draft." : "Failed to submit course.");
      onSuccess?.("error", msg);
    } finally {
      setLoading(false);
    }
  };

  // ── Stripe warning banner ─────────────────────────────────────
  const renderPriceInfo = () => {
    if (stripeLoading) return (
      <div className="acf-info-banner loading">
        <span className="acf-banner-spinner" /> Checking account status…
      </div>
    );

    if (form.isFree) {
      return null;
    }

    if (!stripeStatus || !stripeStatus.hasAccount) {
      return (
        <div className="acf-info-banner warn">
          <svg width="15" height="15" viewBox="0 0 24 24" fill="none" stroke="currentColor" strokeWidth="2.5" strokeLinecap="round"><circle cx="12" cy="12" r="10"/><line x1="12" y1="8" x2="12" y2="12"/><line x1="12" y1="16" x2="12.01" y2="16"/></svg>
          Connect Stripe to create paid courses. Go to <strong>Payments → Connect Stripe</strong>.
        </div>
      );
    }

    if (!stripeStatus.chargesEnabled) {
      return (
        <div className="acf-info-banner warn">
          <svg width="15" height="15" viewBox="0 0 24 24" fill="none" stroke="currentColor" strokeWidth="2.5" strokeLinecap="round"><circle cx="12" cy="12" r="10"/><line x1="12" y1="8" x2="12" y2="12"/><line x1="12" y1="16" x2="12.01" y2="16"/></svg>
          Finish your Stripe onboarding to enable paid courses.
        </div>
      );
    }

    return (
      <div className="acf-info-banner ok">
        <svg width="15" height="15" viewBox="0 0 24 24" fill="none" stroke="currentColor" strokeWidth="2.5" strokeLinecap="round"><polyline points="20 6 9 17 4 12"/></svg>
        Stripe is active — ready to publish paid courses.
      </div>
    );
  };

  return (
    <div
      className="acf-overlay"
      onClick={(e) => e.target === e.currentTarget && onClose()}
    >
      <div className="acf-modal">

        {/* ── Header ── */}
        <div className="acf-header">
          <div className="acf-header-text">
            <h2 className="acf-title">Create New Course</h2>
            <p className="acf-subtitle">Fill in the details below — your course will be published immediately.</p>
          </div>
          <button className="acf-close" onClick={onClose} aria-label="Close">
            <svg width="18" height="18" viewBox="0 0 24 24" fill="none" stroke="currentColor" strokeWidth="2.5" strokeLinecap="round">
              <line x1="18" y1="6" x2="6" y2="18"/><line x1="6" y1="6" x2="18" y2="18"/>
            </svg>
          </button>
        </div>

        {/* ── Body ── */}
        <form className="acf-body" onSubmit={(e) => { e.preventDefault(); handleSubmit("publish"); }}>

          {/* Step 1 — Course info */}
          <div className="acf-section">
            <div className="acf-section-label">
              <span className="acf-step">1</span>
              Course Details
            </div>

            <div className="acf-field">
              <label className="acf-label">Course Title <span className="acf-req">*</span></label>
              <input
                className="acf-input"
                placeholder="e.g. Beginner Contemporary Dance"
                value={form.title}
                onChange={(e) => handleField("title", e.target.value)}
                required
              />
            </div>

            <div className="acf-field">
              <label className="acf-label">Description <span className="acf-optional">(optional)</span></label>
              <textarea
                className="acf-input"
                rows={4}
                placeholder="Describe what students will learn, who this course is for, and what makes it special…"
                value={form.description}
                onChange={(e) => handleField("description", e.target.value)}
                style={{ resize: "vertical", minHeight: 96 }}
              />
            </div>

            <div className="acf-row">
              <div className="acf-field">
                <label className="acf-label">Difficulty Level <span className="acf-req">*</span></label>
                <div className="acf-select-wrap">
                  <select className="acf-select" value={form.level}
                    onChange={(e) => handleField("level", e.target.value)}>
                    {DIFFICULTY_LEVELS.map((l) => <option key={l} value={l}>{l.charAt(0) + l.slice(1).toLowerCase()}</option>)}
                  </select>
                  <svg className="acf-select-arrow" width="14" height="14" viewBox="0 0 24 24" fill="none" stroke="currentColor" strokeWidth="2.5" strokeLinecap="round"><polyline points="6 9 12 15 18 9"/></svg>
                </div>
              </div>

              {(!instructor?.specialization || !categories.find(c => c.name.toLowerCase() === instructor.specialization.toLowerCase())) && (
                <div className="acf-field">
                  <label className="acf-label">Category <span className="acf-req">*</span></label>
                  <div className="acf-select-wrap">
                    {catsLoading ? (
                      <div className="acf-input acf-loading-text">Loading categories…</div>
                    ) : (
                      <>
                        <select
                          className="acf-select"
                          value={form.categoryId}
                          onChange={(e) => handleField("categoryId", e.target.value)}
                          required
                        >
                          {categories.length === 0 && <option value="">No categories found</option>}
                          {categories.map((c) => (
                            <option key={c.id} value={c.id}>{c.name}</option>
                          ))}
                        </select>
                        <svg className="acf-select-arrow" width="14" height="14" viewBox="0 0 24 24" fill="none" stroke="currentColor" strokeWidth="2.5" strokeLinecap="round"><polyline points="6 9 12 15 18 9"/></svg>
                      </>
                    )}
                  </div>
                </div>
              )}
            </div>
          </div>

          {/* Step 2 — Thumbnail */}
          <div className="acf-section">
            <div className="acf-section-label">
              <span className="acf-step">2</span>
              Thumbnail
            </div>

            <div className="acf-field">
              {thumbnailPreview ? (
                <div className="acf-thumb-preview">
                  <img src={thumbnailPreview} alt="preview" className="acf-thumb-img" />
                  <div className="acf-thumb-overlay">
                    <button type="button" className="acf-thumb-btn change"
                      onClick={() => thumbInputRef.current?.click()}>Change</button>
                    <button type="button" className="acf-thumb-btn remove"
                      onClick={removeThumbnail}>Remove</button>
                  </div>
                  <span className="acf-thumb-name">{thumbnailFile?.name}</span>
                </div>
              ) : (
                <div
                  className={`acf-dropzone ${thumbDragging ? "dragging" : ""}`}
                  onClick={() => thumbInputRef.current?.click()}
                  onDragOver={(e) => { e.preventDefault(); setThumbDragging(true); }}
                  onDragLeave={() => setThumbDragging(false)}
                  onDrop={(e) => { e.preventDefault(); setThumbDragging(false); applyThumbnail(e.dataTransfer.files[0]); }}
                >
                  <div className="acf-dropzone-icon">
                    <svg width="26" height="26" viewBox="0 0 24 24" fill="none" stroke="currentColor" strokeWidth="1.5" strokeLinecap="round">
                      <rect x="3" y="3" width="18" height="18" rx="2"/>
                      <circle cx="8.5" cy="8.5" r="1.5"/>
                      <polyline points="21 15 16 10 5 21"/>
                    </svg>
                  </div>
                  <p className="acf-dropzone-primary"><span className="acf-link">Click to upload</span> or drag & drop</p>
                  <p className="acf-dropzone-hint">PNG · JPG · WEBP — recommended 1280×720</p>
                </div>
              )}
              <input ref={thumbInputRef} type="file" accept="image/png,image/jpeg,image/webp"
                style={{ display: "none" }} onChange={(e) => applyThumbnail(e.target.files[0])} />
            </div>
          </div>

          {/* Step 3 — Pricing */}
          <div className="acf-section">
            <div className="acf-section-label">
              <span className="acf-step">3</span>
              Pricing
            </div>

            <div className="acf-pricing-row">
              <button
                type="button"
                className={`acf-pricing-tab ${form.isFree ? "active" : ""}`}
                onClick={() => handleField("isFree", true)}
              >
                <svg width="16" height="16" viewBox="0 0 24 24" fill="none" stroke="currentColor" strokeWidth="2" strokeLinecap="round"><path d="M12 2l3.09 6.26L22 9.27l-5 4.87 1.18 6.88L12 17.77l-6.18 3.25L7 14.14 2 9.27l6.91-1.01L12 2z"/></svg>
                Free
              </button>
              <span title={(!stripeStatus || !stripeStatus.chargesEnabled) ? "You must activate a stripe account first" : ""}>
                <button
                  type="button"
                  className={`acf-pricing-tab ${!form.isFree ? "active" : ""}`}
                  disabled={!stripeStatus || !stripeStatus.chargesEnabled}
                  onClick={() => handleField("isFree", false)}
                  style={(!stripeStatus || !stripeStatus.chargesEnabled) ? { pointerEvents: "none" } : {}}
                >
                  <svg width="16" height="16" viewBox="0 0 24 24" fill="none" stroke="currentColor" strokeWidth="2" strokeLinecap="round"><line x1="12" y1="1" x2="12" y2="23"/><path d="M17 5H9.5a3.5 3.5 0 000 7h5a3.5 3.5 0 010 7H6"/></svg>
                  Paid
                </button>
              </span>
            </div>

            {/* Combined Info Banner */}
            {renderPriceInfo()}

            {!form.isFree && (
              <div className="acf-pricing-details">
                {/* Price Type Selector */}
                <div className="acf-price-type-selector">
                  <button
                    type="button"
                    className={`acf-pts-btn ${form.priceType === "predefined" ? "active" : ""}`}
                    onClick={() => {
                      handleField("priceType", "predefined");
                      if (!PRICE_TIERS.includes(form.price)) {
                        handleField("price", PRICE_TIERS[0]);
                      }
                    }}
                  >
                    Tiers
                  </button>
                  <button
                    type="button"
                    className={`acf-pts-btn ${form.priceType === "custom" ? "active" : ""}`}
                    onClick={() => handleField("priceType", "custom")}
                  >
                    Custom
                  </button>
                </div>

                {form.priceType === "predefined" ? (
                  <div className="acf-field">
                    <label className="acf-label">Select Price Tier <span className="acf-req">*</span></label>
                    <div className="acf-price-tiers">
                      {PRICE_TIERS.map((tier) => (
                        <button
                          key={tier}
                          type="button"
                          className={`acf-tier-chip ${form.price === tier ? "active" : ""}`}
                          onClick={() => handleField("price", tier)}
                        >
                          ${tier}
                        </button>
                      ))}
                    </div>
                  </div>
                ) : (
                  <div className="acf-field">
                    <label className="acf-label">Custom Price ($) <span className="acf-req">*</span></label>
                    <div className="acf-price-wrap">
                      <span className="acf-currency">$</span>
                      <input
                        className="acf-input acf-price-input"
                        type="number"
                        min="10"
                        max="100"
                        step="1"
                        placeholder="e.g. 45"
                        value={form.price}
                        onChange={(e) => handleField("price", e.target.value)}
                        required
                      />
                    </div>
                    <p className="acf-field-hint">Range: $10 – $100</p>
                  </div>
                )}

                <div className="acf-price-earnings">
                  <p className="acf-field-hint">You keep 80% · Platform retains 20%</p>
                </div>
              </div>
            )}
          </div>

          {/* Step 4 — Lessons */}
          <div className="acf-section">
            <div className="acf-section-label">
              <span className="acf-step">4</span>
              Lessons
              <span className="acf-lesson-count">{form.lessons.length}</span>
            </div>

            <div className="acf-lessons">
              {form.lessons.map((lesson, idx) => (
                <div className="acf-lesson" key={lesson.lessonId}>
                  <div className="acf-lesson-head">
                    <div className="acf-lesson-num">
                      <span>#{idx + 1}</span>
                    </div>
                    <span className="acf-lesson-tag">Lesson {idx + 1}</span>
                    {form.lessons.length > 1 && (
                      <button type="button" className="acf-lesson-remove"
                        onClick={() => removeLesson(idx)} title="Remove lesson">
                        <svg width="15" height="15" viewBox="0 0 24 24" fill="none" stroke="currentColor" strokeWidth="2" strokeLinecap="round">
                          <polyline points="3 6 5 6 21 6"/>
                          <path d="M19 6l-1 14H6L5 6"/>
                          <path d="M10 11v6M14 11v6"/>
                        </svg>
                      </button>
                    )}
                  </div>

                  <div className="acf-field">
                    <label className="acf-label">Lesson Title <span className="acf-req">*</span></label>
                    <input className="acf-input" placeholder="e.g. Warm-up & Posture Basics"
                      value={lesson.title}
                      onChange={(e) => handleLessonField(idx, "title", e.target.value)}
                      required />
                  </div>

                  <div className="acf-field" style={{ marginTop: 14 }}>
                    <label className="acf-label">Lesson Video <span className="acf-req">*</span></label>
                    {lesson.videoPreview ? (
                      <div className="acf-video-wrap">
                        <video src={lesson.videoPreview} className="acf-video" controls />
                        <div className="acf-video-bar">
                          <span className="acf-video-name">{lesson.videoFile?.name}</span>
                          <button type="button" className="acf-thumb-btn change"
                            onClick={() => videoInputRefs.current[lesson.lessonId]?.click()}>Change</button>
                          <button type="button" className="acf-thumb-btn remove"
                            onClick={() => removeVideo(idx)}>Remove</button>
                        </div>
                      </div>
                    ) : (
                      <div
                        className={`acf-dropzone video ${videoDragging[lesson.lessonId] ? "dragging" : ""}`}
                        onClick={() => videoInputRefs.current[lesson.lessonId]?.click()}
                        onDragOver={(e) => { e.preventDefault(); setVideoDragging((d) => ({ ...d, [lesson.lessonId]: true })); }}
                        onDragLeave={() => setVideoDragging((d) => ({ ...d, [lesson.lessonId]: false }))}
                        onDrop={(e) => {
                          e.preventDefault();
                          setVideoDragging((d) => ({ ...d, [lesson.lessonId]: false }));
                          applyVideo(idx, e.dataTransfer.files[0]);
                        }}
                      >
                        <div className="acf-dropzone-icon">
                          <svg width="26" height="26" viewBox="0 0 24 24" fill="none" stroke="currentColor" strokeWidth="1.5" strokeLinecap="round">
                            <polygon points="23 7 16 12 23 17 23 7"/>
                            <rect x="1" y="5" width="15" height="14" rx="2"/>
                          </svg>
                        </div>
                        <p className="acf-dropzone-primary"><span className="acf-link">Click to upload</span> or drag & drop</p>
                        <p className="acf-dropzone-hint">MP4 · MOV · WEBM</p>
                      </div>
                    )}
                    <input type="file" accept="video/mp4,video/quicktime,video/webm"
                      style={{ display: "none" }}
                      ref={(el) => { videoInputRefs.current[lesson.lessonId] = el; }}
                      onChange={(e) => applyVideo(idx, e.target.files[0])} />
                  </div>
                </div>
              ))}
            </div>

            <button type="button" className="acf-add-lesson" onClick={addLesson}>
              <svg width="14" height="14" viewBox="0 0 24 24" fill="none" stroke="currentColor" strokeWidth="2.5" strokeLinecap="round">
                <line x1="12" y1="5" x2="12" y2="19"/><line x1="5" y1="12" x2="19" y2="12"/>
              </svg>
              Add another lesson
            </button>
          </div>

          {/* Step 5 — Quizzes */}
          <div className="acf-section">
            <div className="acf-section-label">
              <span className="acf-step">5</span>
              Quizzes (Optional)
              <span className="acf-lesson-count">{(form.quizzes || []).length}</span>
            </div>

            <div className="acf-lessons">
              {(form.quizzes || []).map((quiz, qIdx) => (
                <div className="acf-lesson" key={quiz.quizId}>
                  <div className="acf-lesson-head">
                    <div className="acf-lesson-num">
                      <span>#{qIdx + 1}</span>
                    </div>
                    <span className="acf-lesson-tag">Quiz {qIdx + 1}</span>
                    <button type="button" className="acf-lesson-remove"
                      onClick={() => removeQuiz(qIdx)} title="Remove quiz">
                      <svg width="15" height="15" viewBox="0 0 24 24" fill="none" stroke="currentColor" strokeWidth="2" strokeLinecap="round">
                        <polyline points="3 6 5 6 21 6"/>
                        <path d="M19 6l-1 14H6L5 6"/>
                        <path d="M10 11v6M14 11v6"/>
                      </svg>
                    </button>
                  </div>

                  <div className="acf-field">
                    <label className="acf-label">Quiz Title <span className="acf-req">*</span></label>
                    <input className="acf-input" placeholder="e.g. Mid-term Assessment"
                      value={quiz.title}
                      onChange={(e) => handleQuizField(qIdx, "title", e.target.value)}
                      required />
                  </div>

                  <div className="acf-questions" style={{ marginTop: '16px', paddingLeft: '16px', borderLeft: '2px solid #e8e4da' }}>
                    <h4 style={{ fontSize: '13px', color: '#666', marginBottom: '10px' }}>Questions & Answers</h4>
                    {quiz.questions.map((qst, qstIdx) => (
                      <div key={qst.questionId} style={{ marginBottom: '24px', padding: '16px', background: '#fafafa', borderRadius: '8px', border: '1px solid #eee' }}>
                        <div style={{ display: 'flex', gap: '10px', marginBottom: '12px', alignItems: 'center' }}>
                          <span style={{ fontSize: '13px', fontWeight: '600', color: '#444' }}>Q{qstIdx + 1}:</span>
                          <input className="acf-input" placeholder="e.g. What is the main characteristic of ballet?"
                            style={{ flex: 1 }}
                            value={qst.text}
                            onChange={(e) => handleQuestionField(qIdx, qstIdx, "text", e.target.value)}
                            required />
                          {quiz.questions.length > 1 && (
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
                            <div key={opt.optionId} style={{ display: 'flex', gap: '10px', marginBottom: '8px', alignItems: 'center' }}>
                              <input type="checkbox" 
                                checked={opt.isCorrect} 
                                onChange={(e) => handleOptionField(qIdx, qstIdx, optIdx, "isCorrect", e.target.checked)}
                                title="Mark as correct answer"
                                style={{ width: '16px', height: '16px', accentColor: 'var(--id-gold)' }}
                              />
                              <input className="acf-input" placeholder={`Option ${optIdx + 1}`}
                                style={{ flex: 1, padding: '8px 12px', fontSize: '13px' }}
                                value={opt.text}
                                onChange={(e) => handleOptionField(qIdx, qstIdx, optIdx, "text", e.target.value)}
                                required />
                              {qst.options.length > 2 && (
                                <button type="button" className="acf-lesson-remove" style={{ background: 'none' }}
                                  onClick={() => removeOption(qIdx, qstIdx, optIdx)} title="Remove option">
                                  ✕
                                </button>
                              )}
                            </div>
                          ))}
                          <button type="button" className="acf-add-lesson" style={{ marginTop: '4px', padding: '4px 8px', fontSize: '12px', border: '1px dashed #ccc', background: 'transparent' }} onClick={() => addOption(qIdx, qstIdx)}>
                            + Add Option
                          </button>
                        </div>
                      </div>
                    ))}
                    <button type="button" className="acf-add-lesson" style={{ marginTop: '8px', padding: '8px 14px', fontSize: '13px', border: '1px solid #e8e4da', background: '#fff', fontWeight: '500' }} onClick={() => addQuestion(qIdx)}>
                      + Add Question
                    </button>
                  </div>
                </div>
              ))}
            </div>

            <button type="button" className="acf-add-lesson" onClick={addQuiz}>
              <svg width="14" height="14" viewBox="0 0 24 24" fill="none" stroke="currentColor" strokeWidth="2.5" strokeLinecap="round">
                <line x1="12" y1="5" x2="12" y2="19"/><line x1="5" y1="12" x2="19" y2="12"/>
              </svg>
              Add a quiz (optional)
            </button>
          </div>

        </form>

        {/* ── Footer ── */}
        <div className="acf-footer">
          <div className="acf-footer-meta">
            <span>All courses publish immediately</span>
          </div>
          <div className="acf-footer-actions">
            <button className="acf-btn-cancel" type="button" onClick={onClose}>Cancel</button>
            <button
              className="acf-btn-submit"
              type="button"
              disabled={loading || stripeBlocked || stripeLoading}
              onClick={() => handleSubmit("publish")}
            >
              {loading ? (
                <><span className="acf-spin" /> Uploading…</>
              ) : (
                "Publish Course"
              )}
            </button>
            <button
              className="acf-btn-cancel"
              type="button"
              disabled={loading}
              onClick={() => handleSubmit("draft")}
              title="Save now and publish later"
              style={{ marginLeft: 10 }}
            >
              Save Draft
            </button>
          </div>
        </div>

      </div>
    </div>
  );
}