module NoteLoader(
    input logic clk,                     // Clock signal
    input logic reset,                   // Reset signal
    output logic [15:0] results [0:31],  // Array to store 32 results
    output logic done                    // Signal indicating processing is complete
);

    // BRAM interface (assume 512x16 pre-loaded with .mem)
    logic [8:0] addr;             // BRAM address (512 locations, 9 bits)
    logic [15:0] bram_data;       // Data output from BRAM

    // Registers and counters
    integer result_count;         // Counter for results (up to 32)
    logic [8:0] start_addr;       // Start address for the BRAM read

    // Simulated BRAM (for testing or FPGA instantiation)
    logic [15:0] bram [0:511];    // 512x16 BRAM storage

    // Initial block to load BRAM (use this for simulation or pre-synthesis testing)
    initial begin
        $readmemh("input.mem", bram);  // Replace "input.mem" with your file name
    end

    // Read BRAM and store results
    always_ff @(posedge clk or posedge reset) begin
        if (reset) begin
            addr <= 0;
            result_count <= 0;
            done <= 0;
        end else if (result_count < 32) begin
            bram_data <= bram[addr];          // Read data from BRAM
            results[result_count] <= bram_data; // Store data in results array
            addr <= addr + 1;                // Increment address
            result_count <= result_count + 1;

            if (result_count == 31) begin
                done <= 1; // Indicate completion after storing 32 results
            end
        end
    end
endmodule
