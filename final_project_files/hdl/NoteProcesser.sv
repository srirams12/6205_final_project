//top level of jesssica part
module NoteProcessor (
    input logic clk,
    input logic reset,
    input logic [31:0] frequency_stream [0:15], // Stream of frequencies (max 16 notes)
    input logic process_enable,                // Start processing signal
    output logic [7:0] note_out,               // Note output
    output logic done                          // Processing complete
);

    // Internal signals
    logic [3:0] write_addr, read_addr;
    logic write_enable;
    logic [7:0] note_code;
    logic processing;

    // Instantiate frequency-to-note module
    FrequencyToNote ftn (
        .frequency(frequency_stream[write_addr]),
        .note_code(note_code)
    );

    // Instantiate BRAM
    BRAM bram (
        .clk(clk),
        .write_enable(write_enable),
        .write_addr(write_addr),
        .write_data(note_code),
        .read_addr(read_addr),
        .read_data(note_out)
    );

    // Write state machine
    always_ff @(posedge clk or posedge reset) begin
        if (reset) begin
            write_addr <= 0;
            write_enable <= 0;
            processing <= 0;
        end else if (process_enable && !processing) begin
            processing <= 1;
            write_enable <= 1;
        end else if (processing) begin
            if (write_addr < 15) begin
                write_addr <= write_addr + 1;
            end else begin
                write_enable <= 0;
                processing <= 0;
            end
        end
    end

    // Read state machine
    always_ff @(posedge clk or posedge reset) begin
        if (reset) begin
            read_addr <= 0;
            done <= 0;
        end else if (!processing && write_enable == 0) begin
            if (read_addr < 31) begin
                read_addr <= read_addr + 1;
            end else begin
                done <= 1;
            end
        end
    end

endmodule
