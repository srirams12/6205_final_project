`default_nettype none // prevents system from inferring an undeclared logic (good practice)
module note_game (
    input wire pixel_clk_in,
    input wire rst_in,
    input wire [15:0] note_in,
    input wire [7:0] true_note_in,
    input wire nf_in,
    input wire [10:0] hcount_in,
    input wire [9:0] vcount_in,
    input wire [15:0] sw,
    output logic [7:0] red_out,
    output logic [7:0] green_out,
    output logic [7:0] blue_out,
    output logic note_req
);
    parameter SCREEN_WIDTH = 1280; //WHat is up with this beign divided by 3
    parameter SCREEN_HEIGHT = 720; // Vertical screen resolution
    parameter WALL_COUNT = 3;
    logic [9:0] ball_y;
    logic [10:0] ball_x;
    logic [7:0] wall_r, wall_g, wall_b;
    logic [7:0] ball_r, ball_g, ball_b;


    logic [1:0] state;
    localparam WAIT = 2'b00, PLAY = 2'b01, GAME_OVER = 2'b10;
    logic start_signal, final_note, game_restart;
    //GAME GFSM
    always @(posedge pixel_clk_in) begin
        if(rst_in) begin
            state <= WAIT;
            note_req <= 0;
        end else begin
            case (state)
                WAIT: if (start_signal) state <= PLAY;
                PLAY: if (final_note) state <= GAME_OVER;
                GAME_OVER: if(game_restart) state <= WAIT;
            endcase
        end
    end 
    //Game end code. 
    logic freeze_screen; // Signal to freeze the screen
    always @(posedge pixel_clk_in) begin
        if (rst_in) begin
            freeze_screen <= 0; // Clear freeze condition on reset
        end else begin
            // Check if any two walls have the same x value
            freeze_screen <= 0; // Default: no freeze
            for (int i = 0; i < WALL_COUNT; i++) begin
                for (int j = 0; j < WALL_COUNT; j++) begin
                    if (i != j && wall_x[i] -  wall_x[j] < 10) begin
                        freeze_screen <= 1; // Freeze if two walls have the same x
                    end
                end
            end
        end
    end

    parameter BOUNCE_DECAY_RATE = 2; // Bounce decays by dividing height by this factor
    parameter MAX_BOUNCE_DISTANCE = 16; // Maximum height of a bounce
    logic [12:0] wall_x[2:0];
    logic trigger_bounce[WALL_COUNT-1:0];
    logic [9:0] bounce_offset[WALL_COUNT-1:0]; // Bounce offset for each wall
    logic [1:0] wall_state[WALL_COUNT-1:0]; // State of each wall: MOVE, BOUNCE, or DECAY
    logic [8:0] gap_y [WALL_COUNT-1:0]; //Set of sprite gap heights
    logic resume[WALL_COUNT-1:0];
    localparam MOVE  = 2'b00; // Wall moving left
    localparam BOUNCE = 2'b01; // Wall bouncing
    localparam STOP = 2'b10; // Wall bounce decaying

    logic [15:0] song_note_frequencies [32-1:0];
    always_comb begin
        song_note_frequencies[0] = 262;
        song_note_frequencies[1] = 440;
        song_note_frequencies[2] = 622;
        song_note_frequencies[3] = 349;
        song_note_frequencies[4] = 392;
        song_note_frequencies[5] = 440;
        song_note_frequencies[6] = 494;
        song_note_frequencies[7] = 523;
    end
    logic [15:0] true_note_frequencies [WALL_COUNT-1:0];
    logic [7:0] true_note_codes [WALL_COUNT-1:0];
    logic [5:0] song_note_counter [WALL_COUNT-1:0];

    logic [12:0] road_x;

    //WALL POSITIONING
    always @(posedge pixel_clk_in) begin
        if (rst_in) begin
            // Reset wall positions and states
            for (int i = 0; i < WALL_COUNT; i = i + 1) begin
                wall_x[i] <= SCREEN_WIDTH + i * (SCREEN_WIDTH / WALL_COUNT);
                bounce_offset[i] <= 0;     // No initial bounce
                wall_state[i] <= MOVE;     // Start in MOVE state
                trigger_bounce[i] <= 0; // Default to no bounce
                // true_note_frequencies[i] <= song_note_frequencies[i];
                song_note_counter[i] <= i;
            end
            road_x <= 128;
        end else if (nf_in) begin
            // Update logic for each wall
            logic trigger_stop[WALL_COUNT]; // Track which walls should stop
            for (int i = 0; i < WALL_COUNT; i++) begin
                trigger_stop[i] = 0; // Default: no wall stops
            end

            if (!freeze_screen && wall_state[0] == MOVE && wall_state[1] == MOVE && wall_state[2] == MOVE) begin
                road_x <= road_x == 0 ? 128 : road_x - 1;
            end

            for (int i = 0; i < WALL_COUNT; i = i + 1) begin
                case (wall_state[i])
                    MOVE: begin
                        // Normal wall movement
                        if (!freeze_screen) begin
                            
                            // note_req <=0;                            
                            if (wall_x[i] == 0) begin
                                wall_x[i] <= SCREEN_WIDTH; // Reset wall position
                                // notes_in[i] <= note_in;
                                song_note_counter[i] <= song_note_counter[i] + 3;
                                note_req <=1;                            
                            end else begin
                                note_req <=0;                            
                                wall_x[i] <= wall_x[i] - 1; // Move wall left     
                            end
        
                            // Check for collision with the ball
                            if ((wall_x[i] == ball_x)) begin
                                if ((ball_y < gap_y[i] - 15) || (ball_y > gap_y[i] + 15)) begin
                                    // Ball is not in the gap; trigger bounce
                                    wall_state[i] <= BOUNCE;
                                    bounce_offset[i] <= MAX_BOUNCE_DISTANCE;
                                    trigger_bounce[i] <= 1;
                                end else begin
                                    trigger_bounce[i] <= 0;
                                end
                            end

                            if(wall_x[i] >= 650)begin
                                for (int j = 0; j < WALL_COUNT; j++) begin
                                    if (i != j) begin
                                        // Check if the gap condition is satisfied
                                        if ((wall_x[i] - wall_x[j]) > 0 && (wall_x[i] - wall_x[j]) < (SCREEN_WIDTH / 4)) begin
                                            wall_state[i] <= STOP; // too close,  stop
                                        end
                                    end
                                end
                            end
                        end else begin 
                            wall_x[i] <= wall_x[i]; // Keep wall position unchanged
                        end
                        
                    end
                    STOP: begin
                        // Wall is stopped, but check if it can resume
                        for (int j = 0; j < WALL_COUNT; j++) begin
                            if (i != j) begin
                                // Check if the gap condition is satisfied
                                if (((wall_x[i] - wall_x[j]) > 0 && (wall_x[i] - wall_x[j]) >= (SCREEN_WIDTH / 4))) begin
                                    wall_state[i] <= MOVE; // Still too close, remain stopped
                                end
                            end
                        end

                    end
                    BOUNCE: begin
                        // Wall moving to the right
                        if (bounce_offset[i] > 0) begin
                            wall_x[i] <= wall_x[i] + bounce_offset[i]; // Move right
                            bounce_offset[i] <= bounce_offset[i] - BOUNCE_DECAY_RATE; // Decay bounce
                        end else begin
                            wall_state[i] <= MOVE; // Return to normal movement
                        end
                    end
                endcase
            end
        end
    end

    logic [7:0] wall1_r, wall1_g, wall1_b;
    logic [7:0] wall2_r, wall2_g, wall2_b;
    logic [7:0] wall3_r, wall3_g, wall3_b;
    logic [7:0] back_r, back_g, back_b;


    always_comb begin
        for (int i = 0; i < WALL_COUNT; i = i + 1) begin
            true_note_frequencies[i] = song_note_frequencies[song_note_counter[i]];
        end
    end

    FrequencyToNote wall1_note (
        .frequency(true_note_frequencies[0]),
        .note_code(true_note_codes[0])
    );

    FrequencyToNote wall2_note (
        .frequency(true_note_frequencies[1]),
        .note_code(true_note_codes[1])
    );

    FrequencyToNote wall3_note (
        .frequency(true_note_frequencies[2]),
        .note_code(true_note_codes[2])
    );


    block_sprite #()
    wall1(
        .clk(pixel_clk_in),
        .rst(rst_in),
        .hcount_in(hcount_in),
        .vcount_in(vcount_in),
        .x_in(wall_x[0]),
        .freq_in(true_note_frequencies[0]),
        .true_note(sw[0] ? 8'b010_01_011 : true_note_codes[0]),
        .red_out(wall1_r),
        .green_out(wall1_g),
        .blue_out(wall1_b),
        .gap_height(gap_y[0]));

    block_sprite #()
    wall2(
        .clk(pixel_clk_in),
        .rst(rst_in),
        .hcount_in(hcount_in),
        .vcount_in(vcount_in),
        .x_in(wall_x[1]),
        .freq_in(true_note_frequencies[1] ),
        .true_note(sw[0] ? 8'b000_01_100 : true_note_codes[1]),
        .red_out(wall2_r),
        .green_out(wall2_g),
        .blue_out(wall2_b),
        .gap_height(gap_y[1]));
    block_sprite #()
    wall3(
        .clk(pixel_clk_in),
        .rst(rst_in),
        .hcount_in(hcount_in),
        .vcount_in(vcount_in),
        .x_in(wall_x[2]),
        .freq_in(true_note_frequencies[2]),
        .true_note(sw[0] ? 8'b100_10_101 : true_note_codes[2]),
        .red_out(wall3_r),
        .green_out(wall3_g),
        .blue_out(wall3_b),
        .gap_height(gap_y[2]));
    

    ball_sprite #()
    ball(
        .hcount_in(hcount_in),
        .vcount_in(vcount_in),
        .freq_in(note_in),
        .red_out(ball_r),
        .green_out(ball_g),
        .blue_out(ball_b),
        .ball_y(ball_y),
        .ball_x(ball_x));
    
    background #()
    back(
        .hcount_in(hcount_in),
        .vcount_in(vcount_in),
        .x_in(road_x),
        .red_out(back_r),
        .green_out(back_g),
        .blue_out(back_b));
    always_comb begin
        red_out = wall1_r | wall2_r | wall3_r | ball_r | back_r;
        green_out = wall1_g | wall2_g | wall3_g | ball_g | back_g;
        blue_out = wall1_b | wall2_b | wall3_b | ball_b | back_b;

        if (wall3_r || wall3_g|| wall3_b) begin
            red_out = wall3_r;
            green_out = wall3_g;
            blue_out = wall3_b;
        end else if (wall2_r || wall2_g|| wall2_b) begin
            red_out = wall2_r;
            green_out = wall2_g;
            blue_out = wall2_b;
        end else if (wall1_r || wall1_g|| wall1_b) begin
            red_out = wall1_r;
            green_out = wall1_g;
            blue_out = wall1_b;
        end else if (ball_r || ball_g|| ball_b) begin
            red_out = ball_r;
            green_out = ball_g;
            blue_out = ball_b;
        end
    end

endmodule