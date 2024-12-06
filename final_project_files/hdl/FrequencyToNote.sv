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
        note_mapping[0]  = 8'b000_01_000; // A
        note_mapping[1]  = 8'b001_10_000; // Bb
        note_mapping[2]  = 8'b001_01_000; // B
        note_mapping[3]  = 8'b010_01_000; // C
        note_mapping[4]  = 8'b011_10_000; // Db
        note_mapping[5]  = 8'b011_01_000; // D
        note_mapping[6]  = 8'b100_10_000; // Eb
        note_mapping[7]  = 8'b100_01_000; // E
        note_mapping[8]  = 8'b101_01_000; // F
        note_mapping[9]  = 8'b110_10_000; // Gb
        note_mapping[10] = 8'b110_01_000; // G
        note_mapping[11] = 8'b000_10_000; // Ab
        note_mapping[12]  = 8'b000_01_000; // A
        note_mapping[13]  = 8'b001_10_000; // Bb
        note_mapping[14]  = 8'b001_01_000; // B
        note_mapping[15]  = 8'b010_01_000; // C
        note_mapping[16]  = 8'b011_10_000; // Db
        note_mapping[17]  = 8'b011_01_000; // D
        note_mapping[18]  = 8'b100_10_000; // Eb
        note_mapping[19]  = 8'b100_01_000; // E
        note_mapping[20]  = 8'b101_01_000; // F
        note_mapping[21]  = 8'b110_10_000; // Gb
        note_mapping[22] = 8'b110_01_000; // G
        note_mapping[23] = 8'b000_10_000; // Ab
        note_mapping[24]  = 8'b000_01_000; // A
        note_mapping[25]  = 8'b001_10_000; // Bb
        note_mapping[26]  = 8'b001_01_000; // B
        

        // Base frequencies (example for octave 4)
        base_frequencies[0]  = 220; //A3
        base_frequencies[1]  = 233; //Bb3
        base_frequencies[2]  = 247; //B3
        base_frequencies[3]  = 262; //C4
        base_frequencies[4]  = 277; //Db4
        base_frequencies[5]  = 294; //D4
        base_frequencies[6]  = 311; //Eb4
        base_frequencies[7]  = 330; //E4
        base_frequencies[8]  = 349; //F4
        base_frequencies[9]  = 370; //Gb4
        base_frequencies[10]  = 392; //G4
        base_frequencies[11]  = 415; //Ab4
        base_frequencies[12]  = 440;  // A4
        base_frequencies[13]  = 466;  // Bb4
        base_frequencies[14]  = 494;  // B4
        base_frequencies[15]  = 523;  // C5
        base_frequencies[16]  = 554;  // Db5
        base_frequencies[17]  = 587;  // D5
        base_frequencies[18]  = 622;  // Eb5
        base_frequencies[19]  = 659;  // E5
        base_frequencies[20]  = 698;  // F5
        base_frequencies[21]  = 740;  // Gb5
        base_frequencies[22] = 784;  // G5
        base_frequencies[23] = 831;  // Ab5
        base_frequencies[24]  = 880; //A5
        base_frequencies[25]  = 932; //Bb5
        base_frequencies[26]  = 988; //B5
    end

    always_comb begin
        result = 8'b00000000; // Default result
        for (int i = 0; i < 27; i++) begin
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