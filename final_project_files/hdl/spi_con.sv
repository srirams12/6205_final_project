module spi_con
     #(parameter DATA_WIDTH = 8,
       parameter DATA_CLK_PERIOD = 100
      )
      (input wire   clk_in, //system clock (100 MHz)
       input wire   rst_in, //reset in signal
       input wire   [DATA_WIDTH-1:0] data_in, //data to send
       input wire   trigger_in, //start a transaction
       output logic [DATA_WIDTH-1:0] data_out, //data received!
       output logic data_valid_out, //high when output data is present.
 
       output logic chip_data_out, //(COPI)
       input wire   chip_data_in, //(CIPO)
       output logic chip_clk_out, //(DCLK)
       output logic chip_sel_out // (CS)
      );
    //your code here
    logic [DATA_WIDTH-1: 0] data_to_send;
    logic [DATA_WIDTH-1: 0] data_received;
    logic [7:0] dclk_counter;
    logic [4:0] data_counter;

    always_ff @(posedge clk_in) begin
        // CS should be set to 0 by the Controller. This is an "active low" signal and tells the Peripheral that a transaction is starting.
        // At about the same time, the Controller should set the first bit (if there is one) it wants to transmit on the COPI line.
        if (data_valid_out) begin
            data_valid_out <= 0;
        end
        if (rst_in) begin
            chip_data_out <= 0;
            chip_clk_out <= 0;
            chip_sel_out <= 1;
            data_valid_out <= 0;
            data_out <= 0;
        end else begin
            if (trigger_in) begin
                data_to_send <= data_in << 1;
                data_received <= 0;
                chip_sel_out <= 0;
                dclk_counter <= 8'd0;
                data_counter <= DATA_WIDTH;
                chip_data_out <= data_in[DATA_WIDTH - 1];

            end else begin
                if (dclk_counter == DATA_CLK_PERIOD / 2 - 1 && chip_sel_out == 0) begin
                    // an edge is detected
                    dclk_counter <= 0;
                    if (chip_clk_out) begin
                        // high to low
                        if (data_counter > 0) begin
                            chip_data_out <= data_to_send[DATA_WIDTH - 1];
                            data_to_send <= data_to_send << 1;
                        end
                        // chip_data_out <= {chip_data_out, data_to_send[DATA_WIDTH-1:1]};

                    end else begin
                        // low to high
                        // if (data_counter > 0) begin
                        //     data_received[data_counter - 1] <= chip_data_in;
                        // end
                        data_received <= {data_received[DATA_WIDTH-2:0], chip_data_in};
                        data_counter <= data_counter - 1;

                        if (data_counter == 0) begin
                            chip_sel_out <= 1;
                            // data_out <= 8'h1f;
                            data_out <= data_received;
                            data_valid_out <= 1;
                            dclk_counter <= 0;
                        end
                    end
                    if (chip_sel_out != 1 && data_counter > 0) begin
                        chip_clk_out <= ~chip_clk_out;
                    end else begin
                        chip_clk_out <= 0;
                    end
                end else begin
                    dclk_counter <= dclk_counter +1;
                end
            end

        end
    end
    
    
    
endmodule


// // ['0x6999', '0x92af', '0xa0a3'], correct messages should have been ['0xe999', '0x92af', '0xa0a3']
// // 0110
// // 1110
// // // ['0x7aa6', '0x2495', '0xa573'], correct messages should have been ['0xfaa6', '0x2495', '0xa573']
// // 0111
// // 1111

// module spi_con
//      #(parameter DATA_WIDTH = 8,
//        parameter DATA_CLK_PERIOD = 100
//       )
//       (input wire   clk_in, //system clock (100 MHz)
//        input wire   rst_in, //reset in signal
//        input wire   [DATA_WIDTH-1:0] data_in, //data to send
//        input wire   trigger_in, //start a transaction
//        output logic [DATA_WIDTH-1:0] data_out, //data received!
//        output logic data_valid_out, //high when output data is present.
 
//        output logic chip_data_out, //(COPI)
//        input wire   chip_data_in, //(CIPO)
//        output logic chip_clk_out, //(DCLK)
//        output logic chip_sel_out // (CS)
//       );
//     //your code here
//     logic [DATA_WIDTH-1: 0] data_to_send;
//     logic [DATA_WIDTH-1: 0] data_received;
//     logic [7:0] dclk_counter;
//     logic [4:0] data_counter;

//     always_ff @(posedge clk_in) begin
//         // CS should be set to 0 by the Controller. This is an "active low" signal and tells the Peripheral that a transaction is starting.
//         // At about the same time, the Controller should set the first bit (if there is one) it wants to transmit on the COPI line.
//         if (data_valid_out) begin
//             data_valid_out <= 0;
//         end
//         if (rst_in) begin
//             chip_data_out <= 0;
//             chip_clk_out <= 0;
//             chip_sel_out <= 1;
//             data_valid_out <= 0;
//             data_out <= 0;
//         end else begin
//             if (trigger_in) begin
//                 data_to_send <= data_in;
//                 data_received <= 0;
//                 chip_sel_out <= 0;
//                 dclk_counter <= 8'd0;
//                 data_counter <= DATA_WIDTH;
//                 chip_data_out <= data_in[DATA_WIDTH - 1];

//             end else begin
//                 if (dclk_counter == DATA_CLK_PERIOD / 2 - 1) begin
//                     // an edge is detected
//                     dclk_counter <= 0;
//                     if (chip_clk_out) begin
//                         // high to low
//                         if (data_counter > 0) begin
//                             chip_data_out <= data_to_send[data_counter - 1];
//                         end
//                     end else begin
//                         // low to high
//                         data_received[data_counter - 1] <= chip_data_in;
//                         data_counter <= data_counter - 1;

//                         if (data_counter == 0) begin
//                             chip_sel_out <= 1;
//                             data_out <= data_received;
//                             data_valid_out <= 1;
//                             dclk_counter <= 0;
//                         end
//                     end
//                     if (chip_sel_out != 1 && data_counter > 0) begin
//                         chip_clk_out <= ~chip_clk_out;
//                     end else begin
//                         chip_clk_out <= 0;
//                     end
//                 end else begin
//                     dclk_counter <= dclk_counter +1;
//                 end
//             end

//         end
//     end
    
// endmodule
