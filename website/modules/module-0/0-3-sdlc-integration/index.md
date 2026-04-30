---
layout: lesson
title: "SDLC Integration Points"
description: "Map every phase of your software development lifecycle to specific SRE integration touchpoints — where reliability gates, error budget policies, and engineering practices create the most leverage."
module_number: 0
module_id: module-0
module_slug: module-0
module_title: "Strategic Foundation"
module_icon: "🧭"
module_color: "#8b5cf6"
lesson_number: 3
lesson_id: "0-3"
reading_time: 16
difficulty: "Introductory"
tools_count: 2
objectives:
  - "Map SRE integration points to each phase of the software development lifecycle"
  - "Design reliability gates that protect SLOs without blocking development velocity"
  - "Implement error budget policies that align reliability decisions with business priorities"
  - "Build SRE touchpoints into Agile ceremonies without creating process overhead"
prev_lesson: /modules/module-0/0-2-team-models/
prev_title: "SRE Team Models & Responsibilities"
next_lesson: /modules/module-0/0-4-collaboration/
next_title: "Collaboration & Communication"
---

## Reliability Is Built Throughout the Lifecycle, Not Bolted On at the End

The most expensive way to achieve reliability is to build features without reliability considerations, then fix the resulting production problems reactively. The SRE practices that create the most value are those integrated early — in planning, in design, in development — not just in operations.

This lesson maps the specific SRE touchpoints across each phase of the software development lifecycle, showing what to do, when to do it, and how to avoid creating process overhead that blocks development velocity.

> **The core principle**: Every development lifecycle phase has a natural moment where a reliability question can be asked cheaply. Ask it later, and the cost multiplies dramatically. The SDLC integration points in this lesson are those natural moments.

---

## Phase 1: Planning & Prioritization

SRE's earliest and most underutilized opportunity is in product and engineering planning — before a single line of code is written.

### Reliability as a Product Requirement

At the planning stage, SRE asks one critical question: **What reliability does this feature need to provide, and is that reliability achievable within our current error budget?**

This translates into concrete planning actions:

**SLO consideration in feature scoping**: Every new feature should have a documented reliability expectation. Not a full SLO definition at this stage — just an answer to: "If this feature is unavailable or degraded, what's the business impact? Does it justify a separate SLO or does it fall under an existing one?"

**Error budget awareness in sprint planning**: Teams with low error budget remaining should have a reliability-weighted sprint. Features that increase reliability risk should require explicit error budget approval.

**Dependency mapping**: New features that introduce dependencies on external services, new databases, or third-party APIs should trigger a reliability review. External dependency failures are a leading cause of SLO breaches.

### The Sprint Planning SRE Checklist

Integrate these questions into your sprint planning ceremony without creating a separate process:

1. Does this sprint introduce any new external dependencies?
2. Does any work in this sprint affect services with <20% error budget remaining?
3. Are there any schema migrations or infrastructure changes requiring a reliability review?
4. Does the sprint include any technical debt reduction that improves reliability?

This takes 3–5 minutes in sprint planning and prevents the most common reliability surprises.

{% include tool-embed.html
   title="Sprint Planning Reliability Simulator"
   src="/modules/module-0/0-3-interactive/sprint-planning-simulator.html"
   description="Simulate sprint planning decisions with error budget awareness. See how different feature mixes affect error budget consumption and SLO compliance over time."
   height="660"
%}

---

## Phase 2: Design & Architecture

Architecture reviews are where SRE can prevent the most expensive reliability problems — before they're built in.

### The SRE Architecture Review

Not every service needs a full SRE architecture review. Use a risk-based approach:

**Triggers for a mandatory SRE architecture review:**
- New service being added to production
- Significant changes to a service handling >10,000 requests/day
- New external dependency being introduced
- Database schema changes affecting critical user journeys
- Changes that affect failover or disaster recovery behavior

**What the review covers:**

**Failure mode analysis**: How does this system fail? What happens to dependent services when it does? Are failures isolated (circuit breakers, bulkheads) or cascading?

