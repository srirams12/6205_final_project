module counter(     input wire clk_in,
                    input wire rst_in,
                    input wire [31:0] period_in,
                    output logic [31:0] count_out
              );

  logic [31:0] c;
  logic [31:0] count;
 
  always_comb begin
    if (rst_in== 1)begin
    c = 0;
    end else if(count+1 == period_in)begin
    c = 0;
    end else begin
      c = count +1;
    end
    end
 
    always_ff @(posedge clk_in)begin
      count <= c[31:0];
    end
 
    assign count_out = count;
endmodule
