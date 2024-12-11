module processblock(
    input reset_n,
    input clk,

    input [127:0] r,
    input [128:0] m, // {1 padding + 128 message bits}
    input [129:0] a_in, // {acc < P = 2^130 - 5}

    output [129:0] a_out,

    input start,
    output done
);

    logic [130:0] m1;
    logic [258:0] m2;
    logic [131:0] m3; // first reduction leaves 2 extra bits

    wire [2:0] five;
    logic rdy;
    logic DUT_start;

    assign five = 5;
    
    localparam IDLE = 3'd0;
    localparam M1_CALC = 3'd1;
    localparam PAD = 3'd2; 
    localparam M2_CALC = 3'd3;
    localparam ACC_RUNNING = 3'd4;
    localparam M3_CALC = 3'd5;
    localparam A_OUT_CALC = 3'd6;
    localparam DONE = 3'd7;
    
    logic [2:0] current_state, next_state;
    
    always_ff@(posedge clk or negedge reset_n) begin
      if(!reset_n) begin
        current_state <= IDLE;
      end
      else begin
        current_state <= next_state;
      end
    end
    
    
    
    always_comb begin
      next_state = current_state;
      
      case(current_state)
        IDLE: begin
          if(start) begin
            next_state = M1_CALC;
          end
          else begin
            next_state = IDLE;
          end
        end
        
        M1_CALC: begin
          next_state = PAD;
        end
        
        PAD: begin
          next_state = M2_CALC;
        end
        
        M2_CALC: begin
          next_state = ACC_RUNNING;
        end
        
        ACC_RUNNING: begin
          if(rdy) begin
            next_state = M3_CALC;
          end
          else begin
            next_state = ACC_RUNNING;
          end
        end
        
        M3_CALC: begin
          next_state = A_OUT_CALC;
        end  
        
        A_OUT_CALC: begin
          next_state = DONE;
        end
        
        DONE: begin
          next_state = IDLE;
        end
        
        default: begin
          next_state = IDLE;
        end
      
      endcase
    
    end
    
    //assign m2 = m1 * r; // 131 x 128 multiplier!!     
    accelerator DUT(
      .clk(clk),
      .rst_n(reset_n),
      .start(DUT_start),
      .A(m1),  // 131-bit input A
      .B(r),  // 128-bit input B
      .P(m2),  // 259-bit output P
       .ready(rdy));
    
    always_ff@(posedge clk or negedge reset_n) begin
      if(!reset_n) begin
        m1 <= 0;
        m2 <= 0;
        DUT_start <= 0;
        m3 <= 0;

      end
      else begin
        case(current_state)
          M1_CALC: begin
            m1 <= {2'b0, m} + {1'b0, a_in};
          end
          
          PAD: begin
            //do nothing
            //m1_padded <= {1'b0, m1};
            //r_padded <= {4'b0, r};
          end
          
          M2_CALC: begin
            DUT_start <= 1;
          end
          
          ACC_RUNNING: begin
            DUT_start <= 0;
          end
          
          M3_CALC: begin
            m3 <= {2'b0, m2[129:0]} + m2[258:130] * five; // first reduction
          end
          
          A_OUT_CALC: begin
            //do nothing
          end
          
          default: begin
            m1 <= 0;
            m2 <= 0;
            DUT_start <= 0;
            m3 <= 0;
          end
          
        endcase
      end
    end
    
    assign a_out = m3[129:0] + m3[131:130] * five; // second reduction  
      
    assign done = (current_state == DONE) ? 1 : 0;

endmodule
