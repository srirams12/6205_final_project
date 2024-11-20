module bandpass
# (
    parameter SIG_WIDTH = 8,
    parameter COEF_WIDTH = 32,
    parameter DEC_WIDTH = 16, // [31 for twos complement][30:16].[15:0]
    parameter ORDER = 6
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
        a[0] = 32'h00010000;
        a[1] = 32'hfffb89e1;
        a[2] = 32'h0008689e;
        a[3] = 32'hfff75a12;
        a[4] = 32'h00052777;
        a[5] = 32'hfffe4fd7;
        a[6] = 32'h00003c28;
        
        b[0] = 32'h0000063d;
        b[1] = 32'h00000000;
        b[2] = 32'hffffed49;
        b[3] = 32'h00000000;
        b[4] = 32'h000012b7;
        b[5] = 32'h00000000;
        b[6] = 32'hfffff9c3;
    end

    logic signed [COEF_WIDTH + COEF_WIDTH - 1:0] acc; // Accumulator for filter calculation
    integer i;
    logic [4:0] counter;

    always_ff @(posedge clk_in) begin
        if (rst_in) begin
            y_out <= 0;
            y_out_valid <= 0;
            
            state <= IDLE;

            acc <= 0;
            for (i = 0; i < ORDER; i++) begin
                y_prev[i] <= 0;
                x_prev[i] <= 0;
            end
            counter <= 0;
            x_cur <= 0;

        end else begin
            case (state)
                IDLE: begin
                    y_out_valid <= 0;
                    if (x_in_valid) begin
                        state <= CALC;
                        acc <= 0;
                        counter <= 0;
                        x_cur <= x_in;
                    end
                end

                CALC: begin
                    if (counter == 0) begin
                        // first one
                        acc <= acc + ((b[0] * $signed({1'b0, x_cur})) << DEC_WIDTH);
                        counter <= 1;
                    end else if (counter == ORDER+1) begin
                        // we're done
                        state <= UPDATE;
                    end else begin
                        acc <= acc + ((b[counter] * $signed({1'b0, x_prev[counter-1]})) << DEC_WIDTH) - ((a[counter] * $signed({y_prev[counter-1]})));
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