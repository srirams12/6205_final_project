`default_nettype none
module seven_segment_controller #(parameter COUNT_PERIOD = 100000)
  (input wire           clk_in,
   input wire           rst_in,
   input wire [31:0]    val_in,
   output logic[6:0]    cat_out,
   output logic[7:0]    an_out
  );
 
  logic [7:0]   segment_state;
  logic [31:0]  segment_counter;
  logic [3:0]   sel_values;
  logic [6:0]   led_out;
 
  //TODO: wire up sel_values (-> x_in) with your input, val_in
  //Note that x_in is a 4 bit input, and val_in is 32 bits wide
  //Adjust accordingly, based on what you know re. which digits
  //are displayed when...
//   logic power = $clog2(segment_state);
  logic [3:0] power;
    always_comb begin
    case (segment_state)
        8'h01: power = 4'd0;
        8'h02: power = 4'd1;
        8'h04: power = 4'd2;
        8'h08: power = 4'd3;
        8'h10: power = 4'd4;
        8'h20: power = 4'd5;
        8'h40: power = 4'd6;
        8'h80: power = 4'd7;
    endcase
    end

logic [7:0] val_index;
assign val_index = (power) *4;

logic [31:0] temp;
assign temp = (val_in >> val_index);
assign sel_values = temp[3:0];

  bto7s mbto7s (.x_in(sel_values), .s_out(led_out));
  assign cat_out = ~led_out; //<--note this inversion is needed
  assign an_out = ~segment_state; //note this inversion is needed
 
  always_ff @(posedge clk_in)begin
    if (rst_in)begin
      segment_state <= 8'b0000_0001;
      segment_counter <= 32'b0;
    end else begin
      if (segment_counter == COUNT_PERIOD) begin
        segment_counter <= 32'd0;
        segment_state <= {segment_state[6:0],segment_state[7]};
      end else begin
        segment_counter <= segment_counter +1;
      end
    end
  end
endmodule // seven_segment_controller
 
/* TODO: drop your bto7s module from lab 1 here! */
module bto7s(input wire [3:0]   x_in,output logic [6:0] s_out);

logic [15:0] num;
assign num[0] = ~x_in[3] && ~x_in[2] && ~x_in[1] && ~x_in[0];
assign num[1] = ~x_in[3] && ~x_in[2] && ~x_in[1] && x_in[0];
assign num[2] = x_in == 4'd2;
assign num[3] = x_in == 4'd3;
assign num[4] = x_in == 4'd4;
assign num[5] = x_in == 4'd5;
assign num[6] = x_in == 4'd6;
assign num[7] = x_in == 4'd7;
assign num[8] = x_in == 4'd8;
assign num[9] = x_in == 4'd9;
assign num[10] = x_in == 4'd10;
assign num[11] = x_in == 4'd11;
assign num[12] = x_in == 4'd12;
assign num[13] = x_in == 4'd13;
assign num[14] = x_in == 4'd14;
    assign num[15] = x_in == 4'd15;

     
assign s_out[0] = num [0] || num[2]||num[3]||num[5]||num[6]||num[7]||num[8]||num[9]||num[10]||num[12]||num[14]||num[15];
assign s_out[1] = num [0] || num[1]||num[3]||num[2]||num[4]||num[7]||num[8]||num[9]||num[10]||num[13];
assign s_out[2] = num [0] || num[1]||num[3]||num[5]||num[6]||num[7]||num[8]||num[9]||num[10]||num[11]||num[13]||num[4];
assign s_out[3] = num [0] || num[2]||num[3]||num[5]||num[6]||num[8]||num[9]||num[13]||num[12]||num[14]||num[11];
assign s_out[4] = num [0] || num[2]||num[6]||num[8]||num[10]||num[12]||num[14]||num[15]||num[11]||num[13];
assign s_out[5] = num [0] ||num[4]||num[5]||num[6]||num[11]||num[8]||num[9]||num[10]||num[12]||num[14]||num[15];
assign s_out[6] = num [4] || num[2]||num[3]||num[5]||num[6]||num[11]||num[8]||num[9]||num[10]||num[13]||num[14]||num[15];


endmodule // bto7s
 
`default_nettype wire