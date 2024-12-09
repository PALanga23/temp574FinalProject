module processblock(input rst_ni,
  input clk,
  input [127:0] r,
  input [128:0] m, // {1 padding + 128 message bits}
  input [129:0] a_in, // {acc < P = 2^130 - 5}
  output [129:0] a_out,
  input start,
  output done
  );
  
  logic [130:0] m1;
  logic [258:0] m2; // 128 bits * 131 bits = 259 bits
  logic [131:0] m3; // first reduction leaves 2 extra bits
  logic [129:0] m4;
  logic [2:0] five;
  
  logic dutStart;
  logic dutDone;
  
  assign five = 5;
  
  localparam IDLE = 3'd0;
  localparam START = 3'd1;
  localparam M1_CALC = 3'd2;
  localparam M2_CALC = 3'd3;
  localparam M3_CALC = 3'd4;
  localparam AOUT_CALC = 3'd5;
  localparam DONE = 3'd6;
  
  logic [2:0] state = IDLE;
  logic [2:0] next_state = IDLE;
  
  // State machine to control which step is being completed
  always_ff @(posedge clk or negedge rst_ni) begin
    if (!rst_ni) begin
      state <= IDLE;
    end
    else begin    
      state <= next_state;
    end
  end
  
  always_comb begin   
    //stay in current state unless indicated otherwise
    next_state = state;
  
    //control logic
    case (state)
      IDLE: begin
        if (start) begin
          next_state = START;
        end
      end
  
      START: begin
        next_state = M1_CALC;
      end
  
      M1_CALC: begin
        next_state = M2_CALC;
      end
      
      M2_CALC: begin
        if(dutDone)
          next_state = M3_CALC;
        end
        else begin
          next_state = M2_CALC;
        end
      end
      
      M3_CALC: begin
        next_state = AOUT_CALC;
      end
      
      AOUT_CALC: begin
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
  
  always_ff@(posedge clk or negedge rst_ni) begin
    if(!rst_ni) begin
      done <= 0;      
      dutStart <= 0;         
    end
    else begin
    
      case(state) begin
      
        M2_CALC: begin
          dutStart <= 1;
        end
        
        M3_CALC: begin
          dutStart <= 0;
        end
        
        DONE: begin
          done <= 1;
        end
        
        default: begin
          done <= 0;      
          dutStart <= 0;   
        end
      endcase
    end 
  end

  always_ff@(posedge clk or negedge rst_ni) begin
    if(!rst_ni) begin
      m1 <= 0;
      m2 <= 0;
      m3 <= 0;
      m4 <= 0;
      a_out <= 0;
    end
    else begin
      case(state) begin
        M1_CALC: begin
          m1 <= m + a_in;
        end
        
        M3_CALC: begin
          m3 <= m2[129:0] + m2[258:130] * five; // first reduction
        end
        
        AOUT_CALC: begin
          a_out <= m3[129:0] + m3[131:130] * five; // second reduction
        end
        
        DONE: begin
          done <= 1;
        end
      end
    end
  end
  
  accelerator #(.BufferLength(132), .InputALength(131), .InputBLength(127)) DUT(
    .clk_i(clk), 
    .rst_ni(rst_ni), 
    .inputA(m1), 
    .inputB(r),
    .start(dutStart),
    .done(dutDone),
    .outputM(m2)
  );
  
endmodule
