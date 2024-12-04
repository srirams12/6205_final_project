`default_nettype none // prevents system from inferring an undeclared logic (good practice)

module top_level
(
    input wire          clk_100mhz, //100 MHz onboard clock
    input wire [15:0]   sw, //all 16 input slide switches
    input wire [3:0]    btn, //all four momentary button switches
    output logic [15:0] led, //16 green output LEDs (located right above switches)
    output logic [2:0]  rgb0, //RGB channels of RGB LED0
    output logic [2:0]  rgb1, //RGB channels of RGB LED1
    output logic        spkl, spkr, // left and right channels of line out port
    input wire          cipo, // SPI controller-in peripheral-out
    output logic        copi, dclk, cs, // SPI controller output signals
    input wire 		    uart_rxd, // UART computer-FPGA
    output logic 		uart_txd, // UART FPGA-computer
    output logic [2:0] hdmi_tx_p, //hdmi output signals (positives) (blue, green, red)
    output logic [2:0] hdmi_tx_n, //hdmi output signals (negatives) (blue, green, red)
    output logic hdmi_clk_p, hdmi_clk_n, //differential hdmi clock
    output logic [3:0] ss0_an,//anode control for upper four digits of seven-seg display
    output logic [3:0] ss1_an,//anode control for lower four digits of seven-seg display
    output logic [6:0] ss0_c, //cathode controls for the segments of upper four digits
    output logic [6:0] ss1_c //cathode controls for the segments of lower four digits
);

    //shut up those rgb LEDs for now (active high):
    assign rgb1 = 0; //set to 0.
    assign rgb0 = 0; //set to 0.

    //have btnd control system reset
    logic           sys_rst;
    assign sys_rst = btn[0];

    // clock bs
    logic          clk_camera; // not used
    logic          clk_pixel; // the pixel drawing clock
    logic          clk_5x; // used for outputting hdmi
    logic          clk_xc; // not used
    logic          clk_100_passthrough; // the 100mhz clock for everything else

    // clocking wizards to generate the clock speeds we need for our different domains
    // clk_camera: 200MHz, fast enough to comfortably sample the cameera's PCLK (50MHz)
    cw_hdmi_clk_wiz wizard_hdmi (
        .sysclk(clk_100_passthrough),
        .clk_pixel(clk_pixel),
        .clk_tmds(clk_5x),
        .reset(0)
    );

    cw_fast_clk_wiz wizard_migcam (
        .clk_in1(clk_100mhz),
        .clk_camera(clk_camera),
        .clk_xc(clk_xc),
        .clk_100(clk_100_passthrough),
        .reset(0)
    );

    // 8kHz trigger for the microphone
    localparam CYCLES_PER_TRIGGER_MIC = 12500;
    logic [31:0]        trigger_count_mic;
    logic               spi_trigger;
    counter counter_8khz_trigger (
        .clk_in(clk_100_passthrough),
        .rst_in(sys_rst),
        .period_in(CYCLES_PER_TRIGGER_MIC),
        .count_out(trigger_count_mic)
    );
    assign spi_trigger = trigger_count_mic == 0 ? 1 : 0;


    // 100hz trigger for the yin
    localparam CYCLES_PER_TRIGGER_YIN = 50000000;
    logic [31:0]        trigger_count_yin;
    logic               yin_trigger;
    counter counter_100hz_trigger (
        .clk_in(clk_100_passthrough),
        .rst_in(sys_rst),
        .period_in(CYCLES_PER_TRIGGER_YIN),
        .count_out(trigger_count_yin)
    );
    assign yin_trigger = trigger_count_yin == 0 ? 1 : 0;


    // SPI Controller on our ADC
    parameter ADC_DATA_WIDTH = 17; //MUST CHANGE
    parameter ADC_DATA_CLK_PERIOD = 50; //MUST CHANGE

    // SPI interface controls
    logic [ADC_DATA_WIDTH-1:0] spi_write_data;
    logic [ADC_DATA_WIDTH-1:0] spi_read_data;
    logic                      spi_read_data_valid;
    assign spi_write_data = 17'b11111_0000_0000_0000; // MUST CHANGE

    spi_con #(  
        .DATA_WIDTH(ADC_DATA_WIDTH),
        .DATA_CLK_PERIOD(ADC_DATA_CLK_PERIOD)
    ) my_spi_con (
        .clk_in(clk_100_passthrough),
        .rst_in(sys_rst),
        .data_in(spi_write_data),
        .trigger_in(spi_trigger),
        .data_out(spi_read_data),
        .data_valid_out(spi_read_data_valid), //high when output data is present.
        .chip_data_out(copi), //(serial dout preferably)
        .chip_data_in(cipo), //(serial din preferably)
        .chip_clk_out(dclk),
        .chip_sel_out(cs)
    );

    logic [7:0]                audio_sample;

    always_ff @(posedge clk_100_passthrough) begin
        if (spi_read_data_valid == 1) begin
            audio_sample <= spi_read_data[9:2];
        end
    end

    logic[31:0] f0;
    logic f0_valid;


    audio_processing audio_processor (
        .clk_in(clk_100_passthrough),
        .rst_in(sys_rst),
        .audio_in(spi_read_data[9:2]),
        .audio_in_valid(spi_read_data_valid),
        .start_computation(yin_trigger),
        .f_out(f0),
        .f_out_valid(f0_valid)
    );

    // SEVEN SEGMENT CONTROLLER
    logic [6:0] ss_c; 
    seven_segment_controller mssc(.clk_in(clk_pixel),
        .rst_in(sys_rst),
        .val_in(f0),
        .cat_out(ss_c),
        .an_out({ss0_an, ss1_an})
    );

    assign ss0_c = ss_c; //control upper four digit's cathodes!
    assign ss1_c = ss_c;


    // VIDEO STUFF GOES HERE
    logic [10:0] hcount; //hcount of system!
    logic [9:0] vcount; //vcount of system!
    logic hor_sync; //horizontal sync signal
    logic vert_sync; //vertical sync signal
    logic active_draw; //ative draw! 1 when in drawing region.0 in blanking/sync
    logic new_frame; //one cycle active indicator of new frame of info!
    logic [5:0] frame_count; //0 to 59 then rollover frame counter

    logic game_rst;
    assign game_rst = btn[1]; //reset is btn[1]

    video_sig_gen mvg(
        .pixel_clk_in(clk_pixel),
        .rst_in(sys_rst),
        .hcount_out(hcount),
        .vcount_out(vcount),
        .vs_out(vert_sync),
        .hs_out(hor_sync),
        .ad_out(active_draw),
        .nf_out(new_frame),
        .fc_out(frame_count)
    );
 
    logic [7:0] red, green, blue; //red green and blue pixel values for output
    logic [7:0] pg_r, pg_g, pg_b;//color values as generated by pong game(part 2)

    note_game my_game (
        .pixel_clk_in(clk_pixel),
        .rst_in(game_rst),
        .note_in(f0[15:0]),
        .true_note_in(sw[15:8]),
        .nf_in(new_frame),
        .hcount_in(hcount),
        .vcount_in(vcount),
        .red_out(pg_r),
        .green_out(pg_g),
        .blue_out(pg_b)
    );

    always_comb begin
        red = pg_r;
        green = pg_g;
        blue = pg_b;
    end

    logic [9:0] tmds_10b [0:2]; //output of each TMDS encoder!
    logic tmds_signal [2:0]; //output of each TMDS serializer!

    tmds_encoder tmds_red (
        .clk_in(clk_pixel),
        .rst_in(sys_rst),
        .data_in(red),
        .control_in(2'b0),
        .ve_in(active_draw),
        .tmds_out(tmds_10b[2])
    );

    tmds_encoder tmds_green (
        .clk_in(clk_pixel),
        .rst_in(sys_rst),
        .data_in(green),
        .control_in(2'b0),
        .ve_in(active_draw),
        .tmds_out(tmds_10b[1])
    );

    tmds_encoder tmds_blue (
        .clk_in(clk_pixel),
        .rst_in(sys_rst),
        .data_in(blue),
        .control_in({vert_sync, hor_sync}),
        .ve_in(active_draw),
        .tmds_out(tmds_10b[0])
    );

    tmds_serializer red_ser (
        .clk_pixel_in(clk_pixel),
        .clk_5x_in(clk_5x),
        .rst_in(sys_rst),
        .tmds_in(tmds_10b[2]),
        .tmds_out(tmds_signal[2])
    );

    tmds_serializer green_ser (
        .clk_pixel_in(clk_pixel),
        .clk_5x_in(clk_5x),
        .rst_in(sys_rst),
        .tmds_in(tmds_10b[1]),
        .tmds_out(tmds_signal[1])
    );

    tmds_serializer blue_ser (
        .clk_pixel_in(clk_pixel),
        .clk_5x_in(clk_5x),
        .rst_in(sys_rst),
        .tmds_in(tmds_10b[0]),
        .tmds_out(tmds_signal[0])
    );
 
    OBUFDS OBUFDS_blue (.I(tmds_signal[0]), .O(hdmi_tx_p[0]), .OB(hdmi_tx_n[0]));
    OBUFDS OBUFDS_green(.I(tmds_signal[1]), .O(hdmi_tx_p[1]), .OB(hdmi_tx_n[1]));
    OBUFDS OBUFDS_red  (.I(tmds_signal[2]), .O(hdmi_tx_p[2]), .OB(hdmi_tx_n[2]));
    OBUFDS OBUFDS_clock(.I(clk_pixel), .O(hdmi_clk_p), .OB(hdmi_clk_n));


endmodule

`default_nettype wire