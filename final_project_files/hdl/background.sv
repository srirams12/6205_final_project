module background #(
  parameter ROAD_WIDTH=300)(
  input wire [10:0] hcount_in,
  input wire [9:0] vcount_in,
  input wire [12:0] x_in, // ranges from 0 to 64
  output logic [7:0] red_out,
  output logic [7:0] green_out,
  output logic [7:0] blue_out);
  

  logic in_bottom_line;
  assign in_bottom_line = (vcount_in >= 710);

  logic in_top_line;
  assign in_top_line = (vcount_in <= 710 - ROAD_WIDTH && vcount_in >= 710 - ROAD_WIDTH - 10);

  logic in_median;
  always_comb begin
    in_median = 0;
    for (int i = 0; i < 30; i=i+2) begin
      if (vcount_in <= 710 - ROAD_WIDTH/2 + 3 && vcount_in >= 710 - ROAD_WIDTH/2 - 3) begin
        if ($signed({1'b0, hcount_in}) > $signed(64*i -64 + x_in) && hcount_in < 64*i + x_in) begin
          in_median = 1;
        end
      end
    end
  end

  logic in_a_line;
  assign in_a_line = in_bottom_line || in_top_line || in_median;

  logic in_road;
  assign in_road = (vcount_in < 710 && vcount_in > 710-ROAD_WIDTH);

  logic in_sky;
  assign in_sky = vcount_in < 710-ROAD_WIDTH;
  // Output the color if the pixel is part of the sprite
  always_comb begin
    if (in_a_line) begin
      red_out = 8'hF0;  // White pixel for the sprite
      green_out = 8'hF0;
      blue_out = 8'hF0;

    end else if (in_road) begin
        red_out = 8'h52;  // White pixel for the sprite
        green_out = 8'h52;
        blue_out = 8'h52;
    end else if (in_sky) begin
    // Background color
      red_out = 8'h87;
      green_out = 8'hce;
      blue_out = 8'heb;
    end else begin
      red_out = 0;
      green_out = 0;
      blue_out = 0;
    end
  end


endmodule