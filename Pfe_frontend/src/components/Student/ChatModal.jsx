import React, { useState, useEffect, useRef } from "react";
import { FiX, FiSend, FiMessageSquare } from "react-icons/fi";
import { createPortal } from "react-dom";
import api from "../../components/services/api";
import useCurrentUser from "../services/useCurrentUser";
import "../../styles/Messages.css";

export default function ChatModal({ instructor, onClose }) {
  const { user } = useCurrentUser();
  const [messages, setMessages]   = useState([]);
  const [input, setInput]         = useState("");
  const [sending, setSending]     = useState(false);
  const bottomRef                 = useRef(null);
  const pollRef                   = useRef(null);

  const load = async () => {
    try {
      const res = await api.get(`/messages/thread/${instructor.userId}`);
      setMessages(res.data);
    } catch (e) { console.error(e); }
  };

  useEffect(() => {
    load();
    pollRef.current = setInterval(load, 3000);
    return () => clearInterval(pollRef.current);
  }, [instructor.userId]);

  useEffect(() => {
    bottomRef.current?.scrollIntoView({ behavior: "smooth" });
  }, [messages]);

  const send = async () => {
    if (!input.trim() || sending) return;
    setSending(true);
    try {
      await api.post("/messages/send", { receiverId: instructor.userId, content: input.trim() });
      setInput("");
      load();
    } finally { setSending(false); }
  };

  const photoUrl = instructor.photo
    ? `http://localhost:8080/api/files/${instructor.photo}` : null;

  const modalContent = (
    <div className="chat-modal-overlay" onClick={onClose}>
      <div className="chat-modal" onClick={e => e.stopPropagation()}>

        {/* Header */}
        <div className="chat-modal-header">
          <div className="chat-modal-recipient">
            {photoUrl
              ? <img src={photoUrl} alt={instructor.username} className="chat-modal-avatar" />
              : <div className="chat-modal-avatar-fallback">{(instructor.username ?? "?")[0].toUpperCase()}</div>}
            <div>
              <p className="chat-modal-name">{instructor.username}</p>
              <p className="chat-modal-role">{instructor.specialization || "Instructor"}</p>
            </div>
          </div>
          <button className="chat-modal-close" onClick={onClose}><FiX size={18} /></button>
        </div>

        {/* Messages */}
        <div className="chat-modal-body">
          {messages.length === 0 && (
            <p className="chat-modal-empty">Start the conversation with {instructor.username} ✉️</p>
          )}
          {messages.map(msg => {
            const mine = msg.senderId === user?.userId;
            return (
              <div key={msg.id} className={`chat-bubble-wrap ${mine ? "mine" : "theirs"}`}>
                <div className={`chat-bubble ${mine ? "mine" : "theirs"}`}>{msg.content}</div>
                <span className="chat-time">
                  {new Date(msg.sentAt).toLocaleTimeString([], { hour: "2-digit", minute: "2-digit" })}
                </span>
              </div>
            );
          })}
          <div ref={bottomRef} />
        </div>

        {/* Input */}
        <div className="chat-modal-footer">
          <textarea
            className="chat-modal-input"
            placeholder={`Message ${instructor.username}…`}
            value={input}
            onChange={e => setInput(e.target.value)}
            onKeyDown={e => { if (e.key === "Enter" && !e.shiftKey) { e.preventDefault(); send(); } }}
            rows={1}
          />
          <button
            className={`chat-modal-send ${!input.trim() || sending ? "disabled" : ""}`}
            onClick={send}
            disabled={!input.trim() || sending}
          >
            <FiSend size={16} />
          </button>
        </div>
      </div>
    </div>
  );

  // Render modal via portal to avoid stacking context issues
  return createPortal(modalContent, document.body);
}