module NoteSpriteDisplay (
    input wire clk,                        // Clock signal
    input wire rst,                        // Reset signal
    input wire [7:0] new_note,             // 8-bit note (letter, accidental, octave)
    output logic [47:0] note_sprite [0:15]   // 16x48 binary sprite
);

    // assign note_sprite = 32'hB00B500;
    // Address calculations
    logic[8:0] base_address;       // Address for the letter
    logic[8:0] accidental_address; // Address for the accidental
    logic[8:0] octave_address;     // Address for the octave

    always_comb begin
        // Calculate base addresses
        base_address       = (new_note[7:5]) * 16;  // Letter (A=0, B=16, ..., G=96)
        accidental_address = (new_note[4:3] == 2'b10) ? 272 : 256; // Flat or Blank
        octave_address     = 96 + (new_note[2:0] * 16); // Octave (0=128, ..., 7=240)
    end

    // Temporary storage for ROM data
    logic[15:0] letter_row;
    logic[15:0] accidental_row;
    logic[15:0] octave_row;

    // ROM instance
    font_rom rom_inst (
        .clk_in(clk),
        .addr(addr),
        .data(rom_data)
    );

    logic[8:0] addr;         // Address to access font_rom
    logic[15:0] rom_data;    // Data from font_rom
    
    //Read FSM
    integer row;
    logic [1:0] state;
    localparam IDLE = 2'b00, FETCH_L = 2'b01, FETCH_A = 2'b10, FETCH_O = 2'b11;
    always @(posedge clk or posedge rst) begin
        if (rst) begin
            // Reset sprite data
            for (row = 0; row < 16; row = row + 1) begin
                note_sprite[row] <= 48'b0;
            end
            row <= 0;
            state <= IDLE;
        end else begin

            case (state)
                IDLE: begin
                    row <= 0;
                    state <= FETCH_L;
                end
                FETCH_L: begin
                    addr <= base_address + row;
                    letter_row <= rom_data;
                    state <= FETCH_A;
                end
                FETCH_A: begin
                    addr <= accidental_address + row;
                    accidental_row <= rom_data;
                    state <= FETCH_O;
                end
                FETCH_O: begin 
                    addr <= octave_address + row;
                    octave_row <= rom_data;
                    if (accidental_row == 0) begin
                        // {in the middle, on the left, on the right}

                        note_sprite[row] <= {octave_row, letter_row, 16'h0000};
                    end else begin
                        // {on the right, on the left, in the middle}
                        note_sprite[row] <= {octave_row, letter_row , accidental_row};

                    end
                    // note_sprite[row] <= {new_note, new_note,new_note, new_note,new_note, new_note};
                    if (row == 15) begin 
                        state <= IDLE;
                    end else begin
                        row <= row +1;
                        state <= FETCH_L;
                    end
                end
            endcase
        end
    end
endmodule
