#!/bin/bash

# SRE Masterclass Audio Setup Testing Script
# # Test audio equipment compatibility on Linux
#
echo "=== SRE Masterclass Audio Testing ==="
echo "Date: $(date)"
echo "System: $(uname -a)"
echo ""
#
# # Check USB devices
echo "1. USB Audio Devices:"
echo "===================="
lsusb | grep -iE "(audio|headset|microphone|poly|plantronics)"
echo ""
#
# # Check PulseAudio sources (microphones)
echo "2. Available Audio Sources (Microphones):"
echo "========================================="
pactl list short sources
echo ""
#
# # Check PulseAudio sinks (speakers/headphones)
echo "3. Available Audio Sinks (Output):"
echo "=================================="
pactl list short sinks
echo ""
#
# # Check ALSA devices
echo "4. ALSA Audio Devices:"
echo "====================="
arecord -l
echo ""
aplay -l
echo ""
#
# # Test recording quality
echo "5. Recording Test:"
echo "=================="
echo "Recording 10-second test sample..."
arecord -f cd -t wav -d 10 /tmp/audio_test.wav 2>/dev/null

if [ -f /tmp/audio_test.wav ]; then
    echo "✓ Recording successful"
        echo "File size: $(du -h /tmp/audio_test.wav | cut -f1)"
            echo "Playing back test recording..."
                aplay /tmp/audio_test.wav 2>/dev/null
                    echo "✓ Playback complete"
                    else
                        echo "✗ Recording failed - check microphone setup"
                        fi

                        # Check for Bluetooth audio
                        echo ""
                        echo "6. Bluetooth Audio Devices:"
                        echo "==========================="
                        bluetoothctl devices | grep -i "audio\|headset\|poly"

                        # OBS Audio Test
                        echo ""
                        echo "7. OBS Studio Audio Test:"
                        echo "========================"
                        if command -v obs &> /dev/null; then
                            echo "✓ OBS Studio is installed"
                                echo "Launch OBS and check Audio Sources in Audio Mixer"
                                    echo "Expected sources:"
                                        echo "  - Desktop Audio (for system sounds)"
                                            echo "  - Mic/Aux (for your microphone)"
                                            else
                                                echo "⚠ OBS Studio not installed"
                                                    echo "Install with: sudo apt install obs-studio"
                                                    fi
                                                    echo ""
                                                    echo "=== Test Complete ==="
                                                    echo "Review the output above and test audio quality"
                                                    echo "For video production, aim for:"
                                                    echo "  - Clean recording with no background noise"
                                                    echo "  - Consistent volume levels"
                                                    echo "  - Clear speech without distortion"
#
#                                                     # Cleanup
#                                                     rm -f /tmp/audio_test.wav
