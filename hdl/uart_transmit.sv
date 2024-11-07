`timescale 1ns / 1ps
`default_nettype none

module uart_transmit 
  #(
    parameter INPUT_CLOCK_FREQ = 100_000_000,
    parameter BAUD_RATE = 9600
    )
   (
    input wire 	     clk_in,
    input wire 	     rst_in,
    input wire [7:0] data_byte_in,
    input wire 	     trigger_in,
    output logic     busy_out,
    output logic     tx_wire_out
    );

    localparam BAUD_BIT_PERIOD = INPUT_CLOCK_FREQ / BAUD_RATE;
    logic [31:0] dclk_counter;
    logic [4:0] data_counter;
    logic [9:0] data_to_send;

    always_ff @(posedge clk_in) begin
        if (rst_in) begin
            busy_out <= 0;
            tx_wire_out <= 0;
            dclk_counter <= 0;
            data_counter <= 0;
            data_to_send <= 0;
        end else begin
            if (trigger_in && !busy_out) begin
                dclk_counter <= 0;
                data_counter <= 0;
                data_to_send <= {1'b1, data_byte_in};
                busy_out <= 1;
                tx_wire_out <= 0;
            end else if (busy_out) begin
                if (dclk_counter == BAUD_BIT_PERIOD - 1) begin
                    dclk_counter <= 0;
                    if (data_counter == 9) begin
                        busy_out <= 0;
                    end else begin
                        tx_wire_out <= data_to_send[0];
                        data_to_send <= data_to_send >> 1;
                        data_counter <= data_counter + 1;
                    end
                    
                end else begin
                    dclk_counter <= dclk_counter + 1;
                end
            end
        end
    end
   
   // TODO: module to transmit on UART
   
endmodule // uart_transmit

`default_nettype wire