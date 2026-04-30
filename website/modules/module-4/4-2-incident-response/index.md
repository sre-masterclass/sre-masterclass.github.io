---
layout: lesson
title: "Incident Response Workflows & Root Cause Analysis"
description: "The complete incident lifecycle — detection, triage, diagnosis, mitigation, recovery, review. Incident command structure, runbook automation, structured RCA techniques, and the blameless postmortem process that turns incidents into systemic improvements."
module_number: 4
module_id: module-4
module_slug: module-4
module_title: "Incident Response & Operations"
module_icon: "🚨"
module_color: "#ef4444"
lesson_number: 2
lesson_id: "4-2"
reading_time: 19
difficulty: "Advanced"
tools_count: 1
objectives:
  - "Execute each phase of the incident lifecycle with role clarity and minimal coordination overhead"
  - "Apply the Incident Commander model — including transitions of command and decision authority"
  - "Use structured RCA techniques (5 Whys, fishbone, causal trees) to find systemic causes, not blame"
  - "Run blameless postmortems that produce action items teams actually complete"
prev_lesson: /modules/module-4/4-1-proactive-alerting/
prev_title: "Proactive Alerting Design"
next_lesson: /modules/module-4/4-3-chaos-engineering/
next_title: "Chaos Engineering & Operational Validation"
---

## What Calm Looks Like Under Pressure

Watch a great SRE team handle a Sev-1 incident and you'll notice something striking: it looks *quiet*. There's no panic, no shouting in Slack, no hand-wringing about who's at fault. People know their roles, communication flows in predictable patterns, and decisions are made and recorded crisply.

That calm is not a personality trait. It's a *system* — a set of well-rehearsed roles, structured workflows, and explicit decision rights that reduce coordination cost during the worst possible time to be coordinating.

This lesson is about that system.

> **The core insight**: During a Sev-1 incident, the bottleneck is rarely engineering capability. It's coordination — knowing who decides what, who's communicating with whom, and how to keep new arrivals from re-asking questions that have already been answered. Incident response is fundamentally a coordination protocol.

---

## Part 1: The Incident Lifecycle

Every incident progresses through six phases. Treating them as distinct (rather than collapsing them into one big "fix it" blob) keeps everyone aligned on what's actually happening:

```
1. DETECTION    → Alert fires, on-call notified
2. TRIAGE       → Severity assigned, IC declared, team assembled
3. DIAGNOSIS    → Investigate; identify probable cause
4. MITIGATION   → Stop the bleeding (rollback, failover, traffic shifting)
5. RECOVERY    → Restore full capability, verify users unaffected
6. REVIEW       → Postmortem, action items, systemic improvements
```

The phases are not strictly linear — diagnosis and mitigation often interleave — but each transition is meaningful. Knowing which phase you're in tells you what the team should be doing.

### Phase 1: Detection

**Goal**: Get a competent human aware of the problem within 5 minutes.

The detection phase ends when an engineer has acknowledged the page. Anything that increases that lag — alerts going to Slack channels nobody watches, on-call schedules with gaps, missing escalation rules — is a Phase 1 bug.

**Key metric**: Mean Time To Acknowledge (MTTA), target <5 minutes for Sev-1.

### Phase 2: Triage

**Goal**: Within 10 minutes, have a declared severity, an incident commander, and a working communication channel.

Triage is the most-skipped phase. Engineers love jumping straight to diagnosis ("let me just check the dashboards"). The cost: by the time others join, nobody has set the severity, nobody is communicating to stakeholders, and the IC role is undefined. Five minutes spent on proper triage saves 30 minutes of confusion later.

**Triage checklist**:
- [ ] Severity declared (Sev-1, Sev-2, Sev-3)
- [ ] Incident Commander (IC) named
- [ ] Incident channel open (e.g., `#inc-2026-04-30-checkout-errors`)
- [ ] Status page initialized
- [ ] First stakeholder communication sent

**Key metric**: Mean Time To Triage (MTTT), target <10 minutes.

### Phase 3: Diagnosis

**Goal**: Identify a probable cause specific enough to inform a mitigation.

Diagnosis is the longest phase for most incidents. Two patterns to follow:

1. **Recent changes first.** What deployed in the last 24h? What infrastructure changes happened? 70%+ of incidents trace to a recent change.
2. **Top-down from symptom.** Start with the customer-facing symptom and walk down: which service? which dependency? which underlying resource?

