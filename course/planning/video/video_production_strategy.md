# SRE Masterclass Video Production Strategy

## Recording Setup Recommendations

### Hardware Configuration
- **Primary Monitor**: 4K for main content (Grafana dashboards, code)
- **Secondary Monitor**: 1080p for OBS controls, notes, scripts
- **Webcam**: 1080p minimum for talking head segments
- **Audio**: External USB microphone (Blue Yeti or Audio-Technica ATR2100)

### OBS Scene Configuration

#### Scene 1: Full Screen Demo
- Source: Primary monitor capture (3840x2160)
- Output: 1920x1080 (downscaled for crisp quality)
- Use case: Dashboard walkthroughs, code reviews

#### Scene 2: Picture-in-Picture
- Main: Screen capture (70% of frame)
- Overlay: Webcam (bottom-right, 30% scale)
- Use case: Explaining concepts while showing implementation

#### Scene 3: Talking Head
- Primary: Webcam feed
- Background: Static slide or branded background
- Use case: Strategic content, introductions

#### Scene 4: Terminal Focus
- Source: Terminal window capture
- Font: Large, high-contrast for readability
- Use case: Command demonstrations, chaos engineering triggers

## Content Production Workflow

### Phase 1: Pre-Production
```yaml
script_preparation:
  - Outline key learning objectives
  - Identify demo breakpoints
  - Prepare entropy scenarios in advance
  - Create visual aids (diagrams, slides)
  
environment_setup:
  - Validate docker-compose environment
  - Pre-configure Grafana dashboards
  - Prepare chaos engineering scenarios
  - Test all demo paths
```

### Phase 2: Recording Strategy

#### For Entropy/Chaos Scenarios
**Challenge**: Unpredictable timing, real-time monitoring
**Solution**: Scripted scenarios with time-lapse capability

```bash
# Example: Memory exhaustion demo recording
1. Start recording
2. Trigger entropy scenario via web interface
3. Show immediate dashboard changes
4. *PAUSE RECORDING* during long wait periods
5. Resume at key milestone points (5min, 10min, 15min marks)
6. Capture OOM kill event
7. Show recovery process
```

#### For SLO Mathematics Content
**Format**: Hybrid approach
- Screen capture for calculations
- Webcam overlay for explanations
- Pre-prepared examples with real data

#### For Strategic Content (Business Value, Team Models)
**Format**: Talking head + slides
- Professional background or branded backdrop
- Slide transitions for key concepts
- Real-world examples and case studies

### Phase 3: Post-Production

#### Editing Workflow (DaVinci Resolve)
```
Timeline Structure:
├── Video Track 1: Main content (screen recordings)
├── Video Track 2: Webcam overlay
├── Video Track 3: Graphics/annotations
├── Audio Track 1: Primary audio (mic)
├── Audio Track 2: System audio (alerts, notifications)
└── Audio Track 3: Background music (optional, low volume)
```

#### Standard Editing Patterns
- **Jump cuts**: Remove "thinking pauses" and mistakes
- **Speed ramps**: 2x speed for repetitive tasks
- **Zoom effects**: Focus on specific dashboard elements
- **Annotations**: Highlight important metrics or alerts

## Content Packaging Strategy

### Udemy Course Structure
```
Course Introduction (5 minutes)
├── What you'll learn
├── Prerequisites  
└── Environment overview

Module 0: Strategic Foundation (3-4 hours)
├── 0.1: Business Value (45 min)
├── 0.2: Team Models (45 min)
├── 0.3: SDLC Integration (45 min)
└── 0.4: Team Interactions (45 min)

Module 1: Technical Foundations (4-6 hours)
├── 1.1: Monitoring Taxonomies (90 min)
├── 1.2: Environment Setup (60 min)
└── 1.3: Black Box vs White Box (90 min)

[Continue for all modules...]
```

### YouTube Marketing Extraction
From each Udemy module, create:
- **10-minute "Quick Start" videos**: Key concepts only
- **5-minute "Tool Spotlights"**: Specific tools (Prometheus, Grafana)
- **15-minute "Case Studies"**: Real-world SRE scenarios

## Visual Assets Strategy

### Technical Diagrams
**Tools**: Excalidraw, Mermaid diagrams
**Style**: Clean, minimal, high contrast
**Examples**:
- System architecture overviews
- Data flow diagrams
- Alert escalation paths

### Dashboard Recordings
**Best Practices**:
- Use dark themes (better for video compression)
- Increase font sizes for readability
- Focus on key metrics with cursor highlighting
- Use browser zoom for important details

### Code Demonstrations
**Setup**:
- VS Code with high-contrast theme
- Large font size (16pt minimum)
- Syntax highlighting optimized for recording
- Line numbers visible

### Entropy Control Interface
**Recording Strategy**:
- Full-screen browser capture
- Highlight toggle controls with cursor
- Show immediate metric changes
- Picture-in-picture explanation overlay

## Audio Production

### Recording Setup
- **Environment**: Quiet room with soft furnishings
- **Microphone**: USB condenser mic (Blue Yeti recommended)
- **Positioning**: 6-8 inches from mouth, slightly off-axis
- **Levels**: -12dB to -6dB recording levels

### Post-Production Audio
**DaVinci Resolve Audio Timeline**:
1. **Noise reduction**: Remove background hum
2. **EQ**: Boost clarity frequencies (2-5kHz)
3. **Compression**: Even out volume levels  
4. **Normalization**: -16 LUFS for online content

## Quality Assurance Checklist

### Pre-Recording
- [ ] Environment tested and stable
- [ ] Audio levels checked
- [ ] Screen resolution optimized
- [ ] Demo scenarios validated
- [ ] Script and outline ready

### During Recording
- [ ] Monitor audio levels continuously
- [ ] Check for system notifications (disable)
- [ ] Validate screen capture quality
- [ ] Mark key edit points with clap or gesture

### Post-Recording
- [ ] Audio sync verification
- [ ] Visual quality check
- [ ] Content accuracy review
- [ ] Export settings validation
- [ ] Platform-specific requirements met

## Technical Specifications

### Recording Settings (OBS)
```
Video:
- Resolution: 3840x2160 (record) → 1920x1080 (output)
- Frame Rate: 30fps
- Encoder: NVENC H.264 (utilize your GPU)
- Bitrate: 40,000 Kbps (local recording)

Audio:
- Sample Rate: 48kHz
- Bit Depth: 24-bit
- Channels: Stereo
```

### Export Settings (DaVinci Resolve)
```
Udemy Requirements:
- Format: MP4
- Codec: H.264
- Resolution: 1920x1080
- Frame Rate: 30fps
- Bitrate: 8,000-10,000 Kbps
- Audio: AAC, 128kbps, 44.1kHz

YouTube Optimization:
- Same as above
- Consider 1440p (2560x1440) for premium feel
- Higher bitrate: 12,000-15,000 Kbps
```

## Content Calendar Strategy

### Phase 1: Core Course Production (3-4 months)
- Month 1: Modules 0-1 (Strategic + Technical Foundations)
- Month 2: Modules 2-3 (SLO/SLI + Advanced Monitoring)
- Month 3: Modules 4-5 (Incident Response + CI/CD)
- Month 4: Post-production, course packaging

### Phase 2: YouTube Marketing (Ongoing)
- Extract 2-3 videos per module for YouTube
- Weekly release schedule
- Build audience for future course launches

### Phase 3: Advanced Course Development (6+ months)
- Use feedback from initial course
- Develop advanced chaos engineering content
- Create specialized tracks (Cloud, Kubernetes, etc.)
