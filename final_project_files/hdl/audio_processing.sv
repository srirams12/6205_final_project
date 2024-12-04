`timescale 1ns / 1ps
module audio_processing # (
    parameter SIGNAL_WIDTH = 8,
    parameter WIDTH = 32,
    parameter WINDOW_SIZE = 500
)
(
    input wire clk_in,
    input wire rst_in,
    input wire [SIGNAL_WIDTH-1 :0] audio_in,
    input wire audio_in_valid,
    input wire start_computation,
    output logic signed [WIDTH-1 :0] f_out,
    output logic f_out_valid
);

logic bandpass_valid;
logic signed [SIGNAL_WIDTH: 0] bandpass_out;
bandpass bandpasser (
    .clk_in(clk_in),
    .rst_in(rst_in),
    .x_in(audio_in),
    .x_in_valid(audio_in_valid),
    .y_out(bandpass_out),
    .y_out_valid(bandpass_valid)
);

yinner my_yinner (
    .clk_in(clk_in),
    .rst_in(rst_in),
    .sig_in(bandpass_out+9'd255), // signal may need to be positive
    .sig_in_valid(bandpass_valid),
    .start_computation(start_computation),
    .f_out(f_out),
    .f_out_valid(f_out_valid)
);




endmodule