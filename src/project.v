`default_nettype none

module tt_um_vga_example(
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
  reg  [1:0] R;  // Cambiado a reg
  reg  [1:0] G;  // Cambiado a reg
  reg  [1:0] B;  // Cambiado a reg
  wire video_active;
  wire [9:0] pix_x;
  wire [9:0] pix_y;
  wire sound;

  // TinyVGA PMOD
  assign uo_out = {hsync, B[0], G[0], R[0], vsync, B[1], G[1], R[1]};

  // Unused outputs assigned to 0.
  assign uio_out = 0;
  assign uio_oe  = 0;

  // Suppress unused signals warning
  wire _unused_ok = &{ena, ui_in, uio_in};

  reg [9:0] counter;

  hvsync_generator hvsync_gen(
    .clk(clk),
    .reset(~rst_n),
    .hsync(hsync),
    .vsync(vsync),
    .display_on(video_active),
    .hpos(pix_x),
    .vpos(pix_y)
  );
  
  wire [9:0] moving_x = pix_x + counter;

  always @(*) begin
    if (video_active) begin
      // condiciones para HELLO WORLD
      if
      (
        // H
        (10'd0 <= pix_x && pix_x <= 10'd10 && 10'd0  <= pix_y && pix_y <= 10'd50) 
        || (10'd40 <= pix_x && pix_x <= 10'd50 && 10'd0  <= pix_y && pix_y <= 10'd50)
        || (10'd10 <= pix_x && pix_x <= 10'd40 && 10'd20  <= pix_y && pix_y <= 10'd30)
        // E
        || (10'd50 <= pix_x && pix_x <= 10'd60 && 10'd0  <= pix_y && pix_y <= 10'd50)
        || (10'd50 <= pix_x && pix_x <= 10'd100 && 10'd0  <= pix_y && pix_y <= 10'd10)
        || (10'd50 <= pix_x && pix_x <= 10'd100 && 10'd20 <= pix_y && pix_y <= 10'd30)
        || (10'd50 <= pix_x && pix_x <= 10'd100 && 10'd40 <= pix_y && pix_y <= 10'd50)
        // L
        || (10'd100 <= pix_x && pix_x <= 10'd110 && 10'd0  <= pix_y && pix_y <= 10'd50)
        || (10'd110 <= pix_x && pix_x <= 10'd150 && 10'd40  <= pix_y && pix_y <= 10'd50)
        // L
        || (10'd150 <= pix_x && pix_x <= 10'd160 && 10'd0  <= pix_y && pix_y <= 10'd50)
        || (10'd160 <= pix_x && pix_x <= 10'd200 && 10'd40  <= pix_y && pix_y <= 10'd50)
      ) 
      begin 
        R = 2'b11;
        G = 2'b11;
        B = 2'b11;
      end else begin
        R = {moving_x[5], pix_y[2]};
        G = {moving_x[6], pix_y[2]};
        B = {moving_x[7], pix_y[5]};
      end
    end else begin
        R = 2'b00;
        G = 2'b00;
        B = 2'b00;
    end
  end

  always @(posedge vsync or negedge rst_n) begin
    if (~rst_n) begin
      counter <= 0;
    end else begin
      counter <= counter + 1;
    end
  end
  
endmodule