import React, { useState, useRef, useEffect } from "react";
import api from "./../services/api";
import "../../styles/Addcourseform.css";

const DIFFICULTY_LEVELS = ["BEGINNER", "INTERMEDIATE", "ADVANCED"];

const emptyLesson = () => ({
  lessonId: crypto.randomUUID(),
  title: "",
  duration: "",
  videoFile: null,
  videoPreview: null,
});

const emptyForm = {
  title: "",
  isFree: false,
  price: "",
  level: "BEGINNER",
  categoryId: "",
  lessons: [emptyLesson()],
};

async function uploadFile(file) {
  const fd = new FormData();
  fd.append("file", file);
  const res = await api.post("/files/upload", fd, {
    headers: { "Content-Type": "multipart/form-data" },
  });
  return res.data.url;
}

export default function AddCourseForm({ onClose, onSuccess, instructorId }) {
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
        if (cats.length > 0)
          setForm((f) => ({ ...f, categoryId: cats[0].id }));
      })
      .catch(() => {/* silently fall back to empty list */})
      .finally(() => setCatsLoading(false));
  }, []);

  // ── Fetch Stripe status when instructor switches to paid ──────
  useEffect(() => {
    if (form.isFree || !instructorId) return;
    setStripeLoading(true);
    api.get(`/instructor/payments/${instructorId}/status`)
      .then((res) => setStripeStatus(res.data))
      .catch(() => setStripeStatus(null))
      .finally(() => setStripeLoading(false));
  }, [form.isFree, instructorId]);

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

  // ── Stripe gate check ─────────────────────────────────────────
  const stripeBlocked = !form.isFree && stripeStatus && !stripeStatus.chargesEnabled;

  // ── Submit ────────────────────────────────────────────────────
  const handleSubmit = async (e) => {
    e.preventDefault();

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

    setLoading(true);
    try {
      let thumbnailUrl = "";
      if (thumbnailFile) thumbnailUrl = await uploadFile(thumbnailFile);

      // !! Upload videos sequentially to preserve order (Promise.all reorders by resolve time)
      const videoUrls = [];
      for (const lesson of form.lessons) {
        videoUrls.push(await uploadFile(lesson.videoFile));
      }

      const payload = {
        title:       form.title,
        isFree:      form.isFree,
        price:       form.isFree ? 0 : parseFloat(form.price) || 0,
        level:       form.level,
        categoryId:  form.categoryId,
        thumbnailUrl,
        // lessons as an ordered array — backend now stores List<Lesson>
        lessons: form.lessons.map((l, i) => ({
          lessonId: l.lessonId,
          title:    l.title,
          duration: parseInt(l.duration) || 0,
          mediaUrl: videoUrls[i],
          order:    i,          // explicit order index as safety net
        })),
        quizzes: [],
      };

      await api.post("/courses", payload);

      const msg = form.isFree
        ? "Free course published successfully! 🎉"
        : "Paid course submitted for admin review.";
      onSuccess?.("success", msg);
      onClose();
    } catch (err) {
      const msg = err?.response?.data || "Failed to submit course.";
      onSuccess?.("error", msg);
    } finally {
      setLoading(false);
    }
  };

  // ── Stripe warning banner ─────────────────────────────────────
  const renderStripeBanner = () => {
    if (form.isFree) return null;
    if (stripeLoading) return (
      <div className="acf-stripe-banner loading">
        <span className="acf-banner-spinner" /> Checking Stripe account…
      </div>
    );
    if (!stripeStatus || !stripeStatus.hasAccount) return (
      <div className="acf-stripe-banner warn">
        <svg width="16" height="16" viewBox="0 0 24 24" fill="none" stroke="currentColor" strokeWidth="2" strokeLinecap="round"><circle cx="12" cy="12" r="10"/><line x1="12" y1="8" x2="12" y2="12"/><line x1="12" y1="16" x2="12.01" y2="16"/></svg>
        You need to <strong>connect a Stripe account</strong> before creating paid courses.
        Go to <em>Payments → Connect Stripe</em> first.
      </div>
    );
    if (!stripeStatus.chargesEnabled) return (
      <div className="acf-stripe-banner warn">
        <svg width="16" height="16" viewBox="0 0 24 24" fill="none" stroke="currentColor" strokeWidth="2" strokeLinecap="round"><circle cx="12" cy="12" r="10"/><line x1="12" y1="8" x2="12" y2="12"/><line x1="12" y1="16" x2="12.01" y2="16"/></svg>
        Your Stripe account setup is <strong>incomplete</strong>. Finish onboarding to create paid courses.
      </div>
    );
    return (
      <div className="acf-stripe-banner ok">
        <svg width="16" height="16" viewBox="0 0 24 24" fill="none" stroke="currentColor" strokeWidth="2" strokeLinecap="round"><polyline points="20 6 9 17 4 12"/></svg>
        Stripe account <strong>connected</strong> — payments are active.
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
            <p className="acf-subtitle">Fill in the details below — your course will be reviewed before going live.</p>
          </div>
          <button className="acf-close" onClick={onClose} aria-label="Close">
            <svg width="18" height="18" viewBox="0 0 24 24" fill="none" stroke="currentColor" strokeWidth="2.5" strokeLinecap="round">
              <line x1="18" y1="6" x2="6" y2="18"/><line x1="6" y1="6" x2="18" y2="18"/>
            </svg>
          </button>
        </div>

        {/* ── Body ── */}
        <form className="acf-body" onSubmit={handleSubmit}>

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
              <button
                type="button"
                className={`acf-pricing-tab ${!form.isFree ? "active" : ""}`}
                onClick={() => handleField("isFree", false)}
              >
                <svg width="16" height="16" viewBox="0 0 24 24" fill="none" stroke="currentColor" strokeWidth="2" strokeLinecap="round"><line x1="12" y1="1" x2="12" y2="23"/><path d="M17 5H9.5a3.5 3.5 0 000 7h5a3.5 3.5 0 010 7H6"/></svg>
                Paid
              </button>
            </div>

            {/* Stripe banner */}
            {renderStripeBanner()}

            {!form.isFree && (
              <div className="acf-field" style={{ marginTop: 14 }}>
                <label className="acf-label">Price (USD) <span className="acf-req">*</span></label>
                <div className="acf-price-wrap">
                  <span className="acf-currency">$</span>
                  <input
                    className="acf-input acf-price-input"
                    type="number" min="0.50" step="0.01"
                    placeholder="49.99"
                    value={form.price}
                    onChange={(e) => handleField("price", e.target.value)}
                    required
                  />
                </div>
                <p className="acf-field-hint">You keep 80% · Platform retains 20%</p>
              </div>
            )}

            {form.isFree && (
              <p className="acf-free-note">
                <svg width="14" height="14" viewBox="0 0 24 24" fill="none" stroke="currentColor" strokeWidth="2" strokeLinecap="round"><polyline points="20 6 9 17 4 12"/></svg>
                Free courses are published immediately — no admin review required.
              </p>
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

        </form>

        {/* ── Footer ── */}
        <div className="acf-footer">
          <div className="acf-footer-meta">
            {!form.isFree
              ? <span>Paid · requires admin approval</span>
              : <span>Free · publishes immediately</span>}
          </div>
          <div className="acf-footer-actions">
            <button className="acf-btn-cancel" type="button" onClick={onClose}>Cancel</button>
            <button
              className="acf-btn-submit"
              type="button"
              disabled={loading || stripeBlocked || stripeLoading}
              onClick={handleSubmit}
            >
              {loading ? (
                <><span className="acf-spin" /> Uploading…</>
              ) : (
                form.isFree ? "Publish Course" : "Submit for Review"
              )}
            </button>
          </div>
        </div>

      </div>
    </div>
  );
}