Don't stop diagnosis to do mitigation if mitigation is *risky*. A clean rollback when you're 80% sure of the cause is great; "let's just restart everything" when you're 20% sure can lengthen the incident.

**Key metric**: Mean Time To Diagnose (MTTD), variable by incident.

### Phase 4: Mitigation

**Goal**: Stop the customer impact, even if the underlying problem is not yet fully understood.

The crucial distinction: **mitigation is not the same as resolution**. Common mitigations:

- **Rollback** — undo the recent change that probably caused this
- **Failover** — shift traffic to a different region or replica
- **Load shedding** — return errors for some traffic to keep the rest healthy
- **Feature flag** — disable the broken code path
- **Circuit breaker** — cut off a failing dependency

The right mitigation is whatever stops the bleeding fastest. Beautiful root-cause fixes are for *after* mitigation. **Don't trade MTTR for elegance.**

**Key metric**: Mean Time To Mitigate (MTTM), target proportional to severity (Sev-1: <30 min).

### Phase 5: Recovery

**Goal**: Verify the system is fully healthy, including subtle aftereffects.

Recovery is where rushed incidents go wrong. The mitigation worked, customer impact stopped, everyone breathes — and the team disbands without checking that:

- Background queues drained
- Any caches were warmed
- Replication caught up
- Customer data reconciled
- Internal tooling restored

A specific recovery checklist for each service prevents the "we thought we were done" Sev-1.5 — the second incident that comes from incomplete recovery.

### Phase 6: Review

**Goal**: Convert the incident into systemic improvements.

The postmortem is where most incident-response value is generated. The next two parts cover this in depth.

---

## Part 2: Incident Command

The Incident Commander (IC) is **not the most senior engineer**. The IC is the role responsible for coordination — keeping everyone aligned, deciding what to try next, and communicating to stakeholders.

### IC Responsibilities

1. **Establish and maintain the operating picture.** "Here's what we know, here's what we're trying, here's who's working on what."
2. **Make decisions.** When there's disagreement, the IC decides and the team executes. Disagreements get postmortem-time, not incident-time.
3. **Manage stakeholder communication.** The IC shields engineers from the constant "what's the status?" pings.
4. **Call for resources.** "We need someone from the database team here." "Can we get exec approval to fail over to DR?"
5. **Decide when the incident ends.** Not the engineers — the IC declares the all-clear.

### What the IC Doesn't Do

The IC **does not debug the system**. The moment the IC starts typing PromQL queries, they've stopped doing the IC job. Hand off command before diving in.

### IC Handoff

Long incidents need IC rotation — no one can run an IC role for more than 4 hours effectively. The handoff protocol:

```
Outgoing IC:
  1. Summarize current state (what we know, what we've tried, what's pending)
  2. List active workstreams and their owners
  3. Note next decisions expected
  4. Confirm new IC has acknowledged

Incoming IC:
  1. Read the incident channel from the start
  2. Ask any clarifying questions
  3. Announce takeover in the channel
  4. Re-ping the active workstream owners with updated direction
```

### Roles Beyond the IC

For Sev-1 incidents, you'll typically also need:

- **Tech Lead** — drives the technical debugging and mitigation work
- **Comms Lead** — owns external communication (status page, customer notifications)
- **Scribe** — captures timeline, decisions, and observations for the postmortem

Smaller incidents combine roles (the IC may also be the Comms Lead). But for anything Sev-1 lasting >30 minutes, separating these roles is high-leverage.

---

## Part 3: Runbook Design

A runbook is a written procedure that takes a responder from "this alert fired" to "I know what to do next." Good runbooks reduce MTTR by 5–10×; bad runbooks are worse than nothing.

### What a Good Runbook Contains

