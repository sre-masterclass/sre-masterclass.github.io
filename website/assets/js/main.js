/**
 * SRE Masterclass — Main JavaScript
 * Handles: navigation, mobile sidebar, reading progress, lesson completion tracking.
 * Single file shared across all pages — no per-page JS duplication.
 */

(function () {
  'use strict';

  // ── Mobile Sidebar Toggle ──────────────────────────────────
  const sidebar = document.getElementById('sidebar');
  const sidebarToggle = document.getElementById('sidebar-toggle');
  const sidebarOverlay = document.getElementById('sidebar-overlay');

  function openSidebar() {
    if (!sidebar) return;
    sidebar.classList.add('open');
    sidebarOverlay && sidebarOverlay.classList.add('active');
    sidebarToggle && sidebarToggle.setAttribute('aria-expanded', 'true');
    document.body.style.overflow = 'hidden';
  }

  function closeSidebar() {
    if (!sidebar) return;
    sidebar.classList.remove('open');
    sidebarOverlay && sidebarOverlay.classList.remove('active');
    sidebarToggle && sidebarToggle.setAttribute('aria-expanded', 'false');
    document.body.style.overflow = '';
  }

  if (sidebarToggle) {
    sidebarToggle.addEventListener('click', function () {
      sidebar.classList.contains('open') ? closeSidebar() : openSidebar();
    });
  }

  if (sidebarOverlay) {
    sidebarOverlay.addEventListener('click', closeSidebar);
  }

  // Close sidebar on Escape key
  document.addEventListener('keydown', function (e) {
    if (e.key === 'Escape' && sidebar && sidebar.classList.contains('open')) {
      closeSidebar();
    }
  });

  // ── Reading Progress Bar ───────────────────────────────────
  const progressBar = document.getElementById('progress-bar');
  const lessonContent = document.getElementById('lesson-content');

  if (progressBar && lessonContent) {
    function updateProgress() {
      const contentRect = lessonContent.getBoundingClientRect();
      const contentTop = contentRect.top + window.scrollY;
      const contentHeight = contentRect.height;
      const windowHeight = window.innerHeight;
      const scrolled = window.scrollY - contentTop + windowHeight;
      const progress = Math.min(Math.max(scrolled / contentHeight, 0), 1);
      progressBar.style.width = (progress * 100) + '%';
    }

    window.addEventListener('scroll', updateProgress, { passive: true });
    updateProgress(); // Initial call
  }

  // ── Lesson Completion Tracking (localStorage) ─────────────
  /**
   * Keys: "sre-completed-lessons" → JSON array of lesson IDs
   * e.g. ["0-1", "0-2", "1-1"]
   */
  const STORAGE_KEY = 'sre-completed-lessons';

  function getCompletedLessons() {
    try {
      return JSON.parse(localStorage.getItem(STORAGE_KEY) || '[]');
    } catch (e) {
      return [];
    }
  }

  function saveCompletedLessons(lessons) {
    try {
      localStorage.setItem(STORAGE_KEY, JSON.stringify(lessons));
    } catch (e) {
      // localStorage not available — graceful degradation
    }
  }

  function markLessonComplete(lessonId) {
    const completed = getCompletedLessons();
    if (!completed.includes(lessonId)) {
      completed.push(lessonId);
      saveCompletedLessons(completed);
    }
    updateSidebarCompletionMarkers();
  }

  function updateSidebarCompletionMarkers() {
    const completed = getCompletedLessons();
    document.querySelectorAll('.sidebar-lessons li a').forEach(function (link) {
      // Extract lesson ID from data attribute or URL pattern
      const lessonId = link.dataset.lessonId;
      if (lessonId && completed.includes(lessonId)) {
        link.classList.add('completed');
      }
    });
  }

  // Mark current lesson as complete when user reaches the bottom
  function setupCompletionTracking() {
    const lessonId = document.body.dataset.lessonId;
    if (!lessonId || !progressBar) return;

    let hasMarked = false;

    window.addEventListener('scroll', function () {
      if (hasMarked) return;
      const progress = parseFloat(progressBar.style.width || '0');
      if (progress >= 85) { // 85% read = complete
        markLessonComplete(lessonId);
        hasMarked = true;
      }
    }, { passive: true });
  }

  // ── Auto-resize iframes to fit content ────────────────────
  /**
   * Tool iframes have a fixed height set in the include.
   * For diagrams we try to auto-size after load.
   */
  document.querySelectorAll('.diagram-iframe').forEach(function (iframe) {
    iframe.addEventListener('load', function () {
      try {
        const body = iframe.contentDocument && iframe.contentDocument.body;
        if (body) {
          const height = body.scrollHeight;
          if (height > 100) {
            iframe.style.height = height + 'px';
          }
        }
      } catch (e) {
        // Cross-origin frames — ignore
      }
    });
  });

  // ── Smooth anchor scroll (offset for fixed topnav) ────────
  document.querySelectorAll('a[href^="#"]').forEach(function (anchor) {
    anchor.addEventListener('click', function (e) {
      const target = document.querySelector(this.getAttribute('href'));
      if (target) {
        e.preventDefault();
        const offset = 80; // topnav height + padding
        const top = target.getBoundingClientRect().top + window.scrollY - offset;
        window.scrollTo({ top: top, behavior: 'smooth' });
      }
    });
  });

  // ── Active sidebar link highlighting ──────────────────────
  function highlightActiveSidebarLink() {
    const currentPath = window.location.pathname.replace(/\/$/, '');
    document.querySelectorAll('.sidebar-lessons li a').forEach(function (link) {
      const linkPath = link.getAttribute('href').replace(/\/$/, '');
      if (linkPath === currentPath) {
        link.classList.add('active');
        // Scroll the sidebar to show the active link
        link.scrollIntoView({ block: 'nearest', behavior: 'smooth' });
      }
    });
  }

  // ── Init ──────────────────────────────────────────────────
  function init() {
    updateSidebarCompletionMarkers();
    highlightActiveSidebarLink();
    setupCompletionTracking();
  }

  if (document.readyState === 'loading') {
    document.addEventListener('DOMContentLoaded', init);
  } else {
    init();
  }

})();
