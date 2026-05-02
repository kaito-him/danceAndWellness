import React, { useState, useEffect, useRef } from "react";
import {
    FiPlus,
    FiX,
    FiUpload,
    FiGrid,
    FiCheckCircle,
    FiXCircle,
} from "react-icons/fi";
import api from "./../services/api";
import CategoryCard from "./CategoryCard";
import "../../styles/AdminCategories.css";

export default function AdminCategories() {
    const [categories, setCategories] = useState([]);
    const [loading, setLoading] = useState(true);
    const [showModal, setShowModal] = useState(false);
    const [showDeleteConfirm, setShowDeleteConfirm] = useState(false);
    const [categoryToDelete, setCategoryToDelete] = useState(null);
    const [submitting, setSubmitting] = useState(false);
    const [toast, setToast] = useState(null);
    const [preview, setPreview] = useState(null);
    const [iconFile, setIconFile] = useState(null);
    const [form, setForm] = useState({ name: "" });
    const fileInputRef = useRef();

    /* ── helpers ───────────────────────────────────────── */
    const showToast = (type, msg) => {
        setToast({ type, msg });
        setTimeout(() => setToast(null), 3500);
    };

    const resetModal = () => {
        setForm({ name: "" });
        setIconFile(null);
        setPreview(null);
        setShowModal(false);
    };

    /* ── fetch ─────────────────────────────────────────── */
    const fetchCategories = async () => {
        setLoading(true);
        try {
            const res = await api.get("/categories");
            setCategories(res.data);
        } catch {
            showToast("error", "Failed to load categories.");
        } finally {
            setLoading(false);
        }
    };

    useEffect(() => {
        fetchCategories();
    }, []);

    /* ── delete ────────────────────────────────────────── */
    const initiateDelete = (cat) => {
        setCategoryToDelete(cat);
        setShowDeleteConfirm(true);
    };

    const handleDeleteSubmit = async () => {
        if (!categoryToDelete) return;
        setSubmitting(true);
        try {
            await api.delete(`/categories/${categoryToDelete.id}`);
            showToast("success", "Category deleted successfully!");
            fetchCategories();
            setShowDeleteConfirm(false);
            setCategoryToDelete(null);
        } catch (err) {
            console.error(err);
            showToast("error", "Failed to delete category.");
        } finally {
            setSubmitting(false);
        }
    };

    /* ── file upload ───────────────────────────────────── */
    const handleFileChange = (e) => {
        const file = e.target.files[0];
        if (!file) return;
        if (!file.type.startsWith("image/")) {
            showToast("error", "Please select an image file.");
            return;
        }
        setIconFile(file);
        setPreview(URL.createObjectURL(file));
    };

    /* ── submit ────────────────────────────────────────── */
    const handleSubmit = async () => {
        if (!form.name.trim()) {
            showToast("error", "Category name is required.");
            return;
        }
        setSubmitting(true);
        try {
            let iconUrl = "";
            if (iconFile) {
                const fd = new FormData();
                fd.append("file", iconFile);
                const uploadRes = await api.post("/files/upload", fd, {
                    headers: { "Content-Type": "multipart/form-data" },
                });
                iconUrl = uploadRes.data.url; // "/api/files/<id>"
            }
            await api.post("/categories", { ...form, icon: iconUrl });
            showToast("success", "Category created!");
            resetModal();
            fetchCategories();
        } catch {
            showToast("error", "Failed to create category.");
        } finally {
            setSubmitting(false);
        }
    };

    /* ── render ────────────────────────────────────────── */
    return (
        <div className="cat-page">
            {/* Header */}
            <div className="cat-header">
                <div>
                    <h1 className="cat-title">Categories</h1>
                    <p className="cat-sub">Manage course categories across the platform</p>
                </div>
                <button className="cat-add-btn" onClick={() => setShowModal(true)}>
                    <FiPlus size={16} /> Add Category
                </button>
            </div>

            {/* Stats */}
            <div className="cat-statsbar">
                <div className="cat-stat">
                    <span className="cat-stat-num">{categories.length}</span>
                    <span className="cat-stat-label">Total Categories</span>
                </div>
            </div>

            {/* Content */}
            {loading ? (
                <div className="cat-loading">
                    <div className="cat-spinner" />
                    <p>Loading categories…</p>
                </div>
            ) : categories.length === 0 ? (
                <div className="cat-empty">
                    <FiGrid size={52} />
                    <h2>No categories yet</h2>
                    <p>Create your first category to get started.</p>
                </div>
            ) : (
                <div className="cat-grid">
                    {categories.map((cat) => (
                        <CategoryCard 
                            key={cat.id} 
                            category={cat} 
                            onDelete={initiateDelete}
                        />
                    ))}
                </div>
            )}

            {/* ── Delete Confirmation Modal ─────────────────── */}
            {showDeleteConfirm && (
                <div className="cat-overlay" onClick={() => setShowDeleteConfirm(false)}>
                    <div className="cat-modal confirm" onClick={(e) => e.stopPropagation()}>
                        <div className="cat-modal-header">
                            <h2>Delete Category</h2>
                            <button className="cat-modal-close" onClick={() => setShowDeleteConfirm(false)}>
                                <FiX size={18} />
                            </button>
                        </div>
                        <div className="cat-modal-body">
                            <p>Are you sure you want to delete <strong>{categoryToDelete?.name}</strong> forever?</p>
                            <span>This action cannot be undone and may affect courses using this category.</span>
                        </div>
                        <div className="cat-modal-footer">
                            <button className="cat-btn-cancel" onClick={() => setShowDeleteConfirm(false)}>
                                Keep Category
                            </button>
                            <button 
                                className="cat-btn-delete" 
                                onClick={handleDeleteSubmit}
                                disabled={submitting}
                            >
                                {submitting ? "Deleting..." : "Yes, Delete Forever"}
                            </button>
                        </div>
                    </div>
                </div>
            )}

            {/* ── Add Category Modal ─────────────────────────── */}
            {showModal && (
                <div className="cat-overlay" onClick={resetModal}>
                    <div className="cat-modal" onClick={(e) => e.stopPropagation()}>
                        <div className="cat-modal-header">
                            <h2>New Category</h2>
                            <button className="cat-modal-close" onClick={resetModal}>
                                <FiX size={18} />
                            </button>
                        </div>

                        <div
                            className="cat-upload-area"
                            onClick={() => fileInputRef.current.click()}
                        >
                            {preview ? (
                                <img src={preview} alt="preview" className="cat-preview-img" />
                            ) : (
                                <>
                                    <FiUpload size={28} className="cat-upload-icon" />
                                    <p>Click to upload category icon</p>
                                    <span>PNG, JPG, SVG — recommended 256×256</span>
                                </>
                            )}
                        </div>
                        <input
                            ref={fileInputRef}
                            type="file"
                            accept="image/*"
                            style={{ display: "none" }}
                            onChange={handleFileChange}
                        />

                        <div className="cat-form">
                            <div className="cat-field">
                                <label>Category Name *</label>
                                <input
                                    value={form.name}
                                    onChange={(e) => setForm({ ...form, name: e.target.value })}
                                    placeholder="e.g. Dance Fitness"
                                />
                            </div>
                        </div>

                        <div className="cat-modal-footer">
                            <button className="cat-btn-cancel" onClick={resetModal}>
                                Cancel
                            </button>
                            <button
                                className="cat-btn-submit"
                                onClick={handleSubmit}
                                disabled={submitting}
                            >
                                {submitting ? "Creating…" : "Create Category"}
                            </button>
                        </div>
                    </div>
                </div>
            )}

            {/* Toast */}
            {toast && (
                <div className={`cat-toast ${toast.type}`}>
                    {toast.type === "success" ? (
                        <FiCheckCircle size={15} />
                    ) : (
                        <FiXCircle size={15} />
                    )}
                    {toast.msg}
                </div>
            )}
        </div>
    );
}
