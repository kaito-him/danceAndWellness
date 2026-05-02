// src/components/Student/CourseComments.jsx
import React, { useEffect, useMemo, useState, useRef, useCallback } from "react";
import api from "../services/api";
import {
    FiX, FiSend, FiHeart, FiMessageCircle, FiTrash2,
    FiCornerDownRight, FiChevronDown, FiChevronUp, FiUser
} from "react-icons/fi";
import "../../styles/CourseComments.css";
import "../../styles/LogoutModal.css";

/* ── Confirm Delete Modal ── */
const ConfirmDeleteModal = ({ title, message, onConfirm, onCancel, loading }) => {
    useEffect(() => {
        const handler = (e) => { if (e.key === "Escape") onCancel(); };
        window.addEventListener("keydown", handler);
        return () => window.removeEventListener("keydown", handler);
    }, [onCancel]);

    return (
        <div className="lm-backdrop" onClick={onCancel} style={{ zIndex: 9999 }}>
            <div className="lm-card" onClick={(e) => e.stopPropagation()}>
                <div className="lm-icon-ring">
                    <FiTrash2 className="lm-icon" size={24} strokeWidth={1.8} style={{ color: "currentColor" }} />
                </div>
                <h2 className="lm-title">{title}</h2>
                <p className="lm-message">{message}</p>
                <div className="lm-actions">
                    <button className="lm-btn-cancel" onClick={onCancel}>No, keep it</button>
                    <button className="lm-btn-confirm" onClick={onConfirm} disabled={loading}>
                        {loading ? "Deleting..." : "Yes, delete"}
                    </button>
                </div>
            </div>
        </div>
    );
};

/* ── Helpers ─────────────────────────────────────────────────── */
const timeAgo = (dateStr) => {
    if (!dateStr) return "";
    const diff = (Date.now() - new Date(dateStr)) / 1000;
    if (diff < 60) return "just now";
    if (diff < 3600) return `${Math.floor(diff / 60)}m ago`;
    if (diff < 86400) return `${Math.floor(diff / 3600)}h ago`;
    return `${Math.floor(diff / 86400)}d ago`;
};

const Avatar = ({ username, photo, size = 36 }) => {
    const initial = username?.charAt(0)?.toUpperCase() || "?";
    return photo ? (
        <img
            className="cc-avatar"
            src={`http://localhost:8080/api/files/${photo}`}
            alt={username}
            style={{ width: size, height: size }}
        />
    ) : (
        <div className="cc-avatar cc-avatar-initial" style={{ width: size, height: size, fontSize: size * 0.38 }}>
            {initial}
        </div>
    );
};

/* ── Single Reply Item ───────────────────────────────────────── */
const ReplyItem = ({ reply, currentUserId, courseId, onDelete, isAdmin, onAuthorClick }) => {
    const [liked, setLiked] = useState(reply.likedByUserIds?.includes(currentUserId));
    const [likeCount, setLikeCount] = useState(reply.likedByUserIds?.length ?? 0);
    const [busy, setBusy] = useState(false);

    const toggleLike = async () => {
        if (busy) return;
        setBusy(true);
        try {
            if (liked) {
                await api.delete(`/courses/${courseId}/comments/${reply.commentId}/like`);
                setLiked(false);
                setLikeCount(c => c - 1);
            } else {
                await api.post(`/courses/${courseId}/comments/${reply.commentId}/like`);
                setLiked(true);
                setLikeCount(c => c + 1);
            }
        } finally {
            setBusy(false);
        }
    };

    const isOwn = reply.authorId === currentUserId;

    return (
        <div className="cc-reply-item">
            <button className="cc-author-link-avatar" onClick={() => onAuthorClick?.(reply)} title="Open profile">
                <Avatar username={reply.authorUsername} photo={reply.authorPhoto} size={28} />
            </button>
            <div className="cc-reply-body">
                <div className="cc-reply-header">
                    <button className="cc-author-link" onClick={() => onAuthorClick?.(reply)}>
                        {reply.authorUsername}
                    </button>
                    {reply.authorRole !== "STUDENT" && (
                        <span className={`cc-role-badge cc-role-${reply.authorRole?.toLowerCase()}`}>
                            {reply.authorRole}
                        </span>
                    )}
                    <span className="cc-ts">{timeAgo(reply.createdAt)}</span>
                </div>
                <p className="cc-reply-content">{reply.content}</p>
                <div className="cc-reply-actions">
                    {!isAdmin && (
                        <button
                            className={`cc-like-btn ${liked ? "cc-liked" : ""}`}
                            onClick={toggleLike}
                            disabled={busy}
                        >
                            <FiHeart size={12} strokeWidth={liked ? 0 : 2} style={{ fill: liked ? "currentColor" : "none" }} />
                            <span>{likeCount > 0 ? likeCount : ""}</span>
                        </button>
                    )}
                    {(isOwn || isAdmin) && (
                        <button className="cc-delete-btn" onClick={() => onDelete(reply.commentId)}>
                            <FiTrash2 size={12} />
                        </button>
                    )}
                </div>
            </div>
        </div>
    );
};

