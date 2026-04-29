# SRE Masterclass: Video Script Format & Style Guide

## Document Overview
This guide documents the standard format and style requirements for all SRE Masterclass video scripts, extracted from the established pattern in `sre-latency-script.md`.

**Version**: 1.0  
**Applies to**: All video content (30-40 hours total)  
**Template Count**: 5 core templates covering all module types

---

## Script Structure Standards

### 1. Header Section (Required)
```markdown
# SRE Masterclass: [Topic Title]
## Complete Video Script - Module X.Y: [Specific Learning Focus]

---

## Video Overview
**Duration**: X-Y minutes  
**Learning Objectives**:
- [Specific, measurable learning outcome]
- [Technical skill or concept mastery]
- [Practical application ability]

**Prerequisites**: [Required prior knowledge/modules]
```

### 2. Content Section Structure
All scripts must follow this hierarchical organization:

#### **Introduction (30-60 seconds)**
- Hook with practical problem/scenario
- Learning objective preview
- Context setting with visual elements

#### **Main Content Sections (2-8 minutes each)**
- **Part 1**: Foundation concepts
- **Part 2**: Detailed analysis/implementation
- **Part 3**: Advanced applications
- **Part 4**: Key takeaways & next steps

### 3. Production Notes Section (Required)
```markdown
## Video Production Notes

### Visual Flow and Timing
**Interactive Demonstration Sequence**:
1. **0:00-0:45**: [Segment description with visual cues]
2. **0:45-2:45**: [Next segment with interaction points]

### Critical Visual Moments
**[Concept] Revelation Points**:
- **X:XX**: [Specific visual/interaction] - "[Exact quote for emphasis]"

### Educational Hooks
**Pattern Recognition Training**:
- [Specific learning pattern students should recognize]
**Confidence Building**:
- [How content builds student confidence]
```

### 4. Assessment Integration (Required)
```markdown
## Instructor Notes

### Common Student Questions
**Q: "[Anticipated question]"**
A: "[Clear, actionable answer with examples]"

### Extension Activities
**For Advanced Students**: [Additional challenges]
**For Practical Application**: [Real-world exercises]
```

---

## Content Depth Standards

### Technical Rigor Requirements
- **Mathematical precision**: Include actual calculations with examples
- **Statistical accuracy**: Verify all statistical claims with data
- **Code examples**: Provide working, tested code snippets
- **Practical validation**: Every concept must have hands-on application

### Chaos Engineering Integration
- **Progressive complexity**: Start with simple scenarios, build to complex
- **Real-world correlation**: Connect each scenario to actual incident patterns
- **Measurement focus**: Always show how to measure and detect issues
- **Recovery procedures**: Include resolution and prevention strategies

### Interactive Element Standards
- **Screen directions**: Precise UI interaction guidance
- **Timing coordination**: Exact timing for visual reveals
- **Emphasis patterns**: Consistent visual highlighting techniques
- **Accessibility**: Ensure visual content has verbal descriptions

---

## Script Timing Standards

### Duration Guidelines by Content Type
- **Strategic content**: 6-10 minutes per concept
- **Technical deep-dives**: 8-12 minutes per major topic
- **Hands-on tutorials**: 10-15 minutes per implementation
- **Incident scenarios**: 5-8 minutes per chaos scenario
- **Integration workshops**: 12-18 minutes per workflow

### Pacing Requirements
- **Introduction**: 30-60 seconds maximum
- **Concept introduction**: 90-120 seconds per new idea
- **Deep analysis**: 2-4 minutes per complex topic
- **Practical application**: 3-6 minutes per hands-on section
- **Wrap-up/transition**: 15-30 seconds

---

## Visual Standards

### Screen Interaction Patterns
```markdown
**[SCREEN: Specific dashboard/interface description]**
**[CLICK: Button/UI element]** - "Action description"
**[PAUSE for emphasis, point to specific element]**
**[TOGGLE: Feature on/off]** - "State change explanation"
```

### Emphasis Techniques
- **Bold text**: For key concepts and important terms
- **Code blocks**: For all technical implementations
- **Bullet points**: For structured information
- **Numbered lists**: For sequential procedures
- **Callout boxes**: For critical warnings or insights

### Mathematical Notation
- Use LaTeX syntax for complex formulas
- Provide verbal explanations for all equations
- Include practical examples with real numbers
- Show calculation steps explicitly

---

## Content Quality Standards

### Technical Accuracy Requirements
- All code must be tested and functional
- Prometheus queries must return expected results
- Grafana dashboards must display correctly
- Chaos scenarios must produce measurable effects