```markdown
# Runbook: Checkout High Burn Rate

## What this means
The checkout service is consuming error budget at >14× the SLO rate.
At this rate, the entire monthly budget will be exhausted in <50 minutes.

## First things to check (5 minutes max)
1. **Recent deployments**: Was there a checkout deploy in the last 30 min?
   - Dashboard: https://grafana/d/deploys-checkout
   - If yes → consider rollback (Step A)
   
2. **Dependency health**: Are payment-api and auth-api healthy?
   - Dashboard: https://grafana/d/checkout-deps
   - If a dep is unhealthy → coordinate with that team (Step B)

3. **Traffic anomaly**: Is there an unusual traffic pattern?
   - Dashboard: https://grafana/d/checkout-traffic  
   - If a spike → enable rate limiting (Step C)

## Mitigations
### Step A: Rollback
```
kubectl rollout undo deployment/checkout -n production
# Wait 2 minutes, watch dashboard
# Verify error rate returns below 0.5%
```

### Step B: Coordinate with dependency team
- Open #inc channel cross-link to dep team's incident channel
- Continue local investigation; their fix may resolve us

### Step C: Enable rate limiting
```
kubectl apply -f /runbooks/checkout/rate-limit-emergency.yaml
# This caps incoming traffic at 800 RPS, preserving SLO for users below the limit
```

## When to escalate
- Mitigation has not reduced error rate within 15 minutes → escalate to checkout-team-lead
- Customer-facing impact exceeds 5% → declare Sev-1 if not already
- Multiple AZs affected → page infra-team
```

### Runbook Maintenance

A runbook that wasn't updated in the last 6 months is suspect. A runbook that wasn't used in the last 12 months should be deleted (or its alert deleted — see Lesson 4.1).

The validation cycle: every postmortem that touches a runbook updates it. The on-call rotation review ("did the runbook help?") happens weekly. The full audit happens quarterly.

---

## Part 4: Structured Root Cause Analysis

Once the incident is over, the question is: *what made this possible, and what can we change so the same problem can't recur?*

### Technique 1: The Five Whys

Ask "why" five times to drill from symptom to systemic cause:

```
Q1: Why did checkout error rate spike?
A1: The payment-api was returning 500s.

Q2: Why was payment-api returning 500s?
A2: Database connections were exhausted.

Q3: Why were database connections exhausted?
A3: A new code path opens connections without releasing them on certain error paths.

Q4: Why was that bug not caught?
A4: Our integration tests don't exercise that error path.

Q5: Why don't they exercise it?
A5: We don't have a testing convention for forcing internal errors during tests.
```

The deepest "why" answer is rarely "Sarah made a mistake." It's almost always a missing test, an absent process, or a structural gap. **Five Whys done well surfaces system design issues, not human error.**

### Technique 2: The Fishbone Diagram

For incidents with multiple contributing factors, the fishbone (Ishikawa) diagram organizes them into categories:

```
                              [Incident]
                                  |
   ┌──────────┬───────────┬──────────┬──────────┬──────────┐
 People    Process    Tools     Code        Infra      Communication
   │           │          │         │          │              │
 - on-call  - missed   - alert    - bug in   - DB           - status
   training   handoff    fatigue    error      vendor          page slow
              from        on this    path       capacity        to update
              prev IC     dashboard
```

The fishbone surfaces the *combination* of factors that produced the incident. Fixing only one branch is rarely sufficient — most production incidents are multi-causal.

### Technique 3: Causal Trees / Apollo Method

A causal tree is the fishbone done as a tree, with each node showing what *enabled* the level above:

```
[Incident: Checkout Sev-1, 47 min outage]
├── Why customer-facing?
│   ├── No graceful degradation in checkout UI
│   └── Cache layer doesn't serve stale data on backend errors
├── Why undetected for 12 minutes?
│   ├── Single-window 5m alert was suppressed during deploy
│   └── No multi-window burn rate alert configured
├── Why happened at all?
│   ├── Untested error path in new code
│   ├── Code review didn't catch the connection leak
│   └── Pre-prod environment doesn't replicate connection-pool behavior
```

Each leaf is a potential action item. The team picks the highest-leverage 3–5 to commit to.

### Anti-Patterns in RCA

- **Stopping at "human error."** "Sarah pushed the wrong config" is never the root cause. Why did the system allow it? Why was the wrong config not caught in CI? *That's* the root cause.
- **Searching for a single root cause.** Most production incidents have 3–5 contributing factors. Pick all of them, not one.
- **Postmortem as performance review.** The moment the postmortem becomes about *who* messed up, you stop getting honest input. Honest input is the entire point.

---

## Part 5: The Blameless Postmortem

The postmortem is a written document and a meeting. Both have rules.

### Postmortem Document Structure

