import { useState, useEffect, useRef } from "react";
import { Link } from "react-router-dom";
import Navbar from "./Navbar";
import api from "./services/api";
import pulpfictionBg from "../assets/pulpfiction.png";
import "../styles/InstructorSignup.css";

const VALID_TYPES = ["application/pdf", "image/jpeg", "image/png"];

const EXPERIENCE_OPTIONS = [
  "Less than 1 year",
  "1–3 years",
  "3–5 years",
  "5–10 years",
  "10+ years",
];

const INITIAL_FORM = {
  username: "",
  email: "",
  password: "",
  confirmPassword: "",
  yearsOfExperience: "",
  specialization: "",
  otherSpecialization: "",
  studioName: "",
  bio: "",
  linkedIn: "",
  website: "",
};

const STEPS = [
  { num: "01", label: "Account",     subtitle: "Your identity on the platform" },
  { num: "02", label: "Credentials", subtitle: "Prove your expertise"          },
  { num: "03", label: "Profile",     subtitle: "Tell your story"               },
];

// ── Field ────────────────────────────────────────────────────────────────────
function Field({ label, error, children }) {
  return (
    <div className={`is-field${error ? " is-field--error" : ""}`}>
      <label className="is-label">{label}</label>
      {children}
      {error && <p className="is-error">{error}</p>}
    </div>
  );
}

// ── Success ───────────────────────────────────────────────────────────────────
function SuccessScreen({ email }) {
  return (
    <>
      <Navbar />
      <div className="is-page">
        <div className="is-panel is-panel--success">
          <div className="is-success">
            <span className="is-success__icon">✉</span>
            <h2 className="is-success__title">Application submitted</h2>
            <p className="is-success__body">
              A confirmation was sent to <strong>{email}</strong>.
              Our team reviews applications within{" "}
              <strong>3–5 business days</strong>.
            </p>
            <Link to="/" className="is-btn is-btn--gold" style={{ marginTop: "2rem", display: "block", textAlign: "center", textDecoration: "none" }}>
              Return home
            </Link>
          </div>
        </div>
      </div>
    </>
  );
}

