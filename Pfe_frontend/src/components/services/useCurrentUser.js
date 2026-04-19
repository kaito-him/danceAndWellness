
import { useState, useEffect } from "react";
import api from "./api.js";

export default function useCurrentUser() {
  const [user,    setUser]    = useState(null);
  const [loading, setLoading] = useState(true);

  useEffect(() => {
    api.get("/users/me")          // ← updated path
      .then((res) => setUser(res.data))
      .catch(()  => setUser(null))
      .finally(() => setLoading(false));
  }, []);

  return { user, loading };
}