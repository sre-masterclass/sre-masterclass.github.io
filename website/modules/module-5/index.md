---
layout: module
title: "SRE in CI/CD"
description: "Reliability is not something you bolt on after the build. This module integrates SRE practices directly into the delivery pipeline — turning every deployment into a controlled, observable, reversible event tied to your SLOs."
module_number: 5
module_id: module-5
module_title: "SRE in CI/CD"
module_icon: "🚀"
module_color: "#6366f1"
---

## What this module covers

The CI/CD pipeline is where reliability engineering lives or dies. A team can have perfect SLOs, beautiful runbooks, and rigorous chaos engineering — and still be one bad deploy away from a Sev-1 incident. The CI/CD pipeline is the highest-leverage place in your stack to enforce reliability practices, because every change to the system flows through it.

This module integrates everything you've learned across the course into the pipeline:

1. **Deployment automation** — moving from "deploy when the engineer says so" to controlled progressive delivery with blue/green and canary patterns and automatic rollback
2. **SLO-based deployment gates** — using the SLO data and error budget mathematics from Module 2 to gate which deploys ship and which get paused
3. **Chaos engineering integration** — running chaos experiments as part of CI/CD, not as a separate manual practice

The unifying theme: **every deploy is a small chaos experiment**. Treating it that way — with hypotheses, steady-state validation, and bounded blast radius — turns deployment from a risk into a reliability practice.

---

## Lessons in this module

<ul class="module-lesson-list" style="display: block;">
  <li style="margin-bottom: 16px;">
    <a href="/modules/module-5/5-1-deployment-automation/" style="display: flex; align-items: flex-start; gap: 12px; padding: 16px; border: 1px solid #e2e8f0; border-radius: 10px; text-decoration: none; color: #1e293b;">
      <span style="font-size: 1.4rem;">🚢</span>
      <div>
        <strong style="display: block; margin-bottom: 4px;">5.1 — Deployment Automation &amp; Progressive Delivery</strong>
        <span style="font-size: 0.85rem; color: #64748b;">Blue/green and canary patterns, traffic-shifting strategies, automated rollback triggers, and the pipeline architecture that makes safe deploys the default — not the exception.</span>
      </div>
    </a>
  </li>
  <li style="margin-bottom: 16px;">
    <a href="/modules/module-5/5-2-slo-deployment-gates/" style="display: flex; align-items: flex-start; gap: 12px; padding: 16px; border: 1px solid #e2e8f0; border-radius: 10px; text-decoration: none; color: #1e293b;">
      <span style="font-size: 1.4rem;">🚦</span>
      <div>
        <strong style="display: block; margin-bottom: 4px;">5.2 — SLO-Based Deployment Gates</strong>
        <span style="font-size: 0.85rem; color: #64748b;">Connect error budget mathematics to pipeline policy. Block deploys when budgets are exhausted, run performance regression checks against SLO thresholds, and enforce the error budget policy automatically.</span>
      </div>
    </a>
  </li>
  <li style="margin-bottom: 16px;">
    <a href="/modules/module-5/5-3-chaos-integration/" style="display: flex; align-items: flex-start; gap: 12px; padding: 16px; border: 1px solid #e2e8f0; border-radius: 10px; text-decoration: none; color: #1e293b;">
      <span style="font-size: 1.4rem;">🎲</span>
      <div>
        <strong style="display: block; margin-bottom: 4px;">5.3 — Chaos Engineering Integration in CI/CD</strong>
        <span style="font-size: 0.85rem; color: #64748b;">Automated chaos experiments in staging, scheduled production chaos, GameDay automation, and the full pipeline pattern that proves resilience before each release ships.</span>
      </div>
    </a>
  </li>
</ul>

---

## Interactive tools in this module

Module 5 includes two of the most-requested tools in the course:

- **Pipeline SRE Integration Builder** — drag-and-drop your CI/CD pipeline and see where each SRE practice fits
- **Deployment Gate Simulator** — simulate canary deployments with SLO-based gates to see how different gate configurations affect MTTR and rollback rates

## After this module

You'll have completed the full SRE Masterclass. Six modules, twenty-three lessons, eleven interactive tools, and a complete framework spanning strategic foundation through operational integration. Where you go next depends on what you've built so far — but you'll have the full toolkit to take any SRE program from "we have monitoring" to "reliability engineering is how we ship software."

<div style="margin-top: 32px;">
  <a href="/modules/module-5/5-1-deployment-automation/" class="btn btn-primary" style="background: linear-gradient(135deg, #6366f1, #4f46e5); color: white; display: inline-flex; align-items: center; gap: 8px; padding: 12px 24px; border-radius: 9999px; text-decoration: none; font-weight: 600;">
    Begin Lesson 5.1 →
  </a>
</div>