**Observability design**: What signals will tell us this service is healthy? What metrics, logs, and traces need to be emitted? Are SLO-relevant signals instrumented from day one?

**SLO target review**: Is the proposed SLO target achievable given the architecture? What's the theoretical maximum availability given the dependencies?

**Recovery design**: How does the service recover from failure? Automatic or manual? What's the expected MTTR?

### Design Patterns That Pay SRE Dividends

Certain architectural patterns dramatically reduce operational complexity. Advocate for these in design reviews:

**Circuit breakers**: Automatically stop calling a failing dependency, preventing cascade failures and giving the dependency time to recover.

**Bulkheads**: Isolate service components so that failure in one area (e.g., a slow database query) doesn't exhaust resources for unrelated operations.

**Graceful degradation**: Define what the system does when a non-critical dependency fails. Can checkout work without personalization? Can search work without recommendations?

**Idempotent operations**: Design operations that can be safely retried without side effects — critical for recovery automation.

{% include diagram-embed.html
   title="Traditional vs SRE-Enhanced SDLC Workflow"
   src="/modules/module-0/0-3-visuals/diagrams/traditional-vs-sre-sdlc-workflow.html"
   height="500"
%}

---

## Phase 3: Development & Implementation

SRE's role during development is to ensure that reliability-relevant code gets the same scrutiny as functional code.

### Instrumentation Requirements

Services shipped without proper instrumentation create operational blind spots. Establish minimum instrumentation requirements that apply to all services:

**Mandatory metrics (RED methodology baseline):**
```
# Rate — requests per second
http_requests_total{method, path, status_code}

# Errors — failed requests
http_request_errors_total{method, path, error_type}

# Duration — request latency histogram
http_request_duration_seconds_bucket{method, path, le}
```

**Mandatory structured logging:**
- Correlation IDs for request tracing
- Severity levels used consistently (DEBUG, INFO, WARN, ERROR)
- No sensitive data in log fields
- Latency of external dependency calls logged at DEBUG/INFO

**Health check endpoints:**
- `/health/live` — is the process running?
- `/health/ready` — is the service ready to accept traffic?
- `/health/deep` — are all dependencies healthy? (Used in pre-deployment checks)

### Code Review Reliability Checklist

Add these to your standard code review process:

- Does new code that modifies external calls have appropriate timeout and retry logic?
- Are error types correctly classified? (Transient vs permanent errors require different handling)
- Does new functionality have test coverage for failure paths, not just happy paths?
- Are new configuration values observable? (Can you see them in metrics or logs?)
- Do schema migrations have a rollback path?

---

## Phase 4: Testing & Validation

Testing for reliability requires a different mindset than testing for functionality. Functionality tests ask "does it work?" Reliability tests ask "how does it fail, and does it fail well?"

### The Testing Pyramid for Reliability

**Unit tests**: Cover the error handling logic, not just the happy path. Test what happens when a database call times out, when an API returns 500, when a queue is full.

**Integration tests**: Verify that failure isolation works. Inject failures into dependencies and confirm that the service degrades gracefully rather than failing completely.

**Chaos tests (staging)**: Run controlled failure experiments. Kill service instances, introduce network latency, exhaust connection pools. Verify that SLOs hold under failure conditions.

**Load tests**: Verify that the service meets its SLO targets at expected peak traffic. Don't discover capacity problems in production.

### Pre-Deployment Reliability Gate

Before any service deploys to production, validate:

1. **SLO instrumentation test**: All required metrics are being emitted correctly
2. **Health check validation**: All health endpoints respond correctly
3. **Dependency readiness**: All dependencies are healthy and meeting their own SLOs
4. **Error budget check**: The service's error budget can absorb the deployment risk

{% include diagram-embed.html
   title="CI/CD Pipeline with SRE Gates"
   src="/modules/module-0/0-3-visuals/diagrams/cicd-pipeline-sre-gates.html"
   height="460"
%}

---

## Phase 5: Deployment

Deployment is when changes become production risk. SRE integration here focuses on risk reduction and fast rollback.

