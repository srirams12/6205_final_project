`timescale 1ns / 1ps
module bandpass
# (
    parameter SIG_WIDTH = 8,
    parameter COEF_WIDTH = 32,
    parameter DEC_WIDTH = 16, // [31 for twos complement][30:16].[15:0]
    parameter ORDER = 2 // 16khz
)
(
    input wire          clk_in, //100 MHz onboard clock
    input wire          rst_in,
    input wire [SIG_WIDTH-1:0]    x_in,
    input wire          x_in_valid,
    output logic signed [SIG_WIDTH:0]  y_out,
    output logic        y_out_valid
);

    typedef enum { IDLE, CALC, UPDATE } states;
    states state;

    logic signed [COEF_WIDTH-1:0] y_prev [0:ORDER-1];
    logic [SIG_WIDTH-1:0] x_prev [0:ORDER-1];
    logic [SIG_WIDTH-1:0] x_cur;
    
    logic signed [COEF_WIDTH-1:0] a [0:ORDER];
    logic signed [COEF_WIDTH-1:0] b [0:ORDER];

    always_comb begin
        // 8kHz bandpass coefficients
        // a[0] = 32'h00010000;
        // a[1] = 32'hfffb89e1;
        // a[2] = 32'h0008689e;
        // a[3] = 32'hfff75a12;
        // a[4] = 32'h00052777;
        // a[5] = 32'hfffe4fd7;
        // a[6] = 32'h00003c28;
        
        // b[0] = 32'h0000063d;
        // b[1] = 32'h00000000;
        // b[2] = 32'hffffed49;
        // b[3] = 32'h00000000;
        // b[4] = 32'h000012b7;
        // b[5] = 32'h00000000;
        // b[6] = 32'hfffff9c3;

        // 16kHz bandpass coefficients
        // a[0] = 32'h00010000;
        // a[1] = 32'hfffabea5;
        // a[2] = 32'h000b903c;
        // a[3] = 32'hfff25a8f;
        // a[4] = 32'h00091d6c;
        // a[5] = 32'hfffcbb5e;
        // a[6] = 32'h00007dc7;

        // b[0] = 32'h00000105;
        // b[1] = 32'h00000000;
        // b[2] = 32'hfffffcf0;
        // b[3] = 32'h00000000;
        // b[4] = 32'h00000310;
        // b[5] = 32'h00000000;
        // b[6] = 32'hfffffefb;

        // 16kHz first order
        a[0] = 32'h00010000;
        a[1] = 32'hfffe50f6;
        a[2] = 32'h0000b26c;
        b[0] = 32'h000026c9;
        b[1] = 32'h00000000;
        b[2] = 32'hffffd937;
    end

    logic signed [COEF_WIDTH + COEF_WIDTH - 1:0] acc; // Accumulator for filter calculation
    logic signed [COEF_WIDTH + COEF_WIDTH - 1:0] partial_acc1; // Accumulator for filter calculation
    logic signed [COEF_WIDTH + COEF_WIDTH - 1:0] partial_acc2; // Accumulator for filter calculation
    logic signed [COEF_WIDTH-1:0] y_prev_ind_counter;
    logic signed [COEF_WIDTH-1:0] a_ind_counter;

    integer i;
    logic [4:0] counter;

    always_ff @(posedge clk_in) begin
        if (rst_in) begin
            y_out <= 0;
            y_out_valid <= 0;
            
            state <= IDLE;

            acc <= 0;
            partial_acc1 <= 0;
            partial_acc2 <= 0;

            for (i = 0; i < ORDER; i++) begin
                y_prev[i] <= 0;
                x_prev[i] <= 0;
            end
            counter <= 0;
            x_cur <= 0;
            y_prev_ind_counter <= 0;
            a_ind_counter <= 0;

        end else begin
            case (state)
                IDLE: begin
                    y_out_valid <= 0;
                    if (x_in_valid) begin
                        state <= CALC;
                        acc <= 0;
                        partial_acc1 <= 0;
                        partial_acc2 <= 0;
                        counter <= 0;
                        x_cur <= x_in;
                    end
                end

                CALC: begin
                    if (counter == 0) begin
                        // first one
                        acc <= acc + ((b[0] * $signed({1'b0, x_cur})) << DEC_WIDTH);
                        counter <= 1;
                        y_prev_ind_counter <= $signed({y_prev[counter]});
                        a_ind_counter <= a[counter+1];
                    end else if (counter == ORDER+2) begin
                        // we're done
                        state <= UPDATE;
                    end else begin
                        y_prev_ind_counter <= $signed({y_prev[counter]});
                        a_ind_counter <= a[counter+1];
                        // acc <= acc + ((b[counter] * $signed({1'b0, x_prev[counter-1]})) << DEC_WIDTH) - ((a[counter] * $signed({y_prev[counter-1]})));
                        partial_acc1 <= (b[counter] * $signed({1'b0, x_prev[counter-1]})) << DEC_WIDTH;
                        partial_acc2 <= (a_ind_counter * $signed(y_prev_ind_counter));

                        
                        acc <= acc + partial_acc1 - partial_acc2;
                        counter <= counter + 1;
                    end
                end

                UPDATE: begin
                    for (i = ORDER-1; i > 0; i--) begin
                        y_prev[i] <= y_prev[i-1];
                        x_prev[i] <= x_prev[i-1];
                    end

                    y_prev[0] <= $signed(acc[2*DEC_WIDTH + (COEF_WIDTH-DEC_WIDTH) - 1: 2*DEC_WIDTH - (COEF_WIDTH-DEC_WIDTH)]);
                    x_prev[0] <= x_cur;

                    y_out <= $signed(acc[2*DEC_WIDTH+8: 2*DEC_WIDTH]);
                    y_out_valid <= 1;

                    state <= IDLE;

                end
            endcase

        end
    end

endmodule

`default_nettype wire