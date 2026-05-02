
import { useState, useEffect } from "react";
import api from "./api.js";

export default function useCurrentUser() {
  const [user,    setUser]    = useState(null);
  const [loading, setLoading] = useState(true);

  const refresh = () => {
    setLoading(true);
    api.get("/users/me")
      .then((res) => {
        setUser(res.data);
        // Keep localStorage in sync so components that read it directly stay current
        if (res.data?.photo !== undefined) {
          localStorage.setItem("userPhoto", res.data.photo || "");
        }
      })
      .catch(()  => setUser(null))
      .finally(() => setLoading(false));
  };

  useEffect(() => {
    refresh();
  }, []);

  return { user, loading, refresh };
}