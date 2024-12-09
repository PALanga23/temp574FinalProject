module myreg #(
  parameter int unsigned AddrWidth = 32,
  parameter int unsigned RegAddr   = 8
) (
  input logic 		      clk_i,
  input logic 		      rst_ni,

  input logic 		      device_req_i,
  input logic [AddrWidth-1:0] device_addr_i,
  input logic 		      device_we_i,
  input logic [3:0] 	      device_be_i,
  input logic [31:0] 	      device_wdata_i,
  output logic 		      device_rvalid_o,
  output logic [31:0] 	      device_rdata_o
);
  
  localparam int 	       unsigned POLY1305_R0 = 32h'80006000;
  localparam int 	       unsigned POLY1305_R1 = 32h'80006004;
  localparam int 	       unsigned POLY1305_R2 = 32h'80006008;
  localparam int 	       unsigned POLY1305_R3 = 32h'8000600C;
  
  localparam int 	       unsigned POLY1305_S0 = 32h'80006010;
  localparam int 	       unsigned POLY1305_S1 = 32h'80006014;
  localparam int 	       unsigned POLY1305_S2 = 32h'80006018;
  localparam int 	       unsigned POLY1305_S3 = 32h'8000601C;
  
  localparam int 	       unsigned POLY1305_M0 = 32h'80006020;
  localparam int 	       unsigned POLY1305_M1 = 32h'80006024;
  localparam int 	       unsigned POLY1305_M2 = 32h'80006028;
  localparam int 	       unsigned POLY1305_M3 = 32h'8000602C;
  
  localparam int 	       unsigned POLY1305_P0 = 32h'80006030;
  localparam int 	       unsigned POLY1305_P1 = 32h'80006034;
  localparam int 	       unsigned POLY1305_P2 = 32h'80006038;
  localparam int 	       unsigned POLY1305_P3 = 32h'8000603C;
  
  localparam int 	       unsigned POLY1305_CTL = 32h'80006040;
  localparam int 	       unsigned POLY1305_STAT = 32h'80006044;
  
  logic [RegAddr-1:0] 	       reg_addr;
  
  //signals when poly1305 block is done
  logic rdy;
  
  //stores p values from poly1305 
  logic [127:0] full_p;
  
  logic 		      r0_wr, r0_rd, r1_wr, r1_rd, r2_wr, r2_rd, r3_wr, r3_rd;
  logic           s0_wr, s0_rd, s1_wr, s1_rd, s2_wr, s2_rd, s3_wr, s3_rd;
  logic           m0_wr, m0_rd, m1_wr, m1_rd, m2_wr, m2_rd, m3_wr, m3_rd;
  logic           p0_wr, p0_rd, p1_wr, p1_rd, p2_wr, p2_rd, p3_wr, p3_rd;
  logic           ctl_wr, ctl_rd;
  logic           stat_wr, stat_rd;  
  
  logic [31:0] 	       r0_data, r1_data, r2_data, r3_data;
  logic [31:0] 	       s0_data, s1_data, s2_data, s3_data;
  logic [31:0] 	       m0_data, m1_data, m2_data, m3_data;
  logic [31:0] 	       p0_data, p1_data, p2_data, p3_data;
  logic [31:0] 	       ctl_data, stat_data;
  
  logic [31:0] 	       r0_delay_data, r1_delay_data, r2_delay_data, r3_delay_data;
  logic [31:0] 	       s0_delay_data, s1_delay_data, s2_delay_data, s3_delay_data;
  logic [31:0] 	       m0_delay_data, m1_delay_data, m2_delay_data, m3_delay_data;
  logic [31:0] 	       p0_delay_data, p1_delay_data, p2_delay_data, p3_delay_data;
  logic [31:0] 	       ctl_delay_data, stat_delay_data;

  
  // Decode write and read requests.
  assign reg_addr          = device_addr_i[RegAddr-1:0];
  
  //R
  assign r0_wr           = device_req_i &  device_we_i & (reg_addr == POLY1305_R0[RegAddr-1:0]);
  assign r0_rd           = device_req_i & ~device_we_i & (reg_addr == POLY1305_R0[RegAddr-1:0]);
  assign r1_wr           = device_req_i &  device_we_i & (reg_addr == POLY1305_R1[RegAddr-1:0]);
  assign r1_rd           = device_req_i & ~device_we_i & (reg_addr == POLY1305_R1[RegAddr-1:0]);
  assign r2_wr           = device_req_i &  device_we_i & (reg_addr == POLY1305_R2[RegAddr-1:0]);
  assign r2_rd           = device_req_i & ~device_we_i & (reg_addr == POLY1305_R2[RegAddr-1:0]);
  assign r3_wr           = device_req_i &  device_we_i & (reg_addr == POLY1305_R3[RegAddr-1:0]);
  assign r3_rd           = device_req_i & ~device_we_i & (reg_addr == POLY1305_R3[RegAddr-1:0]);
  
  //S
  assign s0_wr           = device_req_i &  device_we_i & (reg_addr == POLY1305_S0[RegAddr-1:0]);
  assign s0_rd           = device_req_i & ~device_we_i & (reg_addr == POLY1305_S0[RegAddr-1:0]);
  assign s1_wr           = device_req_i &  device_we_i & (reg_addr == POLY1305_S1[RegAddr-1:0]);
  assign s1_rd           = device_req_i & ~device_we_i & (reg_addr == POLY1305_S1[RegAddr-1:0]);
  assign s2_wr           = device_req_i &  device_we_i & (reg_addr == POLY1305_S2[RegAddr-1:0]);
  assign s2_rd           = device_req_i & ~device_we_i & (reg_addr == POLY1305_S2[RegAddr-1:0]);
  assign s3_wr           = device_req_i &  device_we_i & (reg_addr == POLY1305_S3[RegAddr-1:0]);
  assign s3_rd           = device_req_i & ~device_we_i & (reg_addr == POLY1305_S3[RegAddr-1:0]);
  
  //M
  assign m0_wr           = device_req_i &  device_we_i & (reg_addr == POLY1305_M0[RegAddr-1:0]);
  assign m0_rd           = device_req_i & ~device_we_i & (reg_addr == POLY1305_M0[RegAddr-1:0]);
  assign m1_wr           = device_req_i &  device_we_i & (reg_addr == POLY1305_M1[RegAddr-1:0]);
  assign m1_rd           = device_req_i & ~device_we_i & (reg_addr == POLY1305_M1[RegAddr-1:0]);
  assign m2_wr           = device_req_i &  device_we_i & (reg_addr == POLY1305_M2[RegAddr-1:0]);
  assign m2_rd           = device_req_i & ~device_we_i & (reg_addr == POLY1305_M2[RegAddr-1:0]);
  assign m3_wr           = device_req_i &  device_we_i & (reg_addr == POLY1305_M3[RegAddr-1:0]);
  assign m3_rd           = device_req_i & ~device_we_i & (reg_addr == POLY1305_M3[RegAddr-1:0]);
  
  //P
  assign p0_wr           = device_req_i &  device_we_i & (reg_addr == POLY1305_P0[RegAddr-1:0]);
  assign p0_rd           = device_req_i & ~device_we_i & (reg_addr == POLY1305_P0[RegAddr-1:0]);
  assign p1_wr           = device_req_i &  device_we_i & (reg_addr == POLY1305_P1[RegAddr-1:0]);
  assign p1_rd           = device_req_i & ~device_we_i & (reg_addr == POLY1305_P1[RegAddr-1:0]);
  assign p2_wr           = device_req_i &  device_we_i & (reg_addr == POLY1305_P2[RegAddr-1:0]);
  assign p2_rd           = device_req_i & ~device_we_i & (reg_addr == POLY1305_P2[RegAddr-1:0]);
  assign p3_wr           = device_req_i &  device_we_i & (reg_addr == POLY1305_P3[RegAddr-1:0]);
  assign p3_rd           = device_req_i & ~device_we_i & (reg_addr == POLY1305_P3[RegAddr-1:0]);

  assign ctl_wr           = device_req_i &  device_we_i & (reg_addr == POLY1305_CTL[RegAddr-1:0]);
  assign ctl_rd           = device_req_i & ~device_we_i & (reg_addr == POLY1305_CTL[RegAddr-1:0]);
  assign stat_wr          = device_req_i &  device_we_i & (reg_addr == POLY1305_STAT[RegAddr-1:0]);
  assign stat_rd          = device_req_i & ~device_we_i & (reg_addr == POLY1305_STAT[RegAddr-1:0]);


  poly1305 DUT(.rst_ni(rst_ni), .clk(clk),
               .r({r3_, r2_data, r1_data, r0_data}),
               .s({s3_data, s2_data, s1_data, s0_data}),
               .m({m3_data, m2_data, m1_data, m0_data}),
               //ADD FB, LD, and FIRST -> could be values froms stat
               //software is slow compared to hardware so signal might be assereted for multiple cycles, will need to handle that 
               //create separate signal that tracks when a signal is asserted (on signal edge)
               .fb(ctl_data[0]), .ld(1), .first(ctl_data[2]),
               //might need to store p in a buffer then break it up later
               //need to break full_p into parts later
               .p(full_p),
               .rdy(rdy));
  
  always @(posedge clk_i or negedge rst_ni) begin
  if (!rst_ni) begin
    //R
    r0_data <= 32'b0;
    r1_data <= 32'b0;
    r2_data <= 32'b0;
    r3_data <= 32'b0;

    //S
    s0_data <= 32'b0;
    s1_data <= 32'b0;
    s2_data <= 32'b0;
    s3_data <= 32'b0;


    //M
    m0_data <= 32'b0;
    m1_data <= 32'b0;
    m2_data <= 32'b0;
    m3_data <= 32'b0;


    //P
    p0_data <= 32'b0;
    p1_data <= 32'b0;
    p2_data <= 32'b0;
    p3_data <= 32'b0;

    //ctl and stat
    ctl_data <= 32'b0;
    stat_data <= 32'b0;
    
    r0_delay_data <= 32'b0;
    r1_delay_data <= 32'b0;
    r2_delay_data <= 32'b0;
    r3_delay_data <= 32'b0;
    
    s0_delay_data <= 32'b0;
    s1_delay_data <= 32'b0;
    s2_delay_data <= 32'b0;
    s3_delay_data <= 32'b0;
    
    m0_delay_data <= 32'b0;
    m1_delay_data <= 32'b0;
    m2_delay_data <= 32'b0;
    m3_delay_data <= 32'b0;
    
    p0_delay_data <= 32'b0;
    p1_delay_data <= 32'b0;
    p2_delay_data <= 32'b0;
    p3_delay_data <= 32'b0;
    
    ctl_delay_data <= 32'b0;
    stat_delay_data <= 32'b0;

    
  end else begin
  
  //INPUTS
  
  //R
  if (r0_wr) begin
    r0_data[7:0]   <= {device_be_i[0] ? device_wdata_i[7:0] : r0_data[7:0]};
    r0_data[15:8]  <= {device_be_i[1] ? device_wdata_i[15:8] : r0_data[15:8]};
    r0_data[23:16] <= {device_be_i[2] ? device_wdata_i[23:16] : r0_data[23:16]};
    r0_data[31:24] <= {device_be_i[3] ? device_wdata_i[31:24] : r0_data[31:24]};	    
  end

  if (r1_wr) begin
    r1_data[7:0]   <= {device_be_i[0] ? device_wdata_i[7:0] : r1_data[7:0]};
    r1_data[15:8]  <= {device_be_i[1] ? device_wdata_i[15:8] : r1_data[15:8]};
    r1_data[23:16] <= {device_be_i[2] ? device_wdata_i[23:16] : r1_data[23:16]};
    r1_data[31:24] <= {device_be_i[3] ? device_wdata_i[31:24] : r1_data[31:24]};	    
  end

  if (r2_wr) begin
    r2_data[7:0]   <= {device_be_i[0] ? device_wdata_i[7:0] : r2_data[7:0]};
    r2_data[15:8]  <= {device_be_i[1] ? device_wdata_i[15:8] : r2_data[15:8]};
    r2_data[23:16] <= {device_be_i[2] ? device_wdata_i[23:16] : r2_data[23:16]};
    r2_data[31:24] <= {device_be_i[3] ? device_wdata_i[31:24] : r2_data[31:24]};	    
  end

  if (r3_wr) begin
    r3_data[7:0]   <= {device_be_i[0] ? device_wdata_i[7:0] : r3_data[7:0]};
    r3_data[15:8]  <= {device_be_i[1] ? device_wdata_i[15:8] : r3_data[15:8]};
    r3_data[23:16] <= {device_be_i[2] ? device_wdata_i[23:16] : r3_data[23:16]};
    r3_data[31:24] <= {device_be_i[3] ? device_wdata_i[31:24] : r3_data[31:24]};	    
  end


  //S
  if (s0_wr) begin
    s0_data[7:0]   <= {device_be_i[0] ? device_wdata_i[7:0] : s0_data[7:0]};
    s0_data[15:8]  <= {device_be_i[1] ? device_wdata_i[15:8] : s0_data[15:8]};
    s0_data[23:16] <= {device_be_i[2] ? device_wdata_i[23:16] : s0_data[23:16]};
    s0_data[31:24] <= {device_be_i[3] ? device_wdata_i[31:24] : s0_data[31:24]};	    
  end

  if (s1_wr) begin
    s1_data[7:0]   <= {device_be_i[0] ? device_wdata_i[7:0] : s1_data[7:0]};
    s1_data[15:8]  <= {device_be_i[1] ? device_wdata_i[15:8] : s1_data[15:8]};
    s1_data[23:16] <= {device_be_i[2] ? device_wdata_i[23:16] : s1_data[23:16]};
    s1_data[31:24] <= {device_be_i[3] ? device_wdata_i[31:24] : s1_data[31:24]};	    
  end

  if (s2_wr) begin
    s2_data[7:0]   <= {device_be_i[0] ? device_wdata_i[7:0] : s2_data[7:0]};
    s2_data[15:8]  <= {device_be_i[1] ? device_wdata_i[15:8] : s2_data[15:8]};
    s2_data[23:16] <= {device_be_i[2] ? device_wdata_i[23:16] : s2_data[23:16]};
    s2_data[31:24] <= {device_be_i[3] ? device_wdata_i[31:24] : s2_data[31:24]};	    
  end
  
  if (s3_wr) begin
    s3_data[7:0]   <= {device_be_i[0] ? device_wdata_i[7:0] : s3_data[7:0]};
    s3_data[15:8]  <= {device_be_i[1] ? device_wdata_i[15:8] : s3_data[15:8]};
    s3_data[23:16] <= {device_be_i[2] ? device_wdata_i[23:16] : s3_data[23:16]};
    s3_data[31:24] <= {device_be_i[3] ? device_wdata_i[31:24] : s3_data[31:24]};	    
  end


  //M
  if (m0_wr) begin
    m0_data[7:0]   <= {device_be_i[0] ? device_wdata_i[7:0] : m0_data[7:0]};
    m0_data[15:8]  <= {device_be_i[1] ? device_wdata_i[15:8] : m0_data[15:8]};
    m0_data[23:16] <= {device_be_i[2] ? device_wdata_i[23:16] : m0_data[23:16]};
    m0_data[31:24] <= {device_be_i[3] ? device_wdata_i[31:24] : m0_data[31:24]};	    
  end
  
  if (m1_wr) begin
    m1_data[7:0]   <= {device_be_i[0] ? device_wdata_i[7:0] : m1_data[7:0]};
    m1_data[15:8]  <= {device_be_i[1] ? device_wdata_i[15:8] : m1_data[15:8]};
    m1_data[23:16] <= {device_be_i[2] ? device_wdata_i[23:16] : m1_data[23:16]};
    m1_data[31:24] <= {device_be_i[3] ? device_wdata_i[31:24] : m1_data[31:24]};	    
  end
  
  if (m2_wr) begin
    m2_data[7:0]   <= {device_be_i[0] ? device_wdata_i[7:0] : m2_data[7:0]};
    m2_data[15:8]  <= {device_be_i[1] ? device_wdata_i[15:8] : m2_data[15:8]};
    m2_data[23:16] <= {device_be_i[2] ? device_wdata_i[23:16] : m2_data[23:16]};
    m2_data[31:24] <= {device_be_i[3] ? device_wdata_i[31:24] : m2_data[31:24]};	    
  end
  
  if (m3_wr) begin
    m3_data[7:0]   <= {device_be_i[0] ? device_wdata_i[7:0] : m3_data[7:0]};
    m3_data[15:8]  <= {device_be_i[1] ? device_wdata_i[15:8] : m3_data[15:8]};
    m3_data[23:16] <= {device_be_i[2] ? device_wdata_i[23:16] : m3_data[23:16]};
    m3_data[31:24] <= {device_be_i[3] ? device_wdata_i[31:24] : m3_data[31:24]};	    
  end
  
  
  //CTL and STAT
  if (ctl_wr) begin
    ctl_data[7:0]   <= {device_be_i[0] ? device_wdata_i[7:0] : ctl_data[7:0]};
    ctl_data[15:8]  <= {device_be_i[1] ? device_wdata_i[15:8] : ctl_data[15:8]};
    ctl_data[23:16] <= {device_be_i[2] ? device_wdata_i[23:16] : ctl_data[23:16]};
    ctl_data[31:24] <= {device_be_i[3] ? device_wdata_i[31:24] : ctl_data[31:24]};
    
  end
  
  
  //OUPUTS
  
  //IS THIS THE CORRECT WAY OF HANDLING THE CO-PROCESSRO DATA?
  //DOES THIS NEED TO BE BROKEN INTO 8 BIT PARTS
  if(rdy) begin
    p3_data <= p_full[127:96];
    p2_data <= p_full[95:63];
    p1_data <= p_full[63:32];
    p0_data <= p_full[31:0];
  end
  
  //P - I THINK THIS IS LOAD IN SOFTWARE VALUES
  if (p0_wr) begin
    p0_data[7:0]   <= {device_be_i[0] ? device_wdata_i[7:0] : p0_data[7:0]};
    p0_data[15:8]  <= {device_be_i[1] ? device_wdata_i[15:8] : p0_data[15:8]};
    p0_data[23:16] <= {device_be_i[2] ? device_wdata_i[23:16] : p0_data[23:16]};
    p0_data[31:24] <= {device_be_i[3] ? device_wdata_i[31:24] : p0_data[31:24]};	    
  end
  
  if (p1_wr) begin
    p1_data[7:0]   <= {device_be_i[0] ? device_wdata_i[7:0] : p1_data[7:0]};
    p1_data[15:8]  <= {device_be_i[1] ? device_wdata_i[15:8] : p1_data[15:8]};
    p1_data[23:16] <= {device_be_i[2] ? device_wdata_i[23:16] : p1_data[23:16]};
    p1_data[31:24] <= {device_be_i[3] ? device_wdata_i[31:24] : p1_data[31:24]};	    
  end
  
  if (p2_wr) begin
    p2_data[7:0]   <= {device_be_i[0] ? device_wdata_i[7:0] : p2_data[7:0]};
    p2_data[15:8]  <= {device_be_i[1] ? device_wdata_i[15:8] : p2_data[15:8]};
    p2_data[23:16] <= {device_be_i[2] ? device_wdata_i[23:16] : p2_data[23:16]};
    p2_data[31:24] <= {device_be_i[3] ? device_wdata_i[31:24] : p2_data[31:24]};	    
  end
  
  if (p3_wr) begin
    p3_data[7:0]   <= {device_be_i[0] ? device_wdata_i[7:0] : p3_data[7:0]};
    p3_data[15:8]  <= {device_be_i[1] ? device_wdata_i[15:8] : p3_data[15:8]};
    p3_data[23:16] <= {device_be_i[2] ? device_wdata_i[23:16] : p3_data[23:16]};
    p3_data[31:24] <= {device_be_i[3] ? device_wdata_i[31:24] : p3_data[31:24]};	    
  end
                 
  
  if (stat_wr) begin
    stat_data[7:0]   <= {device_be_i[0] ? device_wdata_i[7:0] : stat_data[7:0]};
    stat_data[15:8]  <= {device_be_i[1] ? device_wdata_i[15:8] : stat_data[15:8]};
    stat_data[23:16] <= {device_be_i[2] ? device_wdata_i[23:16] : stat_data[23:16]};
    stat_data[31:24] <= {device_be_i[3] ? device_wdata_i[31:24] : stat_data[31:24]};	    
  end

     device_rvalid_o <= device_req_i;
  end
  end
  
  // Assign device_rdata_o according to request type.
  always_comb begin
  
  //Delay output by one cycle so that bus protocol can function correctly
  r0_delay_data <= r0_data;
  r1_delay_data <= r1_data;
  r2_delay_data <= r2_data;
  r3_delay_data <= r3_data;
  
  s0_delay_data <= s0_data;
  s1_delay_data <= s1_data;
  s2_delay_data <= s2_data;
  s3_delay_data <= s3_data;
  
  m0_delay_data <= m0_data;
  m1_delay_data <= m1_data;
  m2_delay_data <= m2_data;
  m3_delay_data <= m3_data;
  
  p0_delay_data <= p0_data;
  p1_delay_data <= p1_data;
  p2_delay_data <= p2_data;
  p3_delay_data <= p3_data;
  
  ctl_delay_data <= ctl_data;
  stat_delay_data <= stat_data;

  
  if (r0_rd)
    device_rdata_o = r0_delay_data;
    
  else if (r1_rd)
      device_rdata_o = r1_delay_data;
      
  else if (r2_rd)
      device_rdata_o = r2_delay_data;
      
  else if (r3_rd)
      device_rdata_o = r3_delay_data;
      
  else if (s0_rd)
      device_rdata_o = s0_delay_data;
      
  else if (s1_rd)
      device_rdata_o = s1_delay_data;
      
  else if (s2_rd)
      device_rdata_o = s2_delay_data;
      
  else if (s3_rd)
      device_rdata_o = s3_delay_data;
      
  else if (m0_rd)
      device_rdata_o = m0_delay_data;
      
  else if (m1_rd)
      device_rdata_o = m1_delay_data;
      
  else if (m2_rd)
      device_rdata_o = m2_delay_data;
      
  else if (m3_rd)
      device_rdata_o = m3_delay_data;
      
  else if (p0_rd)
      device_rdata_o = p0_delay_data;
      
  else if (p1_rd)
      device_rdata_o = p1_delay_data;
      
  else if (p2_rd)
      device_rdata_o = p2_delay_data;
      
  else if (p3_rd)
      device_rdata_o = p3_delay_data;
      
  else if (ctl_rd)
      device_rdata_o = ctl_delay_data;
      
  else if (stat_rd)
      device_rdata_o = stat_delay_data;
  
  else
      device_rdata_o = 32'b0;

    
  end
  
  // Unused signals.
  logic [AddrWidth-1-RegAddr:0]  unused_device_addr;
  assign unused_device_addr  = device_addr_i[AddrWidth-1:RegAddr];
  
  endmodule
