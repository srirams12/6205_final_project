module sd_access #(
    parameter RAM_WIDTH = 18,     // Match RAM data width
    parameter RAM_DEPTH = 1024    // Match RAM depth
)(
    input wire clk,               //  clock
    input wire rst,               // Reset 
    // Control interface
    input wire [31:0] addr_in,    // Address for read/write operations (sector address)
    input wire read_en,           // Start a read operation
    output logic [511:0] data_out,  // Data read from SD card
    output logic done,              // High when operation is complete
    output logic error,             // High if an error occurs
    // SPI interface
    output wire chip_data_out,    // SPI Master Out (MOSI)
    input wire chip_data_in,      // SPI Master In (MISO)
    output wire chip_clk_out,     // SPI Clock
    output wire chip_sel_out,     // SPI Chip Select
    // RAM interface
    output logic [$clog2(RAM_DEPTH)-1:0] ram_addr, // RAM address
    output logic [RAM_WIDTH-1:0] ram_din,           // RAM write data
    input wire [RAM_WIDTH-1:0] ram_dout,          // RAM read data
    output logic ram_we,                            // RAM write enable
    output logic ram_en                             // RAM enable
);


    // FSM states
    typedef enum logic [3:0] {
        IDLE,
        INIT,
        SEND_CMD,
        WAIT_RESP,
        READ_BLOCK,
        WAIT_SPI,
        DONE,
        ERROR
    } state_t;

    state_t current_state, next_state;

    // SPI Controller signals
    logic [47:0] spi_cmd;             // Command to send to SD card (48 bits)
    logic spi_trigger;                // Trigger SPI transaction
    wire spi_done;                  // SPI transaction complete
    logic [7:0] spi_data_in;          // Data to send to SPI controller
    wire [7:0] spi_data_out;        // Data received from SPI controller

    // RAM Interface signals
    logic [$clog2(RAM_DEPTH-1)-1:0] ram_addr; // RAM address
    logic [RAM_WIDTH-1:0] ram_din;           // RAM write data
    wire [RAM_WIDTH-1:0] ram_dout;         // RAM read data
    logic ram_we;                            // RAM write enable
    logic ram_en;                            // RAM enable

    // Sector Buffer (512 bits for one SD card sector)
    logic [511:0] sector_buffer;
    logic [8:0] byte_counter;  // Counter for 512 bytes (9 bits)

    // FSM Control Signals
    logic cmd_sent;            // Tracks if the current command is sent
    logic read_active;         // Asserted during an active read operation
    logic write_active;        // Asserted during an active write operation

    // SPI Controller instantiation
    spi_con #(
        .DATA_WIDTH(8)
    ) spi_inst (
        .clk_in(clk),
        .rst_in(rst),
        .data_in(spi_data_in),
        .trigger_in(spi_trigger),
        .data_out(spi_data_out),
        .data_valid_out(spi_done),
        .chip_data_out(chip_data_out),
        .chip_data_in(chip_data_in),
        .chip_clk_out(chip_clk_out),
        .chip_sel_out(chip_sel_out)
    );

    // State Machine
    always_ff @(posedge clk or posedge rst) begin
        if (rst)
            current_state <= IDLE;
        else
            current_state <= next_state;
    end
        // FSM Transitions
    always_comb begin
        // Default values
        next_state = current_state;
        case (current_state)
            IDLE: begin
                if (read_en)
                    next_state = INIT;  // Start read operation
            end

            INIT: begin
                // Send SD card initialization commands (CMD0, CMD8, etc.)
                if (cmd_sent)
                    next_state = SEND_CMD;
            end

            SEND_CMD: begin
                // Wait for command response
                next_state = WAIT_RESP;
            end

            WAIT_RESP: begin
                // If valid response received, proceed to read/write
                if (spi_done && spi_data_out == 8'h00) begin
                    if (read_active)
                        next_state = READ_BLOCK;
                    else if (write_active)
                        next_state = WRITE_BLOCK;
                end else if (spi_done && spi_data_out != 8'h00) begin
                    next_state = ERROR;  // Handle invalid response
                end
            end

            READ_BLOCK: begin
                if (byte_counter == 511) // Once 512 bytes are read, finish
                    next_state = DONE;
            end

            DONE: begin
                next_state = IDLE;  // Go back to idle
            end

            ERROR: begin
                next_state = IDLE;  // Return to idle on error
            end

            default: begin
                next_state = IDLE; // Default case
            end
        endcase
    end

    // FSM Output Logic
    always_ff @(posedge clk or posedge rst) begin
        if (rst) begin
            spi_trigger <= 0;
            spi_data_in <= 8'b0;
            done <= 0;
            error <= 0;
            cmd_sent <= 0;
            read_active <= 0;
            byte_counter <= 0;
            ram_we <= 0;
            ram_en <= 0;
        end else begin
            case (current_state)
                IDLE: begin
                    done <= 0;
                    error <= 0;
                    cmd_sent <= 0;
                    read_active <= read_en;
                    byte_counter <= 0;
                end

                INIT: begin
                    // Example: Send CMD0 (GO_IDLE_STATE)
                    if (!cmd_sent) begin
                        spi_data_in <= 8'h40; // CMD0 first byte
                        spi_trigger <= 1;
                        cmd_sent <= 1;
                    end else if (spi_done) begin
                        spi_trigger <= 0;
                    end
                end

                SEND_CMD: begin
                    // Send the next bytes of the command if required
                    spi_trigger <= 0;
                end

                WAIT_RESP: begin
                    if (spi_done) begin
                        if (spi_data_out == 8'h00) begin
                            // Valid response received
                            if (read_active)
                                byte_counter <= 0; // Prepare for read
                        end else begin
                            error <= 1; // Invalid response
                        end
                    end
                end

                READ_BLOCK: begin
                    // Read 512 bytes from SD card and write to RAM
                    if (spi_done) begin
                        sector_buffer[byte_counter * 8 +: 8] <= spi_data_out;
                        byte_counter <= byte_counter + 1;

                        // Write data to RAM every RAM_WIDTH bytes
                        if (byte_counter % (RAM_WIDTH / 8) == 0) begin
                            ram_din <= sector_buffer[byte_counter * 8 - RAM_WIDTH +: RAM_WIDTH];
                            ram_we <= 1;
                            ram_addr <= ram_addr + 1;
                        end else begin
                            ram_we <= 0;
                        end
                    end
                end


                DONE: begin
                    done <= 1;
                end

                ERROR: begin
                    error <= 1;
                end
            endcase
        end
    end


endmodule 