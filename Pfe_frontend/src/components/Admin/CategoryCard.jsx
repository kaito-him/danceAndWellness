import React, { useState, useEffect } from "react";
import { FiGrid } from "react-icons/fi";
import api from "./../services/api";

/**
 * Renders a single category card with icon + name.
 * Icon is fetched through the authenticated axios instance (GridFS).
 */
export default function CategoryCard({ category }) {
    const [src, setSrc] = useState(null);

    useEffect(() => {
        if (!category.icon) return;
        let objectUrl;
        const path = category.icon.replace(/^\/api/, "");
        api
            .get(path, { responseType: "blob" })
            .then((res) => {
                objectUrl = URL.createObjectURL(res.data);
                setSrc(objectUrl);
            })
            .catch(() => setSrc(null));
        return () => {
            if (objectUrl) URL.revokeObjectURL(objectUrl);
        };
    }, [category.icon]);

    return (
        <div className="cat-card">
            <div className="cat-thumb-wrap">
                {src ? (
                    <img src={src} alt={category.name} className="cat-thumb-img" />
                ) : (
                    <FiGrid size={40} className="cat-icon-fallback" />
                )}
            </div>
            <span className="cat-name">{category.name}</span>
        </div>
    );
}