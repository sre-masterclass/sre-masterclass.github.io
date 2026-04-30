---
layout: module
title: "Advanced Monitoring"
description: "Move beyond reactive dashboards into multi-window analysis, anomaly detection, and predictive capacity modeling — the techniques that catch problems before customers do."
module_number: 3
module_id: module-3
module_title: "Advanced Monitoring"
module_icon: "🔬"
module_color: "#f59e0b"
---

## What this module covers

Module 1 taught you how to instrument and collect signals. Module 2 taught you how to define what "good" looks like with SLOs. **Module 3 is about catching problems early** — using monitoring techniques that operate on the trends, patterns, and predictions inside your data, not just the current values.

Three skills define advanced monitoring:

1. **Multi-window analysis** — looking at the same metric through multiple time lenses simultaneously, so you see the 5-minute spike *and* the weekly seasonal pattern *and* the 90-day trend at the same time.
2. **Anomaly detection** — programmatically distinguishing "different from normal" from "actually bad" without drowning the on-call team in false positives.
3. **Predictive capacity modeling** — answering the question *"will we run out of capacity in 30 days?"* before the dashboards turn red.

These three techniques are the difference between operating reactively (you find out about problems when alerts fire) and operating proactively (you find problems while you still have time to fix them gracefully).

---

## Lessons in this module

<ul class="module-lesson-list" style="display: block;">
  <li style="margin-bottom: 16px;">
    <a href="/modules/module-3/3-1-multi-window-aggregation/" style="display: flex; align-items: flex-start; gap: 12px; padding: 16px; border: 1px solid #e2e8f0; border-radius: 10px; text-decoration: none; color: #1e293b;">
      <span style="font-size: 1.4rem;">🪟</span>
      <div>
        <strong style="display: block; margin-bottom: 4px;">3.1 — Multi-Window Aggregation &amp; Seasonal Patterns</strong>
        <span style="font-size: 0.85rem; color: #64748b;">Why one aggregation window is never enough. Detecting weekly deployment patterns, daily traffic cycles, and slow-burn drift using composite Prometheus queries and rolling baselines.</span>
      </div>
    </a>
  </li>
  <li style="margin-bottom: 16px;">
    <a href="/modules/module-3/3-2-anomaly-detection/" style="display: flex; align-items: flex-start; gap: 12px; padding: 16px; border: 1px solid #e2e8f0; border-radius: 10px; text-decoration: none; color: #1e293b;">
      <span style="font-size: 1.4rem;">🎯</span>
      <div>
        <strong style="display: block; margin-bottom: 4px;">3.2 — Anomaly Detection &amp; the SAFE Methodology</strong>
        <span style="font-size: 0.85rem; color: #64748b;">From Z-scores to SAFE to ML-based isolation forests. Choosing the right algorithm for the right signal, calibrating sensitivity, and managing the false-positive/recall trade-off.</span>
      </div>
    </a>
  </li>
  <li style="margin-bottom: 16px;">
    <a href="/modules/module-3/3-3-capacity-modeling/" style="display: flex; align-items: flex-start; gap: 12px; padding: 16px; border: 1px solid #e2e8f0; border-radius: 10px; text-decoration: none; color: #1e293b;">
      <span style="font-size: 1.4rem;">📈</span>
      <div>
        <strong style="display: block; margin-bottom: 4px;">3.3 — Capacity Modeling &amp; Predictive Monitoring</strong>
        <span style="font-size: 0.85rem; color: #64748b;">Predictive linear regression, queueing theory in production, saturation SLIs, and auto-scaling triggers tied directly to SLO targets — not arbitrary CPU thresholds.</span>
      </div>
    </a>
  </li>
</ul>

---

## Interactive tools in this module

Module 3 ships with three of the most-used tools in the course:

- **Multi-Window Aggregation Visualizer** — switch between 5m / 1h / 24h / 7d windows on the same dataset and see how patterns emerge or disappear.
- **Anomaly Detection Playground** — run SAFE, Z-score, IQR, and isolation forest side-by-side on configurable traffic patterns.
- **Capacity Planning Simulator** — model traffic growth, seasonal peaks, and SLO targets to compute required infrastructure headroom.

## After this module

You'll move into **Module 4: Incident Response & Operations** — where the signals you've learned to detect early become triggers for well-designed alerts, calm incident response, and structured postmortems.

<div style="margin-top: 32px;">
  <a href="/modules/module-3/3-1-multi-window-aggregation/" class="btn btn-primary" style="background: linear-gradient(135deg, #f59e0b, #d97706); color: white; display: inline-flex; align-items: center; gap: 8px; padding: 12px 24px; border-radius: 9999px; text-decoration: none; font-weight: 600;">
    Begin Lesson 3.1 →
  </a>
</div>
