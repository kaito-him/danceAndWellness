import React, { useState, useEffect, useRef } from "react";
import { FiMessageSquare, FiSend } from "react-icons/fi";
import api from "../../components/services/api";
import useCurrentUser from "../services/useCurrentUser";
import "../../styles/Messages.css";

const BASE = "http://localhost:8080/api/files/";

export default function StudentMessagesPage() {
  const { user }                      = useCurrentUser();
  const [convs, setConvs]             = useState([]);
  const [selected, setSelected]       = useState(null);
  const [thread, setThread]           = useState([]);
  const [input, setInput]             = useState("");
  const [loading, setLoading]         = useState(true);
  const [sending, setSending]         = useState(false);
  const bottomRef                     = useRef(null);
  const pollRef                       = useRef(null);

  const loadConvs = async () => {
    try { setConvs((await api.get("/messages/conversations")).data); }
    catch (e) { console.error(e); }
    finally { setLoading(false); }
  };

  const loadThread = async (otherId) => {
    try {
      const res = await api.get(`/messages/thread/${otherId}`);
      setThread(res.data);
      api.post(`/messages/read/${otherId}`).catch(() => {});
      // Refresh conversation list so unread badge clears
      loadConvs();
    } catch (e) { console.error(e); }
  };

  useEffect(() => {
    loadConvs();
    const t = setInterval(loadConvs, 5000);
    return () => clearInterval(t);
  }, []);

  useEffect(() => {
    if (!selected) return;
    loadThread(selected.otherUserId);
    clearInterval(pollRef.current);
    pollRef.current = setInterval(() => loadThread(selected.otherUserId), 3000);
    return () => clearInterval(pollRef.current);
  }, [selected?.otherUserId]);

  useEffect(() => {
    bottomRef.current?.scrollIntoView({ behavior: "smooth" });
  }, [thread]);

  const send = async () => {
    if (!input.trim() || sending || !selected) return;
    setSending(true);
    try {
      await api.post("/messages/send", { receiverId: selected.otherUserId, content: input.trim() });
      setInput("");
      loadThread(selected.otherUserId);
    } finally { setSending(false); }
  };

  if (loading) return (
    <div className="msg-loading"><div className="sd-spinner" /><p>Loading messages…</p></div>
  );

  return (
    <div className="msg-layout">

      {/* ── LEFT: conversation list ── */}
      <div className="msg-sidebar">
        <div className="msg-sidebar-header">
          <h2 className="msg-sidebar-title">Messages</h2>
        </div>

        {convs.length === 0
          ? <div className="msg-empty-conv"><FiMessageSquare size={32} /><p>No conversations yet.<br/>Message an instructor to get started.</p></div>
          : <div className="msg-conv-list">
              {convs.map(conv => {
                const active = selected?.otherUserId === conv.otherUserId;
                return (
                  <button
                    key={conv.otherUserId}
                    className={`msg-conv-item ${active ? "active" : ""}`}
                    onClick={() => setSelected(conv)}
                  >
                    <div className="msg-conv-avatar">
                      {conv.otherUserPhoto
                        ? <img src={BASE + conv.otherUserPhoto} alt={conv.otherUsername} />
                        : <div className="msg-conv-avatar-fallback">{(conv.otherUsername ?? "?")[0].toUpperCase()}</div>}
                    </div>
                    <div className="msg-conv-info">
                      <div className="msg-conv-top">
                        <span className="msg-conv-name">{conv.otherUsername}</span>
                        {conv.unreadCount > 0 && <span className="msg-conv-badge">{conv.unreadCount}</span>}
                      </div>
                      <p className="msg-conv-last">
                        <span className="msg-conv-prefix">{conv.lastMessageWasMine ? "You" : conv.otherUsername}:&nbsp;</span>
                        {(conv.lastMessage?.length > 38 ? conv.lastMessage.slice(0, 38) + "…" : conv.lastMessage)}
                      </p>
                    </div>
                  </button>
                );
              })}
            </div>
        }
      </div>

      {/* ── RIGHT: thread ── */}
      <div className="msg-thread">
        {!selected
          ? <div className="msg-no-selection">
              <FiMessageSquare size={48} />
              <h3>Select a conversation</h3>
              <p>Your chats with instructors will appear here.</p>
            </div>
          : <>
              <div className="msg-thread-header">
                <div className="msg-thread-avatar">
                  {selected.otherUserPhoto
                    ? <img src={BASE + selected.otherUserPhoto} alt={selected.otherUsername} />
                    : <div className="msg-conv-avatar-fallback small">{(selected.otherUsername ?? "?")[0].toUpperCase()}</div>}
                </div>
                <p className="msg-thread-name">{selected.otherUsername}</p>
              </div>

              <div className="msg-thread-body">
                {thread.map(msg => {
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

              <div className="msg-thread-footer">
                <textarea
                  className="msg-thread-input"
                  placeholder="Type a message… (Enter to send)"
                  value={input}
                  onChange={e => setInput(e.target.value)}
                  onKeyDown={e => { if (e.key === "Enter" && !e.shiftKey) { e.preventDefault(); send(); } }}
                  rows={1}
                />
                <button
                  className={`msg-send-btn ${!input.trim() || sending ? "disabled" : ""}`}
                  onClick={send}
                  disabled={!input.trim() || sending}
                ><FiSend size={16} /></button>
              </div>
            </>
        }
      </div>
    </div>
  );
}