### Educational Effectiveness
- Learning objectives must be measurable
- Each concept must build on previous knowledge
- Practical applications must be immediately usable
- Assessment questions must validate understanding

### Production Quality
- Scripts must specify exact visual timing
- Interactive elements must be clearly documented
- Audio cues must be integrated with visual elements
- Transitions between sections must be smooth

---

## Module-Specific Adaptations

### Module 0: Strategic Foundation
- **Focus**: Business value and organizational impact
- **Tone**: Executive-friendly, ROI-focused
- **Examples**: Industry case studies, cost calculations
- **Duration**: 6-8 minutes per topic

### Module 1: Technical Foundations
- **Focus**: Core concepts and basic implementation
- **Tone**: Educational, building confidence
- **Examples**: Simple monitoring setups, basic queries
- **Duration**: 8-10 minutes per topic

### Module 2: SLO/SLI Mastery (Your existing script model)
- **Focus**: Deep statistical analysis and practical application
- **Tone**: Analytical, mathematically rigorous
- **Examples**: Real distribution analysis, percentile calculations
- **Duration**: 8-12 minutes per topic

### Module 3: Advanced Monitoring
- **Focus**: Complex analysis and pattern recognition
- **Tone**: Expert-level, system-thinking focused
- **Examples**: Multi-dimensional analysis, anomaly detection
- **Duration**: 10-15 minutes per topic

### Module 4: Incident Response
- **Focus**: Real-time problem solving and decision making
- **Tone**: Urgent but systematic, crisis management
- **Examples**: Live incident walkthroughs, decision trees
- **Duration**: 5-10 minutes per scenario

### Module 5: CI/CD Integration
- **Focus**: Automation and systematic improvement
- **Tone**: Process-oriented, optimization-focused
- **Examples**: Pipeline integration, automated testing
- **Duration**: 12-18 minutes per workflow

---

## Chaos Scenario Integration Patterns

### Basic Integration (Modules 1-2)
```markdown
**[CHAOS SCENARIO: 5-minute-latency-spike.yml]**
"Now let's see what happens when we introduce some realistic chaos..."
**[TRIGGER: Latency spike]**
"Watch how our metrics change..."
```

### Advanced Integration (Modules 3-4)
```markdown
**[CHAOS ORCHESTRATION: cascading-failure.yml]**
"This scenario simulates a real incident that affected Netflix in 2012..."
**[STEP 1: Database slowdown]**
**[STEP 2: Connection pool exhaustion]**
**[STEP 3: Service cascade failure]**
"Notice how each step would trigger different alerts..."
```

### Progressive Complexity Framework
1. **Single-service impacts** (latency, CPU, memory)
2. **Multi-service dependencies** (database, network, connections)
3. **Cascading failures** (deployment, resource starvation)
4. **Full system scenarios** (orchestrated chaos experiments)

---

## Template Integration Guide

This style guide supports 5 core templates:

1. **Technical Deep-Dive Template** (Based on your latency script)
2. **Strategic Foundation Template** (Module 0 content)
3. **Hands-On Implementation Template** (Practical tutorials)
4. **Incident Response Scenario Template** (Module 4 focus)
5. **Integration Workshop Template** (Module 5 workflows)

Each template inherits all standards from this guide while adding specific requirements for its content type.

---

## Quality Assurance Checklist

### Pre-Production Review
- [ ] All learning objectives are specific and measurable
- [ ] Technical content has been validated against running systems
- [ ] Chaos scenarios produce expected measurable effects
- [ ] Interactive elements have precise timing specifications
- [ ] Mathematical calculations have been verified

### Script Completeness Check
- [ ] Header section complete with duration and prerequisites
- [ ] Content follows hierarchical structure standards
- [ ] Production notes include visual flow and timing
- [ ] Assessment integration provides instructor guidance
- [ ] Extension activities support different learning levels

### Educational Effectiveness Validation
- [ ] Content builds progressively on prior knowledge
- [ ] Each concept includes practical application
- [ ] Real-world examples support theoretical concepts
- [ ] Student questions are anticipated and addressed

---

## Maintenance and Updates

This style guide will be updated as content production progresses. Key areas for potential refinement:

- **Timing adjustments** based on actual recording experience
- **Interaction patterns** that prove most effective
- **Chaos scenario integration** improvements
- **Assessment effectiveness** based on student feedback

**Last Updated**: Initial version  
**Next Review**: After first 5 scripts are completed
