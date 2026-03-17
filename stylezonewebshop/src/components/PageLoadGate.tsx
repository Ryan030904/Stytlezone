"use client";

import { useEffect } from "react";

/**
 * Removes the initial loading screen (created by inline script in layout)
 * once React hydrates. Since the loader is outside React's virtual DOM tree,
 * removing it won't cause hydration errors.
 */
export default function PageLoadGate() {
  useEffect(() => {
    const loader = document.getElementById("initial-loader");
    if (!loader) return;

    // Small delay to ensure content is painted
    const timer = setTimeout(() => {
      loader.style.opacity = "0";
      loader.style.pointerEvents = "none";
      // Remove from DOM after fade transition
      setTimeout(() => loader.remove(), 400);
    }, 300);

    return () => clearTimeout(timer);
  }, []);

  return null;
}
