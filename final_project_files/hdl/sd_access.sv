module sd_access #(
    parameter RAM_WIDTH = 512,     // Match RAM data width
    parameter RAM_DEPTH = 3    // Match RAM depth
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
    output logic ram_we,                            // RAM write enable
    output logic ram_en                             // RAM enable
);


    // FSM states
    typedef enum logic [3:0] {
        IDLE,
        INIT,
        SPI_MODE,
        VOLTAGE_CHECK,
        CMD55,
        ACMD41,
        REQ_DATA,
        WAIT,
        RECIEVE
    } state_t;

    state_t state;

    // SPI Controller signals
    logic [47:0] spi_cmd;             // Command to send to SD card (48 bits)
    logic spi_trigger;                // Trigger SPI transaction
    wire spi_done;                  // SPI transaction complete
    logic [7:0] spi_data_in;          // Data to send to SPI controller
    wire [7:0] spi_data_out;        // Data received from SPI controller
    logic [47:0] command;
    logic [31:0] send_counter;

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
        .DATA_WIDTH(8),
        .DATA_CLK_PERIOD(500)
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

    // FSM Output Logic
    always_ff @(posedge clk) begin
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
            command <= 0;
        end else begin
            case (state)
                IDLE: begin
                    if(read_en) begin
                        state <= INIT;
                    end
                end
                INIT: begin            
                    if (send_counter < 100000) begin   
                        // chip_sel_out <= 1; // Ensure CS is high //Cannot change chip sel, so...
                        send_counter <= send_counter + 1;
                        state <= INIT;
                    end else if (send_counter<16000)begin
                        // chip_sel_out <= 0; // Ensure CS is Low maybe?
                        send_counter <= send_counter + 1;
                        state <= INIT;
                    end else begin
                        state <= SPI_MODE;
                        send_counter <= 0;
                        command <= 48'h40_00_00_00_00_95;
                    end
                end
                SPI_MODE: begin
                    if(spi_done) begin
                        if (send_counter < 6) begin
                            spi_trigger <= 1;
                            spi_data_in <= command[47-(8*send_counter) +: 8];
                            send_counter <= send_counter + 1;
                        end else begin
                            spi_data_in <= 8'hFF;
                            spi_trigger <= 1;
                            send_counter <= 0;
                            state <= VOLTAGE_CHECK;
                            command <= 48'h48_00_00_00_01_AA_87;
                        end
                    end
                end
                VOLTAGE_CHECK: begin
                    if(spi_done) begin
                        if (send_counter < 6) begin
                            spi_trigger <= 1;
                            spi_data_in <= command[47-(8*send_counter) +: 8];
                            send_counter <= send_counter + 1;
                        end else begin
                            spi_data_in <= 8'hFF;
                            spi_trigger <= 1;
                            send_counter <= 0;
                            state <= ACMD41;
                            command <= 48'h77_00_00_00_00_01;
                        end
                    end
                end
                CMD55: begin
                    if(spi_done) begin
                        if (send_counter < 6) begin
                            spi_trigger <= 1;
                            spi_data_in <= command[47-(8*send_counter) +: 8];
                            send_counter <= send_counter + 1;
                        end else begin
                            spi_data_in <= 8'hFF;
                            spi_trigger <= 1;
                            send_counter <= 0;
                            state <= ACMD41;
                            command <= 48'h69_40_00_00_00_77;
                        end
                    end

                end
                ACMD41: begin
                    if(spi_done) begin
                        if(spi_data_out != 0'h00) begin
                            if (send_counter < 6) begin
                                spi_trigger <= 1;
                                spi_data_in <= command[47-(8*send_counter) +: 8];
                                send_counter <= send_counter + 1;
                            end else begin
                                spi_data_in <= 8'hFF;
                                spi_trigger <= 1;
                                send_counter <= 0;
                                state <= ACMD41;
                                command <= 48'h69_40_00_00_00_77;
                            end
                        end else begin
                            send_counter <= 0;
                            state <= REQ_DATA;
                            command <= {8'h51,addr_in,8'hFF};
                        end
                    end
                end
                REQ_DATA: begin
                    if(spi_done) begin
                        if (send_counter < 6) begin
                            spi_trigger <= 1;
                            spi_data_in <= command[47-(8*send_counter) +: 8];
                            send_counter <= send_counter + 1;
                        end else begin
                            spi_data_in <= 8'hFF;
                            spi_trigger <= 1;
                            send_counter <= 0;
                            state <= RECIEVE;
                            command <= 48'hFFFF_FFFF_FF;  
                        end
                    end
                end
                WAIT: begin
                    if(spi_done) begin
                        if(spi_data_out != 0'hFE) begin
                            spi_trigger <= 1;
                            spi_data_in <= 8'hFF;
                        end else begin
                            spi_data_in <= 8'hFF;
                            spi_trigger <= 1;
                            send_counter <= 0;
                            state <= RECIEVE;
                            ram_addr <= 0;
                        end
                    end
                end
                RECIEVE: begin
                    if(spi_done) begin
                        if (send_counter < 512) begin
                            spi_trigger <= 1;
                            spi_data_in <= 8'hFF;
                            send_counter <= send_counter + 1;
                            //To Be changed for larger files
                            ram_addr <= ram_addr + 1;
                            ram_din <= spi_data_out;
                            ram_we <= 1;
                        end else begin
                            send_counter <= 0;
                            state <= INIT;
                            command <= 0;
                            ram_we <= 0;
                        end
                    end else begin
                        ram_we <=0;

                    end

                end
            endcase
        end
    end


endmodule 