/* ── Single Comment Item ─────────────────────────────────────── */
const CommentItem = ({ comment, currentUserId, courseId, onDelete, onReplyDelete, isAdmin, onAuthorClick, instructorUserId }) => {
    const [liked, setLiked] = useState(comment.likedByUserIds?.includes(currentUserId));
    const [likeCount, setLikeCount] = useState(comment.likedByUserIds?.length ?? 0);
    const [busy, setBusy] = useState(false);
    const [showReplies, setShowReplies] = useState(false);
    const [replies, setReplies] = useState([]);
    const [loadingRep, setLoadingRep] = useState(false);
    const [repliesFetched, setRepliesFetched] = useState(false);
    const [showReplyBox, setShowReplyBox] = useState(false);
    const [replyText, setReplyText] = useState("");
    const [sendingReply, setSendingReply] = useState(false);
    const replyRef = useRef(null);

    const isOwn = comment.authorId === currentUserId;
    const isInstructorAuthor = comment.authorId === instructorUserId;

    const toggleLike = async () => {
        if (busy) return;
        setBusy(true);
        try {
            if (liked) {
                await api.delete(`/courses/${courseId}/comments/${comment.commentId}/like`);
                setLiked(false);
                setLikeCount(c => c - 1);
            } else {
                await api.post(`/courses/${courseId}/comments/${comment.commentId}/like`);
                setLiked(true);
                setLikeCount(c => c + 1);
            }
        } finally {
            setBusy(false);
        }
    };

    const fetchReplies = async () => {
        if (repliesFetched) return;
        setLoadingRep(true);
        try {
            const res = await api.get(`/courses/${courseId}/comments/${comment.commentId}/replies`);
            setReplies(res.data);
            setRepliesFetched(true);
        } finally {
            setLoadingRep(false);
        }
    };

    const handleToggleReplies = async () => {
        if (!showReplies) await fetchReplies();
        setShowReplies(v => !v);
    };

    const handleSendReply = async () => {
        const text = replyText.trim();
        if (!text || sendingReply) return;
        setSendingReply(true);
        try {
            const res = await api.post(
                `/courses/${courseId}/comments/${comment.commentId}/replies`,
                { content: text }
            );
            setReplies(prev => [...prev, res.data]);
            setRepliesFetched(true);
            setShowReplies(true);
            setReplyText("");
            setShowReplyBox(false);
        } finally {
            setSendingReply(false);
        }
    };

    useEffect(() => {
        if (showReplyBox) replyRef.current?.focus();
    }, [showReplyBox]);

    return (
        <div className={`cc-comment-item ${isInstructorAuthor ? "cc-comment-instructor" : ""}`}>
            <button className="cc-author-link-avatar" onClick={() => onAuthorClick?.(comment)} title="Open profile">
                <Avatar username={comment.authorUsername} photo={comment.authorPhoto} />
            </button>
            <div className="cc-comment-body">
                {/* Header */}
                <div className="cc-comment-header">
                    <button className="cc-author-link" onClick={() => onAuthorClick?.(comment)}>
                        {comment.authorUsername}
                    </button>
                    {comment.authorRole !== "STUDENT" && (
                        <span className={`cc-role-badge cc-role-${comment.authorRole?.toLowerCase()}`}>
                            {comment.authorRole}
                        </span>
                    )}
                    <span className="cc-ts">{timeAgo(comment.createdAt)}</span>
                    {(isOwn || isAdmin) && (
                        <button className="cc-delete-btn cc-delete-top" onClick={() => onDelete(comment.commentId)}>
                            <FiTrash2 size={13} />
                        </button>
                    )}
                </div>

                {/* Content */}
                <p className="cc-comment-content">{comment.content}</p>

                {/* Action bar */}
                <div className="cc-comment-actions">
                    {!isAdmin && (
                        <>
                            <button
                                className={`cc-like-btn ${liked ? "cc-liked" : ""}`}
                                onClick={toggleLike}
                                disabled={busy}
                            >
                                <FiHeart
                                    size={13}
                                    strokeWidth={liked ? 0 : 2}
                                    style={{ fill: liked ? "currentColor" : "none" }}
                                />
                                <span>{likeCount > 0 ? likeCount : "Like"}</span>
                            </button>

                            <button className="cc-reply-toggle-btn" onClick={() => setShowReplyBox(v => !v)}>
                                <FiCornerDownRight size={13} />
                                <span>Reply</span>
                            </button>
                        </>
                    )}

                    <button className="cc-show-replies-btn" onClick={handleToggleReplies}>
                        {loadingRep ? (
                            <span className="cc-mini-spinner" />
                        ) : showReplies ? (
                            <><FiChevronUp size={13} /> Hide replies</>
                        ) : (
                            <><FiChevronDown size={13} /> View replies</>
                        )}
                    </button>
                </div>

                {/* Reply input */}
                {showReplyBox && (
                    <div className="cc-reply-input-row">
                        <textarea
                            ref={replyRef}
                            className="cc-reply-textarea"
                            placeholder="Write a reply…"
                            value={replyText}
                            onChange={e => setReplyText(e.target.value)}
                            onKeyDown={e => {
                                if (e.key === "Enter" && !e.shiftKey) { e.preventDefault(); handleSendReply(); }
                                if (e.key === "Escape") setShowReplyBox(false);
                            }}
                            rows={2}
                        />
                        <button
                            className="cc-reply-send-btn"
                            onClick={handleSendReply}
                            disabled={!replyText.trim() || sendingReply}
                        >
                            {sendingReply ? <span className="cc-mini-spinner" /> : <FiSend size={14} />}
                        </button>
                    </div>
                )}

                {/* Replies list */}
                {showReplies && (
                    <div className="cc-replies-list">
                        {replies.length === 0 && !loadingRep && (
                            <p className="cc-no-replies">No replies yet. Be the first!</p>
                        )}
                        {replies.map(r => (
                            <ReplyItem
                                key={r.commentId}
                                reply={r}
                                currentUserId={currentUserId}
                                courseId={courseId}
                                onDelete={(replyId) => onReplyDelete(replyId)}
                                isAdmin={isAdmin}
                                onAuthorClick={onAuthorClick}
                            />
                        ))}
                    </div>
                )}
            </div>
        </div>
    );
};

