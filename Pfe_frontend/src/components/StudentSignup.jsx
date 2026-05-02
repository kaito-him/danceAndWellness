import { useState, useEffect, useRef } from "react";
import { useNavigate, Link } from "react-router-dom";
import Navbar from "./Navbar";
import api from "./services/api";
import "../styles/StudentSignup.css";

const LEVELS = [
  {
    id: "BEGINNER",
    title: "Beginner",
    desc: "I can follow a beat, I got a couple moves",
  },
  {
    id: "INTERMEDIATE",
    title: "Intermediate",
    desc: "I'm comfortable learning routines",
  },
  {
    id: "ADVANCED",
    title: "Advanced",
    desc: "I'm a trained dancer",
  },
];

const STEPS = [
  { num: "01", label: "Account", subtitle: "Your identity on the platform" },
  { num: "02", label: "Styles", subtitle: "Pick exactly 3 interests" },
  { num: "03", label: "Level", subtitle: "Your dance experience" },
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

const StudentSignup = () => {
  const navigate = useNavigate();
  const panelRef = useRef(null);

  const [step, setStep] = useState(0); // 0-indexed to match InstructorSignup style
  const [dir, setDir] = useState(1);
  const [categories, setCategories] = useState([]);

  // Form State
  const [form, setForm] = useState({
    username: "",
    email: "",
    password: "",
    confirmPassword: "",
  });
  const [selectedCategories, setSelectedCategories] = useState([]);
  const [skillLevel, setSkillLevel] = useState("");

  const [showPw, setShowPw] = useState(false);
  const [showConfirm, setShowConfirm] = useState(false);
  const [errors, setErrors] = useState({});
  const [loading, setLoading] = useState(false);

  useEffect(() => {
    api.get("/categories")
      .then(res => setCategories(res.data || []))
      .catch(err => console.error("Failed to load categories", err));
  }, []);

  const handleChange = (e) => {
    const { name, value } = e.target;
    setForm(prev => ({ ...prev, [name]: value }));
    if (errors[name]) setErrors(prev => ({ ...prev, [name]: "" }));
  };

  const validateStep = (s) => {
    const e = {};
    if (s === 0) {
      const passwordRegex = /^(?=.*[a-z])(?=.*[A-Z])(?=.*\d).{8,}$/;
      if (!form.username.trim()) e.username = "Username is required";
      if (!form.email.trim()) e.email = "Email is required";
      else if (!/\S+@\S+\.\S+/.test(form.email)) e.email = "Enter a valid email";
      if (!passwordRegex.test(form.password))
        e.password = "Min. 8 characters with uppercase, lowercase, and a number";
      if (form.password !== form.confirmPassword)
        e.confirmPassword = "Passwords do not match";
    }
    if (s === 1) {
      if (selectedCategories.length !== 3) {
        e.general = "Please select exactly 3 styles";
      }
    }
    if (s === 2) {
      if (!skillLevel) {
        e.general = "Please select your skill level";
      }
    }
    setErrors(e);
    return Object.keys(e).length === 0;
  };

  const nextStep = () => {
    if (!validateStep(step)) return;
    setDir(1);
    setStep(prev => prev + 1);
    panelRef.current?.scrollTo({ top: 0, behavior: "smooth" });
  };

  const prevStep = () => {
    setDir(-1);
    setStep(prev => prev - 1);
    setErrors({});
    panelRef.current?.scrollTo({ top: 0, behavior: "smooth" });
  };

  const toggleCategory = (id) => {
    if (selectedCategories.includes(id)) {
      setSelectedCategories(selectedCategories.filter(c => c !== id));
      setErrors({});
    } else {
      if (selectedCategories.length < 3) {
        setSelectedCategories([...selectedCategories, id]);
        setErrors({});
      }
    }
  };

  const handleSubmit = async () => {
    if (!validateStep(2)) return;

    setLoading(true);
    setErrors({});
    try {
      await api.post("/auth/register/student", {
        username: form.username,
        email: form.email,
        password: form.password,
        categoryIds: selectedCategories,
        skillLevel: skillLevel,
      });
      navigate("/student", { state: { showWelcomeModal: true } });
    } catch (err) {
      const msg = err.response?.data || "Something went wrong.";
      setErrors({ general: msg });
    } finally {
      setLoading(false);
    }
  };

  return (
    <>
      <Navbar />
      <div className="is-page-student">
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
                <h2 className="is-step__title">Start your <em>journey</em></h2>
                <p className="is-step__desc">Join thousands of students learning dance and wellness.</p>

                <Field label="Username *" error={errors.username}>
                  <input className="is-input" name="username" value={form.username} onChange={handleChange} placeholder="your_handle" />
                </Field>

                <Field label="Email *" error={errors.email}>
                  <input className="is-input" name="email" type="email" value={form.email} onChange={handleChange} placeholder="you@example.com" />
                </Field>

                <div className="is-row">
                  <Field label="Password *" error={errors.password}>
                    <div className="is-pw">
                      <input className="is-input" name="password" type={showPw ? "text" : "password"} value={form.password} onChange={handleChange} placeholder="Min. 8 characters" />
                      <button type="button" className="is-pw__toggle" onClick={() => setShowPw(v => !v)}>{showPw ? "Hide" : "Show"}</button>
                    </div>
                  </Field>

                  <Field label="Confirm Password *" error={errors.confirmPassword}>
                    <div className="is-pw">
                      <input className="is-input" name="confirmPassword" type={showConfirm ? "text" : "password"} value={form.confirmPassword} onChange={handleChange} placeholder="Repeat password" />
                      <button type="button" className="is-pw__toggle" onClick={() => setShowConfirm(v => !v)}>{showConfirm ? "Hide" : "Show"}</button>
                    </div>
                  </Field>
                </div>
              </div>
            )}

            {/* ── Step 1: Styles ── */}
            {step === 1 && (
              <div className="is-step__body">
                <h2 className="is-step__title">Select your <em>styles</em></h2>
                <p className="is-step__desc">Pick exactly 3 styles you're interested in. ({selectedCategories.length}/3)</p>

                <div className="is-cat-grid">
                  {categories.map((cat) => {
                    // FIX: Using cat.id instead of cat.categoryId to resolve picking problem
                    const categoryId = cat.id || cat.categoryId;
                    const isSelected = selectedCategories.includes(categoryId);
                    return (
                      <div
                        key={categoryId}
                        className={`is-cat-card ${isSelected ? "is-cat-card--selected" : ""}`}
                        onClick={() => toggleCategory(categoryId)}
                      >
                        <div className="is-cat-img-wrap">
                          <img
                            src={cat.icon ? `http://localhost:8080${cat.icon}` : "/placeholder.jpg"}
                            alt={cat.name}
                            className="is-cat-img"
                          />
                          {isSelected && <div className="is-cat-overlay">✓</div>}
                        </div>
                        <span className="is-cat-name">{cat.name}</span>
                      </div>
                    );
                  })}
                </div>
                {errors.general && <div className="is-server-error">⚠ {errors.general}</div>}
              </div>
            )}

            {/* ── Step 2: Level ── */}
            {step === 2 && (
              <div className="is-step__body">
                <h2 className="is-step__title">What level are you <em>right now?</em></h2>
                <p className="is-step__desc">Help us personalize your learning experience.</p>

                <div className="is-lvl-list">
                  {LEVELS.map((lvl) => (
                    <div
                      key={lvl.id}
                      className={`is-lvl-card ${skillLevel === lvl.id ? "is-lvl-card--selected" : ""}`}
                      onClick={() => {
                        setSkillLevel(lvl.id);
                        setErrors({});
                      }}
                    >
                      <h4>{lvl.title}</h4>
                      <p>{lvl.desc}</p>
                    </div>
                  ))}
                </div>
                {errors.general && <div className="is-server-error">⚠ {errors.general}</div>}
              </div>
            )}

          </div>

          {/* ── Navigation ── */}
          <div className="is-nav">
            {step > 0 ? (
              <button type="button" className="is-btn is-btn--ghost" onClick={prevStep}>← Back</button>
            ) : (
              <Link to="/signup" className="is-btn is-btn--ghost">← Cancel</Link>
            )}

            {step < STEPS.length - 1 ? (
              <button type="button" className="is-btn is-btn--primary" onClick={nextStep}>
                Continue <span className="is-btn__arrow">→</span>
              </button>
            ) : (
              <button type="button" className="is-btn is-btn--gold" onClick={handleSubmit} disabled={loading}>
                {loading ? "Creating account…" : "Complete Sign Up"}
              </button>
            )}
          </div>

          <p className="is-foot">
            Want to teach instead? <Link to="/signup/instructor">Apply as Instructor</Link>
          </p>
        </div>
      </div>
    </>
  );
};

export default StudentSignup;