// ── Main ─────────────────────────────────────────────────────────────────────
export default function InstructorSignup() {
  const [form, setForm]           = useState(INITIAL_FORM);
  const [file, setFile]           = useState(null);
  const [showPw, setShowPw]       = useState(false);
  const [showCp, setShowCp]       = useState(false);
  const [errors, setErrors]       = useState({});
  const [submitting, setSubmitting] = useState(false);
  const [serverError, setServerError] = useState("");
  const [submitted, setSubmitted] = useState(false);
  const [categories, setCategories] = useState([]);
  const [step, setStep]           = useState(0); // 0-indexed
  const [dir, setDir]             = useState(1); // 1 = forward, -1 = back
  const panelRef                  = useRef(null);

  useEffect(() => {
    api.get("/categories")
      .then((r) => setCategories(r.data))
      .catch(() => setCategories([]));
  }, []);

  const isOther = form.specialization === "Other";

  const set = (e) => {
    const { name, value } = e.target;
    setForm((f) => {
      const next = { ...f, [name]: value };
      if (name === "specialization" && value !== "Other") next.otherSpecialization = "";
      return next;
    });
    if (errors[name]) setErrors((err) => ({ ...err, [name]: "" }));
  };

  const handleFile = (selected) => {
    if (!selected) return;
    if (!VALID_TYPES.includes(selected.type)) {
      setErrors((e) => ({ ...e, certification: "Invalid file type (PDF, JPG, PNG)" }));
      return;
    }
    if (selected.size > 5 * 1024 * 1024) {
      setErrors((e) => ({ ...e, certification: "File must be under 5 MB" }));
      return;
    }
    setFile(selected);
    setErrors((e) => ({ ...e, certification: "" }));
  };

  // Per-step validation
  const validateStep = (s) => {
    const e = {};
    if (s === 0) {
      if (!form.username.trim()) e.username = "Username is required";
      if (!form.email.trim()) e.email = "Email is required";
      else if (!/\S+@\S+\.\S+/.test(form.email)) e.email = "Enter a valid email";
      if (form.password.length < 8) e.password = "Minimum 8 characters";
      if (form.password !== form.confirmPassword) e.confirmPassword = "Passwords do not match";
    }
    if (s === 1) {
      if (!file) e.certification = "Certification document is required";
      if (!form.yearsOfExperience) e.yearsOfExperience = "Select your experience";
      if (!form.specialization) e.specialization = "Select a specialization";
      if (isOther && !form.otherSpecialization.trim()) e.otherSpecialization = "Please specify";
    }
    if (s === 2) {
      if (form.bio.trim().length < 10) e.bio = `${10 - form.bio.trim().length} more characters needed`;
    }
    setErrors(e);
    return Object.keys(e).length === 0;
  };

  const goNext = () => {
    if (!validateStep(step)) return;
    setDir(1);
    setStep((s) => s + 1);
    panelRef.current?.scrollTo({ top: 0, behavior: "smooth" });
  };

  const goBack = () => {
    setDir(-1);
    setStep((s) => s - 1);
    panelRef.current?.scrollTo({ top: 0, behavior: "smooth" });
  };

  const handleSubmit = async () => {
    if (!validateStep(2)) return;
    setServerError("");
    const formData = new FormData();
    const { confirmPassword, otherSpecialization, ...payload } = form;
    payload.specialization = isOther ? otherSpecialization.trim() : form.specialization;
    formData.append("data", new Blob([JSON.stringify(payload)], { type: "application/json" }));
    formData.append("certFile", file);
    setSubmitting(true);
    try {
      await api.post("/auth/register/instructor", formData, {
        headers: { "Content-Type": "multipart/form-data" },
      });
      setSubmitted(true);
    } catch (err) {
      setServerError(err.response?.data || "Something went wrong. Please try again.");
    } finally {
      setSubmitting(false);
    }
  };

  if (submitted) return <SuccessScreen email={form.email} />;

  const bioLen = form.bio.trim().length;
  const progress = ((step) / (STEPS.length - 1)) * 100;

  return (
    <>
      <Navbar />
      <div className="is-page">

        {/* ── Form panel ── */}
        <div className="is-panel" ref={panelRef}>

          {/* Progress bar */}
          <div className="is-progress">
            <div className="is-progress__track">
              <div className="is-progress__fill" style={{ width: `${((step + 1) / STEPS.length) * 100}%` }} />
            </div>
            <span className="is-progress__label">{step + 1} / {STEPS.length}</span>
          </div>

          <div className={`is-step is-step--dir${dir > 0 ? "fwd" : "bck"}`} key={step}>

            {/* ── Step 0: Account ── */}
            {step === 0 && (
              <div className="is-step__body">
                <h2 className="is-step__title">Create your account</h2>
                <p className="is-step__desc">This will be your identity on the platform.</p>

                <Field label="Username *" error={errors.username}>
                  <input className="is-input" name="username" value={form.username} onChange={set} placeholder="your_handle" />
                </Field>

                <Field label="Email *" error={errors.email}>
                  <input className="is-input" name="email" type="email" value={form.email} onChange={set} placeholder="you@example.com" />
                </Field>

                <div className="is-row">
                  <Field label="Password *" error={errors.password}>
                    <div className="is-pw">
                      <input className="is-input" name="password" type={showPw ? "text" : "password"} value={form.password} onChange={set} placeholder="Min. 8 characters" />
                      <button type="button" className="is-pw__toggle" onClick={() => setShowPw(v => !v)}>{showPw ? "Hide" : "Show"}</button>
                    </div>
                  </Field>

                  <Field label="Confirm Password *" error={errors.confirmPassword}>
                    <div className="is-pw">
                      <input className="is-input" name="confirmPassword" type={showCp ? "text" : "password"} value={form.confirmPassword} onChange={set} placeholder="Repeat password" />
                      <button type="button" className="is-pw__toggle" onClick={() => setShowCp(v => !v)}>{showCp ? "Hide" : "Show"}</button>
                    </div>
                  </Field>
                </div>
              </div>
            )}

            {/* ── Step 1: Credentials ── */}
            {step === 1 && (
              <div className="is-step__body">
                <h2 className="is-step__title">Your credentials</h2>
                <p className="is-step__desc">Help us verify your expertise before you start teaching.</p>

                <Field label="Certification Document *" error={errors.certification}>
                  <div className={`is-upload${file ? " is-upload--done" : ""}`}>
                    {file ? (
                      <div className="is-upload__file">
                        <div className="is-upload__icon">✓</div>
                        <span className="is-upload__name">{file.name}</span>
                        <button type="button" className="is-upload__remove" onClick={() => setFile(null)}>Remove</button>
                      </div>
                    ) : (
                      <label className="is-upload__label">
                        <input type="file" accept=".pdf,.jpg,.jpeg,.png" onChange={(e) => handleFile(e.target.files[0])} hidden />
                        <span className="is-upload__icon-big">↑</span>
                        <span className="is-upload__cta">Click to upload</span>
                        <span className="is-upload__hint">PDF · JPG · PNG · Max 5 MB</span>
                      </label>
                    )}
                  </div>
                </Field>

                <div className="is-row">
                  <Field label="Years of Experience *" error={errors.yearsOfExperience}>
                    <select className="is-input is-input--select" name="yearsOfExperience" value={form.yearsOfExperience} onChange={set}>
                      <option value="">Select range</option>
                      {EXPERIENCE_OPTIONS.map((o) => <option key={o}>{o}</option>)}
                    </select>
                  </Field>

                  <Field label="Specialization *" error={errors.specialization}>
                    <select className="is-input is-input--select" name="specialization" value={form.specialization} onChange={set}>
                      <option value="">Select discipline</option>
                      {categories.map((cat) => (
                        <option key={cat.id ?? cat.name} value={cat.name}>{cat.name}</option>
                      ))}
                      <option value="Other">Other</option>
                    </select>
                  </Field>
                </div>

                {isOther && (
                  <Field label="Specify your specialization *" error={errors.otherSpecialization}>
                    <input className="is-input" name="otherSpecialization" value={form.otherSpecialization} onChange={set} placeholder="Describe your discipline…" />
                  </Field>
                )}

                <Field label="Studio / Institution">
                  <input className="is-input" name="studioName" value={form.studioName} onChange={set} placeholder="Optional — leave blank if self-employed" />
                </Field>
              </div>
            )}

            {/* ── Step 2: Profile ── */}
            {step === 2 && (
              <div className="is-step__body">
                <h2 className="is-step__title">Tell your story</h2>
                <p className="is-step__desc">Students choose instructors based on who they are, not just what they teach.</p>

                <Field label="Professional Bio *" error={errors.bio}>
                  <textarea className="is-input is-input--textarea" name="bio" rows={5} value={form.bio} onChange={set} placeholder="Teaching philosophy, experience, style…" />
                  <div className="is-bio-counter">
                    <span>Minimum 10 characters</span>
                    <span className={bioLen >= 10 ? "is-bio-counter__ok" : ""}>{bioLen}</span>
                  </div>
                </Field>

                <div className="is-row">
                  <Field label="LinkedIn">
                    <input className="is-input" name="linkedIn" value={form.linkedIn} onChange={set} placeholder="linkedin.com/in/…" />
                  </Field>
                  <Field label="Website">
                    <input className="is-input" name="website" value={form.website} onChange={set} placeholder="yoursite.com" />
                  </Field>
                </div>

                <div className="is-notice">
                  Applications are reviewed within <strong>3–5 business days</strong>.
                </div>

                {serverError && (
                  <div className="is-server-error">⚠ {serverError}</div>
                )}
              </div>
            )}

          </div>

          {/* ── Navigation ── */}
          <div className="is-nav">
            {step > 0 ? (
              <button type="button" className="is-btn is-btn--ghost" onClick={goBack}>← Back</button>
            ) : (
              <Link to="/signup" className="is-btn is-btn--ghost">← Cancel</Link>
            )}

            {step < STEPS.length - 1 ? (
              <button type="button" className="is-btn is-btn--primary" onClick={goNext}>
                Continue <span className="is-btn__arrow">→</span>
              </button>
            ) : (
              <button type="button" className="is-btn is-btn--gold" onClick={handleSubmit} disabled={submitting}>
                {submitting ? "Submitting…" : "Submit Application"}
              </button>
            )}
          </div>

          <p className="is-foot">
            Want to learn instead? <Link to="/signup/student">Create a student account</Link>
          </p>
        </div>

      </div>
    </>
  );
}