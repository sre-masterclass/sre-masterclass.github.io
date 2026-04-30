---
layout: lesson
title: "SRE Team Models & Responsibilities"
description: "Compare embedded, centralized, and consulting SRE organizational models. Understand what each model owns, how they interact with product engineering, and which fits your organizational context."
module_number: 0
module_id: module-0
module_slug: module-0
module_title: "Strategic Foundation"
module_icon: "🧭"
module_color: "#8b5cf6"
lesson_number: 2
lesson_id: "0-2"
reading_time: 18
difficulty: "Introductory"
tools_count: 2
objectives:
  - "Distinguish between the three primary SRE organizational models and their trade-offs"
  - "Evaluate which model best fits your organization's size, culture, and reliability maturity"
  - "Define clear responsibility boundaries between SRE and product engineering teams"
  - "Design a team evolution path as your SRE program matures"
prev_lesson: /modules/module-0/0-1-business-value/
prev_title: "Business Value Quantification"
next_lesson: /modules/module-0/0-3-sdlc-integration/
next_title: "SDLC Integration Points"
---

## Why Organizational Model Matters as Much as Technical Capability

Many SRE programs fail not because the engineers aren't skilled, but because the team model was wrong for the organization. A centralized SRE team in a company with strong team autonomy culture will be ignored. An embedded model in a company without clear reliability ownership will result in SREs who get absorbed into feature development with no reliability impact at all.

Getting the organizational model right is a prerequisite for technical effectiveness.

> **The fundamental question every SRE program must answer**: Who owns reliability, how does that ownership interact with development velocity, and how do those ownership boundaries evolve as the program matures?

---

## The Three Primary SRE Models

### Model 1: Centralized SRE

A dedicated team of SREs that serves the entire engineering organization as a reliability platform.

**How it works**: The centralized SRE team owns the monitoring platform, incident management process, SLO framework, and reliability tooling. Product teams consume these as internal services. The SRE team may also take on-call responsibilities for critical infrastructure and provide incident response support during major outages.

**Ownership model**:
- **SRE owns**: Monitoring infrastructure, alerting framework, SLO tooling, incident management process, error budget governance, chaos engineering platform
- **Product engineering owns**: Service instrumentation, SLO target setting, on-call for their own services, feature delivery

**When it works best**:
- Organizations with 10+ product engineering teams
- Strong platform engineering culture
- Clear separation between infrastructure and product concerns
- Senior SRE leadership with organizational credibility

**Real-world example — Google's original model**: Google's SRE organization is the definitive centralized model. Central SRE teams own shared infrastructure, define the SLO framework, and "take handoff" of services that meet their reliability standards. Product teams that can't maintain reliability standards have their service handed back. This model requires enormous organizational authority — which Google's SRE org has by virtue of being where the model was invented.

**Pitfalls to avoid**:
- Becoming a bottleneck for teams that need reliability guidance
- SREs disconnected from product context making poor reliability trade-offs
- Building ivory-tower tooling that teams don't actually use

{% include diagram-embed.html
   title="Centralized SRE Model — Organizational Structure"
   src="/modules/module-0/0-2-visuals/diagrams/centralized-sre-model.html"
   height="480"
%}

---

### Model 2: Embedded SRE

SRE engineers are assigned to specific product teams, sitting within those teams and participating in their development cycle.

**How it works**: Each SRE is aligned to one or two product teams. They attend team standups, sprint planning, and retrospectives. They participate in architecture reviews, help define SLOs, build team-specific reliability tooling, and often share on-call rotations. They remain organizationally part of an SRE team or chapter for career development and knowledge sharing.

**Ownership model**:
- **SRE owns**: Team-specific reliability roadmap, SLO definition and measurement, chaos engineering experiments, reliability architecture review
- **Product engineering owns**: Feature development, service ownership, SLO target accountability
- **Shared**: On-call, incident response, service instrumentation

**When it works best**:
- Organizations where product teams have strong autonomy
- Systems with complex, domain-specific reliability requirements
- Early-stage SRE programs establishing credibility
- Companies where central mandates are culturally difficult

**Real-world example — Spotify's Squad model**: Spotify's model embeds SREs (or "reliability engineers") within their squad structure. Each squad owns its service end-to-end, including reliability. SREs provide expertise within squads, not as external gatekeepers. This aligns reliability ownership with product ownership and creates deep domain expertise.

**Pitfalls to avoid**:
- SREs getting absorbed into feature development (the "shadow developer" anti-pattern)
- Knowledge silos across embedded SREs without strong chapter coordination
- Inconsistent SLO definitions and tooling across teams

{% include diagram-embed.html
   title="Embedded SRE Model — Team Integration"
   src="/modules/module-0/0-2-visuals/diagrams/embedded-sre-model.html"
   height="480"
%}

---

### Model 3: Consulting / Center of Excellence SRE

A small team of senior SREs who advise product teams on reliability practices without owning operational responsibility.

**How it works**: The SRE consulting team reviews architectures, defines organizational SLO standards, runs reliability training programs, helps teams instrument services, and facilitates chaos engineering workshops. They do not own production systems or take on-call. Product teams retain full ownership.

**Ownership model**:
- **SRE owns**: Standards, frameworks, education, tooling recommendations, architecture review
- **Product engineering owns**: Everything in production — instrumentation, SLOs, on-call, incident response

