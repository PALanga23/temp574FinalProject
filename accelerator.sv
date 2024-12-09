module accelerator #(
  parameter int unsigned BufferLength = 132,
  parameter int unsigned InputALength = 131,
  parameter int unsigned InputBLength = 127
) (
  input logic 		      clk_i,
  input logic 		      rst_ni,
  
  input logic [InputALength - 1:0] inputA,
  input logic [InputBLength - 1:0] inputB,
  
  input logic start,
  
  output logic done,  
  output logic [BufferLength*2-1:0] outputM
);

  const int HalfLength = int'(BufferLength / 2);

  logic [BufferLength-1:0] bufferedA;
  logic [BufferLength-1:0] bufferedB;
  
  logic [HalfLength-1:0] topA;
  logic [HalfLength-1:0] topB;
  logic [HalfLength-1:0] bottomA;
  logic [HalfLength-1:0] bottomB;
  
  logic [BufferLength-1:0] z2;
  logic [BufferLength-1:0] z1;
  logic [BufferLength-1:0] z0;
  
  logic [BufferLength-1:0] tempA;
  
  logic [HalfLength:0] summedA;
  logic [HalfLength:0] summedB;
  logic [BufferLength-1:0] sumsMult;
  
  logic [BufferLength*2-1:0] z2Shifted;
  logic [BufferLength+HalfLength-1:0] z1Shifted;
  logic [BufferLength*2-1:0] tempM2;
  
  localparam IDLE = 4'd0;
  localparam START = 4'd1;
  localparam FIRST_BUFFER = 4'd2;
  localparam SPLIT = 4'd3;
  localparam FIRST_ADD = 4'd4;
  localparam MULT = 4'd5;
  localparam FIRST_SUB = 4'd6;
  localparam SECOND_SUB = 4'd7;
  localparam SECOND_BUFFER = 4'd8;
  localparam SECOND_ADD = 4'd9;
  localparam THIRD_ADD = 4'd10;
  localparam DONE = 4'd11;
  
  logic subAcc1Done = 1;
  logic subAcc2Done = 1;
  logic subAcc3Done = 1;
  
  logic subAcc1Start = 0;
  logic subAcc2Start = 0;
  logic subAcc3Start = 0;

  
  logic [3:0] state = IDLE;
  logic [3:0] next_state = IDLE;
  
  // State machine to control which step is being completed
  always_ff @(posedge clk_i or negedge rst_ni) begin
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
        next_state = FIRST_BUFFER;
      end
  
      FIRST_BUFFER: begin
        next_state = SPLIT;
      end
  
      SPLIT: begin
        next_state = FIRST_ADD;
      end
  
      FIRST_ADD: begin
        next_state = MULT;
      end
  
      MULT: begin
        if (subAcc1Done && subAcc2Done && subAcc3Done) begin
          next_state = FIRST_SUB;
        end
        else begin
          next_state = MULT;
        end
      end
  
      FIRST_SUB: begin
        next_state = SECOND_SUB;
      end
  
      SECOND_SUB: begin
        next_state = SECOND_BUFFER;
      end
  
      SECOND_BUFFER: begin
        next_state = SECOND_ADD;
      end
  
      SECOND_ADD: begin
        next_state = THIRD_ADD;
      end
  
      THIRD_ADD: begin
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
  
  
  //control done and start signals
  always_ff@(posedge clk or negedge rst_ni) begin
    if(!rst_ni) begin
      done <= 0;
      subAcc1Start <= 0;
      subAcc2Start <= 0;
      subAcc3Start <= 0;
    end
    else begin
      case (state)
        MULT: begin
          subAcc1Start <= 1;
          subAcc2Start <= 1;
          subAcc3Start <= 1;
        end
  
        FIRST_SUB: begin
          subAcc1Start <= 0;
          subAcc2Start <= 0;
          subAcc3Start <= 0;
        end
  
        DONE: begin
          done <= 1;
        end
  
        default: begin
          done <= 0;
          subAcc1Start <= 0;
          subAcc2Start <= 0;
          subAcc3Start <= 0;
        end
      endcase
    end
  end  


  always_ff @(posedge clk_i or negedge rst_ni) begin
    if (!rst_ni) begin
      bufferedA <= 0;
      bufferedB <= 0;
    end 
    else if(FIRST_BUFFER) begin
      bufferedA <= inputA;
      bufferedB <= inputB;
    end
  end
  
  always_ff @(posedge clk_i or negedge rst_ni) begin
    if (!rst_ni) begin
      topA <= 0;
      topB <= 0;
      
      bottomA <= 0;
      bottomB <= 0;
    end 
    else if(SPLIT) begin
      topA <= bufferedA[BufferLength-1: HalfLength];
      topB <= bufferedB[BufferLength-1: HalfLength];
      
      bottomA <= bufferedA[HalfLength-1: 0];
      bottomB <= bufferedB[HalfLength-1: 0];
    end
  end   
  
  always_ff @(posedge clk_i or negedge rst_ni) begin
    if (!rst_ni) begin
      summedA <= 0;
      summedB <= 0;
    end 
    else if(FIRST_ADD) begin
      summedA <= topA + bottomA;
      summedB <= topB + bottomB;
    end
  end
  
  always_ff @(posedge clk_i or negedge rst_ni) begin
    if (!rst_ni) begin
      sumsMult <= 0;
    end 
    else if(MULT) begin      
      if (HalfLength <= 32) begin
        sumsMult <= summedA * summedB;  
      end 
      else begin
        accelerator #(.BufferLength(HalfLength+1), .InputALength(HalfLength+1), .InputBLength(HalfLength+1)) subAcc1(
          .clk_i(clk_i), 
          .rst_ni(rst_ni), 
          .inputA(summedA), 
          .inputB(summedB),
          .start(subAcc1Start),
          .done(subAcc1Done),
          .outputM(sumsMult)
        );
      end

    end
  end
  
  always_ff @(posedge clk_i or negedge rst_ni) begin
    if (!rst_ni) begin
      z2 <= 0;
      z0 <= 0;
    end
    else if(MULT) begin
      if (BufferLength <= 32) begin
        z2 <= topA * topB;
        z0 <= bottomA * bottomB;  
      end 
      else begin
        accelerator #(.BufferLength(HalfLength), .InputALength(HalfLength), .InputBLength(HalfLength)) subAcc2(
          .clk_i(clk_i), 
          .rst_ni(rst_ni), 
          .inputA(topA), 
          .inputB(topB), 
          .start(subAcc2Start),
          .done(subAcc2Done),
          .outputM(z2)
        );
        accelerator #(.BufferLength(HalfLength), .InputALength(HalfLength), .InputBLength(HalfLength)) subAcc3(
          .clk_i(clk_i), 
          .rst_ni(rst_ni), 
          .inputA(bottomA), 
          .inputB(bottomB), 
          .start(subAcc3Start),
          .done(subAcc3Done),
          .outputM(z0)
        );
      end
    end
  end
  
  always_ff @(posedge clk_i or negedge rst_ni) begin
    if (!rst_ni) begin
      tempA <= 0;
    end
    else if(FIRST_SUB) begin
      tempA <= z0 - sumsMult;
    end
  end
  
  always_ff @(posedge clk_i or negedge rst_ni) begin
    if (!rst_ni) begin
      z1 <= 0;
    end
    else if(SECOND_SUB) begin
      z1 <= z2 - tempA;
    end
  end
  
  always_ff @(posedge clk_i or negedge rst_ni) begin
    if (!rst_ni) begin
      z2Shifted <= 0;
      z1Shifted <= 0;
    end
    else if(SECOND_BUFFER) begin
      z2Shifted <= z2 << BufferLength;
      z1Shifted <= z1 << HalfLength;
    end
  end
  
  always_ff @(posedge clk_i or negedge rst_ni) begin
    if (!rst_ni) begin
      tempM2 <= 0;
    end 
    else if(SECOND_ADD) begin
      tempM2 <= z2Shifted + z0;
    end
  end
  
  
  always_ff @(posedge clk_i or negedge rst_ni) begin
    if (!rst_ni) begin
      outputM <= 0;
    end 
    else if(THIRD_ADD) begin
      outputM <= tempM2 + z1Shifted;
    end
  end 


end module
