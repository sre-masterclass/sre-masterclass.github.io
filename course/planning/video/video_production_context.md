# SRE Masterclass Video Production - Discussion Context & Requirements

## Project Overview
Creating a comprehensive SRE training video series (30-40 hours) featuring:
- Real applications with configurable entropy states
- Microservice training environment with common SRE tools
- Open source GitHub repository
- Production-ready video course for distribution

## Hardware & Environment Specifications

### System Configuration
- **CPU**: AMD Ryzen 5 7600X (12 cores)
- **RAM**: 64GB 
- **GPU**: NVIDIA GPUs with 32GB VRAM total (3 GPU setup)
- **Storage**: 2TB HDD + 1TB NVMe SSD
- **OS**: Linux Ubuntu 24 Desktop

### Audio Challenges
- **Motherboard audio panel**: Disconnected to accommodate 3 GPU setup
- **Current audio**: Bluetooth-based workflow
- **Available ports**: Multiple USB3 ports + red USB port (likely USB 3.1/3.2)
- **Existing equipment**: 
  - Poly Voyager Focus 2 headset (Linux compatibility uncertain)
  - Quality microphone headset (model TBD)
  - Access to professional lighting, camera, stands

## Experience Level & Background

### Video Production Experience
- **Previous work**: Basic video splicing, encoding/decoding
- **Software familiarity**: General understanding of editing environments (Corel, etc.)
- **Style expertise**: Self-described as "not an expert" in video production style/taste
- **Technical comfort**: Strong technical background in SRE/software development

### Content Creation Goals
- **Primary platform**: Udemy (requires full course availability at launch)
- **Marketing strategy**: YouTube clips and Reddit for promotion
- **Modular approach**: Core course first, advanced modules potentially separate offering
- **Open source component**: Docker-compose environment and entropy application available publicly

## Content Complexity Considerations

### Demo Challenges
From project specification and Module 5 examples:

#### Chaos Engineering Scenarios
- **Memory exhaustion**: 20-minute gradual progression (200MB → 1.5GB → OOM kill)
- **Cascading failures**: Multi-service failure propagation
- **Network partitions**: Complex distributed system scenarios
- **Resource exhaustion**: CPU spikes, connection pool exhaustion

#### Real-time Monitoring
- **Multiple dashboards**: Prometheus, Grafana, Loki interfaces
- **Live metrics**: Real-time changes during entropy injection
- **Unpredictable timing**: Chaos scenarios don't follow exact schedules
- **Multi-service coordination**: Docker-compose environment with multiple microservices

### Strategic Content Mix
- **Phase 0**: Business value, team models (3-4 hours talking head + slides)
- **Phases 1-2**: Technical foundations, SLO/SLI implementation (hands-on demos)
- **Phases 3-4**: Advanced monitoring, incident response (complex multi-service scenarios)
- **Phase 5**: CI/CD integration (pipeline demonstrations)

## Platform Strategy Discussion

### YouTube vs Udemy Considerations

#### YouTube Channel Approach
- **Pros**: Audience building, algorithm discovery, ongoing revenue stream
- **Cons**: Longer monetization timeline, requires consistent content schedule
- **Content style**: More casual, conversational, iterative based on feedback
- **Format**: Shorter episodes (10-20 minutes)

#### Udemy Course Approach  
- **Pros**: Immediate monetization, complete course purchase model
- **Cons**: One-time purchase, platform dependency
- **Content style**: Polished, structured learning path
- **Format**: Longer modules (30-60 minutes each)

#### Recommended Hybrid Strategy
1. **Primary**: Full Udemy course (30-40 hours, $199-299 price point)
2. **Marketing**: YouTube channel with extracted segments
   - "SRE Quick Tips" (5-10 minutes)
   - "Chaos Engineering in Action" (15-20 minutes) 
   - "Tool Spotlights" (10 minutes)
3. **Long-term**: Use YouTube audience for future course launches

## Technical Production Requirements

### Recording Software Recommendations
- **Primary**: OBS Studio (excellent Linux support, NVENC GPU encoding)
- **Alternative**: SimpleScreenRecorder (lightweight option)
- **Rationale**: Leverage NVIDIA GPU for encoding while CPU handles docker environment

### Editing Software Options
- **Recommended**: DaVinci Resolve (free version, excellent Linux support, utilizes 32GB VRAM)
- **Alternative**: Kdenlive (open source, good middle ground)
- **Workflow**: 4K recording → 1080p delivery for optimal quality

### Recording Challenges Identified

#### Entropy Scenario Management
- **Issue**: Unpredictable timing for chaos engineering demos
- **Solution**: Scripted scenarios with strategic pause/resume recording
- **Approach**: Real-time capture for key moments, time-lapse for gradual changes

#### Multi-Service Demonstrations
- **Challenge**: Multiple dashboards, services, terminals simultaneously
- **Solution**: OBS scene management with pre-configured layouts
- **Scenes needed**: Full screen, picture-in-picture, terminal focus, talking head

#### Audio Quality Concerns
- **Current uncertainty**: Poly headset Linux compatibility unknown
- **Testing required**: Existing quality microphone headset evaluation
- **Backup plan**: USB microphone recommendations (Blue Yeti, Audio-Technica ATR2100x)

## Timeline & Production Strategy

### Proposed Schedule
- **Phase 1**: Core course production (3-4 months)
  - Month 1: Modules 0-1 (Strategic + Technical Foundations)
  - Month 2: Modules 2-3 (SLO/SLI + Advanced Monitoring)  
  - Month 3: Modules 4-5 (Incident Response + CI/CD)
  - Month 4: Post-production, course packaging

- **Phase 2**: YouTube marketing extraction (ongoing)
  - 2-3 videos per module for YouTube
  - Weekly release schedule
  - Audience building for future launches

### Content Flexibility
- **Application stack**: Can be developed on any timeline (open source priority)
- **Video recording**: Can adapt to application readiness
- **Modular release**: Advanced modules can be separate course offering
- **Feedback integration**: Core course feedback can inform advanced content

## Quality Standards & Expectations

### Target Audience
- **Primary**: SREs and developers seeking deep reliability engineering understanding
- **Level**: Advanced technical content, not beginner-friendly
- **Expectations**: Professional production values for Udemy platform

### Content Differentiation
- **Unique value**: Real entropy-injectable applications vs static website demos
- **Depth**: Strategic foundation + hands-on technical implementation
- **Practical focus**: Patterns-based monitoring, real SLO mathematics
- **Business context**: ROI analysis, team models, organizational integration

## Immediate Next Steps Required

### Audio Equipment Validation
1. **Test existing equipment**: Run audio compatibility tests on current setup
2. **Evaluate quality**: Record sample technical explanation content
3. **Determine gaps**: Identify if additional audio equipment needed
4. **USB port utilization**: Leverage red USB port for professional audio interface if needed

### Production Environment Setup
1. **OBS Studio configuration**: Install and configure scene management
2. **Recording workflow testing**: Validate 4K recording → 1080p delivery pipeline
3. **Docker environment optimization**: Ensure smooth operation during recording
4. **Chaos scenario scripting**: Pre-plan entropy injection timing for demonstrations

### Content Structure Finalization
1. **Module breakdown**: Confirm 30-40 hour distribution across phases
2. **Demo complexity scaling**: Start with simpler scenarios, build to advanced chaos engineering
3. **Platform requirements**: Ensure content meets both Udemy and YouTube optimization needs
4. **Quality benchmarks**: Establish consistent production standards across all modules

This context document provides the foundation for all video production decisions, ensuring alignment with technical capabilities, content complexity, and business objectives.