**When it works best**:
- Organizations scaling SRE practices faster than they can hire SREs
- Mature engineering organizations that need a standards layer, not operational support
- Companies transitioning from centralized to embedded models
- Early-stage programs with limited SRE headcount

**Real-world example**: Many mid-size companies use this model as their first SRE investment. A team of 2–3 senior SREs sets the reliability standards, builds the SLO framework, runs training for hundreds of engineers, and advises on architecture — multiplying their impact without requiring embedded headcount.

**Pitfalls to avoid**:
- Recommendations that don't get implemented without accountability
- Consultants disconnected from production realities
- Becoming a compliance function rather than an enabling one

{% include diagram-embed.html
   title="Hybrid SRE Model — Evolution Path"
   src="/modules/module-0/0-2-visuals/diagrams/hybrid-sre-model.html"
   height="480"
%}

---

## Comparing the Models

| Dimension | Centralized | Embedded | Consulting |
|---|---|---|---|
| **Reliability ownership** | SRE team | Shared | Product team |
| **Scale** | High (1 SRE : many teams) | Low (1 SRE : 1-2 teams) | Very high (1 SRE : org) |
| **Domain expertise** | Broad, shallow | Deep, narrow | Standards-deep |
| **Response to incidents** | SRE leads | Shared | Product team leads |
| **Best org size** | Large (500+ eng) | Medium (50-500 eng) | Any |
| **SRE headcount needed** | High | Very high | Low |
| **Risk of SRE bottleneck** | High | Low | None |
| **Risk of reliability gap** | Low | Medium | High |

---

## Choosing the Right Model

Use these questions to guide the selection:

**1. How much organizational authority does the SRE program have?**
- High authority → Centralized can work
- Low authority → Embedded or Consulting to earn credibility first

**2. How autonomous are your product teams?**
- High autonomy culture → Embedded fits naturally
- Platform culture → Centralized fits naturally

**3. How many SRE engineers do you have or plan to hire?**
- < 5 SREs → Consulting or selective embedding
- 5–15 SREs → Embedded with chapter structure
- 15+ SREs → Centralized platform with embedded specialists

**4. What's your current reliability maturity?**
- Low maturity → Centralized establishes standards faster
- High maturity → Consulting maintains standards efficiently

{% include tool-embed.html
   title="SRE Team Model Selector"
   src="/modules/module-0/0-2-interactive/team-model-selector.html"
   description="Answer questions about your organization's size, culture, reliability maturity, and headcount to get a model recommendation with implementation guidance."
   height="680"
%}

---

## Defining Responsibility Boundaries

Regardless of which model you choose, clear responsibility boundaries prevent the most common SRE organizational failures.

### The Engagement Model

Every SRE program needs a documented engagement model that answers:

**What does a team need to do to get SRE support?**
- Minimum instrumentation requirements
- SLO definition process
- Architecture review process for new services

**What does SRE owe to product teams?**
- Response time for reliability reviews
- Support during incidents
- Tooling and framework availability

**What happens when reliability degrades?**
- Error budget policy enforcement
- Escalation path for chronic reliability issues
- SLO renegotiation process

### The Toil Boundary

One of the most critical boundaries is between SRE work and toil. **Toil** is manual, repetitive operational work that scales with service growth without providing lasting value.

SREs should spend no more than 50% of their time on operational toil (incident response, manual deployments, routine maintenance). The other 50% must go toward engineering work that reduces future toil — automation, tooling, process improvement.

If your SREs are spending more than 50% on toil, the team model is wrong: either you need more SREs, or the product team needs to take back more operational ownership.

---

## The Team Evolution Path

SRE organizational models should evolve as the program matures. A common progression:

**Phase 1 (0–6 months): Consulting**
2–3 senior SREs establish the framework, define SLO standards, and build foundational tooling. No operational ownership — purely advisory.

**Phase 2 (6–18 months): Selective Embedding**
SREs embed with the highest-risk or highest-value product teams. They build deep domain expertise and establish proof points for the model. Centralized tooling emerges.

**Phase 3 (18+ months): Hybrid**
A central SRE platform team owns shared infrastructure. Embedded SREs own domain-specific reliability with product teams. The consulting function continues for new teams and edge cases.

{% include tool-embed.html
   title="Incident Response Model Comparison"
   src="/modules/module-0/0-2-interactive/incident-response-simulator.html"
   description="Simulate how different SRE organizational models respond to incidents of varying severity. Compare response times, escalation paths, and resolution quality across models."
   height="640"
%}

---

## Key Takeaways

**1. Model selection is a strategic decision, not a technical one.** The right model depends on your organization's culture, size, and reliability maturity — not on what Google or Netflix does.

**2. Start with clear authority.** Whatever model you choose, the SRE program needs explicit organizational backing. Without it, recommendations won't be implemented and ownership boundaries will be violated.

**3. Define the engagement model in writing.** Clear written agreements about what SRE provides and what product teams are responsible for prevent the most common organizational failures.

**4. Plan for evolution.** No organization keeps the same SRE model forever. Design your initial model with the next phase in mind.

**5. Guard against toil accumulation.** The 50% toil limit is a forcing function. If SREs are buried in operational work, the program is failing — regardless of how good individual engineers are.

---

*The next lesson maps every phase of the software development lifecycle to specific SRE integration points — where reliability gates, error budget policies, and SRE reviews create the most leverage.*
