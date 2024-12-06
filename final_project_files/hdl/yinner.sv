`timescale 1ns / 1ps

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
    input wire start_computation,
    output logic [WIDTH - 1:0] f_out,
    output logic f_out_valid
);

    typedef enum {IDLE, DIFF_FUNCTION, CMNDF, PI, DIVIDING} states;
    states state;

    logic [SIG_WIDTH - 1: 0] sig_buffer [0: WINDOW_SIZE - 1];
    logic [$clog2(WINDOW_SIZE):0] sample_num; // 0 -> 500, keeps track of which index is "index zero"
    logic [$clog2(WINDOW_SIZE):0] sample_counter; // "for loop" counter

    localparam TAU_MAX = SAMPLE_RATE / F_MIN;

    logic [2*SIG_WIDTH + $clog2(WINDOW_SIZE): 0] df_buffer [0: TAU_MAX - 1];
    logic [$clog2(TAU_MAX):0] tau; // 0 -> 80ish
    // pipelining stages
    logic [2*SIG_WIDTH: 0] squared_diff;
    logic [SIG_WIDTH-1: 0] diff;


    logic [2*SIG_WIDTH + $clog2(WINDOW_SIZE) + $clog2(TAU_MAX): 0] diff_sum;

    logic [4*SIG_WIDTH + 2*$clog2(WINDOW_SIZE) + $clog2(TAU_MAX)+40: 0] sum_times_point_one;
    logic [2*SIG_WIDTH + $clog2(WINDOW_SIZE) + $clog2(TAU_MAX) + 1: 0] product;
    logic [2*SIG_WIDTH + $clog2(WINDOW_SIZE): 0] df_buff_ind_tau;
    logic [WIDTH - 1:0] ZERO_POINT_ONE;
    // assign ZERO_POINT_ONE = 32'b0000_0000_0000_0000_0001_1001_1001_1001;
    // assign ZERO_POINT_ONE = 32'b0000_0000_0000_0000_0010_0110_0110_0110; // 0.15 not 0.1
    assign ZERO_POINT_ONE = 32'b0000_0000_0000_0000_0100_0000_0000_0000; // 0.25 not 0.1


    logic [$clog2(TAU_MAX) : 0] tau_final;

    // logic for indexing math
    logic[$clog2(WINDOW_SIZE):0] lower_index;
    logic[$clog2(WINDOW_SIZE):0] upper_index;

    // always_comb begin
    //     // lower_index = sample_num + 1 + sample_counter < WINDOW_SIZE ? sample_num + 1 + sample_counter : sample_num + 1 + sample_counter - WINDOW_SIZE;
    //     // upper_index = sample_num + 1 + sample_counter + tau < WINDOW_SIZE ? sample_num + 1 + sample_counter + tau : sample_num + 1 + sample_counter + tau - WINDOW_SIZE;
    // end

    integer i;

    logic divide_done;
    logic divide_start;
    logic divide_busy;
    logic divide_valid;
    logic [WIDTH - 1:0] EIGHT_THOUSAND;
    assign EIGHT_THOUSAND = 32'h3E80_0000; //32'h1F40_0000; // 16kHz
    logic [WIDTH - 1:0] f0;
    divider #(  
        .WIDTH(WIDTH)
    ) final_divider (
        .clk_in(clk_in),
        .rst_in(rst_in),
        .dividend_in(EIGHT_THOUSAND),
        .divisor_in({8'h00, tau_final, 16'h0000}),
        .data_valid_in(divide_start),
        .quotient_out(f0),
        .remainder_out(),
        .data_valid_out(divide_valid), //high when output data is present.
        .error_out(),
        .busy_out(divide_busy)
    );

    always_ff @(posedge clk_in) begin
        if (rst_in) begin
            f_out <= 0;
            f_out_valid <= 0;

            state <= IDLE;

            lower_index <= 0;
            upper_index <= 0;

            for (i = 0; i < WINDOW_SIZE; i++) begin
                sig_buffer[i] <= 0;
                sig_buffer[i] <= 0;
            end
            sample_num <= 0;
            sample_counter <= 0;
            squared_diff <= 0;
            diff <= 0;
            for (i = 0; i < TAU_MAX; i++) begin
                df_buffer[i] <= 0;
                df_buffer[i] <= 0;
            end
            tau <= 0;

            sum_times_point_one <= 0;
            product <= 0;
            df_buff_ind_tau <= 0;

            diff_sum <= 0;

            divide_start <= 0;

        end else begin
            case (state)
                IDLE: begin
                    f_out_valid <= 0;
                    if (sig_in_valid) begin
                        // shift the buffer
                        sig_buffer[sample_num] <= sig_in;
                        sample_num <= (sample_num == WINDOW_SIZE - 1) ? 0 : sample_num + 1;
                    end

                    if (start_computation) begin
                        state <= DIFF_FUNCTION;
                        sample_counter <= 0;
                        squared_diff <= 0;
                        diff <= 0;
                        for (i = 0; i < TAU_MAX; i++) begin
                            df_buffer[i] <= 0;
                            df_buffer[i] <= 0;
                        end
                        tau <= 0;

                        lower_index <= sample_num + 1 < WINDOW_SIZE ? sample_num + 1 : sample_num + 1 - WINDOW_SIZE;
                        upper_index <= sample_num + 1 + tau < WINDOW_SIZE ? sample_num + 1 + tau : sample_num + 1 + tau - WINDOW_SIZE;
                    end
                end

                DIFF_FUNCTION: begin
                    if (sample_counter + tau + 1 < WINDOW_SIZE) begin
                        diff <= sig_buffer[upper_index] - sig_buffer[lower_index];
                        squared_diff <= $signed(diff) * $signed(diff);
                        // squared_diff <= (sig_buffer[upper_index] - sig_buffer[lower_index]) * (sig_buffer[upper_index] - sig_buffer[lower_index]);
                        df_buffer[tau] <= df_buffer[tau] + squared_diff;
                        // df_buffer[tau] <= df_buffer[tau] + (sig_buffer[upper_index] - sig_buffer[lower_index]) * (sig_buffer[upper_index] - sig_buffer[lower_index]);
                        sample_counter <= sample_counter + 1;
                        
                        lower_index <= (lower_index == WINDOW_SIZE - 1) ? 0 : lower_index + 1;
                        upper_index <= (upper_index == WINDOW_SIZE - 1) ? 0 : upper_index + 1;

                    end else begin
                        sample_counter <= 0;
                        tau <= tau + 1;
                        diff <= 0;
                        squared_diff <= 0;
                        lower_index <= sample_num + 1 < WINDOW_SIZE ? sample_num + 1 : sample_num + 1 - WINDOW_SIZE;
                        upper_index <= sample_num + 1 + tau < WINDOW_SIZE ? sample_num + 1 + tau : sample_num + 1 + tau - WINDOW_SIZE;
                        if (tau == TAU_MAX) begin
                            tau <= 0;
                            state <= CMNDF;
                            diff_sum <= 0;
                        end
                    end
                end

                CMNDF: begin
                    if (tau == 0) begin
                        // diff_sum <= df_buffer[tau];
                        diff_sum <= 0;
                        tau <= tau + 1;
                        df_buff_ind_tau <= df_buffer[1];
                    end else begin
                        if (tau <= TAU_MAX) begin
                            sum_times_point_one <= ((diff_sum + df_buffer[tau]) * ZERO_POINT_ONE) >> DEC_WIDTH;
                            product <= df_buff_ind_tau * tau;
                            df_buff_ind_tau <= df_buffer[tau + 1];
                            if (product < sum_times_point_one) begin
                                // we've found our lag that works
                                tau_final <= tau;
                                state <= PI;
                            end else begin
                                tau <= tau + 1;
                                diff_sum <= diff_sum + df_buffer[tau];
                            end
                        end else begin
                            tau_final <= 0;
                            state <= PI;
                        end
                    end
                end

                PI: begin
                    if (tau_final == 0) begin
                        f_out <= 0;
                        f_out_valid <= 1;
                        state <= IDLE;
                    end else begin
                        divide_start <= 1;
                        state <= DIVIDING;
                    end
                end

                DIVIDING: begin
                    if (divide_valid == 1) begin
                        f_out <= f0;
                        f_out_valid <= 1;
                        state <= IDLE;
                    end
                end
            endcase
        
        end
    end

endmodule