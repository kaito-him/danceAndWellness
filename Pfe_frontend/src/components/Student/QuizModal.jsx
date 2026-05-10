import React, { useState } from "react";
import { FiX, FiCheckCircle, FiXCircle, FiAward, FiAlertCircle } from "react-icons/fi";
import api from "../../components/services/api";

/* ─────────────────────────────────────────────────────────────
   QuizModal — supports multiple correct answers per question
   Props:
     quiz            – quiz object from course.quizzes
     courseId        – string
     attempt         – existing QuizAttempt | null
     onClose         – () => void
     onSubmitted     – (attempt) => void
   ───────────────────────────────────────────────────────────── */
export default function QuizModal({ quiz, courseId, attempt: existingAttempt, onClose, onSubmitted }) {
  const questions = quiz.questions ? [...quiz.questions] : [];

  // selected: questionId → Set of chosen option indices
  const [selected, setSelected] = useState(() => {
    const init = {};
    questions.forEach(q => { init[q.questionId] = new Set(); });
    return init;
  });

  const [submitting, setSubmitting]   = useState(false);
  const [error, setError]             = useState("");
  const [result, setResult]           = useState(existingAttempt || null);
  const [showConfirm, setShowConfirm] = useState(false);

  const isReview = !!result;

  // Toggle a checkbox
  const handleToggle = (questionId, optIdx) => {
    if (isReview) return;
    setSelected(prev => {
      const next = new Set(prev[questionId]);
      next.has(optIdx) ? next.delete(optIdx) : next.add(optIdx);
      return { ...prev, [questionId]: next };
    });
    setError("");
  };

  // Convert Sets → plain arrays for the API
  const buildAnswersPayload = () => {
    const payload = {};
    questions.forEach(q => {
      payload[q.questionId] = [...selected[q.questionId]];
    });
    return payload;
  };

  const answeredCount = questions.filter(q => selected[q.questionId]?.size > 0).length;

  const handleSubmit = async () => {
    setShowConfirm(false);
    setSubmitting(true);
    setError("");
    try {
      const res = await api.post("/quizzes/submit", {
        courseId,
        quizId: quiz.quizId,
        answers: buildAnswersPayload(),
      });
      setResult(res.data);
      onSubmitted(res.data);
    } catch (err) {
      const status = err?.response?.status;
      if (status === 409) setError("You have already taken this quiz.");
      else setError(err?.response?.data || "Failed to submit. Please try again.");
    } finally {
      setSubmitting(false);
    }
  };

  const scoreColor = result
    ? result.score >= 80 ? "#22783c"
    : result.score >= 50 ? "#b89c4d"
    : "#c0392b"
    : "#b89c4d";

  return (
    <>
      {/* ── Main modal ── */}
      <div
        style={{
          position: "fixed", inset: 0, zIndex: 4000,
          background: "rgba(15,10,5,0.6)", backdropFilter: "blur(4px)",
          display: "flex", alignItems: "center", justifyContent: "center",
          padding: "20px",
        }}
        onClick={(e) => e.target === e.currentTarget && !showConfirm && onClose()}
      >
        <div style={{
          background: "#fff", borderRadius: 20, width: "100%", maxWidth: 700,
          maxHeight: "90vh", display: "flex", flexDirection: "column",
          boxShadow: "0 24px 60px rgba(0,0,0,0.2)",
          border: "1px solid #e8e4d8", overflow: "hidden",
          animation: "qm-up 0.25s ease",
        }}>
          <style>{`
            @keyframes qm-up {
              from { opacity:0; transform:translateY(16px); }
              to   { opacity:1; transform:translateY(0); }
            }
            .qm-checkbox {
              width: 18px; height: 18px; border-radius: 5px;
              border: 2px solid #d0ccc4; background: #fff;
              display: flex; align-items: center; justify-content: center;
              flex-shrink: 0; transition: all 0.15s; cursor: pointer;
            }
            .qm-checkbox.checked {
              background: #b89c4d; border-color: #b89c4d;
            }
            .qm-checkbox.correct-checked { background: #27ae60; border-color: #27ae60; }
            .qm-checkbox.wrong-checked   { background: #c0392b; border-color: #c0392b; }
            .qm-checkbox.correct-unchecked { border-color: #27ae60; }
          `}</style>

          {/* Header */}
          <div style={{
            padding: "20px 24px 16px", borderBottom: "1px solid #e8e4d8",
            display: "flex", alignItems: "flex-start", justifyContent: "space-between",
            background: "linear-gradient(135deg,#fdf9ef,#fff)", flexShrink: 0,
          }}>
            <div>
              <p style={{ fontSize: 11, fontWeight: 700, textTransform: "uppercase",
                letterSpacing: "0.1em", color: "#b89c4d", margin: "0 0 4px" }}>
                Knowledge Check
              </p>
              <h2 style={{ fontFamily: "'Playfair Display',serif", fontSize: 20,
                fontWeight: 700, color: "#1a1a1a", margin: 0 }}>
                {quiz.title}
              </h2>
              <p style={{ fontSize: 13, color: "#888", margin: "4px 0 0" }}>
                {questions.length} question{questions.length !== 1 ? "s" : ""}
                {" · "}Select all correct answers for each question
                {isReview && " · Already completed"}
              </p>
            </div>
            <button onClick={onClose} style={{
              background: "none", border: "none", cursor: "pointer",
              color: "#aaa", padding: "4px", borderRadius: 8,
              display: "flex", alignItems: "center", flexShrink: 0,
            }}>
              <FiX size={20} />
            </button>
          </div>

          {/* Score banner */}
          {isReview && (
            <div style={{
              padding: "14px 24px", background: "#fafaf8",
              borderBottom: "1px solid #e8e4d8", flexShrink: 0,
              display: "flex", alignItems: "center", gap: 16,
            }}>
              <div style={{
                width: 52, height: 52, borderRadius: "50%",
                background: `${scoreColor}15`, border: `2px solid ${scoreColor}`,
                display: "flex", alignItems: "center", justifyContent: "center", flexShrink: 0,
              }}>
                <FiAward size={20} style={{ color: scoreColor }} />
              </div>
              <div>
                <p style={{ margin: 0, fontSize: 12, color: "#888" }}>Your Score</p>
                <p style={{ margin: "2px 0 0", fontSize: 26, fontWeight: 700,
                  color: scoreColor, lineHeight: 1 }}>{result.score}%</p>
                <p style={{ margin: "2px 0 0", fontSize: 12, color: "#888" }}>
                  {result.correctCount} / {result.totalQuestions} correct
                </p>
              </div>
              <p style={{ marginLeft: "auto", fontSize: 13, color: "#888" }}>
                {result.score >= 80 ? "🎉 Excellent!" : result.score >= 50 ? "👍 Good effort" : "📚 Keep studying"}
              </p>
            </div>
          )}

          {/* Questions */}
          <div style={{ overflowY: "auto", padding: "20px 24px", flex: 1 }}>
            {questions.map((q, qIdx) => {
              // In review mode, get chosen indices from saved attempt
              const chosenSet = isReview
                ? new Set(result.answers?.[q.questionId] || [])
                : selected[q.questionId];

              const correctIndices = new Set(
                (q.options || []).map((o, i) => o.isCorrect ? i : -1).filter(i => i >= 0)
              );
              const hasMultipleCorrect = correctIndices.size > 1;

              return (
                <div key={q.questionId} style={{
                  marginBottom: 24, padding: "18px 20px",
                  background: "#fafaf8", borderRadius: 14,
                  border: "1px solid #e8e4d8",
                }}>
                  <div style={{ display: "flex", alignItems: "flex-start",
                    justifyContent: "space-between", marginBottom: 12, gap: 8 }}>
                    <p style={{ fontSize: 14, fontWeight: 600, color: "#1a1a1a",
                      margin: 0, lineHeight: 1.5, flex: 1 }}>
                      <span style={{ color: "#b89c4d", marginRight: 6 }}>Q{qIdx + 1}.</span>
                      {q.text}
                    </p>
                    {hasMultipleCorrect && (
                      <span style={{ fontSize: 10, fontWeight: 700, color: "#7a6a3a",
                        background: "#fdf9ef", border: "1px solid #e0d7b8",
                        padding: "2px 8px", borderRadius: 20, flexShrink: 0,
                        whiteSpace: "nowrap" }}>
                        Multiple answers
                      </span>
                    )}
                  </div>

                  <div style={{ display: "flex", flexDirection: "column", gap: 8 }}>
                    {(q.options || []).map((opt, oIdx) => {
                      const isChosen  = chosenSet.has(oIdx);
                      const isCorrect = Boolean(opt.isCorrect);

                      let bg = "#fff", border = "1.5px solid #e8e4d8", color = "#333";
                      let checkboxClass = "qm-checkbox";

                      if (isReview) {
                        if (isCorrect) {
                          bg = "#f0faf4"; border = "1.5px solid #27ae60"; color = "#1a7a40";
                          checkboxClass += isChosen ? " correct-checked" : " correct-unchecked";
                        } else if (isChosen) {
                          bg = "#fdf3f2"; border = "1.5px solid #c0392b"; color = "#c0392b";
                          checkboxClass += " wrong-checked";
                        }
                      } else if (isChosen) {
                        bg = "#fdf9ef"; border = "1.5px solid #b89c4d"; color = "#7a6a3a";
                        checkboxClass += " checked";
                      }

                      return (
                        <button
                          key={oIdx}
                          onClick={() => handleToggle(q.questionId, oIdx)}
                          disabled={isReview}
                          style={{
                            display: "flex", alignItems: "center", gap: 10,
                            padding: "10px 14px", borderRadius: 9,
                            background: bg, border, color,
                            fontSize: 13.5, fontFamily: "inherit",
                            cursor: isReview ? "default" : "pointer",
                            textAlign: "left", transition: "all 0.15s",
                            fontWeight: isChosen || (isReview && isCorrect) ? 600 : 400,
                            width: "100%",
                          }}
                        >
                          {/* Custom checkbox */}
                          <div className={checkboxClass}>
                            {(isChosen || (isReview && isCorrect && isChosen)) && (
                              <svg width="10" height="10" viewBox="0 0 12 12" fill="none">
                                <polyline points="2,6 5,9 10,3" stroke="#fff" strokeWidth="2"
                                  strokeLinecap="round" strokeLinejoin="round"/>
                              </svg>
                            )}
                            {isReview && isCorrect && !isChosen && (
                              <svg width="10" height="10" viewBox="0 0 12 12" fill="none">
                                <polyline points="2,6 5,9 10,3" stroke="#27ae60" strokeWidth="2"
                                  strokeLinecap="round" strokeLinejoin="round"/>
                              </svg>
                            )}
                          </div>

                          {/* Option letter */}
                          <span style={{
                            width: 20, height: 20, borderRadius: "50%", flexShrink: 0,
                            display: "flex", alignItems: "center", justifyContent: "center",
                            fontSize: 10, fontWeight: 700,
                            background: isChosen ? (isReview && !isCorrect ? "#c0392b" : "#b89c4d")
                              : (isReview && isCorrect ? "#27ae60" : "#f0ede5"),
                            color: (isChosen || (isReview && isCorrect)) ? "#fff" : "#888",
                          }}>
                            {String.fromCharCode(65 + oIdx)}
                          </span>

                          <span style={{ flex: 1 }}>{opt.text}</span>

                          {/* Review labels */}
                          {isReview && isCorrect && (
                            <span style={{ fontSize: 10, fontWeight: 700, color: "#27ae60",
                              background: "#f0faf4", padding: "2px 7px", borderRadius: 20,
                              flexShrink: 0, display: "flex", alignItems: "center", gap: 3 }}>
                              <FiCheckCircle size={10} /> Correct
                            </span>
                          )}
                          {isReview && isChosen && !isCorrect && (
                            <span style={{ fontSize: 10, fontWeight: 700, color: "#c0392b",
                              background: "#fdf3f2", padding: "2px 7px", borderRadius: 20,
                              flexShrink: 0, display: "flex", alignItems: "center", gap: 3 }}>
                              <FiXCircle size={10} /> Wrong
                            </span>
                          )}
                        </button>
                      );
                    })}
                  </div>

                  {/* Per-question result */}
                  {isReview && (
                    <p style={{ margin: "10px 0 0", fontSize: 12, fontWeight: 600,
                      color: result.questionResults?.[q.questionId] ? "#27ae60" : "#c0392b" }}>
                      {result.questionResults?.[q.questionId]
                        ? "✓ Fully correct"
                        : chosenSet.size === 0
                          ? "✗ Not answered"
                          : "✗ Incorrect or incomplete"}
                    </p>
                  )}
                </div>
              );
            })}
          </div>

          {/* Footer */}
          <div style={{
            padding: "14px 24px 18px", borderTop: "1px solid #e8e4d8",
            background: "#fafaf8", flexShrink: 0,
            display: "flex", alignItems: "center", justifyContent: "space-between", gap: 12,
          }}>
            {error ? (
              <p style={{ margin: 0, fontSize: 13, color: "#c0392b", flex: 1 }}>{error}</p>
            ) : isReview ? (
              <p style={{ margin: 0, fontSize: 13, color: "#888", flex: 1 }}>
                Results are saved permanently.
              </p>
            ) : (
              <p style={{ margin: 0, fontSize: 13, color: "#888", flex: 1 }}>
                {answeredCount} / {questions.length} questions answered
              </p>
            )}
            <div style={{ display: "flex", gap: 10, flexShrink: 0 }}>
              <button onClick={onClose} style={{
                padding: "10px 20px", borderRadius: 9, border: "1.5px solid #e8e4d8",
                background: "#fff", color: "#666", fontSize: 13.5, fontFamily: "inherit",
                cursor: "pointer", fontWeight: 500,
              }}>
                {isReview ? "Close" : "Cancel"}
              </button>
              {!isReview && (
                <button
                  onClick={() => setShowConfirm(true)}
                  disabled={submitting || answeredCount === 0}
                  style={{
                    padding: "10px 24px", borderRadius: 9, border: "none",
                    background: (submitting || answeredCount === 0) ? "#ccc" : "#b89c4d",
                    color: "#fff", fontSize: 13.5, fontFamily: "inherit", fontWeight: 600,
                    cursor: (submitting || answeredCount === 0) ? "not-allowed" : "pointer",
                    boxShadow: (submitting || answeredCount === 0) ? "none" : "0 3px 12px rgba(184,156,77,0.3)",
                  }}>
                  {submitting ? "Submitting…" : "Submit Quiz"}
                </button>
              )}
            </div>
          </div>
        </div>
      </div>

      {/* ── Confirmation modal ── */}
      {showConfirm && (
        <div style={{
          position: "fixed", inset: 0, zIndex: 5000,
          background: "rgba(15,10,5,0.5)", backdropFilter: "blur(3px)",
          display: "flex", alignItems: "center", justifyContent: "center",
          padding: "20px",
        }}>
          <div style={{
            background: "#fff", borderRadius: 18, padding: "32px 28px 26px",
            width: "100%", maxWidth: 380, textAlign: "center",
            boxShadow: "0 20px 60px rgba(0,0,0,0.18)",
            border: "1px solid #e8e4d8",
            animation: "qm-up 0.2s ease",
          }}>
            <div style={{
              width: 52, height: 52, borderRadius: "50%",
              background: "rgba(184,156,77,0.1)", border: "1.5px solid rgba(184,156,77,0.3)",
              display: "flex", alignItems: "center", justifyContent: "center",
              margin: "0 auto 16px",
            }}>
              <FiAlertCircle size={22} style={{ color: "#b89c4d" }} />
            </div>
            <h3 style={{ fontFamily: "'Playfair Display',serif", fontSize: 18,
              fontWeight: 700, color: "#1a1a1a", margin: "0 0 8px" }}>
              Submit Quiz?
            </h3>
            <p style={{ fontSize: 13.5, color: "#666", margin: "0 0 6px", lineHeight: 1.5 }}>
              You answered <strong>{answeredCount}</strong> of <strong>{questions.length}</strong> questions.
            </p>
            {answeredCount < questions.length && (
              <p style={{ fontSize: 12.5, color: "#c0392b", margin: "0 0 20px",
                background: "#fdf3f2", padding: "8px 12px", borderRadius: 8,
                border: "1px solid #f0b8b2" }}>
                ⚠ {questions.length - answeredCount} question{questions.length - answeredCount !== 1 ? "s" : ""} left unanswered — they will be marked incorrect.
              </p>
            )}
            {answeredCount === questions.length && (
              <p style={{ fontSize: 12.5, color: "#888", margin: "0 0 20px" }}>
                This cannot be undone — you can only take each quiz once.
              </p>
            )}
            <div style={{ display: "flex", gap: 10 }}>
              <button
                onClick={() => setShowConfirm(false)}
                style={{
                  flex: 1, padding: "11px", borderRadius: 9,
                  border: "1.5px solid #e8e4d8", background: "#fff",
                  color: "#666", fontSize: 13.5, fontFamily: "inherit",
                  cursor: "pointer", fontWeight: 500,
                }}>
                Go Back
              </button>
              <button
                onClick={handleSubmit}
                style={{
                  flex: 1, padding: "11px", borderRadius: 9, border: "none",
                  background: "#b89c4d", color: "#fff",
                  fontSize: 13.5, fontFamily: "inherit", fontWeight: 600,
                  cursor: "pointer",
                  boxShadow: "0 3px 12px rgba(184,156,77,0.3)",
                }}>
                Yes, Submit
              </button>
            </div>
          </div>
        </div>
      )}
    </>
  );
}
