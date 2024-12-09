module poly1305(
  input rst_ni,
  input clk,
  input [127:0] r,
  input [127:0] s,
  input [127:0] m,
  input fb,
  input ld,
  input first,
  output [127:0] p,
  output rdy);
  
  reg [129:0] acc;
  wire [129:0] acc_out;
  wire [129:0] acc_in;
  wire block_start;
  wire block_done;
  wire [128:0] msep;
  assign msep = fb ? {1'b1, m} : m;
  assign acc_in = first ? 130'b0 : acc;
  wire [127:0] rclamp;
  assign rclamp = r & 128'h0FFF_FFFC_0FFF_FFFC_0FFF_FFFC_0FFF_FFFF;
  
  processblock single(.rst_ni(rst_ni),
  .clk (clk),
  .r (rclamp),
  .m (msep),
  .a_in (acc_in),
  .a_out(acc_out),
  .start(block_start),
  .done (block_done)
  );
  
  always @(posedge clk)
    if (!rst_ni)
      acc <= 130'h0;
    else
      acc <= block_done ? acc_out : acc;
  
  assign block_start = ld;
  assign p = acc_out + s;
  assign rdy = block_done;
  
endmodule
