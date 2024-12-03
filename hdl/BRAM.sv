module BRAM (
    input logic clk,
    input logic write_enable,
    input logic [3:0] write_addr, // Address for writing
    input logic [7:0] write_data, // Data to write
    input logic [3:0] read_addr,  // Address for reading
    output logic [7:0] read_data  // Data output
);
    // 16x8 BRAM (16 locations, 8 bits per location)
    logic [7:0] memory [0:15];

    always_ff @(posedge clk) begin
        if (write_enable)
            memory[write_addr] <= write_data; // Write data
        read_data <= memory[read_addr];      // Read data
    end
endmodule
