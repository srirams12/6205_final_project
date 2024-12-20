module block_sprite #(
  parameter WIDTH=32, HEIGHT=512, GAP_HEIGHT=50,Y_HEIGHT= 600 ,COLOR=24'hFF_FF_FF, Y_TOP=100)(
  input wire clk,
  input wire rst,
  input wire [10:0] hcount_in,
  input wire [9:0] vcount_in,
  input wire [12:0] x_in,
  input wire[15:0] freq_in,
  input wire[7:0] true_note,
  output logic [7:0] red_out,
  output logic [7:0] green_out,
  output logic [7:0] blue_out,
  output logic [8:0] gap_height);

  //Note logic
  localparam FONT_HEIGHT = 16;          // Font height (16 pixels)
  logic [10:0] note_x;                  // X position of the note sprite
  logic [9:0] note_y;                   // Y position of the note sprite

  assign note_x = x_in - 8;                 // Align horizontally with the block
  assign note_y = Y_TOP - FONT_HEIGHT - 10; // Place above the block

  logic [47:0] note_sprite [0:15];       // Combined sprite row for the note

  // Detect changes in true_note
  
  // Instantiate the NoteSpriteDisplay module
  NoteSpriteDisplay note_display_inst (
      .clk(clk),                        // Connect clock signal
      .rst(rst),                        // Connect reset signal
      .new_note(true_note),             // Pass the input true_note
      .note_sprite(note_sprite)     // Output combined sprite row
  );

  logic in_note_sprite;

  assign in_note_sprite = ((hcount_in >= note_x) && (hcount_in < (note_x + 48)) && // 48 pixels wide (16+16+16)
                         (vcount_in >= note_y) && (vcount_in < (note_y + FONT_HEIGHT)));

  logic [8:0] gap_pos;       // Declare `gap_pos` as a 9-bit signal
  logic [31:0] shifted_val;  // Temporary signal to store the shifted value
  assign shifted_val = freq_in >> 1;  // Perform the shift first
  assign gap_pos = shifted_val[8:0];
  assign gap_height = Y_HEIGHT - gap_pos;

  logic in_top_block, in_bottom_block;
  assign in_top_block = ((hcount_in >= x_in && hcount_in < (x_in + WIDTH)) &&
                         (vcount_in <= gap_height - GAP_HEIGHT / 2 && vcount_in > (Y_TOP)));
  assign in_bottom_block = ((hcount_in >= x_in && hcount_in < (x_in + WIDTH)) &&
                            (vcount_in >= (gap_height + GAP_HEIGHT/2) && vcount_in < 720));
  logic in_sprite;
  assign in_sprite = in_top_block || in_bottom_block;

  // Compute dynamic color based on `freq_in`
  logic [23:0] dynamic_color;
  always_comb begin
    // Example logic to map `freq_in` to RGB color
    dynamic_color = {freq_in, ~freq_in, freq_in ^ 8'hFF}; // Example: create a color gradient
  end

  // Output the color if the pixel is part of the sprite
  always_comb begin
    if (in_note_sprite) begin
        // Calculate row and column within the 16x48 sprite
      logic [3:0] sprite_row = vcount_in - note_y;      // Vertical offset (0 to 15)
      logic [5:0] sprite_col = hcount_in - note_x;      // Horizontal offset (0 to 47)

      // Check if the corresponding bit in the sprite is 1
      if (note_sprite[sprite_row][47 - sprite_col]) begin
          red_out = 8'hFF;  // White pixel for the sprite
          green_out = 8'hFF;
          blue_out = 8'hFF;
      end else begin
          red_out = 0;      // red pixel (background)
          green_out = 0;
          blue_out = 0;
      end
    end else if (in_sprite) begin
        // Default block sprite color
        // red_out = dynamic_color[23:16];
        // green_out = dynamic_color[15:8];
        // blue_out = dynamic_color[7:0];
        red_out = 8'hd1;  // White pixel for the sprite
        green_out = 8'haf;
        blue_out = 8'h84;
    end else begin
        // Background color
        red_out = 0;
        green_out = 0;
        blue_out = 0;
    end
  end


endmodule