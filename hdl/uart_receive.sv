`timescale 1ns / 1ps
`default_nettype none

module uart_receive
  #(
    parameter INPUT_CLOCK_FREQ = 100_000_000,
    parameter BAUD_RATE = 9600
    )
    (
      input wire 	       clk_in,
      input wire 	       rst_in,
      input wire 	       rx_wire_in,
      output logic       new_data_out,
      output logic [7:0] data_byte_out
      );

    // TODO: module to read UART rx wire
    localparam UART_BIT_PERIOD = INPUT_CLOCK_FREQ / BAUD_RATE;
    typedef enum { IDLE, START, DATA, TRANSMIT, STOP } states;
    logic [3:0]   bit_counter;
    logic [31:0]  dclk_counter;
    states state;

    always_ff @(posedge clk_in) begin
      if (rst_in) begin
        bit_counter <= 0;
        dclk_counter <= 0;
        state <= IDLE;
        new_data_out <= 0;
        data_byte_out <= 0;

      end else begin
        case (state)
          IDLE: begin
            if (rx_wire_in == 0) begin
              state <= START;
              dclk_counter <= 0;
            end
          end

          START: begin
            if (dclk_counter == UART_BIT_PERIOD / 2 - 1) begin
              if (rx_wire_in == 0) begin
                // good start bit
                dclk_counter <= 0;
                state <= DATA;
              end else begin
                // bad start bit
                dclk_counter <= 0;
                state <= IDLE;
              end
            end else begin
              dclk_counter <= dclk_counter + 1;
              if (rx_wire_in == 1) begin
                dclk_counter <= 0;
                state <= IDLE;
              end
            end
          end

          DATA: begin
            if (bit_counter == 8) begin
              // total bits == 8
              bit_counter <= 0;
              dclk_counter <= 0;
              state <= STOP;
            end else begin
              // total bits < 8
              if (dclk_counter == UART_BIT_PERIOD - 1) begin
                data_byte_out[bit_counter] <= rx_wire_in;
                bit_counter <= bit_counter + 1;
                dclk_counter <= 0;
              end else begin
                dclk_counter <= dclk_counter + 1;
              end
            end
          end

          TRANSMIT: begin
            if (new_data_out == 1) begin
              new_data_out <= 0;
              state <= IDLE;
            end else begin
              new_data_out <= 1;
            end
          end

          STOP: begin
            if (dclk_counter == UART_BIT_PERIOD * 5 / 4 - 1) begin
              if (rx_wire_in == 1) begin
                // good stop bit
                dclk_counter <= 0;
                state <= TRANSMIT;
              end else begin
                // bad stop bit
                dclk_counter <= 0;
                data_byte_out <= 0;
                state <= IDLE;
              end
            end else begin
              if (dclk_counter > UART_BIT_PERIOD) begin
                if (rx_wire_in == 0) begin
                  // bad stop bit
                  dclk_counter <= 0;
                  data_byte_out <= 0;
                  state <= IDLE;
                end
              end
              dclk_counter <= dclk_counter + 1;
            end
          end
          endcase
        end
        
      end
    


endmodule // uart_receive

`default_nettype wire


