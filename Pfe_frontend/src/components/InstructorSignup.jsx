import { useState, useEffect } from "react";
import { Link } from "react-router-dom";
import Navbar from "./Navbar";
import api from "./services/api";
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

// ── Success screen ────────────────────────────────────────────────────────────
function SuccessScreen({ email }) {
  return (
    <>
      <Navbar />
      <div className="instructor-page">
        <div className="instructor-container">
          <div className="instructor-card success-card">
            <div className="success-icon">✉️</div>
            <h2>Application <em>submitted!</em></h2>
            <p className="subtitle">
              A confirmation email has been sent to <strong>{email}</strong>.
            </p>
            <div className="review-inline">
              Our admin team will review your application and get back to you
              within <strong>3 to 5 days</strong>.
            </div>
            <Link
              to="/"
              className="submit-btn"
              style={{ display: "block", textAlign: "center", textDecoration: "none", marginTop: "1.5rem" }}
            >
              Back to home
            </Link>
          </div>
        </div>
      </div>
    </>
  );
}

// ── Main component ────────────────────────────────────────────────────────────
export default function InstructorSignup() {
  const [form, setForm] = useState(INITIAL_FORM);
  const [file, setFile] = useState(null);
  const [showPw, setShowPw] = useState(false);
  const [showConfirm, setShowConfirm] = useState(false);
  const [errors, setErrors] = useState({});
  const [submitting, setSubmitting] = useState(false);
  const [serverError, setServerError] = useState("");
  const [submitted, setSubmitted] = useState(false);
  const [categories, setCategories] = useState([]);

  // ── Fetch categories from API ───────────────────────────────────────────────
  useEffect(() => {
    api.get("/categories")
      .then((res) => setCategories(res.data))
      .catch(() => setCategories([]));
  }, []);

  const isOther = form.specialization === "Other";

  const set = (e) => {
    const { name, value } = e.target;
    setForm((f) => {
      const next = { ...f, [name]: value };
      // Clear the custom field if user switches away from Other
      if (name === "specialization" && value !== "Other") {
        next.otherSpecialization = "";
      }
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

  const validate = () => {
    const e = {};
    if (!form.username.trim()) e.username = "Username is required";
    if (!form.email.trim()) e.email = "Email is required";
    else if (!/\S+@\S+\.\S+/.test(form.email)) e.email = "Enter a valid email";
    if (form.password.length < 8) e.password = "Minimum 8 characters";
    if (form.password !== form.confirmPassword) e.confirmPassword = "Passwords do not match";
    if (!file) e.certification = "Certification document is required";
    if (!form.yearsOfExperience) e.yearsOfExperience = "Select your experience";
    if (!form.specialization) e.specialization = "Select a specialization";
    if (isOther && !form.otherSpecialization.trim())
      e.otherSpecialization = "Please specify your specialization";
    if (form.bio.trim().length < 10) e.bio = `${10 - form.bio.trim().length} more characters needed`;
    setErrors(e);
    return Object.keys(e).length === 0;
  };

  const handleSubmit = async (e) => {
    e.preventDefault();
    setServerError("");
    if (!validate()) return;

    const formData = new FormData();
    const { confirmPassword, otherSpecialization, ...payload } = form;

    // Send the resolved specialization value
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
      const msg = err.response?.data || "Something went wrong. Please try again.";
      setServerError(msg);
    } finally {
      setSubmitting(false);
    }
  };

  if (submitted) return <SuccessScreen email={form.email} />;

  const bioLen = form.bio.trim().length;

  return (
    <>
      <Navbar />
      <div className="instructor-page">
        <div className="instructor-container">

          <Link to="/signup" className="back-btn">← Back to role selection</Link>

          <div className="instructor-card">
            <h2>Apply as an <em>instructor</em></h2>
            <p className="subtitle">
              Share your expertise with thousands of students across the platform.
            </p>

            <form onSubmit={handleSubmit} noValidate>

              {/* ── Account ─────────────────────────────────────────────────── */}
              <div className="form-section">
                <h3>Account</h3>

                <div className="input-row">
                  <div className="input-group">
                    <label>Username *</label>
                    <input name="username" value={form.username.trim()} onChange={set} placeholder="your_handle" />
                    <p className="error">{errors.username}</p>
                  </div>
                  <div className="input-group">
                    <label>Email *</label>
                    <input name="email" type="email" value={form.email} onChange={set} placeholder="you@example.com" />
                    <p className="error">{errors.email}</p>
                  </div>
                </div>

                <div className="input-row">
                  <div className="input-group">
                    <label>Password *</label>
                    <div className="password-field">
                      <input
                        name="password"
                        type={showPw ? "text" : "password"}
                        value={form.password}
                        onChange={set}
                        placeholder="Min. 8 characters"
                      />
                      <button type="button" onClick={() => setShowPw((v) => !v)}>
                        {showPw ? "Hide" : "Show"}
                      </button>
                    </div>
                    <p className="error">{errors.password}</p>
                  </div>

                  <div className="input-group">
                    <label>Confirm Password *</label>
                    <div className="password-field">
                      <input
                        name="confirmPassword"
                        type={showConfirm ? "text" : "password"}
                        value={form.confirmPassword}
                        onChange={set}
                        placeholder="Repeat password"
                      />
                      <button type="button" onClick={() => setShowConfirm((v) => !v)}>
                        {showConfirm ? "Hide" : "Show"}
                      </button>
                    </div>
                    <p className="error">{errors.confirmPassword}</p>
                  </div>
                </div>
              </div>

              {/* ── Credentials ─────────────────────────────────────────────── */}
              <div className="form-section">
                <h3>Credentials</h3>

                <div className="input-group">
                  <label>Certification Document *</label>
                  <div className="upload-box">
                    {file ? (
                      <div className="file-row">
                        <span>✓ {file.name}</span>
                        <button type="button" onClick={() => setFile(null)}>Remove</button>
                      </div>
                    ) : (
                      <>
                        <label className="upload-label">
                          Click to upload
                          <input
                            type="file"
                            accept=".pdf,.doc,.docx,.jpg,.jpeg,.png"
                            onChange={(e) => handleFile(e.target.files[0])}
                            hidden
                          />
                        </label>
                        <p className="file-note">PDF · DOC · DOCX · JPG · PNG · Max 5 MB</p>
                      </>
                    )}
                  </div>
                  <p className="error">{errors.certification}</p>
                </div>

                <div className="input-row">
                  <div className="input-group">
                    <label>Years of Experience *</label>
                    <select name="yearsOfExperience" value={form.yearsOfExperience} onChange={set}>
                      <option value="">Select range</option>
                      {EXPERIENCE_OPTIONS.map((o) => <option key={o}>{o}</option>)}
                    </select>
                    <p className="error">{errors.yearsOfExperience}</p>
                  </div>

                  <div className="input-group">
                    <label>Specialization *</label>
                    <select name="specialization" value={form.specialization} onChange={set}>
                      <option value="">Select discipline</option>
                      {categories.map((cat) => (
                        <option key={cat.id ?? cat.name} value={cat.name}>
                          {cat.name}
                        </option>
                      ))}
                      <option value="Other">Other</option>
                    </select>
                    <p className="error">{errors.specialization}</p>
                  </div>
                </div>

                {/* ── Other specialization input ─────────────────────────────── */}
                {isOther && (
                  <div className="input-group">
                    <label>specify your specialization *</label>
                    <input
                      name="otherSpecialization"
                      value={form.otherSpecialization}
                      onChange={set}
                      placeholder="Describe your specialization…"
                    />
                    <p className="error">{errors.otherSpecialization}</p>
                  </div>
                )}

                <div className="input-group">
                  <label>Studio / Institution</label>
                  <input
                    name="studioName"
                    value={form.studioName}
                    onChange={set}
                    placeholder="Optional — leave blank if self-employed"
                  />
                </div>
              </div>

              {/* ── Profile ─────────────────────────────────────────────────── */}
              <div className="form-section">
                <h3>Profile</h3>

                <div className="input-group">
                  <label>Professional Bio *</label>
                  <textarea
                    name="bio"
                    rows={4}
                    value={form.bio}
                    onChange={set}
                    placeholder="Describe your teaching philosophy, experience, and style…"
                  />
                  <div className="bio-info">
                    <span>Minimum 10 characters</span>
                    <span className={bioLen >= 10 ? "ok" : ""}>{bioLen}</span>
                  </div>
                  <p className="error">{errors.bio}</p>
                </div>

                <div className="input-row">
                  <div className="input-group">
                    <label>LinkedIn</label>
                    <input name="linkedIn" value={form.linkedIn} onChange={set} placeholder="linkedin.com/in/…" />
                  </div>
                  <div className="input-group">
                    <label>Website</label>
                    <input name="website" value={form.website} onChange={set} placeholder="yoursite.com" />
                  </div>
                </div>
              </div>

              {/* ── Notice ── */}
              <p className="review-inline">
                Your application will be reviewed by our team within{" "}
                <strong>3–5 business days</strong>.
              </p>

              {serverError && (
                <div className="server-error-banner">⚠ {serverError}</div>
              )}

              <button type="submit" className="submit-btn" disabled={submitting}>
                {submitting ? "Submitting…" : "Submit Application"}
              </button>

            </form>
          </div>

          <p className="form-foot">
            Want to learn instead?{" "}
            <Link to="/signup/student">Create a student account</Link>
          </p>

        </div>
      </div>
    </>
  );
}