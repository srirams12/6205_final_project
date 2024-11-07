`timescale 1ns / 1ps
`default_nettype none // prevents system from inferring an undeclared logic (good practice)
 
module tmds_encoder(
  input wire clk_in,
  input wire rst_in,
  input wire [7:0] data_in,  // video data (red, green or blue)
  input wire [1:0] control_in, //for blue set to {vs,hs}, else will be 0
  input wire ve_in,  // video data enable, to choose between control or video signal
  output logic [9:0] tmds_out
);
    
    logic [8:0] q_m;
    
    tm_choice mtm(
        .data_in(data_in),
        .qm_out(q_m));

    logic [4:0] count;
    // logic [9:0] q_out;

    logic[3:0] num_ones;

    always_comb begin
        num_ones = $countones(q_m[7:0]);
    end



    always_ff @(posedge clk_in) begin
        if (rst_in) begin
            count <= 0;
            // q_out <= 0;
            tmds_out <= 0;
        end else if (ve_in == 0) begin
            count <= 0;
            if (control_in == 2'b00) begin
                tmds_out <= 10'b1101010100;
            end else if (control_in == 2'b01) begin
                tmds_out <= 10'b0010101011;
            end else if (control_in == 2'b10) begin
                tmds_out <= 10'b0101010100;
            end else if (control_in == 2'b11) begin
                tmds_out <= 10'b1010101011;
            end

        end else begin
            if (count == 0 || num_ones == 4) begin
                tmds_out[9] <= !q_m[8];
                tmds_out[8] <= q_m[8];
                tmds_out[7:0] <= q_m[8] ? q_m[7:0] : ~q_m[7:0];
    
                if (q_m[8] == 0) begin
                    count <= count + (8 - num_ones) - num_ones;
                end else begin
                    count <= count + num_ones - (8 - num_ones);
                end
            end else begin
    
                if ((count[4] == 0 && num_ones > 4) || (count[4] == 1 && num_ones < 4)) begin
                    tmds_out[9] <= 1;
                    tmds_out[8] <= q_m[8];
                    tmds_out[7:0] <= ~q_m[7:0];
                    count <= count + q_m[8] + q_m[8] + (8 - num_ones) - num_ones;
                end else begin
                    tmds_out[9] <= 0;
                    tmds_out[8] <= q_m[8];
                    tmds_out[7:0] <= q_m[7:0];
                    count <= count - (!q_m[8]) - (!q_m[8]) + num_ones - (8 - num_ones);
                end
            end

        end
    end

    // always_comb begin
    //     tmds_out = q_out;
    // end

 
endmodule
 
`default_nettype wire