module yinner #(
    parameter SIG_WIDTH = 9,
    parameter WIDTH = 32, // [15:5].[4:0]
    parameter DEC_WIDTH = 16,
    parameter SAMPLE_RATE = 8000,
    parameter WINDOW_SIZE= 500,
    parameter F_MIN = 100,
    parameter F_MAX = 1000,
    parameter THRESHOLD = 0.1
) 
(
    input wire clk_in,
    input wire rst_in,
    input wire [SIG_WIDTH - 1:0] sig_in,
    input wire sig_in_valid,
    output logic [WIDTH - 1:0] f_out,
    output logic f_out_valid
);

    typedef enum {IDLE, DIFF_FUNCTION, CMNDF, PI} states;
    states state;

    logic [SIG_WIDTH - 1: 0] sig_buffer [0: WINDOW_SIZE - 1]
    logic [$clog2(WINDOW_SIZE):0] sample_num; // 0 -> 500, keeps track of which index is "index zero"
    logic [$clog2(WINDOW_SIZE):0] sample_counter; // "for loop" counter

    localparam TAU_MIN = SAMPLE_RATE / F_MAX;
    localparam TAU_MAX = SAMPLE_RATE / F_MIN;

    logic [2*SIG_WIDTH + $clog2(WINDOW_SIZE): 0] df_buffer [0: TAU_MAX-TAU_MIN - 1]
    logic [$clog2(TAU_MAX):0] tau; // 8 -> 80ish

    logic [WIDTH-1 : 0] tau_final;


    always_ff @(posedge clk_in) begin
        if (rst_in) begin
            f_out <= 0;
            f_out_valid <= 0;

            state <= IDLE;

            sig_buffer <= 0; // maybe for loop
            sample_num <= 0;
            sample_counter <= 0;
            df_buffer <= 0; // might need to for loop
            tau <= TAU_MIN;

        end else begin
            case (state)
                IDLE: begin
                    f_out_valid <= 0;
                    if (sig_in_valid) begin
                        // shift the buffer
                        sig_buffer[sample_num] <= sig_in;
                        if (sample_num == WINDOW_SIZE - 1) begin
                            sample_num <= 0;
                        end else begin
                            sample_num <= sample_num + 1;
                        end
                        state <= DIFF_FUNCTION;
                    end
                end

                DIFF_FUNCTION: begin
                    
                end

                CMNDF: begin
                    
                end

                PI: begin
                    
                end
            endcase
        
        end
    end

endmodule