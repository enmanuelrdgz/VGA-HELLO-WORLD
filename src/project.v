`default_nettype none

// Musical note definitions (frequencies as clock divisors)
`define C4  60  // 261.63 Hz 
`define D4  54  // 293.66 Hz 
`define E4  48  // 329.63 Hz 
`define F4  45  // 349.23 Hz 
`define G4  40  // 392.0 Hz 
`define A4  36  // 440.0 Hz 
`define B4  32  // 493.88 Hz 
`define C5  30  // 523.26 Hz 

`define MUSIC_SPEED 1'b1  // For 60 FPS

module tt_um_vga_hello_world(
  input  wire [7:0] ui_in,    
  output wire [7:0] uo_out,   
  input  wire [7:0] uio_in,   
  output wire [7:0] uio_out,  
  output wire [7:0] uio_oe,   
  input  wire       ena,      
  input  wire       clk,      
  input  wire       rst_n     
);

  // VGA signals
  wire hsync;
  wire vsync;
  reg  [1:0] R;
  reg  [1:0] G;
  reg  [1:0] B;
  wire video_active;
  wire [9:0] pix_x;
  wire [9:0] pix_y;
  
  // Audio signals
  wire sound;
  reg [11:0] frame_counter;
  reg [7:0] note_freq;
  reg [7:0] note_counter;
  reg note_wave;
  
  // Beat counter for synchronized visual effects
  wire [2:0] beat = frame_counter[7:5]; // 8 beats per cycle
  wire [4:0] envelope = 5'd31 - frame_counter[4:0]; // Envelope for fade

  // TinyVGA PMOD with audio
  assign uo_out = {hsync, B[0], G[0], R[0], vsync, B[1], G[1], R[1]};
  assign uio_out = {sound, 7'b0}; // Audio on the most significant bit
  assign uio_oe  = 8'hff; // Enable output for audio

  // Suppress unused signals warning
  wire _unused_ok = &{ena, ui_in, uio_in};

  hvsync_generator hvsync_gen(
    .clk(clk),
    .reset(~rst_n),
    .hsync(hsync),
    .vsync(vsync),
    .display_on(video_active),
    .hpos(pix_x),
    .vpos(pix_y)
  );
  
  // Note selector based on frame counter
  wire [2:0] note_select = frame_counter[9:7]; // 8 notes, each lasting 128 frames
  
  always @(note_select) begin
    case(note_select)
      3'd0: note_freq = `C4;
      3'd1: note_freq = `D4;
      3'd2: note_freq = `E4;
      3'd3: note_freq = `F4;
      3'd4: note_freq = `G4;
      3'd5: note_freq = `A4;
      3'd6: note_freq = `B4;
      3'd7: note_freq = `C5;
    endcase
  end
  
  // Square wave generator for the notes
  always @(posedge clk) begin
    if (~rst_n) begin
      frame_counter <= 0;
      note_counter <= 0;
      note_wave <= 0;
    end else begin
      // Increment frame counter at the beginning of each frame
      if (pix_x == 0 && pix_y == 0) begin
        frame_counter <= frame_counter + `MUSIC_SPEED;
      end
      
      // Generate square wave for the note
      if (pix_x == 0) begin // Once per horizontal line
        if (note_counter >= note_freq) begin
          note_counter <= 0;
          note_wave <= ~note_wave;
        end else begin
          note_counter <= note_counter + 1'b1;
        end
      end
    end
  end
  
  // Audio output with simple envelope
  assign sound = note_wave & (envelope > 5'd10); // Only sounds when envelope is high
  
  // Visual logic with audio-synchronized effects
  always @(*) begin
    if (video_active) begin
      // Colors that change with the beat
      reg [1:0] beat_r, beat_g, beat_b;
      
      // Base colors that change with the musical beat
      case(beat)
        3'd0: {beat_r, beat_g, beat_b} = 6'b110000; // Red
        3'd1: {beat_r, beat_g, beat_b} = 6'b001100; // Green
        3'd2: {beat_r, beat_g, beat_b} = 6'b000011; // Blue
        3'd3: {beat_r, beat_g, beat_b} = 6'b111100; // Yellow
        3'd4: {beat_r, beat_g, beat_b} = 6'b110011; // Magenta
        3'd5: {beat_r, beat_g, beat_b} = 6'b001111; // Cyan
        3'd6: {beat_r, beat_g, beat_b} = 6'b111000; // Orange
        3'd7: {beat_r, beat_g, beat_b} = 6'b101010; // Gray
      endcase
      
      // H - Pulses with the sound
      if (
        (10'd50 <= pix_x && pix_x <= 10'd60 && 10'd100  <= pix_y && pix_y <= 10'd150) 
        || (10'd90 <= pix_x && pix_x <= 10'd100 && 10'd100  <= pix_y && pix_y <= 10'd150)
        || (10'd60 <= pix_x && pix_x <= 10'd90 && 10'd120  <= pix_y && pix_y <= 10'd130)
      ) begin
        if (sound) begin
          R = 2'b11; G = 2'b11; B = 2'b11; // White when sounding
        end else begin
          R = beat_r; G = beat_g; B = beat_b; // Beat color when not sounding
        end
      // E
      end else if (
        (10'd100 <= pix_x && pix_x <= 10'd110 && 10'd100  <= pix_y && pix_y <= 10'd150)
        || (10'd100 <= pix_x && pix_x <= 10'd150 && 10'd100  <= pix_y && pix_y <= 10'd110)
        || (10'd100 <= pix_x && pix_x <= 10'd150 && 10'd120 <= pix_y && pix_y <= 10'd130)
        || (10'd100 <= pix_x && pix_x <= 10'd150 && 10'd140 <= pix_y && pix_y <= 10'd150)
      ) begin
        if (sound) begin
          R = 2'b11; G = 2'b11; B = 2'b11;
        end else begin
          R = beat_g; G = beat_r; B = beat_b; // Color rotation
        end
      // L
      end else if (
        (10'd150 <= pix_x && pix_x <= 10'd160 && 10'd100  <= pix_y && pix_y <= 10'd150)
        || (10'd160 <= pix_x && pix_x <= 10'd200 && 10'd140  <= pix_y && pix_y <= 10'd150)
      ) begin
        if (sound) begin
          R = 2'b11; G = 2'b11; B = 2'b11;
        end else begin
          R = beat_b; G = beat_r; B = beat_g; // Another rotation
        end
      // L
      end else if (
        (10'd200 <= pix_x && pix_x <= 10'd210 && 10'd100  <= pix_y && pix_y <= 10'd150)
        || (10'd210 <= pix_x && pix_x <= 10'd250 && 10'd140  <= pix_y && pix_y <= 10'd150)
      ) begin
        if (sound) begin
          R = 2'b11; G = 2'b11; B = 2'b11;
        end else begin
          R = beat_r; G = beat_b; B = beat_g;
        end
      // O
      end else if (
        (10'd250 <= pix_x && pix_x <= 10'd300 && 10'd100  <= pix_y && pix_y <= 10'd110)
        || (10'd250 <= pix_x && pix_x <= 10'd260 && 10'd100  <= pix_y && pix_y <= 10'd150)
        || (10'd250 <= pix_x && pix_x <= 10'd300 && 10'd140 <= pix_y && pix_y <= 10'd150)
        || (10'd290 <= pix_x && pix_x <= 10'd300 && 10'd100 <= pix_y && pix_y <= 10'd150)
      ) begin
        if (sound) begin
          R = 2'b11; G = 2'b11; B = 2'b11;
        end else begin
          R = beat_g; G = beat_b; B = beat_r;
        end
      //W
      end else if (
        (10'd350 <= pix_x && pix_x <= 10'd360 && 10'd100  <= pix_y && pix_y <= 10'd150)
        || (10'd390 <= pix_x && pix_x <= 10'd400 && 10'd100  <= pix_y && pix_y <= 10'd150)
        || (10'd370 <= pix_x && pix_x <= 10'd380 && 10'd100 <= pix_y && pix_y <= 10'd150)
        || (10'd350 <= pix_x && pix_x <= 10'd400 && 10'd140 <= pix_y && pix_y <= 10'd150)
      ) begin
        if (sound) begin
          R = 2'b11; G = 2'b11; B = 2'b11;
        end else begin
          R = beat_b; G = beat_g; B = beat_r;
        end
      // O
      end else if (
        (10'd400 <= pix_x && pix_x <= 10'd450 && 10'd100  <= pix_y && pix_y <= 10'd110)
        || (10'd400 <= pix_x && pix_x <= 10'd410 && 10'd100  <= pix_y && pix_y <= 10'd150)
        || (10'd400 <= pix_x && pix_x <= 10'd450 && 10'd140 <= pix_y && pix_y <= 10'd150)
        || (10'd440 <= pix_x && pix_x <= 10'd450 && 10'd100 <= pix_y && pix_y <= 10'd150)
      ) begin
        if (sound) begin
          R = 2'b11; G = 2'b11; B = 2'b11;
        end else begin
          R = beat_r; G = beat_g; B = beat_b;
        end
      // R
      end else if (
        (10'd450 <= pix_x && pix_x <= 10'd460 && 10'd100  <= pix_y && pix_y <= 10'd150)
        || (10'd480 <= pix_x && pix_x <= 10'd490 && 10'd130  <= pix_y && pix_y <= 10'd150)
        || (10'd450 <= pix_x && pix_x <= 10'd500 && 10'd100 <= pix_y && pix_y <= 10'd110)
        || (10'd450 <= pix_x && pix_x <= 10'd500 && 10'd120 <= pix_y && pix_y <= 10'd130)
        || (10'd490 <= pix_x && pix_x <= 10'd500 && 10'd100 <= pix_y && pix_y <= 10'd130)
      ) begin
        if (sound) begin
          R = 2'b11; G = 2'b11; B = 2'b11;
        end else begin
          R = beat_g; G = beat_r; B = beat_b;
        end
      // L
      end else if (
        (10'd500 <= pix_x && pix_x <= 10'd510 && 10'd100  <= pix_y && pix_y <= 10'd150)
        || (10'd500 <= pix_x && pix_x <= 10'd550 && 10'd140  <= pix_y && pix_y <= 10'd150)
      ) begin
        if (sound) begin
          R = 2'b11; G = 2'b11; B = 2'b11;
        end else begin
          R = beat_b; G = beat_r; B = beat_g;
        end
      // D
      end else if (
        (10'd550 <= pix_x && pix_x <= 10'd560 && 10'd100  <= pix_y && pix_y <= 10'd150)
        || (10'd550 <= pix_x && pix_x <= 10'd590 && 10'd100  <= pix_y && pix_y <= 10'd110)
        || (10'd580 <= pix_x && pix_x <= 10'd600 && 10'd110  <= pix_y && pix_y <= 10'd120)
        || (10'd550 <= pix_x && pix_x <= 10'd590 && 10'd140  <= pix_y && pix_y <= 10'd150)
        || (10'd580 <= pix_x && pix_x <= 10'd600 && 10'd130  <= pix_y && pix_y <= 10'd140)
        || (10'd590 <= pix_x && pix_x <= 10'd600 && 10'd110  <= pix_y && pix_y <= 10'd140)
      ) begin
        if (sound) begin
          R = 2'b11; G = 2'b11; B = 2'b11;
        end else begin
          R = beat_r; G = beat_b; B = beat_g;
        end
      // HEART - Beats stronger with the audio
      end else if (
        // Upper left part of the heart
        (10'd230 <= pix_x && pix_x <= 10'd280 && 10'd170 <= pix_y && pix_y <= 10'd180)
        || (10'd220 <= pix_x && pix_x <= 10'd230 && 10'd180 <= pix_y && pix_y <= 10'd200)
        || (10'd230 <= pix_x && pix_x <= 10'd240 && 10'd180 <= pix_y && pix_y <= 10'd210)
        || (10'd240 <= pix_x && pix_x <= 10'd270 && 10'd180 <= pix_y && pix_y <= 10'd200)
        || (10'd270 <= pix_x && pix_x <= 10'd280 && 10'd180 <= pix_y && pix_y <= 10'd190)
        // Upper right part of the heart
        || (10'd300 <= pix_x && pix_x <= 10'd350 && 10'd170 <= pix_y && pix_y <= 10'd180)
        || (10'd300 <= pix_x && pix_x <= 10'd310 && 10'd180 <= pix_y && pix_y <= 10'd190)
        || (10'd310 <= pix_x && pix_x <= 10'd340 && 10'd180 <= pix_y && pix_y <= 10'd200)
        || (10'd340 <= pix_x && pix_x <= 10'd350 && 10'd180 <= pix_y && pix_y <= 10'd210)
        || (10'd350 <= pix_x && pix_x <= 10'd360 && 10'd180 <= pix_y && pix_y <= 10'd200)
        // Middle part of the heart
        || (10'd230 <= pix_x && pix_x <= 10'd350 && 10'd190 <= pix_y && pix_y <= 10'd210)
        || (10'd220 <= pix_x && pix_x <= 10'd360 && 10'd200 <= pix_y && pix_y <= 10'd220)
        || (10'd230 <= pix_x && pix_x <= 10'd350 && 10'd220 <= pix_y && pix_y <= 10'd240)
        || (10'd240 <= pix_x && pix_x <= 10'd340 && 10'd240 <= pix_y && pix_y <= 10'd250)
        // Heart tip
        || (10'd250 <= pix_x && pix_x <= 10'd330 && 10'd250 <= pix_y && pix_y <= 10'd260)
        || (10'd270 <= pix_x && pix_x <= 10'd310 && 10'd260 <= pix_y && pix_y <= 10'd270)
        || (10'd280 <= pix_x && pix_x <= 10'd300 && 10'd270 <= pix_y && pix_y <= 10'd280)
        || (10'd285 <= pix_x && pix_x <= 10'd295 && 10'd280 <= pix_y && pix_y <= 10'd285)
      ) begin
        if (sound) begin
          // Heart beats in bright red when there's sound
          R = 2'b11; G = 2'b00; B = 2'b00;
        end else begin
          // Heart is dimmer when there's no sound
          R = 2'b10; G = 2'b00; B = 2'b00;
        end
      end else begin
        // Background that changes subtly with the music
        R = (beat[0]) ? 2'b01 : 2'b00;
        G = (beat[1]) ? 2'b01 : 2'b00;
        B = (beat[2]) ? 2'b10 : 2'b01;
      end
    end else begin
      // Outside active area, black
      R = 2'b00;
      G = 2'b00;
      B = 2'b00;
    end
  end
  
endmodule