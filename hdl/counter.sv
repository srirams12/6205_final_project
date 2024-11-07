module counter(     input wire clk_in,
                    input wire rst_in,
                    input wire [31:0] period_in,
                    output logic [31:0] count_out
              );
  logic [31:0] c;
  logic [31:0] count;
  always_comb begin
    c = count + 1;
    if (c > period_in -1 || rst_in) begin
      c = 0;
    end
  end

  always_ff @(posedge clk_in)begin
    count <= c;
  end

    //your code here
  assign count_out = count;
endmodule