```markdown
# Incident Postmortem: Checkout High Burn Rate, 2026-04-30

## Summary
One paragraph describing what happened, when, customer impact, resolution.

## Impact
- Customer-facing duration: X minutes
- Affected users: ~Y%
- Failed transactions: Z
- Error budget consumed: W%
- Revenue impact: $estimate

## Timeline
- 14:32 UTC — Deploy of checkout v3.4.1
- 14:38 UTC — First error rate increase (latent for 6 min)
- 14:44 UTC — Multi-window burn rate alert fires; on-call paged
- 14:46 UTC — IC declared, channel opened
- 14:51 UTC — Diagnosis pointed to deploy
- 14:53 UTC — Rollback initiated
- 14:58 UTC — Error rate returned to baseline
- 15:15 UTC — Recovery verified, all-clear declared

## Root Cause
[Causal analysis using Five Whys or fishbone — see above]

## What went well
- Multi-window burn rate alert fired before single-window would have
- Rollback procedure executed cleanly in 5 minutes
- IC role transition between two responders was smooth

## What didn't go well  
- Status page update was delayed by 8 minutes
- Initial deploy missed our integration test gap
- Stakeholder comms were inconsistent across channels

## Action items
| ID | Description | Owner | Due | Priority |
|---|---|---|---|---|
| AI-1 | Add integration test for error-path connection leaks | sarah | 2026-05-15 | P0 |
| AI-2 | Pre-deploy automation for status page warming | jordan | 2026-05-22 | P1 |
| AI-3 | Update deploy runbook with new check | mike | 2026-05-08 | P1 |
```

### Postmortem Meeting Rules

1. **Blameless language.** "The system allowed X" not "Person did X." When a human action contributed, frame it as "the process didn't prevent" — this surfaces the system gap that made the action possible.
2. **Read the doc together.** Don't present the postmortem; everyone reads it silently for 10 minutes, then discusses. Reading reveals different reactions to the same facts.
3. **Action items must have owners and dates.** "Improve testing" is not an action item. "Sarah will add an integration test for connection leak detection by 2026-05-15" is.
4. **Count last quarter's action items.** Open the previous postmortem at the start. How many action items completed? If <80%, you have a process problem larger than the current incident.

### Action Item Hygiene

The single most-cited cause of "incidents that recur" is action items from the original postmortem that never got done. Treat postmortem action items with the same rigor as committed sprint work — and if the team's velocity won't accommodate them, *escalate to leadership* rather than letting them silently rot.

---

## Try the Root Cause Analysis Workshop

The interactive workshop walks you through realistic incident scenarios using structured RCA techniques. You'll practice the Five Whys, fishbone diagrams, and causal trees on incidents drawn from the same kinds of services you'd see in production.

{% include tool-embed.html
   title="Root Cause Analysis Workshop"
   src="/tools/root-cause-analysis-workshop.html"
   description="Practice RCA on simulated incidents. Apply Five Whys, fishbone analysis, and causal trees to identify systemic causes (not just immediate triggers). See how different RCA techniques surface different aspects of the same incident."
   height="780"
%}

---

## Key Takeaways

**1. Incident response is a coordination protocol, not a debugging exercise.** The bottleneck during a Sev-1 is almost never engineering capability — it's coordination cost. Investing in role clarity (IC, Tech Lead, Comms, Scribe) pays back enormously.

**2. The IC role is about coordination, not seniority.** The IC's job is to keep everyone aligned and make decisions. The moment the IC starts debugging, the IC has stopped doing the IC job. Hand off command before diving in.

**3. Mitigation is not resolution. Stop the bleeding first.** Beautiful root-cause fixes belong in the postmortem-driven follow-up. During the incident, optimize for "customer impact stopped" — even if the system isn't fully healthy yet.

**4. RCA techniques surface systemic causes, not blame.** Five Whys, fishbone, and causal trees all converge on the same insight: production incidents are almost always multi-causal and rooted in process or design gaps, not individual failure.

**5. The blameless postmortem is the SRE program's primary improvement engine.** Without it, incidents are just damage. With it, they're tuition. Action item completion rate is the single best metric for postmortem effectiveness.

---

*The next step beyond responding to incidents is *manufacturing* them — deliberately, in controlled ways, to validate your systems. Lesson 4.3 covers chaos engineering: how to break things on purpose to make them harder to break by accident.*