/* ── Skeleton Loader ─────────────────────────────────────────── */
const CommentSkeleton = () => (
    <div className="cc-skeleton-item">
        <div className="cc-skel cc-skel-avatar" />
        <div className="cc-skeleton-lines">
            <div className="cc-skel cc-skel-name" />
            <div className="cc-skel cc-skel-line" />
            <div className="cc-skel cc-skel-line-short" />
        </div>
    </div>
);

/* ── Main CourseComments Component ───────────────────────────── */
export default function CourseComments({ courseId, onClose, onAuthorClick }) {
    const currentUserId = localStorage.getItem("userId");
    const currentRole   = localStorage.getItem("role");
    const currentPhoto  = localStorage.getItem("userPhoto");   // GridFS file ID
    const isAdmin = currentRole === "ADMIN";

    const [comments, setComments] = useState([]);
    const [loading, setLoading] = useState(true);
    const [newText, setNewText] = useState("");
    const [sending, setSending] = useState(false);
    const [error, setError] = useState("");
    const [commentToDelete, setCommentToDelete] = useState(null);
    const [replyToDelete, setReplyToDelete] = useState(null);
    const [deleting, setDeleting] = useState(false);
    const orderedComments = useMemo(() => {
        const mine = comments.filter(c => c.authorId === currentUserId);
        const rest = comments.filter(c => c.authorId !== currentUserId);
        return [...mine, ...rest];
    }, [comments, currentUserId]);

    const drawerRef = useRef(null);
    const textareaRef = useRef(null);

    /* Fetch top-level comments */
    const loadComments = useCallback(async () => {
        setLoading(true);
        setError("");
        try {
            const res = await api.get(`/courses/${courseId}/comments`);
            setComments(res.data);
        } catch {
            setError("Failed to load comments. Please try again.");
        } finally {
            setLoading(false);
        }
    }, [courseId]);

    useEffect(() => { loadComments(); }, [loadComments]);

    /* Close on Escape */
    useEffect(() => {
        const handler = e => { if (e.key === "Escape") onClose(); };
        window.addEventListener("keydown", handler);
        return () => window.removeEventListener("keydown", handler);
    }, [onClose]);

    /* Post new comment */
    const handlePost = async () => {
        const text = newText.trim();
        if (!text || sending) return;
        setSending(true);
        try {
            const res = await api.post(`/courses/${courseId}/comments`, { content: text });
            setComments(prev => [res.data, ...prev]);
            setNewText("");
            textareaRef.current?.focus();
        } catch {
            setError("Could not post comment. Please try again.");
        } finally {
            setSending(false);
        }
    };

    /* Delete handlers */
    const confirmDelete = async () => {
        const id = commentToDelete || replyToDelete;
        if (!id) return;
        setDeleting(true);
        try {
            await api.delete(`/courses/${courseId}/comments/${id}`);
            if (commentToDelete) {
                setComments(prev => prev.filter(c => c.commentId !== id));
                setCommentToDelete(null);
            } else {
                // For simplicity, refresh comments if a reply is deleted
                // Or I could find the parent comment and update its replies state...
                // But a refresh is safer and cleaner for now.
                loadComments();
                setReplyToDelete(null);
            }
        } catch {
            setError("Could not delete.");
        } finally {
            setDeleting(false);
        }
    };

    return (
        <>
            {/* Backdrop */}
            <div className="cc-backdrop" onClick={onClose} />

            {/* Drawer */}
            <aside className="cc-drawer" ref={drawerRef} role="dialog" aria-label="Course Comments">
                {/* Header */}
                <div className="cc-drawer-header">
                    <div className="cc-header-left">
                        <FiMessageCircle size={20} className="cc-header-icon" />
                        <div>
                            <h2 className="cc-drawer-title">Discussion</h2>
                            <span className="cc-comment-count">
                                {loading ? "—" : `${comments.length} comment${comments.length !== 1 ? "s" : ""}`}
                            </span>
                        </div>
                    </div>
                    <button className="cc-close-btn" onClick={onClose} aria-label="Close comments">
                        <FiX size={20} />
                    </button>
                </div>

                {/* Compose box */}
                {!isAdmin && (
                    <div className="cc-compose-area">
                        <div className="cc-compose-inner">
                            <div className="cc-compose-avatar">
                                <Avatar
                                    username={localStorage.getItem("username") || ""}
                                    photo={currentPhoto || ""}
                                    size={36}
                                />
                            </div>
                            <div className="cc-compose-right">
                                <textarea
                                    ref={textareaRef}
                                    className="cc-compose-textarea"
                                    placeholder="Share your thoughts on this course…"
                                    value={newText}
                                    rows={3}
                                    onChange={e => setNewText(e.target.value)}
                                    onKeyDown={e => {
                                        if (e.key === "Enter" && !e.shiftKey) { e.preventDefault(); handlePost(); }
                                    }}
                                />
                                <div className="cc-compose-footer">
                                    <span className="cc-compose-hint">Press Enter to post · Shift+Enter for new line</span>
                                    <button
                                        className="cc-post-btn"
                                        onClick={handlePost}
                                        disabled={!newText.trim() || sending}
                                    >
                                        {sending ? <span className="cc-mini-spinner cc-spinner-white" /> : <FiSend size={14} />}
                                        <span>{sending ? "Posting…" : "Post"}</span>
                                    </button>
                                </div>
                            </div>
                        </div>
                    </div>
                )}

                {/* Error */}
                {error && (
                    <div className="cc-error-bar">
                        <span>{error}</span>
                        <button onClick={() => setError("")}><FiX size={14} /></button>
                    </div>
                )}

                {/* Divider */}
                <div className="cc-section-divider">
                    <span>Comments</span>
                </div>

                {/* Comments list */}
                <div className="cc-comments-list">
                    {loading ? (
                        [1, 2, 3].map(i => <CommentSkeleton key={i} />)
                    ) : comments.length === 0 ? (
                        <div className="cc-empty-state">
                            <FiMessageCircle size={40} strokeWidth={1.2} className="cc-empty-icon" />
                            <p className="cc-empty-title">Start the conversation</p>
                            <p className="cc-empty-sub">Be the first to share your thoughts on this course.</p>
                        </div>
                    ) : (
                        orderedComments.map(c => (
                            <CommentItem
                                key={c.commentId}
                                comment={c}
                                currentUserId={currentUserId}
                                courseId={courseId}
                                onDelete={(id) => setCommentToDelete(id)}
                                onReplyDelete={(id) => setReplyToDelete(id)}
                                isAdmin={isAdmin}
                                onAuthorClick={onAuthorClick}
                                instructorUserId={currentUserId}
                            />
                        ))
                    )}
                </div>
            </aside>

            {(commentToDelete || replyToDelete) && (
                <ConfirmDeleteModal
                    title={`Delete ${commentToDelete ? "Comment" : "Reply"}`}
                    message="Are you sure you want to delete this? This cannot be undone."
                    loading={deleting}
                    onConfirm={confirmDelete}
                    onCancel={() => { setCommentToDelete(null); setReplyToDelete(null); }}
                />
            )}
        </>
    );
}