### Safe Deployment Practices

**Progressive rollouts**: Never deploy to 100% of traffic immediately. Use canary deployments (1% → 10% → 50% → 100%) with automated SLO evaluation at each stage.

**Deployment windows**: Avoid deployments during high-traffic periods unless absolutely necessary. Define deployment windows and make exceptions require explicit approval.

**Rollback automation**: Every deployment must have an automated rollback procedure that can be triggered in < 5 minutes without requiring the original deploying engineer.

**Deployment freezes**: When error budgets are critically low (< 10% remaining), non-emergency deployments require explicit SRE approval. This is the error budget policy in practice.

### The Deployment Decision Framework

Use this decision tree for every non-trivial deployment:

```
Is error budget > 20%?
  Yes → Standard deployment process
  No  → Is this a reliability fix?
          Yes → Expedited review, then deploy
          No  → Defer until budget recovers OR get explicit VP Engineering approval
```

This isn't bureaucracy — it's a principled trade-off framework that prevents "we burned our error budget on features and now can't respond to incidents."

---

## Phase 6: Operations & Incident Response

Operations is where SRE is most visible, but it's also where the leverage of earlier SDLC integration becomes apparent. Systems designed, built, and deployed with SRE practices are dramatically easier to operate.

### Operational Runbooks

Every critical service path needs a runbook — a documented response procedure for the most common failure scenarios. Runbooks should be:

- **Actionable**: Step-by-step procedures, not vague guidance
- **Tested**: Reviewed during chaos engineering exercises
- **Linked from alerts**: When an alert fires, the runbook is one click away
- **Living documents**: Updated after every incident that reveals a gap

### Post-Incident Learning

Every significant incident should produce a blameless post-incident review (PIR). The PIR is not about finding fault — it's about finding system improvements.

A complete PIR includes:
1. **Timeline**: What happened, when, detected by whom
2. **Root cause analysis**: Contributing factors (not a single root cause — systems rarely have one)
3. **Customer impact**: Quantified in SLO terms
4. **Error budget impact**: How much budget was consumed
5. **Action items**: Specific, assigned, time-bound improvements

{% include tool-embed.html
   title="SDLC Integration Planner"
   src="/modules/module-0/0-3-interactive/sdlc-integration-planner.html"
   description="Map SRE integration points to your team's specific SDLC phases. Generate a custom integration checklist based on your team size, deployment frequency, and current reliability maturity."
   height="680"
%}

---

## The Error Budget Policy

The error budget policy is the document that connects SRE's SDLC integration points into a coherent framework. It answers: **what happens when the error budget is consumed at different rates?**

A practical error budget policy has four tiers:

**Green (> 50% budget remaining)**: Normal operations. Full deployment velocity. Feature work continues without restrictions.

**Yellow (20–50% remaining)**: Enhanced monitoring. Deployment reviews for high-risk changes. SRE team alerted to the trend.

**Orange (10–20% remaining)**: Mandatory reliability sprint. One sprint of reliability-focused work before new features. Deployments require SRE approval.

**Red (< 10% remaining)**: Feature freeze. Only reliability-improving changes deploy. Executive visibility. Root cause analysis required.

---

## Key Takeaways

**1. Shift reliability left.** The cheapest reliability investments are those made during design and planning. The most expensive are production incidents.

**2. Integrate, don't add process.** SRE touchpoints should fit into existing planning ceremonies and code review processes — not create parallel processes that teams bypass.

**3. The error budget policy is your reliability constitution.** It translates abstract SLO percentages into concrete operational decisions that everyone understands.

**4. Runbooks are a reliability investment.** Every hour spent writing runbooks in calm times saves 5–10 hours of chaotic incident response.

**5. Post-incident reviews are where systems improve.** The blameless PIR process turns incidents from pure losses into system-improvement opportunities.

---

*The final Module 0 lesson covers the cross-functional collaboration and communication patterns that make SRE programs stick — the cultural and process work that separates SRE programs that achieve lasting change from those that fade after the initial enthusiasm.*
