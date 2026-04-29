# Module Asset Production Workflow & Guidelines

This document outlines the standard operating procedure for creating and refining all visual and interactive assets for the SRE Masterclass modules. Following this workflow will ensure high-quality, context-rich assets and minimize rework.

---

## Phase 1: Module Setup & Planning

### 1.1. Create Module Folder Structure
For each new module (e.g., "Module 0.2"), create the standard folder structure:
```
/course/modules/module-0-strategic-foundation/
└── 0-2-team-models/
    ├── scripts/
    ├── visuals/
    │   ├── dashboards/
    │   ├── charts/
    │   └── diagrams/
    ├── interactive/
    └── templates/
```

### 1.2. Organize Script Files
- **Move and rename** the script files from `/course/video-scripts/` to the new module's `scripts/` directory.
- **Convention**:
    - `module-X-Y-topic-outline.md` → `outline.md`
    - `module-X-Y-topic-script.md` → `video-script.md`
    - `module-X-Y-topic-technical-validation.md` → `technical-validation.md`

### 1.3. Conduct Asset Inventory
- **Thoroughly read the video script** for the module.
- **Identify every visual or interactive element** mentioned (e.g., `[SCREEN: ...]`, `[CLICK: ...]`, `[DEMONSTRATE ...]`).
- **Create a checklist** for the module in the master `production-planning.md` document.

### 1.4. Create Git Feature Branch
- Before starting any work, create a new feature branch from `main`.
- **Naming Convention**: `module-X.Y-assets` (e.g., `module-0.2-assets`).

---

## Phase 2: Asset Creation & Refinement

For each asset identified in the inventory, follow these steps in order:

### 2.1. Create Initial Draft
- Build the basic HTML/SVG structure for the visual or interactive element.

### 2.2. Add Full Context
- **Immediately enrich the asset** with all relevant details from the video script. This is a critical step to avoid creating overly simplistic "bare-bones" visuals.
- This includes, but is not limited to:
    - **Titles, descriptions, and data points.**
    - **Annotations and callouts** that explain *why* something is important.
    - **Contextual information** like "Best for," "Advantages," "Trade-offs," and "Key Interactions."
    - **Directly quoting or paraphrasing** key insights from the script to ensure the visual and verbal messages are aligned.
- **Goal**: The asset should be a rich, self-contained piece of content that is understandable on its own, without needing the script for context.

### 2.3. Add Credibility Markers
- If the asset presents data or claims, **add source citations** from the corresponding `technical-validation.md` document.
- This can be a simple footer, a "Learn More" section, or a tooltip.
- **Explicitly state the source** where appropriate (e.g., "Source: Netflix Technology Blog"). This builds trust and authority.
- **Cross-reference claims** in the asset with the validation document to ensure 100% accuracy.

### 2.4. Ensure Clarity & Usability
- **Spell out acronyms** (e.g., "LTV") or provide tooltips for them.
- Ensure interactive elements are user-friendly (e.g., sliders must display their current value).
- **Check for visual bugs**, such as charts rendering incorrectly or elements overlapping.

### 2.5. Finalize Layout & Sizing
- **Confirm the layout is visually balanced** and professional.
- **Ensure the entire asset is visible on a standard 1920x1080 screen** without requiring scrolling. This may require adjusting padding, margins, and container heights.

---

## Phase 3: Review & Version Control

### 3.1. Self-Correction & Final Review
- Before presenting the work, review all created assets against this checklist.
- Ensure all steps in Phase 2 have been completed for every asset.

### 3.2. Request Feedback
- Once all assets for a module are complete and self-reviewed, ask for user feedback.

### 3.3. Await Approval for Commit
- **CRITICAL**: **Do not commit any changes** until you receive explicit approval from the user.

### 3.4. Commit & Push
- Once approved, create a single, clean commit for all the new assets and enhancements for that module.
- **Commit Message Convention**: `feat: create all production assets for module X.Y`
- Merge the feature branch to `main`.
- Push to the private repository using the `scripts/git-push-private.sh` script.

---

By following this workflow, we will ensure that all assets are created to the required standard from the beginning, saving significant time on revisions.
