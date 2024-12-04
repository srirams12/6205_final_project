module ball_sprite #(
  parameter WIDTH=32, HEIGHT=512, GAP_HEIGHT=16,Y_HEIGHT= 208,SPHERE_R = 16 ,COLOR=24'hFF_FF_FF)(
  input wire [10:0] hcount_in,
  input wire [9:0] vcount_in,
  input wire[15:0] freq_in,
  output logic [7:0] red_out,
  output logic [7:0] green_out,
  output logic [7:0] blue_out,
  output logic [9:0] ball_y,
  output logic [10:0] ball_x
  );

  logic [8:0] ball_pos;       // Declare `gap_pos` as a 9-bit signal
  logic [31:0] shifted_val;  // Temporary signal to store the shifted value
  
  assign shifted_val = freq_in >> 2;  // Perform the shift first
  assign ball_pos = shifted_val[8:0];

  // Calculate the circle's center
  logic [10:0] x_center;
  logic [9:0] y_center;
  assign x_center = 640 + SPHERE_R;   
  assign ball_x = x_center+ SPHERE_R;        
  assign y_center = Y_HEIGHT + ball_pos+ 20;       // Circle's vertical center
  assign ball_y = y_center - 16;

  // Check if the current pixel is inside the sphere
  logic in_sphere;
  assign in_sphere = ((hcount_in - x_center) * (hcount_in - x_center) + 
                      (vcount_in - y_center) * (vcount_in - y_center)) <= (SPHERE_R * SPHERE_R);

  // Compute dynamic color based on `freq_in`
  logic [23:0] dynamic_color;
  always_comb begin
    // Example logic to map `freq_in` to RGB color
    dynamic_color = {freq_in[7:0], freq_in[7:0] + 85,freq_in[7:0] + 175 }; // Example: create a color gradient
  end

  // Output the color if the pixel is part of the sprite
  always_comb begin
    if (in_sphere) begin
      red_out = {dynamic_color[19:16], 0'h0};
      green_out = {dynamic_color[11:8], 0'h0};
      blue_out = {dynamic_color[3:0], 0'h0};
    end else begin
      red_out = 0;
      green_out = 0;
      blue_out = 0;
    end
  end

endmodule