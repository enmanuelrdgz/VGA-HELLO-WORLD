# VGA Music Visualizer - Project Documentation

## How it works

This project shows VGA graphics together with synchronized sound. It displays the text "HELLO WORLD" with a beating heart while a musical scale (C4-C5) plays in a loop.

## How to test

### Basic Functionality Test:
1. **Power On:** Connect the TinyTapeout chip to power and clock source
2. **VGA Connection:** Connect a VGA monitor to the VGA PMOD output pins
3. **Audio Connection:** Connect speakers or headphones to the audio output (uio_out[7])
4. **Reset:** Toggle the reset signal to initialize the system

## External hardware

**VGA PMOD:**
- Standard VGA output module for TinyTapeout
- Provides RGB video signals and sync (hsync/vsync)
- Connects to dedicated output pins: `uo_out[7:0]`
- Pin mapping:
  - `uo_out[7]`: hsync
  - `uo_out[6:4]`: B[1], G[1], R[1] (MSB of RGB)
  - `uo_out[3]`: vsync  
  - `uo_out[2:0]`: B[0], G[0], R[0] (LSB of RGB)

**VGA Monitor:**
- Any standard VGA monitor supporting 640x480 @ 60Hz
- Resolution: 640x480 pixels
- Refresh rate: 60 Hz
- Color depth: 2 bits per channel (64 colors total)

**Audio Output:**
- External speakers or headphones
- Connect to `uio_out[7]` (MSB of bidirectional I/O)
- Digital square wave output (may need amplification)
- Optional: Low-pass filter for smoother audio quality