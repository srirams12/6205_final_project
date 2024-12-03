module FrequencyToNote (
    input logic [31:0] frequency,   // Input frequency in Hz (integer for simplicity)
    output logic [7:0] note_code   // Encoded note: [7:5]=note, [4:3]=accidental, [2:0]=octave
);

    // Internal variables
    logic [7:0] note_mapping [0:11]; // 12 semitones in an octave
    logic [7:0] result;
    logic [31:0] base_frequencies [0:11]; // Base frequencies for an octave
    
    // Initialize note mappings and base frequencies
    initial begin
        // Mapping for notes (example: A=000, A#=001, B=010, ...)
        note_mapping[0]  = 8'b000_00_000; // A
        note_mapping[1]  = 8'b000_01_000; // A#
        note_mapping[2]  = 8'b001_00_000; // B
        note_mapping[3]  = 8'b010_00_000; // C
        note_mapping[4]  = 8'b010_01_000; // C#
        note_mapping[5]  = 8'b011_00_000; // D
        note_mapping[6]  = 8'b011_01_000; // D#
        note_mapping[7]  = 8'b100_00_000; // E
        note_mapping[8]  = 8'b101_00_000; // F
        note_mapping[9]  = 8'b101_01_000; // F#
        note_mapping[10] = 8'b110_00_000; // G
        note_mapping[11] = 8'b110_01_000; // G#

        // Base frequencies (example for octave 4)
        base_frequencies[0]  = 440;  // A4
        base_frequencies[1]  = 466;  // A#4
        base_frequencies[2]  = 494;  // B4
        base_frequencies[3]  = 523;  // C5
        base_frequencies[4]  = 554;  // C#5
        base_frequencies[5]  = 587;  // D5
        base_frequencies[6]  = 622;  // D#5
        base_frequencies[7]  = 659;  // E5
        base_frequencies[8]  = 698;  // F5
        base_frequencies[9]  = 740;  // F#5
        base_frequencies[10] = 784;  // G5
        base_frequencies[11] = 831;  // G#5
    end

    always_comb begin
        result = 8'b00000000; // Default result
        for (int i = 0; i < 11; i++) begin
            if (frequency >= base_frequencies[i] && frequency < base_frequencies[i + 1]) begin
                result = note_mapping[i];
            end
        end
        // Determine octave based on frequency
        for (int octave = 0; octave < 8; octave++) begin
            if (frequency < (base_frequencies[0] << octave)) begin
                result[2:0] = octave - 1;
                break;
            end
        end
    end

    assign note_code = result;
endmodule
